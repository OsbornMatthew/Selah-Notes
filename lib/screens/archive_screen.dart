import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../services/notes_database.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dialogs.dart';
import 'note_view_screen.dart';
import 'notes_list_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Folder> _folders = [];
  List<Note> _notes = [];
  final Set<String> _selectedFolders = {};
  final Set<String> _selectedNotes = {};
  bool _isLoading = true;

  bool get _isSelecting => _selectedFolders.isNotEmpty || _selectedNotes.isNotEmpty;
  int get _selectedCount => _selectedFolders.length + _selectedNotes.length;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      NotesService.getArchivedFolders(),
      NotesService.getArchivedNotes(),
    ]);
    final folders = results[0] as List<Folder>;
    final notes = results[1] as List<Note>;
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    folders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() { _folders = folders; _notes = notes; _isLoading = false; });
  }

  void _toggleSelectFolder(String id) {
    setState(() {
      if (_selectedFolders.contains(id)) _selectedFolders.remove(id); else _selectedFolders.add(id);
    });
  }

  void _toggleSelectNote(String id) {
    setState(() {
      if (_selectedNotes.contains(id)) _selectedNotes.remove(id); else _selectedNotes.add(id);
    });
  }

  void _clearSelection() => setState(() { _selectedFolders.clear(); _selectedNotes.clear(); });

  Future<void> _unarchiveSelected() async {
    final foldersToRestore = _folders.where((f) => _selectedFolders.contains(f.id)).toList();
    final notesToRestore = _notes.where((n) => _selectedNotes.contains(n.id)).toList();
    for (final f in foldersToRestore) await NotesService.unarchiveFolder(f);
    for (final n in notesToRestore) await NotesService.unarchiveNote(n);
    _clearSelection();
    _loadAll();
  }

  Future<void> _deleteSelected() async {
    final confirm = await showConfirmDialog(context,
      title: 'Move to Recycle Bin?',
      message: '$_selectedCount item(s) will be moved to the recycle bin and deleted after 30 days.',
      confirmLabel: 'Move', isDanger: true);
    if (confirm != true) return;
    final foldersToDelete = _folders.where((f) => _selectedFolders.contains(f.id)).toList();
    final notesToDelete = _notes.where((n) => _selectedNotes.contains(n.id)).toList();
    for (final f in foldersToDelete) await NotesService.softDeleteFolder(f.id);
    if (notesToDelete.isNotEmpty) await NotesService.softDeleteNotes(notesToDelete);
    _clearSelection();
    _loadAll();
  }

  Future<void> _showFolderMenu(Folder f) async {
    final action = await showModalBottomSheet<String>(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: GlassCard(
          blurSigma: 20,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(f.name, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            ListTile(
              leading: const Icon(Icons.unarchive_outlined, color: AppColors.gold),
              title: const Text('Unarchive', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'unarchive'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: const Text('Move to Bin', style: TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ]),
        ),
      ),
    );
    if (action == 'unarchive') { await NotesService.unarchiveFolder(f); _loadAll(); }
    if (action == 'delete') {
      final ok = await showConfirmDialog(context,
        title: 'Move to Recycle Bin?',
        message: '"${f.name}" and all its notes will be moved to the recycle bin.',
        confirmLabel: 'Move to Bin', isDanger: true);
      if (ok == true) { await NotesService.softDeleteFolder(f.id); _loadAll(); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSelecting
            ? Text('$_selectedCount selected')
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
          top: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : (_folders.isEmpty && _notes.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      color: AppColors.gold,
                      backgroundColor: AppColors.bgTop,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 40, 16, 32),
                        children: [
                          if (_folders.isNotEmpty) ...[
                            Padding(padding: const EdgeInsets.only(bottom: 8),
                              child: Text('Folders', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
                            ..._folders.map((f) {
                              final sel = _selectedFolders.contains(f.id);
                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                borderColor: sel ? AppColors.gold : AppColors.glassBorder,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                onLongPress: () { if (!_isSelecting) _showFolderMenu(f); },
                                onTap: () {
                                  if (_isSelecting) { _toggleSelectFolder(f.id); return; }
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => NotesListScreen(folder: f))).then((_) => _loadAll());
                                },
                                child: Row(children: [
                                  if (_isSelecting)
                                    Padding(padding: const EdgeInsets.only(right: 12),
                                      child: Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                        color: sel ? AppColors.gold : AppColors.textSecondary)),
                                  Container(width: 38, height: 38,
                                    decoration: BoxDecoration(color: AppColors.goldMuted.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.glassBorder)),
                                    child: const Icon(Icons.folder_rounded, color: AppColors.gold, size: 20)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(f.name,
                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ]),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                          if (_notes.isNotEmpty) ...[
                            Padding(padding: const EdgeInsets.only(bottom: 8),
                              child: Text('Notes', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
                            ..._notes.map((n) {
                              final sel = _selectedNotes.contains(n.id);
                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                borderColor: sel ? AppColors.gold : AppColors.glassBorder,
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                onLongPress: () => _toggleSelectNote(n.id),
                                onTap: () {
                                  if (_isSelecting) { _toggleSelectNote(n.id); return; }
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => NoteViewScreen(note: n))).then((_) => _loadAll());
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
                            }),
                          ],
                        ],
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
    const Text('Long press a folder or note and select Archive', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
  ]));
}
