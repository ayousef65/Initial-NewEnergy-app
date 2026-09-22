import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/common_widgets.dart';

Future<bool> openExternalUrl(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null) {
    showAppMessage(context, 'الرابط غير صالح.', isError: true);
    return false;
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    showAppMessage(
      context,
      'تعذر فتح الرابط. تأكد من توفر تطبيق مناسب على الجهاز.',
      isError: true,
    );
  }
  return opened;
}
