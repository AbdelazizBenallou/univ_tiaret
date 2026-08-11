import 'package:flutter/material.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('terms_and_conditions')),
        centerTitle: true,
      ),
      body: const SizedBox.shrink(),
    );
  }
}
