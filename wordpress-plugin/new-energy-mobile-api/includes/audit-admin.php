<?php
/**
 * Read-only audit reporting for WordPress managers.
 *
 * @package NewEnergyMobileApi
 */

if (!defined('ABSPATH')) {
    exit;
}

function nem_register_audit_admin_page(): void
{
    add_submenu_page(
        'edit.php?post_type=' . NEM_REQUEST_CPT,
        'Mobile Audit History',
        'Audit History',
        'manage_options',
        'new-energy-mobile-audit',
        'nem_render_audit_admin_page'
    );
}

function nem_render_audit_admin_page(): void
{
    if (!current_user_can('manage_options')) {
        wp_die(esc_html__('You are not allowed to view this page.'));
    }

    global $wpdb;
    $table = nem_audit_table();
    $page = max(1, (int) ($_GET['paged'] ?? 1));
    $per_page = 50;
    $offset = ($page - 1) * $per_page;
    $action_filter = sanitize_key((string) ($_GET['event_action'] ?? ''));
    $where = '';
    $query_args = [];
    if ($action_filter !== '') {
        $where = ' WHERE action = %s';
        $query_args[] = $action_filter;
    }

    $count_sql = "SELECT COUNT(*) FROM {$table}{$where}";
    $rows_sql = "SELECT id, request_id, actor_user_id, actor_role, action, object_type, object_id, status, metadata, created_at
        FROM {$table}{$where} ORDER BY id DESC LIMIT %d OFFSET %d";
    $row_args = array_merge($query_args, [$per_page, $offset]);

    $total = $query_args
        ? (int) $wpdb->get_var($wpdb->prepare($count_sql, $query_args))
        : (int) $wpdb->get_var($count_sql);
    $rows = $wpdb->get_results($wpdb->prepare($rows_sql, $row_args));
    $total_pages = max(1, (int) ceil($total / $per_page));
    $export_url = wp_nonce_url(
        admin_url('admin-post.php?action=nem_export_audit'),
        'nem_export_audit'
    );

    echo '<div class="wrap">';
    echo '<h1 class="wp-heading-inline">Mobile Audit History</h1> ';
    echo '<a class="page-title-action" href="' . esc_url($export_url) . '">Export CSV</a>';
    echo '<p>Security and business events are retained for ' . esc_html((string) NEM_AUDIT_RETENTION_DAYS) . ' days. Passwords, tokens, email addresses, and phone numbers are never stored in this log.</p>';
    echo '<form method="get" style="margin:16px 0;">';
    echo '<input type="hidden" name="post_type" value="' . esc_attr(NEM_REQUEST_CPT) . '">';
    echo '<input type="hidden" name="page" value="new-energy-mobile-audit">';
    echo '<label for="nem-event-action" class="screen-reader-text">Event action</label>';
    echo '<input id="nem-event-action" type="text" name="event_action" value="' . esc_attr($action_filter) . '" placeholder="Example: request.created"> ';
    submit_button('Filter', 'secondary', '', false);
    echo '</form>';
    echo '<table class="widefat striped"><thead><tr>';
    echo '<th>Date (UTC)</th><th>Action</th><th>User</th><th>Object</th><th>Status</th><th>Context</th><th>Request ID</th>';
    echo '</tr></thead><tbody>';

    if (!$rows) {
        echo '<tr><td colspan="7">No audit events found.</td></tr>';
    }

    foreach ($rows as $row) {
        $user_label = $row->actor_user_id ? '#' . (int) $row->actor_user_id : 'System';
        if ($row->actor_role) {
            $user_label .= ' (' . sanitize_key((string) $row->actor_role) . ')';
        }
        $object = $row->object_type ?: '-';
        if ($row->object_id) {
            $object .= ' #' . (int) $row->object_id;
        }
        $metadata = (string) $row->metadata;
        if (strlen($metadata) > 300) {
            $metadata = substr($metadata, 0, 297) . '...';
        }

        echo '<tr>';
        echo '<td>' . esc_html((string) $row->created_at) . '</td>';
        echo '<td><code>' . esc_html((string) $row->action) . '</code></td>';
        echo '<td>' . esc_html($user_label) . '</td>';
        echo '<td>' . esc_html($object) . '</td>';
        echo '<td>' . esc_html((string) $row->status) . '</td>';
        echo '<td><small>' . esc_html($metadata ?: '-') . '</small></td>';
        echo '<td><small><code>' . esc_html((string) $row->request_id) . '</code></small></td>';
        echo '</tr>';
    }

    echo '</tbody></table>';
    echo '<div class="tablenav"><div class="tablenav-pages">';
    echo wp_kses_post(
        paginate_links(
            [
                'base' => add_query_arg('paged', '%#%'),
                'format' => '',
                'current' => $page,
                'total' => $total_pages,
            ]
        )
    );
    echo '</div></div>';
    echo '</div>';
}

function nem_export_audit_csv(): void
{
    if (!current_user_can('manage_options')) {
        wp_die(esc_html__('You are not allowed to export this report.'));
    }
    check_admin_referer('nem_export_audit');

    global $wpdb;
    $rows = $wpdb->get_results(
        'SELECT request_id, actor_user_id, actor_role, action, object_type, object_id, status, metadata, created_at
         FROM ' . nem_audit_table() . ' ORDER BY id DESC LIMIT 5000',
        ARRAY_A
    );

    nem_audit_log('audit.exported', 'audit', null, ['row_count' => count($rows)]);
    nocache_headers();
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename=new-energy-mobile-audit-' . gmdate('Y-m-d') . '.csv');
    $output = fopen('php://output', 'w');
    if (!$output) {
        wp_die(esc_html__('The export could not be created.'));
    }

    fputcsv($output, ['request_id', 'actor_user_id', 'actor_role', 'action', 'object_type', 'object_id', 'status', 'metadata', 'created_at']);
    foreach ($rows as $row) {
        fputcsv($output, array_map('nem_csv_safe_value', array_values($row)));
    }
    fclose($output);
    exit;
}

function nem_csv_safe_value($value): string
{
    $value = (string) $value;
    if (preg_match('/^[=+\-@]/', $value)) {
        return "'" . $value;
    }
    return $value;
}
