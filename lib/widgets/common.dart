import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/l10n.dart';
import '../core/nepali.dart';
import '../core/tokens.dart';
import '../models.dart';
import '../state/app_state.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.radius = AppTokens.radiusCard,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final content = Padding(padding: padding, child: child);
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Material(
        color: color ?? scheme.surfaceContainerLow,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(64, AppTokens.minTap),
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 2),
                const Icon(CoolIcons.caretRight, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

class TonalIcon extends StatelessWidget {
  const TonalIcon({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 22,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? scheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: foreground ?? scheme.onPrimary),
    );
  }
}

class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.height = 42});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      isDark
          ? 'assets/branding/wordmark_dark.svg'
          : 'assets/branding/wordmark.svg',
      width: height * 375 / 126,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({super.key, required this.doctor, this.size = 48});

  final Doctor doctor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: doctor.nameNp,
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.035),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            doctor.avatar,
            width: size,
            height: size,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              color: scheme.primaryContainer,
              alignment: Alignment.center,
              child: Text(
                initials(doctor.nameNp),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.disabledHint,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final background = selected
        ? scheme.primary
        : enabled
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLow;
    final foreground = selected
        ? scheme.onPrimary
        : enabled
        ? scheme.onSurfaceVariant
        : scheme.onSurfaceVariant.withValues(alpha: 0.5);

    final pill = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final semantic = Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: pill,
    );

    if (!enabled && disabledHint != null) {
      return Tooltip(message: disabledHint, child: semantic);
    }
    return semantic;
  }
}

class PillTabBar extends StatelessWidget {
  const PillTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: Semantics(
                  button: true,
                  selected: i == selectedIndex,
                  child: InkWell(
                    onTap: () => onChanged(i),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    child: AnimatedContainer(
                      duration: AppTokens.motionFast,
                      curve: AppTokens.ease,
                      height: AppTokens.minTap,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == selectedIndex
                            ? scheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusPill,
                        ),
                      ),
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: i == selectedIndex
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: i == selectedIndex
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TonalIcon(
              icon: icon,
              size: 72,
              iconSize: 32,
              background: theme.colorScheme.primaryContainer,
              foreground: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class TabPageHeader extends StatelessWidget {
  const TabPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.gutter,
        AppTokens.gutter,
        AppTokens.gutter,
        AppTokens.s16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

void showAppSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: onAction != null ? 6 : 4),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(label: actionLabel, onPressed: onAction)
          : null,
    ),
  );
}

/// Coolicons back button for pushed screens.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const Icon(CoolIcons.arrowLeft),
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}

/// Confirm dialog → cancel → Undo snackbar. Shared by the appointments list
/// and the appointment detail screen.
Future<void> cancelAppointmentFlow(
  BuildContext context,
  Appointment appointment,
) async {
  final l10n = L10n.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final dialogL10n = L10n.of(dialogContext);
      return AlertDialog(
        title: Text(dialogL10n.cancelDialogTitle),
        content: Text(dialogL10n.cancelDialogBody(appointment.date)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogL10n.keep),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(dialogL10n.cancel),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return;
  final state = context.read<AppState>();
  state.cancelAppointment(appointment.id);
  if (!context.mounted) return;
  showAppSnack(
    context,
    l10n.cancelDoneSnack,
    actionLabel: l10n.undo,
    onAction: () {
      final restored = state.restoreAppointment(appointment.id);
      if (!restored && context.mounted) {
        showAppSnack(context, l10n.restoreFailedSnack);
      }
    },
  );
}

/// Label/value row with a flexible label column so long Nepali labels wrap
/// instead of overflowing a fixed-width box.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style:
                valueStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

/// Primary date (Bikram Sambat by default) with the other calendar beneath it
/// in smaller, muted text.
class DateText extends StatelessWidget {
  const DateText({
    super.key,
    required this.date,
    this.primaryStyle,
    this.secondaryStyle,
    this.color,
    this.mutedColor,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.maxLines = 2,
  });

  final DateTime date;
  final TextStyle? primaryStyle;
  final TextStyle? secondaryStyle;
  final Color? color;
  final Color? mutedColor;
  final CrossAxisAlignment crossAxisAlignment;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final primary = context.watch<AppState>().datePrimary;
    final muted =
        mutedColor ?? color?.withValues(alpha: 0.72) ?? scheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          l10n.primaryDateLine(date, primary),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: (primaryStyle ?? theme.textTheme.titleSmall)?.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          l10n.secondaryDateLine(date, primary),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: (secondaryStyle ?? theme.textTheme.bodySmall)?.copyWith(
            color: muted,
            fontSize:
                (secondaryStyle?.fontSize ??
                    theme.textTheme.bodySmall?.fontSize ??
                    12) *
                0.92,
          ),
        ),
      ],
    );
  }
}
