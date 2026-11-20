import 'package:flutter/material.dart';

import '../core/icons.dart';

import '../core/l10n.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'contact_screen.dart';

/// Reports are not connected to the clinic's system yet, so this tab announces
/// the feature instead of showing the sample records that are still unused.
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = L10n.of(context);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabPageHeader(
            title: l10n.recordsTitle,
            subtitle: l10n.recordsSubtitle,
            trailing: StatusPill(
              label: l10n.comingSoonLabel,
              background: scheme.primaryContainer,
              foreground: scheme.onPrimaryContainer,
            ),
          ),
          Expanded(
            child: AppRefreshEmpty(
              child: EmptyState(
                icon: CoolIcons.fileText,
                title: l10n.reportsComingTitle,
                message: l10n.reportsComingMessage,
                action: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ContactScreen(),
                    ),
                  ),
                  icon: const Icon(CoolIcons.phoneCall, size: 18),
                  label: Text(l10n.callClinic),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
