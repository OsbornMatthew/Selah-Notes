import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../services/notes_database.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'note_view_screen.dart';

enum NoteSort { newest, oldest, nameAsc, nameDesc }

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

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    final notes = NotesDatabase.getNotesByFolder(widget.folder.id);
    setState(() => _notes = _sortNotes(notes));
  }

  List<Note> _sortNotes(List<Note> notes) {
    final list = [...notes];
    switch (_sort) {
      case NoteSort.newest:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NoteSort.oldest:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case NoteSort.nameAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NoteSort.nameDesc:
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }
    // Pinned notes always float to top, preserving the chosen sort within each group
    list.sort((a, b) => (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0));
    return list;
  }

  Future<void> _createNote() async {
    final note = Note(
      id: _uuid.v4(),
      title: '',
      content: '',
      folderId: widget.folder.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteViewScreen(note: note, startInEditMode: true, isNewNote: true),
      ),
    );

    if (result == true) _loadNotes();
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          blurSigma: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delete Note?', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 12),
              const Text('This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await NotesDatabase.deleteNote(note.id);
      _loadNotes();
    }
  }

  Future<void> _togglePin(Note note) async {
    note.isPinned = !note.isPinned;
    await NotesDatabase.saveNote(note);
    _loadNotes();
  }

  Future<void> _moveNote(Note note) async {
    final folders = NotesDatabase.getAllFolders().where((f) => f.id != widget.folder.id).toList();
    if (folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other folders to move to. Create one first.')),
      );
      return;
    }

    final target = await showModalBottomSheet<Folder>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GlassCard(
          blurSigma: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8, top: 4),
                child: Text('Move to folder', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              for (final f in folders)
                ListTile(
                  onTap: () => Navigator.pop(context, f),
                  leading: const Icon(Icons.folder_rounded, color: AppColors.gold),
                  title: Text(f.name, style: const TextStyle(color: AppColors.textPrimary)),
                ),
            ],
          ),
        ),
      ),
    );

    if (target != null) {
      note.folderId = target.id;
      await NotesDatabase.saveNote(note);
      _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved to "${target.name}"')),
        );
      }
    }
  }

  void _showSortMenu() async {
    final options = {
      NoteSort.newest: ('Newest first', Icons.arrow_downward_rounded),
      NoteSort.oldest: ('Oldest first', Icons.arrow_upward_rounded),
      NoteSort.nameAsc: ('Title A → Z', Icons.sort_by_alpha_rounded),
      NoteSort.nameDesc: ('Title Z → A', Icons.sort_by_alpha_rounded),
    };

    final selected = await showModalBottomSheet<NoteSort>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GlassCard(
          blurSigma: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8, top: 4),
                child: Text('Sort notes', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              for (final entry in options.entries)
                ListTile(
                  onTap: () => Navigator.pop(context, entry.key),
                  leading: Icon(entry.value.$2, color: _sort == entry.key ? AppColors.gold : AppColors.textSecondary),
                  title: Text(
                    entry.value.$1,
                    style: TextStyle(
                      color: _sort == entry.key ? AppColors.gold : AppColors.textPrimary,
                      fontWeight: _sort == entry.key ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: _sort == entry.key ? const Icon(Icons.check_rounded, color: AppColors.gold) : null,
                ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _sort = selected;
        _notes = _sortNotes(_notes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.folder.name),
        actions: [
          IconButton(icon: const Icon(Icons.sort_rounded), tooltip: 'Sort', onPressed: _showSortMenu),
          const SizedBox(width: 4),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          child: _notes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 100),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return _NoteCard(
                      note: note,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NoteViewScreen(note: note, startInEditMode: false)),
                        );
                        if (result == true || result == 'deleted') _loadNotes();
                      },
                      onDelete: () => _deleteNote(note),
                      onTogglePin: () => _togglePin(note),
                      onMove: () => _moveNote(note),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_alt_outlined, size: 72, color: AppColors.goldMuted),
          const SizedBox(height: 16),
          const Text('No notes here yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Tap + to write your first note', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onMove;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onTogglePin,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = note.title.trim().isEmpty ? 'Untitled' : note.title;
    final preview = note.content.trim().replaceAll('\n', ' ');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      onTap: onTap,
      borderColor: note.isPinned ? AppColors.gold.withOpacity(0.5) : AppColors.glassBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.isPinned) ...[
                      const Icon(Icons.push_pin, size: 14, color: AppColors.gold),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  preview.isEmpty ? 'No content' : preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 7),
                Text(
                  DateFormat('MMM d, yyyy · h:mm a').format(note.updatedAt),
                  style: const TextStyle(color: AppColors.textFaint, fontSize: 11),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            color: AppColors.bgTop,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.glassBorder)),
            onSelected: (value) {
              switch (value) {
                case 'pin':
                  onTogglePin();
                  break;
                case 'move':
                  onMove();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 18, color: AppColors.gold),
                    const SizedBox(width: 10),
                    Text(note.isPinned ? 'Unpin' : 'Pin to top', style: const TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'move',
                child: Row(
                  children: [
                    Icon(Icons.drive_file_move_outlined, size: 18, color: AppColors.gold),
                    SizedBox(width: 10),
                    Text('Move to folder', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Text('Delete', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
