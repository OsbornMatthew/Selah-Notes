import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../services/notes_database.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dialogs.dart';
import 'note_view_screen.dart';

enum NoteSort { newest, oldest, nameAsc, nameDesc }
enum ViewMode { list, grid, details }

class NotesListScreen extends StatefulWidget {
  final Folder folder;
  const NotesListScreen({super.key, required this.folder});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final _uuid = const Uuid();
  List<Note> _notes = [];
  NoteSort _sort = NoteSort.newest;
  ViewMode _view = ViewMode.list;
  bool _isLoading = true;
  final Set<String> _selected = {};
  bool _isSelecting = false;

  @override
  void initState() { super.initState(); _loadNotes(); }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await NotesService.getNotesByFolder(widget.folder.id);
    if (!mounted) return;
    setState(() { _notes = _sortNotes(notes); _isLoading = false; });
  }

  List<Note> _sortNotes(List<Note> notes) {
    final list = [...notes];
    switch (_sort) {
      case NoteSort.newest: list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); break;
      case NoteSort.oldest: list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt)); break;
      case NoteSort.nameAsc: list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase())); break;
      case NoteSort.nameDesc: list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase())); break;
    }
    list.sort((a, b) => (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0));
    return list;
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) _selected.remove(id); else _selected.add(id);
      _isSelecting = _selected.isNotEmpty;
    });
  }

  void _clearSelection() => setState(() { _selected.clear(); _isSelecting = false; });

  Future<void> _archiveSelected() async {
    final toArchive = _notes.where((n) => _selected.contains(n.id)).toList();
    await NotesService.archiveNotes(toArchive);
    _clearSelection(); _loadNotes();
  }

  Future<void> _deleteSelected() async {
    final confirm = await showConfirmDialog(context,
      title: 'Move to Recycle Bin?',
      message: '${_selected.length} note(s) will be moved to the recycle bin.',
      confirmLabel: 'Move', isDanger: true);
    if (confirm != true) return;
    final toDel = _notes.where((n) => _selected.contains(n.id)).toList();
    await NotesService.softDeleteNotes(toDel);
    _clearSelection(); _loadNotes();
  }

  Future<void> _createNote() async {
    final note = Note(id: _uuid.v4(), title: '', content: '', folderId: widget.folder.id,
      createdAt: DateTime.now(), updatedAt: DateTime.now());
    final result = await Navigator.push(context,
      MaterialPageRoute(builder: (_) => NoteViewScreen(note: note, startInEditMode: true, isNewNote: true)));
    if (result == true) _loadNotes();
  }

  Future<void> _togglePin(Note note) async {
    note.isPinned = !note.isPinned;
    await NotesService.saveNote(note); _loadNotes();
  }

  Future<void> _moveNote(Note note) async {
    final allFolders = await NotesService.getAllFolders();
    final folders = allFolders.where((f) => f.id != widget.folder.id).toList();
    if (folders.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No other folders. Create one first.')));
      return;
    }
    if (!mounted) return;
    final target = await showModalBottomSheet<Folder>(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GlassCard(blurSigma: 24, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.only(bottom: 8, top: 4),
            child: Text('Move to folder', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16))),
          for (final f in folders)
            ListTile(onTap: () => Navigator.pop(ctx, f),
              leading: const Icon(Icons.folder_rounded, color: AppColors.gold),
              title: Text(f.name, style: const TextStyle(color: AppColors.textPrimary))),
        ])),
      ),
    );
    if (target != null) {
      note.folderId = target.id;
      await NotesService.saveNote(note); _loadNotes();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Moved to "${target.name}"')));
    }
  }

  void _showSortMenu() async {
    final sel = await showModalBottomSheet<NoteSort>(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => buildSortSheet<NoteSort>(ctx, title: 'Sort notes', current: _sort, options: {
        NoteSort.newest: ('Newest first', Icons.arrow_downward_rounded),
        NoteSort.oldest: ('Oldest first', Icons.arrow_upward_rounded),
        NoteSort.nameAsc: ('Title A → Z', Icons.sort_by_alpha_rounded),
        NoteSort.nameDesc: ('Title Z → A', Icons.sort_by_alpha_rounded),
      }),
    );
    if (sel != null) setState(() { _sort = sel; _notes = _sortNotes(_notes); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSelecting ? Text('${_selected.length} selected') : Text(widget.folder.name),
        leading: _isSelecting ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection) : null,
        actions: _isSelecting ? [
          IconButton(icon: const Icon(Icons.archive_outlined, color: AppColors.gold), tooltip: 'Archive', onPressed: _archiveSelected),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), tooltip: 'Delete', onPressed: _deleteSelected),
          const SizedBox(width: 4),
        ] : [
          IconButton(icon: const Icon(Icons.sort_rounded), onPressed: _showSortMenu),
          IconButton(
            icon: Icon(_view == ViewMode.list ? Icons.grid_view_rounded : _view == ViewMode.grid ? Icons.view_list_rounded : Icons.view_agenda_rounded),
            onPressed: () => setState(() => _view = ViewMode.values[(_view.index + 1) % 3]),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : (_notes.isEmpty ? _buildEmpty() : RefreshIndicator(
                  onRefresh: _loadNotes, color: AppColors.gold, backgroundColor: AppColors.bgTop,
                  child: _view == ViewMode.grid ? _buildGrid() : _buildList(),
                )),
        ),
      ),
      floatingActionButton: _isSelecting ? null :
        FloatingActionButton(onPressed: _createNote, child: const Icon(Icons.add_rounded)),
    );
  }

  Widget _buildList() => ListView.builder(
    padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 35, 16, 100),
    itemCount: _notes.length,
    itemBuilder: (ctx, i) {
      final n = _notes[i];
      final sel = _selected.contains(n.id);
      final showDetails = _view == ViewMode.details;
      return GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        borderColor: sel ? AppColors.gold : (n.isPinned ? AppColors.gold.withOpacity(0.4) : AppColors.glassBorder),
        onLongPress: () => _toggleSelect(n.id),
        onTap: () {
          if (_isSelecting) { _toggleSelect(n.id); return; }
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => NoteViewScreen(note: n, startInEditMode: false)))
            .then((r) { if (r == true || r == 'deleted') _loadNotes(); });
        },
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_isSelecting)
            Padding(padding: const EdgeInsets.only(right: 10, top: 2),
              child: Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: sel ? AppColors.gold : AppColors.textSecondary, size: 20)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (n.isPinned && !_isSelecting) ...[const Icon(Icons.push_pin, size: 13, color: AppColors.gold), const SizedBox(width: 5)],
              Expanded(child: Text(n.title.isEmpty ? 'Untitled' : n.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 15))),
            ]),
            if (showDetails) ...[
              const SizedBox(height: 5),
              Text(n.content.length > 2 ? _preview(n.content) : 'No content', maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ] else ...[
              const SizedBox(height: 4),
              Text(_preview(n.content), maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ],
            const SizedBox(height: 6),
            Text(DateFormat('MMM d, yyyy · h:mm a').format(n.updatedAt),
              style: const TextStyle(color: AppColors.textFaint, fontSize: 10.5)),
          ])),
          if (!_isSelecting)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
              color: AppColors.bgTop, surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.glassBorder)),
              onSelected: (v) {
                if (v == 'pin') _togglePin(n);
                if (v == 'move') _moveNote(n);
                if (v == 'archive') NotesService.archiveNote(n).then((_) => _loadNotes());
                if (v == 'delete') NotesService.softDeleteNote(n).then((_) => _loadNotes());
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'pin', child: _menuItem(n.isPinned ? Icons.push_pin_outlined : Icons.push_pin, n.isPinned ? 'Unpin' : 'Pin', AppColors.gold)),
                PopupMenuItem(value: 'move', child: _menuItem(Icons.folder_copy_outlined, 'Move to folder', AppColors.gold)),
                PopupMenuItem(value: 'archive', child: _menuItem(Icons.archive_outlined, 'Archive', AppColors.gold)),
                PopupMenuItem(value: 'delete', child: _menuItem(Icons.delete_outline_rounded, 'Delete', AppColors.danger)),
              ],
            ),
        ]),
      );
    },
  );

  Widget _buildGrid() => GridView.builder(
    padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 35, 16, 100),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.9),
    itemCount: _notes.length,
    itemBuilder: (ctx, i) {
      final n = _notes[i];
      final sel = _selected.contains(n.id);
      return GlassCard(
        borderColor: sel ? AppColors.gold : AppColors.glassBorder,
        padding: const EdgeInsets.all(14),
        onTap: () {
          if (_isSelecting) { _toggleSelect(n.id); return; }
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => NoteViewScreen(note: n, startInEditMode: false)))
            .then((r) { if (r == true) _loadNotes(); });
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (n.isPinned && !_isSelecting) const Icon(Icons.push_pin, size: 12, color: AppColors.gold),
            if (_isSelecting) Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: sel ? AppColors.gold : AppColors.textSecondary, size: 18),
            const Spacer(),
            Icon(Icons.note_outlined, color: AppColors.goldMuted, size: 16),
          ]),
          const SizedBox(height: 8),
          Text(n.title.isEmpty ? 'Untitled' : n.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          Expanded(child: Text(_preview(n.content), maxLines: 5, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5))),
          const SizedBox(height: 6),
          Text(DateFormat('MMM d').format(n.updatedAt), style: const TextStyle(color: AppColors.textFaint, fontSize: 10)),
        ]),
      );
    },
  );

  String _preview(String content) {
    if (content.isEmpty) return 'No content';
    try {
      if (content.startsWith('[')) {
        final regex = RegExp(r'"insert"\s*:\s*"((?:[^"\\]|\\.)*)"');
        return regex.allMatches(content).map((m) {
          var t = m.group(1) ?? '';
          return t.replaceAll(r'\n', ' ').replaceAll(r'\"', '"');
        }).join(' ').trim();
      }
    } catch (_) {}
    return content.replaceAll('\n', ' ');
  }

  Widget _menuItem(IconData icon, String label, Color color) => Row(children: [
    Icon(icon, size: 17, color: color), const SizedBox(width: 10),
    Text(label, style: TextStyle(color: color == AppColors.danger ? AppColors.danger : AppColors.textPrimary)),
  ]);

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.note_alt_outlined, size: 72, color: AppColors.goldMuted),
    const SizedBox(height: 16),
    const Text('No notes here yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    const Text('Tap + to write your first note', style: TextStyle(color: AppColors.textSecondary)),
  ]));
}
