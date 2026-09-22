<?php
/**
 * Mobile account and opaque bearer-session support.
 *
 * @package NewEnergyMobileApi
 */

if (!defined('ABSPATH')) {
    exit;
}

function nem_register_auth_routes(): void
{
    register_rest_route(
        NEM_API_NAMESPACE,
        '/auth/register',
        [
            'methods' => WP_REST_Server::CREATABLE,
            'permission_callback' => '__return_true',
            'callback' => 'nem_rest_auth_register',
        ]
    );
    register_rest_route(
        NEM_API_NAMESPACE,
        '/auth/login',
        [
            'methods' => WP_REST_Server::CREATABLE,
            'permission_callback' => '__return_true',
            'callback' => 'nem_rest_auth_login',
        ]
    );
    register_rest_route(
        NEM_API_NAMESPACE,
        '/auth/forgot-password',
        [
            'methods' => WP_REST_Server::CREATABLE,
            'permission_callback' => '__return_true',
            'callback' => 'nem_rest_auth_forgot_password',
        ]
    );
    register_rest_route(
        NEM_API_NAMESPACE,
        '/auth/me',
        [
            'methods' => WP_REST_Server::READABLE,
            'permission_callback' => 'nem_rest_authenticated_permission',
            'callback' => 'nem_rest_auth_me',
        ]
    );
    register_rest_route(
        NEM_API_NAMESPACE,
        '/auth/refresh',
        [
            'methods' => WP_REST_Server::CREATABLE,
            'permission_callback' => 'nem_rest_authenticated_permission',
            'callback' => 'nem_rest_auth_refresh',
        ]
    );
    register_rest_route(
        NEM_API_NAMESPACE,
        '/auth/logout',
        [
            'methods' => WP_REST_Server::CREATABLE,
            'permission_callback' => 'nem_rest_authenticated_permission',
            'callback' => 'nem_rest_auth_logout',
        ]
    );
}

function nem_rest_auth_register(WP_REST_Request $request)
{
    $transport_error = nem_require_secure_auth_transport();
    if (is_wp_error($transport_error)) {
        return $transport_error;
    }

    if (!apply_filters('nem_mobile_registration_enabled', true)) {
        return new WP_Error('nem_registration_disabled', 'Account registration is unavailable.', ['status' => 403]);
    }

    $params = nem_auth_json_params($request);
    $name = sanitize_text_field((string) ($params['display_name'] ?? ''));
    $email = sanitize_email((string) ($params['email'] ?? ''));
    $phone = nem_normalize_phone((string) ($params['phone'] ?? ''));
    $password = (string) ($params['password'] ?? '');
    $rate_key = nem_auth_rate_key('register', $email ?: $phone);
    $rate_error = nem_auth_rate_limit($rate_key, 5, 15 * MINUTE_IN_SECONDS);
    if (is_wp_error($rate_error)) {
        return $rate_error;
    }

    if ($name === '' || !is_email($email) || !nem_phone_is_valid($phone) || strlen($password) < 10 || strlen($password) > 4096) {
        nem_auth_rate_increment($rate_key, 15 * MINUTE_IN_SECONDS);
        return new WP_Error(
            'nem_invalid_registration',
            'Enter a valid name, email, phone, and a password of at least 10 characters.',
            ['status' => 400]
        );
    }

    if (email_exists($email) || nem_find_user_by_phone($phone)) {
        nem_auth_rate_increment($rate_key, 15 * MINUTE_IN_SECONDS);
        nem_audit_log(
            'auth.register_failed',
            'user',
            null,
            ['identifier_hash' => nem_identifier_fingerprint($email), 'reason' => 'unavailable'],
            'failed'
        );
        return new WP_Error(
            'nem_account_unavailable',
            'An account could not be created with these details.',
            ['status' => 400]
        );
    }

    $role = get_role('customer') ? 'customer' : 'subscriber';
    $user_id = wp_insert_user(
        [
            'user_login' => nem_unique_login_from_email($email),
            'user_pass' => $password,
            'user_email' => $email,
            'display_name' => $name,
            'first_name' => $name,
            'role' => $role,
        ]
    );

    if (is_wp_error($user_id)) {
        nem_auth_rate_increment($rate_key, 15 * MINUTE_IN_SECONDS);
        nem_audit_log(
            'auth.register_failed',
            'user',
            null,
            ['identifier_hash' => nem_identifier_fingerprint($email), 'reason' => 'wordpress_error'],
            'failed'
        );
        return new WP_Error('nem_registration_failed', 'The account could not be created.', ['status' => 400]);
    }

    update_user_meta((int) $user_id, 'nem_mobile_phone', $phone);
    update_user_meta((int) $user_id, 'billing_phone', $phone);
    delete_transient($rate_key);
    wp_set_current_user((int) $user_id);

    $session = nem_issue_session((int) $user_id, nem_device_label($params));
    if (is_wp_error($session)) {
        return $session;
    }

    nem_audit_log('auth.registered', 'user', (int) $user_id, ['role' => $role]);
    return new WP_REST_Response(nem_session_payload($session), 201);
}

function nem_rest_auth_login(WP_REST_Request $request)
{
    $transport_error = nem_require_secure_auth_transport();
    if (is_wp_error($transport_error)) {
        return $transport_error;
    }

    $params = nem_auth_json_params($request);
    $identifier = sanitize_text_field((string) ($params['identifier'] ?? ''));
    $password = (string) ($params['password'] ?? '');
    $rate_key = nem_auth_rate_key('login', $identifier);
    $rate_error = nem_auth_rate_limit($rate_key, 5, 15 * MINUTE_IN_SECONDS);
    if (is_wp_error($rate_error)) {
        return $rate_error;
    }

    if ($identifier === '' || $password === '' || strlen($password) > 4096) {
        nem_auth_rate_increment($rate_key, 15 * MINUTE_IN_SECONDS);
        return nem_invalid_credentials_error();
    }

    $candidate = nem_find_user_by_identifier($identifier);
    $login = $candidate instanceof WP_User ? $candidate->user_login : $identifier;
    $user = wp_authenticate($login, $password);

    if (is_wp_error($user) || !($user instanceof WP_User)) {
        nem_auth_rate_increment($rate_key, 15 * MINUTE_IN_SECONDS);
        nem_audit_log(
            'auth.login_failed',
            'user',
            null,
            ['identifier_hash' => nem_identifier_fingerprint($identifier)],
            'failed'
        );
        return nem_invalid_credentials_error();
    }

    delete_transient($rate_key);
    wp_set_current_user($user->ID);
    $session = nem_issue_session($user->ID, nem_device_label($params));
    if (is_wp_error($session)) {
        return $session;
    }

    nem_audit_log('auth.login', 'user', $user->ID);
    return rest_ensure_response(nem_session_payload($session));
}

function nem_rest_auth_forgot_password(WP_REST_Request $request)
{
    $transport_error = nem_require_secure_auth_transport();
    if (is_wp_error($transport_error)) {
        return $transport_error;
    }

    $params = nem_auth_json_params($request);
    $identifier = sanitize_text_field((string) ($params['identifier'] ?? ''));
    $rate_key = nem_auth_rate_key('password_reset', $identifier);
    $rate_error = nem_auth_rate_limit($rate_key, 3, HOUR_IN_SECONDS);

    if (!is_wp_error($rate_error) && $identifier !== '') {
        $user = nem_find_user_by_identifier($identifier);
        if ($user instanceof WP_User) {
            retrieve_password($user->user_login);
        }
        nem_auth_rate_increment($rate_key, HOUR_IN_SECONDS);
        nem_audit_log(
            'auth.password_reset_requested',
            'user',
            $user instanceof WP_User ? $user->ID : null,
            ['identifier_hash' => nem_identifier_fingerprint($identifier)]
        );
    }

    return rest_ensure_response(
        [
            'ok' => true,
            'message' => 'If the account exists, a password reset email will be sent.',
        ]
    );
}

function nem_rest_auth_me(): WP_REST_Response
{
    $session = $GLOBALS['nem_current_mobile_session'] ?? null;
    return rest_ensure_response(
        [
            'user' => nem_user_payload(wp_get_current_user()),
            'expiresAt' => is_object($session) ? mysql_to_rfc3339((string) $session->expires_at) : '',
        ]
    );
}

function nem_rest_auth_refresh(WP_REST_Request $request)
{
    $user_id = get_current_user_id();
    if (!$user_id) {
        return nem_invalid_session_error();
    }

    $session = nem_issue_session($user_id, 'Refreshed mobile session');
    if (is_wp_error($session)) {
        return $session;
    }

    nem_revoke_request_session($request);
    nem_audit_log('auth.session_refreshed', 'user', $user_id);
    return rest_ensure_response(nem_session_payload($session));
}

function nem_rest_auth_logout(WP_REST_Request $request): WP_REST_Response
{
    $user_id = get_current_user_id();
    nem_revoke_request_session($request);
    nem_audit_log('auth.logout', 'user', $user_id ?: null);
    wp_set_current_user(0);
    return rest_ensure_response(['ok' => true]);
}

function nem_rest_authenticated_permission(WP_REST_Request $request)
{
    $transport_error = nem_require_secure_auth_transport();
    if (is_wp_error($transport_error)) {
        return $transport_error;
    }

    if (get_current_user_id() && current_user_can('manage_options')) {
        return true;
    }

    return nem_authenticate_request($request);
}

function nem_authenticate_request(WP_REST_Request $request)
{
    global $wpdb;

    $token = nem_bearer_token($request);
    if ($token === '') {
        return nem_invalid_session_error();
    }

    $token_hash = hash('sha256', $token);
    $now = current_time('mysql', true);
    $table = nem_sessions_table();
    $session = $wpdb->get_row(
        $wpdb->prepare(
            "SELECT id, user_id, last_used_at, expires_at FROM {$table}
             WHERE token_hash = %s AND revoked_at IS NULL AND expires_at > %s LIMIT 1",
            $token_hash,
            $now
        )
    );

    if (!$session || !get_userdata((int) $session->user_id)) {
        return nem_invalid_session_error();
    }

    wp_set_current_user((int) $session->user_id);
    $GLOBALS['nem_current_mobile_session'] = $session;
    $GLOBALS['nem_current_mobile_token_hash'] = $token_hash;

    if (strtotime($now) - strtotime((string) $session->last_used_at) >= 300) {
        $wpdb->update(
            $table,
            ['last_used_at' => $now],
            ['id' => (int) $session->id],
            ['%s'],
            ['%d']
        );
    }

    return true;
}

function nem_bearer_token(WP_REST_Request $request): string
{
    $header = trim((string) $request->get_header('authorization'));
    if (!preg_match('/^Bearer\s+([A-Za-z0-9_-]{40,})$/i', $header, $matches)) {
        return '';
    }
    return (string) $matches[1];
}

function nem_issue_session(int $user_id, string $device_label)
{
    global $wpdb;

    try {
        $token = rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '=');
    } catch (Exception $error) {
        return new WP_Error('nem_session_failed', 'A secure session could not be created.', ['status' => 500]);
    }

    $now_timestamp = time();
    $created_at = gmdate('Y-m-d H:i:s', $now_timestamp);
    $expires_at = gmdate('Y-m-d H:i:s', $now_timestamp + NEM_SESSION_TTL);
    $inserted = $wpdb->insert(
        nem_sessions_table(),
        [
            'user_id' => $user_id,
            'token_hash' => hash('sha256', $token),
            'device_label' => nem_limit_text(sanitize_text_field($device_label), 190),
            'created_at' => $created_at,
            'last_used_at' => $created_at,
            'expires_at' => $expires_at,
            'revoked_at' => null,
        ],
        ['%d', '%s', '%s', '%s', '%s', '%s', '%s']
    );

    if (!$inserted) {
        return new WP_Error('nem_session_failed', 'A secure session could not be created.', ['status' => 500]);
    }

    nem_limit_user_sessions($user_id);
    return [
        'token' => $token,
        'expires_at' => $expires_at,
        'user' => get_userdata($user_id),
    ];
}

function nem_limit_user_sessions(int $user_id): void
{
    global $wpdb;

    $table = nem_sessions_table();
    $active_ids = $wpdb->get_col(
        $wpdb->prepare(
            "SELECT id FROM {$table} WHERE user_id = %d AND revoked_at IS NULL ORDER BY id DESC",
            $user_id
        )
    );
    $expired_ids = array_slice(array_map('intval', $active_ids), 5);
    if (!$expired_ids) {
        return;
    }

    $placeholders = implode(',', array_fill(0, count($expired_ids), '%d'));
    $wpdb->query(
        $wpdb->prepare(
            "UPDATE {$table} SET revoked_at = %s WHERE id IN ({$placeholders})",
            array_merge([current_time('mysql', true)], $expired_ids)
        )
    );
}

function nem_revoke_request_session(WP_REST_Request $request): void
{
    global $wpdb;

    $token = nem_bearer_token($request);
    if ($token === '') {
        return;
    }

    $wpdb->update(
        nem_sessions_table(),
        ['revoked_at' => current_time('mysql', true)],
        ['token_hash' => hash('sha256', $token)],
        ['%s'],
        ['%s']
    );
}

function nem_revoke_user_sessions(WP_User $user): void
{
    global $wpdb;
    $wpdb->update(
        nem_sessions_table(),
        ['revoked_at' => current_time('mysql', true)],
        ['user_id' => $user->ID],
        ['%s'],
        ['%d']
    );
    nem_audit_log('auth.password_changed', 'user', $user->ID, [], 'success', $user->ID);
}

/**
 * @param array{token:string, expires_at:string, user:WP_User} $session
 * @return array<string, mixed>
 */
function nem_session_payload(array $session): array
{
    return [
        'token' => $session['token'],
        'expiresAt' => mysql_to_rfc3339($session['expires_at']),
        'user' => nem_user_payload($session['user']),
    ];
}

/** @return array<string, mixed> */
function nem_user_payload(WP_User $user): array
{
    return [
        'id' => $user->ID,
        'displayName' => $user->display_name,
        'email' => $user->user_email,
        'phone' => (string) get_user_meta($user->ID, 'nem_mobile_phone', true),
    ];
}

/** @return array<string, mixed> */
function nem_auth_json_params(WP_REST_Request $request): array
{
    $params = $request->get_json_params();
    return is_array($params) ? $params : [];
}

function nem_find_user_by_identifier(string $identifier): ?WP_User
{
    $identifier = trim($identifier);
    if (is_email($identifier)) {
        $user = get_user_by('email', sanitize_email($identifier));
        return $user instanceof WP_User ? $user : null;
    }

    $phone = nem_normalize_phone($identifier);
    if (nem_phone_is_valid($phone)) {
        $user = nem_find_user_by_phone($phone);
        if ($user instanceof WP_User) {
            return $user;
        }
    }

    $user = get_user_by('login', sanitize_user($identifier));
    return $user instanceof WP_User ? $user : null;
}

function nem_find_user_by_phone(string $phone): ?WP_User
{
    $query = new WP_User_Query(
        [
            'number' => 1,
            'count_total' => false,
            'meta_key' => 'nem_mobile_phone',
            'meta_value' => $phone,
        ]
    );
    $users = $query->get_results();
    return !empty($users) && $users[0] instanceof WP_User ? $users[0] : null;
}

function nem_normalize_phone(string $phone): string
{
    $phone = trim($phone);
    $prefix = strpos($phone, '+') === 0 ? '+' : '';
    return $prefix . preg_replace('/\D+/', '', $phone);
}

function nem_phone_is_valid(string $phone): bool
{
    return (bool) preg_match('/^\+?[0-9]{8,15}$/', $phone);
}

function nem_unique_login_from_email(string $email): string
{
    $base = sanitize_user((string) strstr($email, '@', true), true);
    if ($base === '') {
        $base = 'newenergy';
    }

    $candidate = $base;
    $suffix = 1;
    while (username_exists($candidate)) {
        ++$suffix;
        $candidate = $base . $suffix;
    }
    return $candidate;
}

/** @param array<string, mixed> $params */
function nem_device_label(array $params): string
{
    $label = sanitize_text_field((string) ($params['device_label'] ?? 'New Energy Flutter app'));
    return $label !== '' ? $label : 'New Energy Flutter app';
}

function nem_require_secure_auth_transport()
{
    if (is_ssl()) {
        return true;
    }

    $environment = function_exists('wp_get_environment_type') ? wp_get_environment_type() : 'production';
    $host = strtolower((string) wp_parse_url(home_url(), PHP_URL_HOST));
    $is_local = in_array($host, ['localhost', '127.0.0.1', '::1'], true);
    if ($is_local || in_array($environment, ['local', 'development'], true)) {
        return true;
    }

    return new WP_Error('nem_https_required', 'Secure HTTPS is required for account access.', ['status' => 403]);
}

function nem_auth_rate_key(string $bucket, string $identifier): string
{
    $remote = sanitize_text_field((string) ($_SERVER['REMOTE_ADDR'] ?? 'unknown'));
    $fingerprint = hash_hmac('sha256', strtolower(trim($identifier)) . '|' . $remote, wp_salt('auth'));
    return 'nem_rl_' . sanitize_key($bucket) . '_' . substr($fingerprint, 0, 32);
}

function nem_auth_rate_limit(string $key, int $limit, int $window)
{
    $attempts = (int) get_transient($key);
    if ($attempts < $limit) {
        return true;
    }
    return new WP_Error(
        'nem_too_many_attempts',
        'Too many attempts. Try again later.',
        ['status' => 429, 'retryAfter' => $window]
    );
}

function nem_auth_rate_increment(string $key, int $window): void
{
    set_transient($key, (int) get_transient($key) + 1, $window);
}

function nem_invalid_credentials_error(): WP_Error
{
    return new WP_Error('nem_invalid_credentials', 'The login details are incorrect.', ['status' => 401]);
}

function nem_invalid_session_error(): WP_Error
{
    return new WP_Error('nem_invalid_session', 'Your session is invalid or has expired.', ['status' => 401]);
}
