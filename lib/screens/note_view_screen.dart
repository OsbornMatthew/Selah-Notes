import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../services/notes_database.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class NoteViewScreen extends StatefulWidget {
  final Note note;
  final bool startInEditMode;
  final bool isNewNote;

  const NoteViewScreen({
    super.key,
    required this.note,
    this.startInEditMode = false,
    this.isNewNote = false,
  });

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  late bool _isEditing;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _wasEverSaved = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEditMode;
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _wasEverSaved = !widget.isNewNote;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text;

    if (widget.isNewNote && !_wasEverSaved && title.isEmpty && content.trim().isEmpty) {
      return;
    }

    widget.note.title = title;
    widget.note.content = content;
    widget.note.updatedAt = DateTime.now();
    await NotesDatabase.saveNote(widget.note);
    _wasEverSaved = true;
  }

  Future<bool> _handleBack() async {
    if (_isEditing) {
      await _save();
      if (!_wasEverSaved) return true;
      setState(() => _isEditing = false);
      return false;
    }
    return true;
  }

  Future<void> _toggleEdit() async {
    if (_isEditing) {
      await _save();
      if (!_wasEverSaved) {
        if (mounted) Navigator.pop(context, false);
        return;
      }
      setState(() => _isEditing = false);
    } else {
      setState(() => _isEditing = true);
    }
  }

  void _shareNote() {
    final title = _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim();
    final content = _contentController.text;
    final text = '$title\n\n$content';
    Share.share(text, subject: title);
  }

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
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
              if (shouldPop && mounted) {
                Navigator.pop(context, _wasEverSaved);
              }
            },
          ),
          title: Text(_isEditing ? 'Editing' : 'Note'),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.ios_share_rounded, size: 21),
                tooltip: 'Share',
                onPressed: _shareNote,
              ),
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 12, 16, 16),
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
                            decoration: const InputDecoration(
                              hintText: 'Title',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                          )
                        : Text(
                            _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text,
                            style: const TextStyle(color: AppColors.gold, fontSize: 21, fontWeight: FontWeight.w700),
                          ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Last edited ${DateFormat('MMM d, yyyy · h:mm a').format(widget.note.updatedAt)}',
                            style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                          ),
                        ),
                        Text(
                          '$_wordCount ${_wordCount == 1 ? "word" : "words"}',
                          style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _isEditing
                          ? TextField(
                              controller: _contentController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.55),
                              decoration: const InputDecoration(
                                hintText: 'Start writing...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            )
                          : SingleChildScrollView(
                              child: Text(
                                _contentController.text.isEmpty
                                    ? 'Nothing written yet. Tap the pencil icon to start editing.'
                                    : _contentController.text,
                                style: TextStyle(
                                  color: _contentController.text.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                                  fontSize: 16,
                                  height: 1.55,
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
