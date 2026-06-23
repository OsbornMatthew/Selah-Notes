import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../models/folder.dart';
import '../services/notes_database.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dialogs.dart';

// Unified bin item for display
class _BinItem {
  final bool isFolder;
  final Note? note;
  final Folder? folder;
  final int noteCount; // only used when isFolder=true
  _BinItem.note(this.note) : isFolder = false, folder = null, noteCount = 0;
  _BinItem.folder(this.folder, this.noteCount) : isFolder = true, note = null;

  DateTime get deletedAt => isFolder ? folder!.deletedAt! : note!.deletedAt!;
  String get id => isFolder ? folder!.id : note!.id;
  String get displayTitle => isFolder ? folder!.name : (note!.title.isEmpty ? 'Untitled' : note!.title);
}

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  List<_BinItem> _items = [];
  final Set<String> _selected = {};
  bool _isSelecting = false;
  bool _isLoading = true;

  // We also keep raw lists so we can filter for empty-bin
  List<Note> _deletedNotes = [];
  List<Folder> _deletedFolders = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      NotesService.getDeletedFolders(),
      NotesService.getDeletedNotes(),
    ]);

    final folders = results[0] as List<Folder>;
    final notes = results[1] as List<Note>;

    _deletedFolders = folders;
    _deletedNotes = notes;

    // Get note counts for each deleted folder (notes deleted with it)
    final folderNoteSnap = await Future.wait(
      folders.map((f) => NotesService.getNotesByDeletedFolder(f.id)),
    );

    // Build unified list: folders first then standalone notes, sorted by deletedAt desc
    final items = <_BinItem>[
      ...folders.asMap().entries.map((e) => _BinItem.folder(e.value, folderNoteSnap[e.key].length)),
      ...notes.where((n) => !(n.deletedWithFolder)).map((n) => _BinItem.note(n)),
    ];
    items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));

    if (!mounted) return;
    setState(() { _items = items; _isLoading = false; });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) _selected.remove(id); else _selected.add(id);
      _isSelecting = _selected.isNotEmpty;
    });
  }

  void _clearSelection() => setState(() { _selected.clear(); _isSelecting = false; });

  Future<void> _restoreSelected() async {
    final selectedItems = _items.where((i) => _selected.contains(i.id)).toList();
    for (final item in selectedItems) {
      if (item.isFolder) {
        await NotesService.restoreFolder(item.folder!.id);
      } else {
        await NotesService.restoreNote(item.note!);
      }
    }
    _clearSelection();
    _loadItems();
  }

  Future<void> _permanentDeleteSelected() async {
    final confirm = await showConfirmDialog(context,
      title: 'Delete Forever?',
      message: '${_selected.length} item(s) will be permanently deleted. This cannot be undone.',
      confirmLabel: 'Delete Forever', isDanger: true);
    if (confirm != true) return;

    final selectedItems = _items.where((i) => _selected.contains(i.id)).toList();
    for (final item in selectedItems) {
      if (item.isFolder) {
        await NotesService.permanentDeleteFolder(item.folder!.id);
      } else {
        await NotesService.permanentDeleteNote(item.note!.id);
      }
    }
    _clearSelection();
    _loadItems();
  }

  Future<void> _emptyBin() async {
    if (_items.isEmpty) return;
    final confirm = await showConfirmDialog(context,
      title: 'Empty Recycle Bin?',
      message: 'Everything will be permanently deleted. This cannot be undone.',
      confirmLabel: 'Empty Bin', isDanger: true);
    if (confirm != true) return;

    for (final f in _deletedFolders) await NotesService.permanentDeleteFolder(f.id);
    await NotesService.permanentDeleteNotes(_deletedNotes);
    _loadItems();
  }

  int _daysLeft(DateTime deletedAt) =>
      (30 - DateTime.now().difference(deletedAt).inDays).clamp(0, 30);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSelecting
            ? Text('${_selected.length} selected')
            : const Text('Recycle Bin'),
        leading: _isSelecting
            ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection)
            : null,
        actions: _isSelecting ? [
          IconButton(
            icon: const Icon(Icons.restore_rounded, color: AppColors.gold),
            tooltip: 'Restore',
            onPressed: _restoreSelected,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
            tooltip: 'Delete Forever',
            onPressed: _permanentDeleteSelected,
          ),
          const SizedBox(width: 4),
        ] : [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger),
              tooltip: 'Empty Bin',
              onPressed: _emptyBin,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          top: false,
          child: Column(children: [
            SizedBox(height: kToolbarHeight + 40),
            if (!_isLoading && _items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.goldMuted, size: 16),
                    const SizedBox(width: 10),
                    const Expanded(child: Text(
                      'Items are permanently deleted after 30 days.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5))),
                  ]),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : _items.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _loadItems,
                          color: AppColors.gold,
                          backgroundColor: AppColors.bgTop,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                            itemCount: _items.length,
                            itemBuilder: (ctx, i) => _buildItem(_items[i]),
                          ),
                        ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildItem(_BinItem item) {
    final sel = _selected.contains(item.id);
    final days = _daysLeft(item.deletedAt);
    final dateStr = DateFormat('MMM d, yyyy').format(item.deletedAt);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: sel ? AppColors.gold : AppColors.glassBorder,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      onTap: () => _toggleSelect(item.id),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: sel ? AppColors.gold : AppColors.textSecondary,
          ),
        ),
        // Icon indicating folder vs note
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppColors.goldMuted.withOpacity(0.14),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Icon(
            item.isFolder ? Icons.folder_rounded : Icons.description_outlined,
            color: AppColors.gold,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            item.displayTitle,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          if (item.isFolder)
            Text(
              '${item.noteCount} note${item.noteCount == 1 ? "" : "s"} inside',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          Text(
            'Deleted $dateStr',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '$days day${days == 1 ? "" : "s"} left',
            style: TextStyle(
              color: days <= 3 ? AppColors.danger : AppColors.textFaint,
              fontSize: 11,
              fontWeight: days <= 3 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ])),
        // Quick restore button
        IconButton(
          icon: const Icon(Icons.restore_rounded, size: 20, color: AppColors.goldMuted),
          tooltip: 'Restore',
          onPressed: () async {
            if (item.isFolder) {
              await NotesService.restoreFolder(item.folder!.id);
            } else {
              await NotesService.restoreNote(item.note!);
            }
            _loadItems();
          },
        ),
      ]),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.delete_outline_rounded, size: 72, color: AppColors.goldMuted),
    const SizedBox(height: 16),
    const Text('Recycle bin is empty',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    const Text('Deleted folders and notes appear here for 30 days',
        style: TextStyle(color: AppColors.textSecondary)),
  ]));
}
