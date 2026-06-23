import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class ExportService {
  static const _appFolder = 'Selah Notes';
  static final _mediaStore = MediaStore();

  // ── Public entry points ───────────────────────────────────────────────────

  static Future<void> exportAsText(Note note, BuildContext context) async {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    final plainText = _extractPlainText(note.content);
    final content = '$title\n${'─' * title.length}\n\n$plainText';
    final filename = '${_safeFilename(title)}.txt';
    final bytes = Uint8List.fromList(content.codeUnits);
    await _saveToDownloads(
      context: context,
      bytes: bytes,
      filename: filename,
      mimeType: 'text/plain',
      mediaType: DirType.download,
    );
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

    final bytes = await pdf.save();
    final filename = '${_safeFilename(title)}.pdf';
    await _saveToDownloads(
      context: context,
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      mimeType: 'application/pdf',
      mediaType: DirType.download,
    );
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
                  style: TextStyle(
                      color: AppColors.goldMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(dateStr,
                style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(plainText,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 16, height: 1.6)),
          ],
        ),
      ),
    );

    final Uint8List? imageBytes = await controller.captureFromLongWidget(
      InheritedTheme.captureAll(context, widget),
      pixelRatio: 2.0,
    );
    if (imageBytes == null) return;

    final filename = '${_safeFilename(title)}.png';
    await _saveToDownloads(
      context: context,
      bytes: imageBytes,
      filename: filename,
      mimeType: 'image/png',
      mediaType: DirType.image,
    );
  }

  // ── Core save logic ───────────────────────────────────────────────────────

  static Future<void> _saveToDownloads({
    required BuildContext context,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    required DirType mediaType,
  }) async {
    try {
      // Android 10+ (API 29+): use MediaStore — no permission needed
      // Android 9 and below: need WRITE_EXTERNAL_STORAGE permission
      final sdkInt = await _getAndroidSdkInt();

      if (sdkInt != null && sdkInt < 29) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showSnack(context, 'Storage permission denied', isError: true);
          return;
        }
      }

      // Write to a temp file first
      final tmp = await getTemporaryDirectory();
      final tmpFile = File('${tmp.path}/$filename');
      await tmpFile.writeAsBytes(bytes);

      // Save via MediaStore (works on all API levels with media_store_plus)
      await MediaStore.appFolder = _appFolder;
      final saved = await _mediaStore.saveFile(
        tempFilePath: tmpFile.path,
        dirType: mediaType,
        dirName: _appFolder,
      );

      // Clean up temp file
      await tmpFile.delete().catchError((_) {});

      if (!context.mounted) return;
      if (saved != null) {
        _showSnack(context, '✓ Saved to Downloads/$_appFolder/$filename');
      } else {
        _showSnack(context, 'Could not save file', isError: true);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, 'Export failed: $e', isError: true);
    }
  }

  static void _showSnack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: isError ? AppColors.danger : const Color(0xFF2A2000),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      duration: Duration(seconds: isError ? 4 : 3),
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<int?> _getAndroidSdkInt() async {
    try {
      if (!Platform.isAndroid) return null;
      // Read from build props — available without native channel
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim());
    } catch (_) {
      return null;
    }
  }

  static String _extractPlainText(String content) {
    if (content.isEmpty) return '';
    try {
      final regex = RegExp(r'"insert"\s*:\s*"((?:[^"\\]|\\.)*)?\"');
      final matches = regex.allMatches(content);
      if (matches.isNotEmpty) {
        return matches.map((m) {
          var text = m.group(1) ?? '';
          text = text
              .replaceAll(r'\n', '\n')
              .replaceAll(r'\"', '"')
              .replaceAll(r'\\', '\\');
          return text;
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
