import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/notes_database.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dialogs.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
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
    final notes = await NotesService.getDeletedNotes();
    notes.sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
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

  Future<void> _restoreSelected() async {
    final toRestore = _notes.where((n) => _selected.contains(n.id)).toList();
    for (final n in toRestore) await NotesService.restoreNote(n);
    _clearSelection();
    _loadNotes();
  }

  Future<void> _permanentDeleteSelected() async {
    final confirm = await showConfirmDialog(context,
      title: 'Delete Forever?',
      message: '${_selected.length} note(s) will be permanently deleted. This cannot be undone.',
      confirmLabel: 'Delete Forever', isDanger: true);
    if (confirm != true) return;
    final toDel = _notes.where((n) => _selected.contains(n.id)).toList();
    await NotesService.permanentDeleteNotes(toDel);
    _clearSelection();
    _loadNotes();
  }

  Future<void> _emptyBin() async {
    if (_notes.isEmpty) return;
    final confirm = await showConfirmDialog(context,
      title: 'Empty Recycle Bin?',
      message: 'All ${_notes.length} note(s) will be permanently deleted. This cannot be undone.',
      confirmLabel: 'Empty Bin', isDanger: true);
    if (confirm != true) return;
    await NotesService.permanentDeleteNotes(_notes);
    _loadNotes();
  }

  int _daysLeft(Note n) {
    if (n.deletedAt == null) return 30;
    return (30 - DateTime.now().difference(n.deletedAt!).inDays).clamp(0, 30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSelecting ? Text('${_selected.length} selected') : const Text('Recycle Bin'),
        leading: _isSelecting ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection) : null,
        actions: _isSelecting ? [
          IconButton(icon: const Icon(Icons.restore_rounded, color: AppColors.gold), tooltip: 'Restore', onPressed: _restoreSelected),
          IconButton(icon: const Icon(Icons.delete_forever_rounded, color: AppColors.danger), tooltip: 'Delete Forever', onPressed: _permanentDeleteSelected),
          const SizedBox(width: 4),
        ] : [
          if (_notes.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger), tooltip: 'Empty Bin', onPressed: _emptyBin),
          const SizedBox(width: 4),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          top: false,
          child: Column(children: [
            SizedBox(height: kToolbarHeight + 28),
            if (!_isLoading && _notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.goldMuted, size: 16),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Notes are permanently deleted after 30 days.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5))),
                  ]),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : (_notes.isEmpty ? _buildEmpty() : RefreshIndicator(
                      onRefresh: _loadNotes,
                      color: AppColors.gold,
                      backgroundColor: AppColors.bgTop,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: _notes.length,
                        itemBuilder: (ctx, i) {
                          final n = _notes[i];
                          final sel = _selected.contains(n.id);
                          final days = _daysLeft(n);
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            borderColor: sel ? AppColors.gold : AppColors.glassBorder,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            onTap: () => _toggleSelect(n.id),
                            child: Row(children: [
                              Padding(padding: const EdgeInsets.only(right: 12),
                                child: Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: sel ? AppColors.gold : AppColors.textSecondary)),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(n.title.isEmpty ? 'Untitled' : n.title,
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('Deleted ${DateFormat('MMM d, yyyy').format(n.deletedAt!)}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text('$days day${days == 1 ? "" : "s"} left',
                                  style: TextStyle(
                                    color: days <= 3 ? AppColors.danger : AppColors.textFaint,
                                    fontSize: 11, fontWeight: days <= 3 ? FontWeight.w600 : FontWeight.w400)),
                              ])),
                            ]),
                          );
                        },
                      ),
                    )),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.delete_outline_rounded, size: 72, color: AppColors.goldMuted),
    const SizedBox(height: 16),
    const Text('Recycle bin is empty', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    const Text('Deleted notes appear here for 30 days', style: TextStyle(color: AppColors.textSecondary)),
  ]));
}
