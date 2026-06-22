import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/notes_database.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dialogs.dart';
import 'note_view_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Note> _notes = [];
  final Set<String> _selected = {};
  bool _isSelecting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await NotesService.getArchivedNotes();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!mounted) return;
    setState(() { _notes = notes; _isLoading = false; });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) _selected.remove(id); else _selected.add(id);
      _isSelecting = _selected.isNotEmpty;
    });
  }

  void _clearSelection() => setState(() { _selected.clear(); _isSelecting = false; });

  Future<void> _unarchiveSelected() async {
    final toUnarchive = _notes.where((n) => _selected.contains(n.id)).toList();
    for (final n in toUnarchive) await NotesService.unarchiveNote(n);
    _clearSelection();
    _loadNotes();
  }

  Future<void> _deleteSelected() async {
    final confirm = await showConfirmDialog(context,
      title: 'Move to Recycle Bin?',
      message: '${_selected.length} note(s) will be moved to the recycle bin and deleted after 30 days.',
      confirmLabel: 'Move', isDanger: true);
    if (confirm != true) return;
    final toDel = _notes.where((n) => _selected.contains(n.id)).toList();
    await NotesService.softDeleteNotes(toDel);
    _clearSelection();
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSelecting
            ? Text('${_selected.length} selected')
            : const Text('Archive'),
        leading: _isSelecting
            ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection)
            : null,
        actions: _isSelecting ? [
          IconButton(icon: const Icon(Icons.unarchive_outlined, color: AppColors.gold), tooltip: 'Unarchive', onPressed: _unarchiveSelected),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), tooltip: 'Delete', onPressed: _deleteSelected),
          const SizedBox(width: 4),
        ] : [const SizedBox(width: 4)],
      ),
      body: GlassBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : (_notes.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadNotes,
                      color: AppColors.gold,
                      backgroundColor: AppColors.bgTop,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 32),
                        itemCount: _notes.length,
                        itemBuilder: (ctx, i) {
                          final n = _notes[i];
                          final sel = _selected.contains(n.id);
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            borderColor: sel ? AppColors.gold : AppColors.glassBorder,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            onTap: () {
                              if (_isSelecting) { _toggleSelect(n.id); return; }
                              Navigator.push(context, MaterialPageRoute(builder: (_) => NoteViewScreen(note: n))).then((_) => _loadNotes());
                            },
                            child: Row(children: [
                              if (_isSelecting)
                                Padding(padding: const EdgeInsets.only(right: 12),
                                  child: Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: sel ? AppColors.gold : AppColors.textSecondary)),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(n.title.isEmpty ? 'Untitled' : n.title,
                                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 15),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 5),
                                Text(DateFormat('MMM d, yyyy').format(n.updatedAt),
                                  style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                              ])),
                            ]),
                          );
                        },
                      ),
                    )),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.archive_outlined, size: 72, color: AppColors.goldMuted),
    const SizedBox(height: 16),
    const Text('Archive is empty', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    const Text('Long press a note and select Archive', style: TextStyle(color: AppColors.textSecondary)),
  ]));
}
