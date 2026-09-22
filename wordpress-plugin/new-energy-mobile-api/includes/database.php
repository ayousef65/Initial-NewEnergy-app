<?php
/**
 * Database schema, retention, and audit helpers.
 *
 * @package NewEnergyMobileApi
 */

if (!defined('ABSPATH')) {
    exit;
}

function nem_sessions_table(): string
{
    global $wpdb;
    return $wpdb->prefix . 'nem_mobile_sessions';
}

function nem_audit_table(): string
{
    global $wpdb;
    return $wpdb->prefix . 'nem_mobile_audit';
}

function nem_install_database(): void
{
    global $wpdb;

    $charset_collate = $wpdb->get_charset_collate();
    $sessions_table = nem_sessions_table();
    $audit_table = nem_audit_table();

    $sessions_sql = "CREATE TABLE {$sessions_table} (
        id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
        user_id bigint(20) unsigned NOT NULL,
        token_hash char(64) NOT NULL,
        device_label varchar(190) NOT NULL DEFAULT '',
        created_at datetime NOT NULL,
        last_used_at datetime NOT NULL,
        expires_at datetime NOT NULL,
        revoked_at datetime DEFAULT NULL,
        PRIMARY KEY  (id),
        UNIQUE KEY token_hash (token_hash),
        KEY user_id (user_id),
        KEY expires_at (expires_at)
    ) {$charset_collate};";

    $audit_sql = "CREATE TABLE {$audit_table} (
        id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
        request_id char(36) NOT NULL,
        actor_user_id bigint(20) unsigned DEFAULT NULL,
        actor_role varchar(64) NOT NULL DEFAULT '',
        action varchar(100) NOT NULL,
        object_type varchar(64) NOT NULL DEFAULT '',
        object_id bigint(20) unsigned DEFAULT NULL,
        status varchar(24) NOT NULL DEFAULT 'success',
        metadata longtext DEFAULT NULL,
        created_at datetime NOT NULL,
        PRIMARY KEY  (id),
        KEY actor_user_id (actor_user_id),
        KEY action (action),
        KEY object_lookup (object_type, object_id),
        KEY created_at (created_at)
    ) {$charset_collate};";

    require_once ABSPATH . 'wp-admin/includes/upgrade.php';
    dbDelta($sessions_sql);
    dbDelta($audit_sql);

    update_option(NEM_DATABASE_VERSION_OPTION, NEM_DATABASE_VERSION, false);
}

function nem_maybe_upgrade_database(): void
{
    if ((string) get_option(NEM_DATABASE_VERSION_OPTION) !== NEM_DATABASE_VERSION) {
        nem_install_database();
    }

    nem_schedule_cleanup();
}

function nem_schedule_cleanup(): void
{
    if (!wp_next_scheduled(NEM_CLEANUP_HOOK)) {
        wp_schedule_event(time() + HOUR_IN_SECONDS, 'daily', NEM_CLEANUP_HOOK);
    }
}

function nem_unschedule_cleanup(): void
{
    wp_clear_scheduled_hook(NEM_CLEANUP_HOOK);
}

function nem_cleanup_security_data(): void
{
    global $wpdb;

    $now = current_time('mysql', true);
    $audit_cutoff = gmdate('Y-m-d H:i:s', time() - (NEM_AUDIT_RETENTION_DAYS * DAY_IN_SECONDS));
    $sessions_table = nem_sessions_table();
    $audit_table = nem_audit_table();

    $wpdb->query(
        $wpdb->prepare(
            "DELETE FROM {$sessions_table} WHERE expires_at < %s OR revoked_at IS NOT NULL",
            $now
        )
    );
    $wpdb->query(
        $wpdb->prepare(
            "DELETE FROM {$audit_table} WHERE created_at < %s",
            $audit_cutoff
        )
    );
}

/**
 * Write a redacted business/security event to the append-only audit table.
 *
 * @param array<string, mixed> $metadata Non-secret context only.
 */
function nem_audit_log(
    string $action,
    string $object_type = '',
    ?int $object_id = null,
    array $metadata = [],
    string $status = 'success',
    ?int $actor_user_id = null
): void {
    global $wpdb;

    if ($actor_user_id === null) {
        $actor_user_id = get_current_user_id() ?: null;
    }

    $role = '';
    if ($actor_user_id) {
        $user = get_userdata($actor_user_id);
        if ($user instanceof WP_User && !empty($user->roles)) {
            $role = sanitize_key((string) reset($user->roles));
        }
    }

    $safe_metadata = nem_redact_audit_metadata($metadata);
    $wpdb->insert(
        nem_audit_table(),
        [
            'request_id' => wp_generate_uuid4(),
            'actor_user_id' => $actor_user_id,
            'actor_role' => $role,
            'action' => sanitize_key($action),
            'object_type' => sanitize_key($object_type),
            'object_id' => $object_id,
            'status' => sanitize_key($status),
            'metadata' => $safe_metadata ? wp_json_encode($safe_metadata) : null,
            'created_at' => current_time('mysql', true),
        ],
        ['%s', '%d', '%s', '%s', '%s', '%d', '%s', '%s', '%s']
    );
}

/**
 * Remove credentials and personal identifiers before an audit payload is stored.
 *
 * @param array<string, mixed> $metadata
 * @return array<string, mixed>
 */
function nem_redact_audit_metadata(array $metadata): array
{
    $safe = [];
    foreach ($metadata as $key => $value) {
        $clean_key = sanitize_key((string) $key);
        if ($clean_key === '' || preg_match('/password|token|secret|authorization|cookie|email|phone/', $clean_key)) {
            continue;
        }

        if (is_array($value)) {
            $safe[$clean_key] = nem_redact_audit_metadata($value);
            continue;
        }

        if (is_bool($value) || is_int($value) || is_float($value)) {
            $safe[$clean_key] = $value;
            continue;
        }

        $safe[$clean_key] = nem_limit_text(sanitize_text_field((string) $value), 500);
    }

    return $safe;
}

function nem_identifier_fingerprint(string $identifier): string
{
    return substr(hash_hmac('sha256', strtolower(trim($identifier)), wp_salt('auth')), 0, 16);
}

function nem_limit_text(string $value, int $length): string
{
    return function_exists('mb_substr')
        ? mb_substr($value, 0, $length)
        : substr($value, 0, $length);
}
