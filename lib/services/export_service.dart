import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class ExportService {
  static const _subFolder = 'Selah Notes';

  // ── Public entry points ───────────────────────────────────────────────────

  static Future<void> exportAsText(Note note, BuildContext context) async {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    final plainText = _extractPlainText(note.content);
    final content = '$title\n${'─' * title.length}\n\n$plainText';
    final bytes = Uint8List.fromList(content.codeUnits);
    await _save(context: context, bytes: bytes,
        filename: '${_safeFilename(title)}.txt');
  }

  static Future<void> exportAsPdf(Note note, BuildContext context) async {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    final plainText = _extractPlainText(note.content);
    final dateStr = DateFormat('MMM d, yyyy').format(note.updatedAt);

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Last edited: $dateStr',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
          pw.Divider(height: 24, color: PdfColors.grey400),
          pw.Text(plainText,
              style: const pw.TextStyle(fontSize: 14, lineSpacing: 4)),
        ],
      ),
    ));

    await _save(context: context,
        bytes: Uint8List.fromList(await pdf.save()),
        filename: '${_safeFilename(title)}.pdf');
  }

  static Future<void> exportAsImage(Note note, BuildContext context) async {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    final plainText = _extractPlainText(note.content);
    final dateStr = DateFormat('MMM d, yyyy · h:mm a').format(note.updatedAt);

    final controller = ScreenshotController();
    final widget = Material(
      color: Colors.transparent,
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1408), Color(0xFF0D0B08)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Icon(Icons.spa_outlined, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              const Text('Selah Notes',
                  style: TextStyle(color: AppColors.goldMuted,
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(color: AppColors.gold,
                    fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(dateStr,
                style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(plainText,
                style: const TextStyle(color: AppColors.textPrimary,
                    fontSize: 16, height: 1.6)),
          ],
        ),
      ),
    );

    final Uint8List? imageBytes = await controller.captureFromLongWidget(
      InheritedTheme.captureAll(context, widget),
      pixelRatio: 2.0,
    );
    if (imageBytes == null) return;

    await _save(context: context, bytes: imageBytes,
        filename: '${_safeFilename(title)}.png');
  }

  // ── Core: write to Downloads/Selah Notes/ ────────────────────────────────

  static Future<void> _save({
    required BuildContext context,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final dir = await _getDownloadsDir();
      if (dir == null) {
        _snack(context, 'Could not access storage', isError: true);
        return;
      }

      // On Android ≤ 9 (API 28) we need WRITE_EXTERNAL_STORAGE
      if (Platform.isAndroid) {
        final info = await _sdkInt();
        if (info != null && info <= 28) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            _snack(context, 'Storage permission denied', isError: true);
            return;
          }
        }
      }

      final folder = Directory('${dir.path}/$_subFolder');
      if (!await folder.exists()) await folder.create(recursive: true);

      final file = File('${folder.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      if (!context.mounted) return;
      _snack(context, '✓ Saved to Downloads/$_subFolder/$filename');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Export failed: $e', isError: true);
    }
  }

  // ── Storage directory ─────────────────────────────────────────────────────

  static Future<Directory?> _getDownloadsDir() async {
    if (Platform.isAndroid) {
      // /storage/emulated/0/Download — works on API 19+
      const downloads = '/storage/emulated/0/Download';
      final d = Directory(downloads);
      if (await d.exists()) return d;
      // Fallback: getExternalStorageDirectory gives .../Android/data/...
      // which is app-private but always writable without permission
      return await getExternalStorageDirectory();
    }
    // iOS / others: Documents folder
    return await getApplicationDocumentsDirectory();
  }

  static Future<int?> _sdkInt() async {
    try {
      final r = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(r.stdout.toString().trim());
    } catch (_) {
      return null;
    }
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────

  static void _snack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: isError ? AppColors.danger : const Color(0xFF2A2000),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      duration: Duration(seconds: isError ? 4 : 3),
    ));
  }

  // ── Text extraction ───────────────────────────────────────────────────────

  static String _extractPlainText(String content) {
    if (content.isEmpty) return '';
    try {
      final regex = RegExp(r'"insert"\s*:\s*"((?:[^"\\]|\\.)*)?\"');
      final matches = regex.allMatches(content);
      if (matches.isNotEmpty) {
        return matches.map((m) {
          var text = m.group(1) ?? '';
          return text
              .replaceAll(r'\n', '\n')
              .replaceAll(r'\"', '"')
              .replaceAll(r'\\', '\\');
        }).join('');
      }
    } catch (_) {}
    return content;
  }

  static String _safeFilename(String title) {
    final safe = title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final clamped = safe.substring(0, safe.length.clamp(0, 40));
    return clamped.isEmpty ? 'untitled' : clamped;
  }
}
