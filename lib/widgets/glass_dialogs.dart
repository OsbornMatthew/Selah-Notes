import 'package:flutter/material.dart';
import 'glass_card.dart';
import '../theme/app_theme.dart';

class GlassDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  const GlassDialog({super.key, required this.title, required this.child, required this.actions});

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: GlassCard(
      blurSigma: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      ),
    ),
  );
}

class GlassDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDanger;
  const GlassDialogButton({super.key, required this.label, required this.onTap, this.isPrimary = false, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : (isPrimary ? AppColors.gold : AppColors.textSecondary);
    return TextButton(onPressed: onTap, child: Text(label, style: TextStyle(color: color, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500)));
  }
}

Future<bool?> showConfirmDialog(BuildContext context, {required String title, required String message, String confirmLabel = 'Confirm', bool isDanger = false}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => GlassDialog(
      title: title,
      child: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        GlassDialogButton(label: 'Cancel', onTap: () => Navigator.pop(ctx, false)),
        GlassDialogButton(label: confirmLabel, isDanger: isDanger, isPrimary: !isDanger, onTap: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
}

Widget buildSortSheet<T>(BuildContext context, {required String title, required Map<T, (String, IconData)> options, required T current}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    child: GlassCard(
      blurSigma: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16))),
          for (final entry in options.entries)
            ListTile(
              onTap: () => Navigator.pop(context, entry.key),
              leading: Icon(entry.value.$2, color: current == entry.key ? AppColors.gold : AppColors.textSecondary),
              title: Text(entry.value.$1, style: TextStyle(
                color: current == entry.key ? AppColors.gold : AppColors.textPrimary,
                fontWeight: current == entry.key ? FontWeight.w600 : FontWeight.w400)),
              trailing: current == entry.key ? const Icon(Icons.check_rounded, color: AppColors.gold) : null,
            ),
        ],
      ),
    ),
  );
}
