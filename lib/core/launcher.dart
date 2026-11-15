import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'clinic.dart';
import 'l10n.dart';

Future<void> openExternal(BuildContext context, Uri uri) async {
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showError(context);
    }
  } catch (_) {
    if (context.mounted) _showError(context);
  }
}

void _showError(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(L10n.of(context).linkError)));
}

Future<void> callClinic(BuildContext context) {
  return openExternal(context, Uri(scheme: 'tel', path: Clinic.phonePrimary));
}

Future<void> messageClinic(BuildContext context) {
  return openExternal(context, Uri.parse('https://wa.me/${Clinic.whatsapp}'));
}

Future<void> emailClinic(BuildContext context) {
  return openExternal(context, Uri(scheme: 'mailto', path: Clinic.email));
}

Future<void> openClinicMap(BuildContext context) {
  return openExternal(context, Uri.parse(Clinic.mapsUrl));
}

Future<void> openClinicWebsite(BuildContext context) {
  return openExternal(context, Uri.parse(Clinic.websiteUrl));
}
