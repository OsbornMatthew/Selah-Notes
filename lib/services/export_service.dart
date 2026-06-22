import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class ExportService {
  // ── Export as plain text ──────────────────────────────────────────────────
  static Future<void> exportAsText(Note note) async {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    // Strip Quill Delta JSON to plain text
    final plainText = _extractPlainText(note.content);
    final content = '$title\n${'─' * title.length}\n\n$plainText';

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeFilename(title)}.txt');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)], subject: title);
  }

  // ── Export as PDF ─────────────────────────────────────────────────────────
  static Future<void> exportAsPdf(Note note) async {
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
          pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Last edited: $dateStr', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
          pw.Divider(height: 24, color: PdfColors.grey400),
          pw.Text(plainText, style: const pw.TextStyle(fontSize: 14, lineSpacing: 4)),
        ],
      ),
    ));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeFilename(title)}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], subject: title);
  }

  // ── Export as image ───────────────────────────────────────────────────────
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
            // Header
            Row(children: [
              const Icon(Icons.spa_outlined, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              const Text('Selah Notes', style: TextStyle(color: AppColors.goldMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: AppColors.gold, fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(dateStr, style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(plainText, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.6)),
          ],
        ),
      ),
    );

    final Uint8List? imageBytes = await controller.captureFromLongWidget(
      InheritedTheme.captureAll(context, widget),
      pixelRatio: 2.0,
    );

    if (imageBytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeFilename(title)}.png');
    await file.writeAsBytes(imageBytes);
    await Share.shareXFiles([XFile(file.path)], subject: title);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _extractPlainText(String content) {
    if (content.isEmpty) return '';
    // If content is Quill Delta JSON, extract text
    try {
      // Simple extraction: get all "insert" string values from delta
      final regex = RegExp(r'"insert"\s*:\s*"((?:[^"\\]|\\.)*)?"');
      final matches = regex.allMatches(content);
      if (matches.isNotEmpty) {
        return matches.map((m) {
          var text = m.group(1) ?? '';
          text = text.replaceAll(r'\n', '\n').replaceAll(r'\"', '"').replaceAll(r'\\', '\\');
          return text;
        }).join('');
      }
    } catch (_) {}
    return content; // fallback: return as-is
  }

  static String _safeFilename(String title) =>
      title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_').toLowerCase().substring(0, title.length.clamp(0, 40));
}
