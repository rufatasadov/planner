import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timeline, size: 40, color: Color(0xFF8B5CF6)),
              const SizedBox(height: 12),
              Text(
                l10n.comingTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedColor(context), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
