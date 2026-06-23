import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/notes_database.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class NoteViewScreen extends StatefulWidget {
  final Note note;
  final bool startInEditMode;
  final bool isNewNote;

  const NoteViewScreen({super.key, required this.note, this.startInEditMode = false, this.isNewNote = false});

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  late bool _isEditing;
  late TextEditingController _titleController;
  late QuillController _quillController;
  final FocusNode _editorFocus = FocusNode();
  bool _wasEverSaved = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEditMode;
    _titleController = TextEditingController(text: widget.note.title);
    _wasEverSaved = !widget.isNewNote;
    _initQuill();
  }

  void _initQuill() {
    Document doc;
    try {
      if (widget.note.content.isNotEmpty && widget.note.content.startsWith('[')) {
        doc = Document.fromJson(jsonDecode(widget.note.content) as List);
      } else if (widget.note.content.isNotEmpty) {
        doc = Document()..insert(0, widget.note.content);
      } else {
        doc = Document();
      }
    } catch (_) {
      doc = Document();
    }
    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: !_isEditing,
    );
    _quillController.addListener(_onQuillChanged);
  }

  void _onQuillChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.removeListener(_onQuillChanged);
    _quillController.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  int get _wordCount {
    final text = _quillController.document.toPlainText().trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText().trim();
    if (widget.isNewNote && !_wasEverSaved && title.isEmpty && plainText.isEmpty) return;
    widget.note.title = title;
    widget.note.content = contentJson;
    widget.note.updatedAt = DateTime.now();
    await NotesService.saveNote(widget.note);
    _wasEverSaved = true;
  }

  Future<bool> _handleBack() async {
    if (_isEditing) {
      await _save();
      if (!_wasEverSaved) return true;
      _quillController.readOnly = true;
      setState(() => _isEditing = false);
      return false;
    }
    return true;
  }

  Future<void> _toggleEdit() async {
    if (_isEditing) {
      await _save();
      if (!_wasEverSaved) { if (mounted) Navigator.pop(context, false); return; }
      _quillController.readOnly = true;
      setState(() => _isEditing = false);
    } else {
      _quillController.readOnly = false;
      setState(() => _isEditing = true);
      Future.delayed(const Duration(milliseconds: 100), () => _editorFocus.requestFocus());
    }
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: GlassCard(
          blurSigma: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(padding: EdgeInsets.only(top: 4, bottom: 12),
                child: Text('Export Note', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16))),
              _ExportTile(icon: Icons.text_snippet_outlined, label: 'Export as Text (.txt)',
                onTap: () { Navigator.pop(ctx); ExportService.exportAsText(widget.note); }),
              _ExportTile(icon: Icons.picture_as_pdf_outlined, label: 'Export as PDF',
                onTap: () { Navigator.pop(ctx); ExportService.exportAsPdf(widget.note); }),
              _ExportTile(icon: Icons.image_outlined, label: 'Export as Image (.png)',
                onTap: () { Navigator.pop(ctx); ExportService.exportAsImage(widget.note, context); }),
            ],
          ),
        ),
      ),
    );
  }

  void _applyTextSize(String size) {
    final attr = size == 'normal'
        ? Attribute.clone(Attribute.size, null)
        : SizeAttribute(size);
    _quillController.formatSelection(attr);
  }

  void _applyTextColor(Color color) {
    _quillController.formatSelection(
      ColorAttribute('#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}'));
  }

  bool _hasAttribute(Attribute attribute) {
    final style = _quillController.getSelectionStyle();
    return style.attributes.containsKey(attribute.key);
  }

  void _toggleAttribute(Attribute attribute) {
    final isActive = _hasAttribute(attribute);
    _quillController.formatSelection(isActive ? Attribute.clone(attribute, null) : attribute);
  }

  void _showFormattingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: GlassCard(
          blurSigma: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(padding: EdgeInsets.only(top: 4, bottom: 12),
                child: Text('Format Selected Text', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16))),
              const Text('Style', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (sheetCtx, sheetSetState) => Row(children: [
                  _StyleBtn(
                    icon: Icons.format_bold_rounded,
                    label: 'Bold',
                    active: _hasAttribute(Attribute.bold),
                    onTap: () { _toggleAttribute(Attribute.bold); sheetSetState(() {}); },
                  ),
                  const SizedBox(width: 8),
                  _StyleBtn(
                    icon: Icons.format_italic_rounded,
                    label: 'Italic',
                    active: _hasAttribute(Attribute.italic),
                    onTap: () { _toggleAttribute(Attribute.italic); sheetSetState(() {}); },
                  ),
                  const SizedBox(width: 8),
                  _StyleBtn(
                    icon: Icons.format_underline_rounded,
                    label: 'Underline',
                    active: _hasAttribute(Attribute.underline),
                    onTap: () { _toggleAttribute(Attribute.underline); sheetSetState(() {}); },
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              const Text('Text Size', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                _SizeBtn(label: 'Small', onTap: () { _applyTextSize('small'); Navigator.pop(ctx); }),
                const SizedBox(width: 8),
                _SizeBtn(label: 'Normal', onTap: () { _applyTextSize('normal'); Navigator.pop(ctx); }),
                const SizedBox(width: 8),
                _SizeBtn(label: 'Large', onTap: () { _applyTextSize('large'); Navigator.pop(ctx); }),
                const SizedBox(width: 8),
                _SizeBtn(label: 'Huge', onTap: () { _applyTextSize('huge'); Navigator.pop(ctx); }),
              ]),
              const SizedBox(height: 16),
              const Text('Text Color', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                _ColorBtn(color: AppColors.gold, label: 'Gold', onTap: () { _applyTextColor(AppColors.gold); Navigator.pop(ctx); }),
                const SizedBox(width: 8),
                _ColorBtn(color: AppColors.textPrimary, label: 'White', onTap: () { _applyTextColor(AppColors.textPrimary); Navigator.pop(ctx); }),
                const SizedBox(width: 8),
                _ColorBtn(color: AppColors.danger, label: 'Red', onTap: () { _applyTextColor(AppColors.danger); Navigator.pop(ctx); }),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              final shouldPop = await _handleBack();
              if (shouldPop && mounted) Navigator.pop(context, _wasEverSaved);
            },
          ),
          title: Text(_isEditing ? 'Editing' : 'Note'),
          actions: [
            if (_isEditing)
              IconButton(icon: const Icon(Icons.format_size_rounded), tooltip: 'Format', onPressed: _showFormattingSheet)
            else
              IconButton(icon: const Icon(Icons.ios_share_rounded, size: 21), tooltip: 'Export', onPressed: _showExportMenu),
            IconButton(
              icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_outlined, color: AppColors.gold),
              tooltip: _isEditing ? 'Save' : 'Edit',
              onPressed: _toggleEdit,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: GlassBackground(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 28, 16, 16),
              child: GlassCard(
                blurSigma: 22,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isEditing
                        ? TextField(
                            controller: _titleController,
                            style: const TextStyle(color: AppColors.gold, fontSize: 21, fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(hintText: 'Title',
                              border: InputBorder.none, enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
                            onChanged: (_) => setState(() {}),
                          )
                        : Text(
                            _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text,
                            style: const TextStyle(color: AppColors.gold, fontSize: 21, fontWeight: FontWeight.w700),
                          ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: Text(
                        'Last edited ${DateFormat('MMM d, yyyy · h:mm a').format(widget.note.updatedAt)}',
                        style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5))),
                      Text('$_wordCount ${_wordCount == 1 ? "word" : "words"}',
                        style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5)),
                    ]),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 10),
                    Expanded(
                      child: QuillEditor.basic(
                        controller: _quillController,
                        focusNode: _isEditing ? _editorFocus : null,
                        config: QuillEditorConfig(
                          placeholder: 'Start writing...',
                          padding: EdgeInsets.zero,
                          customStyles: DefaultStyles(
                            paragraph: DefaultTextBlockStyle(
                              const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.55),
                              HorizontalSpacing.zero, VerticalSpacing.zero, VerticalSpacing.zero, null),
                            placeHolder: DefaultTextBlockStyle(
                              const TextStyle(color: AppColors.textFaint, fontSize: 16),
                              HorizontalSpacing.zero, VerticalSpacing.zero, VerticalSpacing.zero, null),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _ExportTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap,
    leading: Icon(icon, color: AppColors.gold),
    title: Text(label, style: const TextStyle(color: AppColors.textPrimary)));
}

class _StyleBtn extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _StyleBtn({required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.gold.withOpacity(0.18) : AppColors.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.gold : AppColors.glassBorder)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: active ? AppColors.gold : AppColors.textPrimary),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: active ? AppColors.gold : AppColors.textSecondary, fontSize: 11)),
        ]))));
}

class _SizeBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _SizeBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: AppColors.glassFill, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder)),
        child: Text(label, textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))));
}

class _ColorBtn extends StatelessWidget {
  final Color color; final String label; final VoidCallback onTap;
  const _ColorBtn({required this.color, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))));
}
