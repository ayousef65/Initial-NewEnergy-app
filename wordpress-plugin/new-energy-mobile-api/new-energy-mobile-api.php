<?php
/**
 * Plugin Name: New Energy Mobile API
 * Description: Connects the New Energy mobile app to WordPress with service requests, maintenance updates, invoices, payments, and reviews.
 * Version: 1.1.1
 * Author: New Energy
 * Update URI: https://newenergyeg.com/new-energy-mobile-api
 */

if (!defined('ABSPATH')) {
    exit;
}

const NEM_API_NAMESPACE = 'newenergy/v1';
const NEM_REQUEST_CPT = 'ne_service_request';
const NEM_TOKEN_OPTION = 'nem_mobile_api_token';
const NEM_PLUGIN_VERSION = '1.1.1';
const NEM_UPDATE_OPTION = 'nem_mobile_update_manifest_url';
const NEM_GITHUB_REPO_OPTION = 'nem_mobile_github_repo';
const NEM_GITHUB_ASSET_OPTION = 'nem_mobile_github_asset';

register_activation_hook(__FILE__, 'nem_activate_plugin');
register_deactivation_hook(__FILE__, 'nem_deactivate_plugin');

add_action('init', 'nem_register_request_post_type');
add_action('init', 'nem_register_request_meta');
add_action('rest_api_init', 'nem_register_rest_routes');
add_action('admin_menu', 'nem_register_admin_page');
add_action('add_meta_boxes', 'nem_register_request_metaboxes');
add_action('save_post_' . NEM_REQUEST_CPT, 'nem_save_request_meta');
add_filter('manage_ne_service_request_posts_columns', 'nem_request_columns');
add_action('manage_ne_service_request_posts_custom_column', 'nem_request_column_values', 10, 2);
add_filter('site_transient_update_plugins', 'nem_check_for_plugin_update');
add_filter('plugins_api', 'nem_plugin_update_info', 10, 3);

function nem_activate_plugin(): void
{
    if (!get_option(NEM_TOKEN_OPTION)) {
        add_option(NEM_TOKEN_OPTION, wp_generate_password(48, false, false));
    }

    nem_register_request_post_type();
    flush_rewrite_rules();
}

function nem_deactivate_plugin(): void
{
    flush_rewrite_rules();
}

function nem_register_request_post_type(): void
{
    register_post_type(
        NEM_REQUEST_CPT,
        [
            'labels' => [
                'name' => 'Mobile Service Requests',
                'singular_name' => 'Mobile Service Request',
                'add_new_item' => 'Add Service Request',
                'edit_item' => 'Edit Service Request',
                'menu_name' => 'Mobile Requests',
            ],
            'public' => false,
            'show_ui' => true,
            'show_in_menu' => true,
            'show_in_rest' => true,
            'menu_icon' => 'dashicons-car',
            'supports' => ['title'],
            'capability_type' => 'post',
        ]
    );
}

function nem_register_request_meta(): void
{
    $fields = [
        'request_number',
        'service_id',
        'service_title',
        'status',
        'priority',
        'customer_name',
        'phone',
        'vehicle',
        'location',
        'preferred_date',
        'notes',
        'report_text',
        'repair_items',
        'invoice_items',
        'invoice_total',
        'payment_status',
        'payment_method',
        'paid_amount',
        'rating',
        'review_message',
    ];

    foreach ($fields as $field) {
        register_post_meta(
            NEM_REQUEST_CPT,
            $field,
            [
                'single' => true,
                'type' => 'string',
                'show_in_rest' => true,
                'auth_callback' => static function () {
                    return current_user_can('edit_posts');
                },
            ]
        );
    }
}

function nem_register_rest_routes(): void
{
    register_rest_route(
        NEM_API_NAMESPACE,
        '/health',
        [
            'methods' => WP_REST_Server::READABLE,
            'permission_callback' => '__return_true',
            'callback' => 'nem_rest_health',
        ]
    );

    register_rest_route(
        NEM_API_NAMESPACE,
        '/service-requests',
        [
            [
                'methods' => WP_REST_Server::CREATABLE,
                'permission_callback' => 'nem_rest_permission',
                'callback' => 'nem_rest_create_request',
            ],
            [
                'methods' => WP_REST_Server::READABLE,
                'permission_callback' => 'nem_rest_permission',
                'callback' => 'nem_rest_list_requests',
            ],
        ]
    );

    register_rest_route(
        NEM_API_NAMESPACE,
        '/service-requests/(?P<id>\d+)',
        [
            'methods' => WP_REST_Server::READABLE,
            'permission_callback' => 'nem_rest_permission',
            'callback' => 'nem_rest_get_request',
            'args' => [
                'id' => [
                    'validate_callback' => 'is_numeric',
                ],
            ],
        ]
    );

    register_rest_route(
        NEM_API_NAMESPACE,
        '/service-requests/(?P<id>\d+)/payment',
        [
            'methods' => WP_REST_Server::CREATABLE,
            'permission_callback' => 'nem_rest_permission',
            'callback' => 'nem_rest_record_payment',
            'args' => [
                'id' => [
                    'validate_callback' => 'is_numeric',
                ],
            ],
        ]
    );

    register_rest_route(
        NEM_API_NAMESPACE,
        '/service-requests/(?P<id>\d+)/review',
        [
            'methods' => WP_REST_Server::CREATABLE,
            'permission_callback' => 'nem_rest_permission',
            'callback' => 'nem_rest_record_review',
            'args' => [
                'id' => [
                    'validate_callback' => 'is_numeric',
                ],
            ],
        ]
    );
}

function nem_rest_permission(WP_REST_Request $request)
{
    $configured_token = (string) get_option(NEM_TOKEN_OPTION);
    $provided_token = (string) $request->get_header('x-newenergy-app-token');

    if (!$provided_token) {
        $provided_token = (string) $request->get_param('app_token');
    }

    if (!$configured_token || !$provided_token || !hash_equals($configured_token, $provided_token)) {
        return new WP_Error(
            'nem_invalid_token',
            'Invalid New Energy app token.',
            ['status' => 401]
        );
    }

    return true;
}

function nem_rest_health(): WP_REST_Response
{
    return rest_ensure_response(
        [
            'ok' => true,
            'site' => home_url(),
            'namespace' => NEM_API_NAMESPACE,
        ]
    );
}

function nem_rest_create_request(WP_REST_Request $request)
{
    $params = $request->get_json_params();
    if (!is_array($params)) {
        $params = [];
    }

    $phone = nem_get_param($params, 'phone');
    $location = nem_get_param($params, 'location');
    $service_title = nem_get_param($params, 'service_title');

    if (!$phone || !$location) {
        return new WP_Error(
            'nem_missing_required_fields',
            'Phone and location are required.',
            ['status' => 400]
        );
    }

    $post_id = wp_insert_post(
        [
            'post_type' => NEM_REQUEST_CPT,
            'post_status' => 'publish',
            'post_title' => sprintf('%s - %s', $service_title ?: 'Mobile request', $phone),
            'post_content' => nem_get_param($params, 'notes'),
        ],
        true
    );

    if (is_wp_error($post_id)) {
        return $post_id;
    }

    $request_number = 'NE-' . $post_id;
    $meta = [
        'request_number' => $request_number,
        'service_id' => nem_get_param($params, 'service_id'),
        'service_title' => $service_title,
        'status' => nem_get_param($params, 'status') ?: 'registered',
        'priority' => nem_get_param($params, 'priority'),
        'customer_name' => nem_get_param($params, 'customer_name'),
        'phone' => $phone,
        'vehicle' => nem_get_param($params, 'vehicle'),
        'location' => $location,
        'preferred_date' => nem_get_param($params, 'preferred_date'),
        'notes' => nem_get_param($params, 'notes'),
        'report_text' => '',
        'repair_items' => wp_json_encode([]),
        'invoice_items' => wp_json_encode([]),
        'invoice_total' => '0',
        'payment_status' => 'pending',
        'payment_method' => '',
        'paid_amount' => '0',
        'rating' => '0',
        'review_message' => '',
    ];

    foreach ($meta as $key => $value) {
        update_post_meta($post_id, $key, $value);
    }

    return new WP_REST_Response(nem_serialize_request($post_id), 201);
}

function nem_rest_list_requests(WP_REST_Request $request): WP_REST_Response
{
    $phone = sanitize_text_field((string) $request->get_param('phone'));

    $args = [
        'post_type' => NEM_REQUEST_CPT,
        'post_status' => 'publish',
        'posts_per_page' => 30,
        'orderby' => 'date',
        'order' => 'DESC',
    ];

    if ($phone) {
        $args['meta_query'] = [
            [
                'key' => 'phone',
                'value' => $phone,
                'compare' => '=',
            ],
        ];
    }

    $query = new WP_Query($args);
    $items = [];

    foreach ($query->posts as $post) {
        $items[] = nem_serialize_request((int) $post->ID);
    }

    return rest_ensure_response($items);
}

function nem_rest_get_request(WP_REST_Request $request)
{
    $post_id = (int) $request['id'];

    if (get_post_type($post_id) !== NEM_REQUEST_CPT) {
        return new WP_Error('nem_not_found', 'Service request not found.', ['status' => 404]);
    }

    return rest_ensure_response(nem_serialize_request($post_id));
}

function nem_rest_record_payment(WP_REST_Request $request)
{
    $post_id = (int) $request['id'];

    if (get_post_type($post_id) !== NEM_REQUEST_CPT) {
        return new WP_Error('nem_not_found', 'Service request not found.', ['status' => 404]);
    }

    $params = $request->get_json_params();
    if (!is_array($params)) {
        $params = [];
    }

    $status = nem_get_param($params, 'status') ?: 'paid';
    $method = nem_get_param($params, 'payment_method');
    $amount = (float) nem_get_param($params, 'amount');

    update_post_meta($post_id, 'payment_status', $status);
    update_post_meta($post_id, 'payment_method', $method);
    update_post_meta($post_id, 'paid_amount', (string) $amount);
    update_post_meta($post_id, 'status', $status === 'paid' ? 'paid' : get_post_meta($post_id, 'status', true));

    add_post_meta(
        $post_id,
        'payment_event',
        wp_json_encode(
            [
                'status' => $status,
                'method' => $method,
                'amount' => $amount,
                'created_at' => current_time('mysql'),
            ]
        )
    );

    return rest_ensure_response(nem_serialize_request($post_id));
}

function nem_rest_record_review(WP_REST_Request $request)
{
    $post_id = (int) $request['id'];

    if (get_post_type($post_id) !== NEM_REQUEST_CPT) {
        return new WP_Error('nem_not_found', 'Service request not found.', ['status' => 404]);
    }

    $params = $request->get_json_params();
    if (!is_array($params)) {
        $params = [];
    }

    $rating = max(1, min(5, (int) nem_get_param($params, 'rating')));
    $message = nem_get_param($params, 'message');

    update_post_meta($post_id, 'rating', (string) $rating);
    update_post_meta($post_id, 'review_message', $message);

    return rest_ensure_response(nem_serialize_request($post_id));
}

function nem_get_param(array $params, string $key): string
{
    return sanitize_text_field((string) ($params[$key] ?? ''));
}

function nem_serialize_request(int $post_id): array
{
    $invoice_items = json_decode((string) get_post_meta($post_id, 'invoice_items', true), true);
    if (!is_array($invoice_items)) {
        $invoice_items = [];
    }

    $repair_items = json_decode((string) get_post_meta($post_id, 'repair_items', true), true);
    if (!is_array($repair_items)) {
        $repair_items = [];
    }

    return [
        'id' => $post_id,
        'requestNumber' => (string) get_post_meta($post_id, 'request_number', true),
        'serviceId' => (string) get_post_meta($post_id, 'service_id', true),
        'serviceTitle' => (string) get_post_meta($post_id, 'service_title', true),
        'status' => (string) get_post_meta($post_id, 'status', true),
        'priority' => (string) get_post_meta($post_id, 'priority', true),
        'customerName' => (string) get_post_meta($post_id, 'customer_name', true),
        'phone' => (string) get_post_meta($post_id, 'phone', true),
        'vehicle' => (string) get_post_meta($post_id, 'vehicle', true),
        'location' => (string) get_post_meta($post_id, 'location', true),
        'preferredDate' => (string) get_post_meta($post_id, 'preferred_date', true),
        'notes' => (string) get_post_meta($post_id, 'notes', true),
        'reportText' => (string) get_post_meta($post_id, 'report_text', true),
        'repairItems' => $repair_items,
        'invoiceItems' => $invoice_items,
        'invoiceTotal' => (float) get_post_meta($post_id, 'invoice_total', true),
        'paymentStatus' => (string) get_post_meta($post_id, 'payment_status', true),
        'paymentMethod' => (string) get_post_meta($post_id, 'payment_method', true),
        'paidAmount' => (float) get_post_meta($post_id, 'paid_amount', true),
        'rating' => (int) get_post_meta($post_id, 'rating', true),
        'createdAt' => get_post_time('c', true, $post_id),
        'updatedAt' => get_post_modified_time('c', true, $post_id),
    ];
}

function nem_register_admin_page(): void
{
    add_options_page(
        'New Energy Mobile API',
        'New Energy Mobile API',
        'manage_options',
        'new-energy-mobile-api',
        'nem_render_admin_page'
    );
}

function nem_render_admin_page(): void
{
    if (!current_user_can('manage_options')) {
        return;
    }

    if (isset($_POST['nem_rotate_token']) && check_admin_referer('nem_rotate_token_action')) {
        update_option(NEM_TOKEN_OPTION, wp_generate_password(48, false, false));
        echo '<div class="notice notice-success"><p>New token generated.</p></div>';
    }

    if (isset($_POST['nem_save_update_settings']) && check_admin_referer('nem_update_settings_action')) {
        update_option(NEM_UPDATE_OPTION, esc_url_raw((string) ($_POST['nem_update_manifest_url'] ?? '')));
        update_option(NEM_GITHUB_REPO_OPTION, sanitize_text_field((string) ($_POST['nem_github_repo'] ?? '')));
        update_option(NEM_GITHUB_ASSET_OPTION, sanitize_file_name((string) ($_POST['nem_github_asset'] ?? 'new-energy-mobile-api.zip')));
        delete_site_transient('update_plugins');
        echo '<div class="notice notice-success"><p>Update settings saved.</p></div>';
    }

    $token = (string) get_option(NEM_TOKEN_OPTION);
    $base = esc_url_raw(rest_url(NEM_API_NAMESPACE));
    $manifest_url = (string) get_option(NEM_UPDATE_OPTION);
    $github_repo = (string) get_option(NEM_GITHUB_REPO_OPTION);
    $github_asset = (string) get_option(NEM_GITHUB_ASSET_OPTION, 'new-energy-mobile-api.zip');

    echo '<div class="wrap">';
    echo '<h1>New Energy Mobile API</h1>';
    echo '<p>Use this screen to connect the Expo mobile app with this WordPress website.</p>';
    echo '<table class="widefat striped" style="max-width: 900px;">';
    echo '<tbody>';
    echo '<tr><th scope="row">REST base URL</th><td><code>' . esc_html($base) . '</code></td></tr>';
    echo '<tr><th scope="row">Installed version</th><td><code>' . esc_html(NEM_PLUGIN_VERSION) . '</code></td></tr>';
    echo '<tr><th scope="row">App token</th><td><code style="word-break: break-all;">' . esc_html($token) . '</code></td></tr>';
    echo '<tr><th scope="row">Mobile env key</th><td><code>EXPO_PUBLIC_NEWENERGY_APP_TOKEN</code></td></tr>';
    echo '</tbody>';
    echo '</table>';
    echo '<form method="post" style="margin-top: 16px;">';
    wp_nonce_field('nem_rotate_token_action');
    submit_button('Generate New Token', 'secondary', 'nem_rotate_token');
    echo '</form>';
    echo '<h2>Plugin Updates</h2>';
    echo '<p>Use a GitHub public repository release asset, or paste a public update manifest URL.</p>';
    echo '<form method="post" style="max-width: 900px;">';
    wp_nonce_field('nem_update_settings_action');
    echo '<p><label><strong>GitHub repository</strong></label><br>';
    echo '<input type="text" name="nem_github_repo" value="' . esc_attr($github_repo) . '" class="regular-text" style="width:100%;max-width:720px;" placeholder="owner/repository"></p>';
    echo '<p><label><strong>GitHub release asset</strong></label><br>';
    echo '<input type="text" name="nem_github_asset" value="' . esc_attr($github_asset) . '" class="regular-text" style="width:100%;max-width:720px;" placeholder="new-energy-mobile-api.zip"></p>';
    echo '<p><label><strong>Manifest URL fallback</strong></label><br>';
    echo '<input type="url" name="nem_update_manifest_url" value="' . esc_attr($manifest_url) . '" class="regular-text" style="width:100%;max-width:720px;" placeholder="https://example.com/new-energy-mobile-api-update.json"></p>';
    submit_button('Save Update Settings', 'secondary', 'nem_save_update_settings');
    echo '</form>';
    echo '<p>Requests created by the app are stored under <strong>Mobile Requests</strong> in the WordPress admin menu.</p>';
    echo '</div>';
}

function nem_check_for_plugin_update($transient)
{
    if (!is_object($transient)) {
        return $transient;
    }

    $manifest = nem_get_update_manifest();
    if (!$manifest || empty($manifest['version']) || empty($manifest['download_url'])) {
        return $transient;
    }

    if (!version_compare(NEM_PLUGIN_VERSION, (string) $manifest['version'], '<')) {
        return $transient;
    }

    $plugin_file = plugin_basename(__FILE__);
    if (!isset($transient->response) || !is_array($transient->response)) {
        $transient->response = [];
    }

    $update = (object) [
        'id' => $manifest['details_url'] ?? $manifest['download_url'],
        'slug' => dirname($plugin_file),
        'plugin' => $plugin_file,
        'new_version' => (string) $manifest['version'],
        'url' => $manifest['details_url'] ?? 'https://newenergyeg.com',
        'package' => (string) $manifest['download_url'],
        'tested' => $manifest['tested'] ?? '',
        'requires' => $manifest['requires'] ?? '',
        'requires_php' => $manifest['requires_php'] ?? '',
    ];

    $transient->response[$plugin_file] = $update;
    return $transient;
}

function nem_plugin_update_info($result, string $action, object $args)
{
    $plugin_file = plugin_basename(__FILE__);
    if ($action !== 'plugin_information' || ($args->slug ?? '') !== dirname($plugin_file)) {
        return $result;
    }

    $manifest = nem_get_update_manifest();
    if (!$manifest) {
        return $result;
    }

    return (object) [
        'name' => 'New Energy Mobile API',
        'slug' => dirname($plugin_file),
        'version' => $manifest['version'] ?? NEM_PLUGIN_VERSION,
        'author' => 'New Energy',
        'homepage' => $manifest['details_url'] ?? 'https://newenergyeg.com',
        'requires' => $manifest['requires'] ?? '',
        'tested' => $manifest['tested'] ?? '',
        'requires_php' => $manifest['requires_php'] ?? '',
        'download_link' => $manifest['download_url'] ?? '',
        'sections' => [
            'description' => $manifest['description'] ?? 'Mobile app API and request management for New Energy.',
            'changelog' => $manifest['changelog'] ?? '',
        ],
    ];
}

function nem_get_update_manifest(): ?array
{
    $url = esc_url_raw((string) get_option(NEM_UPDATE_OPTION));
    if ($url) {
        $response = wp_remote_get($url, ['timeout' => 10]);
        if (!is_wp_error($response) && wp_remote_retrieve_response_code($response) === 200) {
            $manifest = json_decode(wp_remote_retrieve_body($response), true);
            return is_array($manifest) ? $manifest : null;
        }
    }

    return nem_get_github_release_manifest();
}

function nem_get_github_release_manifest(): ?array
{
    $repo = trim((string) get_option(NEM_GITHUB_REPO_OPTION));
    if (!$repo || !preg_match('/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/', $repo)) {
        return null;
    }

    $asset_name = (string) get_option(NEM_GITHUB_ASSET_OPTION, 'new-energy-mobile-api.zip');
    $response = wp_remote_get(
        'https://api.github.com/repos/' . $repo . '/releases/latest',
        [
            'timeout' => 10,
            'headers' => [
                'Accept' => 'application/vnd.github+json',
                'User-Agent' => 'New-Energy-Mobile-API-Updater',
            ],
        ]
    );

    if (is_wp_error($response) || wp_remote_retrieve_response_code($response) !== 200) {
        return null;
    }

    $release = json_decode(wp_remote_retrieve_body($response), true);
    if (!is_array($release) || empty($release['tag_name']) || empty($release['assets']) || !is_array($release['assets'])) {
        return null;
    }

    foreach ($release['assets'] as $asset) {
        if (!is_array($asset) || ($asset['name'] ?? '') !== $asset_name || empty($asset['browser_download_url'])) {
            continue;
        }

        return [
            'version' => ltrim((string) $release['tag_name'], 'vV'),
            'download_url' => (string) $asset['browser_download_url'],
            'details_url' => (string) ($release['html_url'] ?? 'https://github.com/' . $repo),
            'description' => 'Mobile app API and request management for New Energy.',
            'changelog' => (string) ($release['body'] ?? ''),
        ];
    }

    return null;
}

function nem_register_request_metaboxes(): void
{
    add_meta_box(
        'nem_request_details',
        'Request Details',
        'nem_render_request_details_metabox',
        NEM_REQUEST_CPT,
        'normal',
        'high'
    );
}

function nem_render_request_details_metabox(WP_Post $post): void
{
    wp_nonce_field('nem_save_request_meta', 'nem_request_meta_nonce');

    $invoice_items = json_decode((string) get_post_meta($post->ID, 'invoice_items', true), true);
    if (!is_array($invoice_items)) {
        $invoice_items = [];
    }

    $repair_items = json_decode((string) get_post_meta($post->ID, 'repair_items', true), true);
    if (!is_array($repair_items)) {
        $repair_items = [];
    }

    while (count($invoice_items) < 5) {
        $invoice_items[] = ['label' => '', 'amount' => ''];
    }

    while (count($repair_items) < 6) {
        $repair_items[] = ['issue' => '', 'fix' => '', 'status' => 'checking'];
    }

    $request_number = (string) get_post_meta($post->ID, 'request_number', true);
    $service_title = (string) get_post_meta($post->ID, 'service_title', true);
    $customer_name = (string) get_post_meta($post->ID, 'customer_name', true);
    $phone = (string) get_post_meta($post->ID, 'phone', true);
    $status = (string) get_post_meta($post->ID, 'status', true);

    echo '<style>
        .nem-app{background:#f6f7f9;border:1px solid #e2e6ea;border-radius:8px;padding:16px}
        .nem-hero{display:flex;justify-content:space-between;gap:16px;align-items:flex-start;background:#15232d;color:#fff;border-radius:8px;padding:16px;margin-bottom:14px}
        .nem-hero h2{color:#fff;margin:6px 0 4px}
        .nem-hero p{margin:0;color:#c9d3da}
        .nem-badge{display:inline-block;border-radius:8px;padding:6px 10px;background:#e0f3ef;color:#157a6e;font-weight:700}
        .nem-hero .nem-badge{background:#fff;color:#15232d}
        .nem-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}
        .nem-card{background:#fff;border:1px solid #e2e6ea;border-radius:8px;padding:16px;margin-top:14px}
        .nem-card h3{margin-top:0}
        .nem-field label{display:block;font-weight:600;margin-bottom:5px}
        .nem-field input,.nem-field select,.nem-field textarea{width:100%}
        .nem-field textarea{min-height:110px}
        .nem-invoice-row{display:grid;grid-template-columns:1fr 160px;gap:10px;margin-bottom:8px}
        .nem-repair-row{display:grid;grid-template-columns:1fr 1fr 160px;gap:10px;margin-bottom:10px}
        .nem-help{color:#646970;margin-top:0}
        @media(max-width:900px){.nem-grid,.nem-invoice-row,.nem-repair-row{grid-template-columns:1fr}.nem-hero{display:block}}
    </style>';

    echo '<div class="nem-app">';
    echo '<div class="nem-hero">';
    echo '<div><span class="nem-badge">' . esc_html($request_number ?: 'New request') . '</span><h2>' . esc_html($service_title ?: 'Mobile Request') . '</h2><p>' . esc_html(trim($customer_name . ' - ' . $phone, ' -')) . '</p></div>';
    echo '<span class="nem-badge">' . esc_html($status ?: 'registered') . '</span>';
    echo '</div>';

    echo '<div class="nem-grid">';
    echo '<div class="nem-card"><h3>Customer Request</h3>';
    nem_admin_input($post->ID, 'request_number', 'Request Number', true);
    nem_admin_input($post->ID, 'service_title', 'Service');
    nem_admin_input($post->ID, 'customer_name', 'Customer Name');
    nem_admin_input($post->ID, 'phone', 'Phone');
    nem_admin_input($post->ID, 'vehicle', 'Vehicle');
    nem_admin_input($post->ID, 'location', 'Location');
    nem_admin_input($post->ID, 'preferred_date', 'Preferred Date');
    nem_admin_input($post->ID, 'priority', 'Priority');
    echo '</div>';

    echo '<div class="nem-card"><h3>Status & Payment</h3>';
    nem_admin_select($post->ID, 'status', 'Maintenance Status', nem_status_options());
    nem_admin_select($post->ID, 'payment_status', 'Payment Status', nem_payment_status_options());
    nem_admin_input($post->ID, 'payment_method', 'Payment Method');
    nem_admin_input($post->ID, 'paid_amount', 'Paid Amount');
    echo '</div>';
    echo '</div>';

    echo '<div class="nem-card"><h3>Notes & Technical Report</h3>';
    nem_admin_textarea($post->ID, 'notes', 'Customer Notes');
    nem_admin_textarea($post->ID, 'report_text', 'Technical Report');
    echo '</div>';

    echo '<div class="nem-card"><h3>Missing / Problems / Repairs</h3>';
    echo '<p class="nem-help">Use these rows to tell the customer what is missing, what is not needed, what was fixed, and what is still pending.</p>';
    foreach ($repair_items as $index => $item) {
        $issue = is_array($item) ? (string) ($item['issue'] ?? '') : '';
        $fix = is_array($item) ? (string) ($item['fix'] ?? '') : '';
        $repair_status = is_array($item) ? (string) ($item['status'] ?? 'checking') : 'checking';
        echo '<div class="nem-repair-row">';
        echo '<input type="text" name="nem_repair_items[' . esc_attr((string) $index) . '][issue]" value="' . esc_attr($issue) . '" placeholder="Missing item / problem">';
        echo '<input type="text" name="nem_repair_items[' . esc_attr((string) $index) . '][fix]" value="' . esc_attr($fix) . '" placeholder="Repair note / not needed">';
        echo '<select name="nem_repair_items[' . esc_attr((string) $index) . '][status]">';
        foreach (nem_repair_status_options() as $option_value => $option_label) {
            echo '<option value="' . esc_attr((string) $option_value) . '"' . selected($repair_status, (string) $option_value, false) . '>' . esc_html((string) $option_label) . '</option>';
        }
        echo '</select>';
        echo '</div>';
    }
    echo '</div>';

    echo '<div class="nem-card"><h3>Invoice Items</h3>';
    foreach ($invoice_items as $index => $item) {
        $label = is_array($item) ? (string) ($item['label'] ?? '') : '';
        $amount = is_array($item) ? (string) ($item['amount'] ?? '') : '';
        echo '<div class="nem-invoice-row">';
        echo '<input type="text" name="nem_invoice_items[' . esc_attr((string) $index) . '][label]" value="' . esc_attr($label) . '" placeholder="Item label">';
        echo '<input type="number" step="0.01" min="0" name="nem_invoice_items[' . esc_attr((string) $index) . '][amount]" value="' . esc_attr($amount) . '" placeholder="Amount">';
        echo '</div>';
    }
    echo '</div>';
    echo '</div>';
}

function nem_save_request_meta(int $post_id): void
{
    if (!isset($_POST['nem_request_meta_nonce']) || !wp_verify_nonce((string) $_POST['nem_request_meta_nonce'], 'nem_save_request_meta')) {
        return;
    }

    if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE) {
        return;
    }

    if (!current_user_can('edit_post', $post_id)) {
        return;
    }

    $meta = isset($_POST['nem_meta']) && is_array($_POST['nem_meta']) ? $_POST['nem_meta'] : [];
    $text_fields = [
        'service_title',
        'customer_name',
        'phone',
        'vehicle',
        'location',
        'preferred_date',
        'priority',
        'status',
        'payment_status',
        'payment_method',
        'paid_amount',
    ];

    foreach ($text_fields as $field) {
        update_post_meta($post_id, $field, sanitize_text_field((string) ($meta[$field] ?? '')));
    }

    update_post_meta($post_id, 'notes', sanitize_textarea_field((string) ($meta['notes'] ?? '')));
    update_post_meta($post_id, 'report_text', sanitize_textarea_field((string) ($meta['report_text'] ?? '')));

    $repair_items = [];
    $raw_repairs = isset($_POST['nem_repair_items']) && is_array($_POST['nem_repair_items']) ? $_POST['nem_repair_items'] : [];

    foreach ($raw_repairs as $item) {
        if (!is_array($item)) {
            continue;
        }

        $issue = sanitize_text_field((string) ($item['issue'] ?? ''));
        $fix = sanitize_text_field((string) ($item['fix'] ?? ''));
        $status = sanitize_text_field((string) ($item['status'] ?? 'checking'));

        if ($issue === '' && $fix === '') {
            continue;
        }

        $repair_items[] = ['issue' => $issue, 'fix' => $fix, 'status' => $status];
    }

    update_post_meta($post_id, 'repair_items', wp_json_encode($repair_items));

    $items = [];
    $total = 0;
    $raw_items = isset($_POST['nem_invoice_items']) && is_array($_POST['nem_invoice_items']) ? $_POST['nem_invoice_items'] : [];

    foreach ($raw_items as $item) {
        if (!is_array($item)) {
            continue;
        }

        $label = sanitize_text_field((string) ($item['label'] ?? ''));
        $amount = (float) ($item['amount'] ?? 0);

        if ($label === '' && $amount <= 0) {
            continue;
        }

        $items[] = ['label' => $label, 'amount' => $amount];
        $total += $amount;
    }

    update_post_meta($post_id, 'invoice_items', wp_json_encode($items));
    update_post_meta($post_id, 'invoice_total', (string) $total);
}

function nem_admin_input(int $post_id, string $key, string $label, bool $readonly = false): void
{
    $id = 'nem_' . $key;
    echo '<p class="nem-field">';
    echo '<label for="' . esc_attr($id) . '">' . esc_html($label) . '</label>';
    echo '<input id="' . esc_attr($id) . '" type="text" name="nem_meta[' . esc_attr($key) . ']" value="' . esc_attr((string) get_post_meta($post_id, $key, true)) . '"' . ($readonly ? ' readonly' : '') . '>';
    echo '</p>';
}

function nem_admin_textarea(int $post_id, string $key, string $label): void
{
    $id = 'nem_' . $key;
    echo '<p class="nem-field">';
    echo '<label for="' . esc_attr($id) . '">' . esc_html($label) . '</label>';
    echo '<textarea id="' . esc_attr($id) . '" name="nem_meta[' . esc_attr($key) . ']">' . esc_textarea((string) get_post_meta($post_id, $key, true)) . '</textarea>';
    echo '</p>';
}

function nem_admin_select(int $post_id, string $key, string $label, array $options): void
{
    $value = (string) get_post_meta($post_id, $key, true);
    echo '<p class="nem-field">';
    echo '<label for="nem_' . esc_attr($key) . '">' . esc_html($label) . '</label>';
    echo '<select id="nem_' . esc_attr($key) . '" name="nem_meta[' . esc_attr($key) . ']">';

    foreach ($options as $option_value => $option_label) {
        echo '<option value="' . esc_attr((string) $option_value) . '"' . selected($value, (string) $option_value, false) . '>' . esc_html((string) $option_label) . '</option>';
    }

    if ($value && !isset($options[$value])) {
        echo '<option value="' . esc_attr($value) . '" selected>' . esc_html($value) . '</option>';
    }

    echo '</select>';
    echo '</p>';
}

function nem_status_options(): array
{
    return [
        'registered' => 'Registered',
        'inspection' => 'Inspection',
        'issues_found' => 'Issues Found',
        'repairing' => 'Repairing',
        'quality_check' => 'Quality Check',
        'invoice_ready' => 'Invoice Ready',
        'paid' => 'Paid',
        'closed' => 'Closed',
    ];
}

function nem_payment_status_options(): array
{
    return [
        'pending' => 'Pending',
        'paid' => 'Paid',
        'failed' => 'Failed',
        'refunded' => 'Refunded',
    ];
}

function nem_repair_status_options(): array
{
    return [
        'missing' => 'Missing / Required',
        'checking' => 'Checking',
        'waiting_part' => 'Waiting for Part',
        'repairing' => 'Repairing',
        'testing' => 'Testing',
        'fixed' => 'Fixed',
        'not_needed' => 'Not Needed',
    ];
}

function nem_request_columns(array $columns): array
{
    $new_columns = [];

    foreach ($columns as $key => $label) {
        $new_columns[$key] = $label;

        if ($key === 'title') {
            $new_columns['nem_service'] = 'Service';
            $new_columns['nem_phone'] = 'Phone';
            $new_columns['nem_status'] = 'Status';
            $new_columns['nem_payment'] = 'Payment';
        }
    }

    return $new_columns;
}

function nem_request_column_values(string $column, int $post_id): void
{
    if ($column === 'nem_service') {
        echo esc_html((string) get_post_meta($post_id, 'service_title', true));
    }

    if ($column === 'nem_phone') {
        echo esc_html((string) get_post_meta($post_id, 'phone', true));
    }

    if ($column === 'nem_status') {
        echo esc_html((string) get_post_meta($post_id, 'status', true));
    }

    if ($column === 'nem_payment') {
        echo esc_html((string) get_post_meta($post_id, 'payment_status', true));
    }
}
