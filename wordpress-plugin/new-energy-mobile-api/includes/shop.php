<?php
/**
 * Native mobile shop routes backed by WooCommerce orders.
 */

if (!defined('ABSPATH')) {
    exit;
}

add_action('woocommerce_order_status_changed', 'nem_audit_shop_order_status_change', 10, 4);

function nem_register_shop_routes(): void
{
    register_rest_route(
        NEM_API_NAMESPACE,
        '/shop/orders',
        [
            [
                'methods' => WP_REST_Server::READABLE,
                'permission_callback' => 'nem_rest_authenticated_permission',
                'callback' => 'nem_rest_list_shop_orders',
            ],
            [
                'methods' => WP_REST_Server::CREATABLE,
                'permission_callback' => 'nem_rest_authenticated_permission',
                'callback' => 'nem_rest_create_shop_order',
            ],
        ]
    );
}

function nem_rest_list_shop_orders()
{
    $availability_error = nem_shop_woocommerce_error();
    if (is_wp_error($availability_error)) {
        return $availability_error;
    }

    $orders = wc_get_orders(
        [
            'customer_id' => get_current_user_id(),
            'limit' => 20,
            'orderby' => 'date',
            'order' => 'DESC',
            'return' => 'objects',
        ]
    );

    $items = [];
    foreach ($orders as $order) {
        if ($order instanceof WC_Order) {
            $items[] = nem_serialize_shop_order($order);
        }
    }

    nem_audit_log('shop.history_viewed', 'shop_order', null, ['item_count' => count($items)]);
    return rest_ensure_response($items);
}

function nem_rest_create_shop_order(WP_REST_Request $request)
{
    $availability_error = nem_shop_woocommerce_error();
    if (is_wp_error($availability_error)) {
        return $availability_error;
    }

    $params = $request->get_json_params();
    if (!is_array($params)) {
        $params = [];
    }

    $user_id = get_current_user_id();
    $mutation_id = sanitize_text_field((string) ($params['client_mutation_id'] ?? ''));
    if (!preg_match('/^[A-Za-z0-9_-]{8,100}$/', $mutation_id)) {
        return new WP_Error('nem_invalid_shop_order', 'The order retry key is invalid.', ['status' => 400]);
    }

    $retry_key = 'nem_shop_' . md5($user_id . '|' . $mutation_id);
    $existing_id = (int) get_transient($retry_key);
    if ($existing_id > 0) {
        $existing = wc_get_order($existing_id);
        if ($existing instanceof WC_Order && (int) $existing->get_customer_id() === $user_id) {
            return rest_ensure_response(nem_serialize_shop_order($existing));
        }
    }

    $rate_error = nem_auth_rate_limit('shop-order:' . $user_id, 10, 15 * MINUTE_IN_SECONDS);
    if (is_wp_error($rate_error)) {
        return $rate_error;
    }

    $raw_items = $params['items'] ?? [];
    $customer_name = nem_limit_text(sanitize_text_field((string) ($params['customer_name'] ?? '')), 120);
    $phone = nem_normalize_phone((string) ($params['phone'] ?? ''));
    $address = nem_limit_text(sanitize_text_field((string) ($params['address'] ?? '')), 190);
    $city = nem_limit_text(sanitize_text_field((string) ($params['city'] ?? '')), 100);
    $notes = nem_limit_text(sanitize_textarea_field((string) ($params['notes'] ?? '')), 1000);

    if (
        !is_array($raw_items)
        || !$raw_items
        || count($raw_items) > 25
        || $customer_name === ''
        || !nem_phone_is_valid($phone)
        || $address === ''
        || $city === ''
    ) {
        return new WP_Error('nem_invalid_shop_order', 'Valid products and delivery details are required.', ['status' => 400]);
    }

    $validated_items = [];
    foreach ($raw_items as $raw_item) {
        if (!is_array($raw_item)) {
            return new WP_Error('nem_invalid_shop_order', 'An order item is invalid.', ['status' => 400]);
        }

        $product_id = absint($raw_item['product_id'] ?? 0);
        $quantity = absint($raw_item['quantity'] ?? 0);
        if ($product_id <= 0 || $quantity < 1 || $quantity > 20) {
            return new WP_Error('nem_invalid_shop_order', 'An order item is invalid.', ['status' => 400]);
        }

        $product = wc_get_product($product_id);
        if (
            !$product instanceof WC_Product
            || $product->get_status() !== 'publish'
            || !$product->is_purchasable()
            || $product->is_type('variable')
        ) {
            return new WP_Error('nem_product_unavailable', 'A selected product is unavailable.', ['status' => 409]);
        }
        if (!$product->is_in_stock() || !$product->has_enough_stock($quantity)) {
            return new WP_Error('nem_product_out_of_stock', 'The requested quantity is unavailable.', ['status' => 409]);
        }

        $validated_items[] = ['product' => $product, 'quantity' => $quantity];
    }

    $user = wp_get_current_user();
    [$first_name, $last_name] = nem_split_customer_name($customer_name);
    $order = null;

    try {
        $order = wc_create_order(
            [
                'customer_id' => $user_id,
                'created_via' => 'newenergy-mobile',
            ]
        );
        if (is_wp_error($order)) {
            return $order;
        }

        foreach ($validated_items as $item) {
            $added = $order->add_product($item['product'], $item['quantity']);
            if (!$added) {
                throw new RuntimeException('Unable to add a product to the order.');
            }
        }

        $order->set_billing_first_name($first_name);
        $order->set_billing_last_name($last_name);
        $order->set_billing_email(sanitize_email((string) $user->user_email));
        $order->set_billing_phone($phone);
        $order->set_billing_address_1($address);
        $order->set_billing_city($city);
        $order->set_billing_country('EG');
        $order->set_shipping_first_name($first_name);
        $order->set_shipping_last_name($last_name);
        $order->set_shipping_address_1($address);
        $order->set_shipping_city($city);
        $order->set_shipping_country('EG');
        $order->set_customer_note($notes);
        $order->set_payment_method('nem_mobile_confirmation');
        $order->set_payment_method_title('New Energy mobile confirmation');
        $order->add_meta_data('_nem_mobile_order', 'yes', true);
        $order->add_meta_data('_nem_client_mutation_id', $mutation_id, true);
        $order->calculate_totals(true);
        $order->save();
        $order->update_status('on-hold', 'Order placed from the New Energy mobile app.', true);

        set_transient($retry_key, $order->get_id(), 7 * DAY_IN_SECONDS);
        nem_audit_log(
            'shop.order_created',
            'shop_order',
            $order->get_id(),
            [
                'item_count' => count($validated_items),
                'total' => (float) $order->get_total(),
                'currency' => $order->get_currency(),
            ]
        );

        return new WP_REST_Response(nem_serialize_shop_order($order), 201);
    } catch (Throwable $error) {
        if ($order instanceof WC_Order && $order->get_id()) {
            $order->delete(true);
        }
        nem_audit_log('shop.order_failed', 'shop_order', null, ['reason' => 'order_creation_error']);
        return new WP_Error('nem_shop_order_failed', 'The shop order could not be created.', ['status' => 500]);
    }
}

function nem_serialize_shop_order(WC_Order $order): array
{
    $item_count = 0;
    foreach ($order->get_items() as $item) {
        $item_count += max(0, (int) $item->get_quantity());
    }
    $created = $order->get_date_created();

    return [
        'id' => $order->get_id(),
        'number' => $order->get_order_number(),
        'status' => $order->get_status(),
        'total' => (float) $order->get_total(),
        'currency' => $order->get_currency(),
        'createdAt' => $created ? $created->date('c') : '',
        'itemCount' => $item_count,
    ];
}

function nem_shop_woocommerce_error()
{
    if (!class_exists('WooCommerce') || !function_exists('wc_get_orders') || !function_exists('wc_create_order')) {
        return new WP_Error('nem_woocommerce_unavailable', 'WooCommerce is not available.', ['status' => 503]);
    }
    return null;
}

function nem_split_customer_name(string $name): array
{
    $parts = preg_split('/\s+/u', trim($name), 2);
    if (!is_array($parts) || !$parts) {
        return [$name, ''];
    }
    return [(string) ($parts[0] ?? ''), (string) ($parts[1] ?? '')];
}

function nem_audit_shop_order_status_change($order_id, $from_status, $to_status, $order): void
{
    if (!$order instanceof WC_Order) {
        $order = wc_get_order((int) $order_id);
    }
    if (
        !$order instanceof WC_Order
        || ($order->get_created_via() !== 'newenergy-mobile' && $order->get_meta('_nem_mobile_order') !== 'yes')
    ) {
        return;
    }

    nem_audit_log(
        'shop.order_status_changed',
        'shop_order',
        (int) $order->get_id(),
        [
            'from_status' => sanitize_key((string) $from_status),
            'to_status' => sanitize_key((string) $to_status),
        ]
    );
}
