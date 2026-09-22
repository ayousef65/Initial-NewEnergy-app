class AppConfig {
  const AppConfig({
    required this.wordpressBaseUrl,
    required this.facebookReviewUrl,
    required this.googleMapsReviewUrl,
    required this.servicePhone,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      wordpressBaseUrl: _normalizeBaseUrl(
        const String.fromEnvironment(
          'EXPO_PUBLIC_WORDPRESS_BASE_URL',
          defaultValue: 'https://newenergyeg.com',
        ),
      ),
      facebookReviewUrl: const String.fromEnvironment(
        'EXPO_PUBLIC_FACEBOOK_REVIEW_URL',
        defaultValue: 'https://www.facebook.com/newenergyeg',
      ),
      googleMapsReviewUrl: const String.fromEnvironment(
        'EXPO_PUBLIC_GOOGLE_MAPS_REVIEW_URL',
        defaultValue: 'https://www.google.com/maps/search/?api=1&query=New%20Energy%20Egypt',
      ),
      servicePhone: const String.fromEnvironment(
        'NEWENERGY_SERVICE_PHONE',
        defaultValue: '01000000000',
      ),
    );
  }

  final String wordpressBaseUrl;
  final String facebookReviewUrl;
  final String googleMapsReviewUrl;
  final String servicePhone;

  bool get isWordpressConfigured => wordpressBaseUrl.isNotEmpty;

  static String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
