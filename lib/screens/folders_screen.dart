import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:uuid/uuid.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../services/notes_database.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'notes_list_screen.dart';
import 'note_view_screen.dart';

enum FolderSort { nameAsc, nameDesc, newest, oldest }

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final _uuid = const Uuid();
  final _searchController = TextEditingController();

  List<Folder> _folders = [];
  List<Note> _searchResults = [];
  FolderSort _sort = FolderSort.newest;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFolders() {
    final folders = NotesDatabase.getAllFolders();
    setState(() {
      _folders = _sortFolders(folders);
    });
  }

  List<Folder> _sortFolders(List<Folder> folders) {
    final list = [...folders];
    switch (_sort) {
      case FolderSort.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case FolderSort.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case FolderSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case FolderSort.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return list;
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchResults = NotesDatabase.searchNotes(query)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _GlassDialog(
        title: 'New Folder',
        child: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          _DialogButton(label: 'Cancel', onTap: () => Navigator.pop(context)),
          _DialogButton(
            label: 'Create',
            isPrimary: true,
            onTap: () => Navigator.pop(context, controller.text.trim()),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final folder = Folder(id: _uuid.v4(), name: name, createdAt: DateTime.now());
      await NotesDatabase.saveFolder(folder);
      _loadFolders();
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _GlassDialog(
        title: 'Delete Folder?',
        child: Text(
          'This will delete "${folder.name}" and all notes inside it.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          _DialogButton(label: 'Cancel', onTap: () => Navigator.pop(context, false)),
          _DialogButton(
            label: 'Delete',
            isDanger: true,
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotesDatabase.deleteFolder(folder.id);
      _loadFolders();
    }
  }

  int _noteCount(String folderId) => NotesDatabase.getNotesByFolder(folderId).length;

  void _showSortMenu() async {
    final selected = await showModalBottomSheet<FolderSort>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SortSheet(current: _sort),
    );
    if (selected != null) {
      setState(() {
        _sort = selected;
        _folders = _sortFolders(_folders);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Selah Notes'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onPressed: _showSortMenu,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: kToolbarHeight + 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  borderRadius: 16,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search all notes...',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: false,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isSearching ? _buildSearchResults() : _buildFolderList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isSearching
          ? null
          : FloatingActionButton.extended(
              onPressed: _createFolder,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('New Folder', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches found',
        subtitle: 'Try a different search term',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final note = _searchResults[index];
        final folder = _folders.firstWhere(
          (f) => f.id == note.folderId,
          orElse: () => Folder(id: '', name: 'Unknown', createdAt: DateTime.now()),
        );
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteViewScreen(note: note, startInEditMode: false)),
            );
            _loadFolders();
            _onSearchChanged(_searchController.text);
          },
          child: Row(
            children: [
              if (note.isPinned)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.push_pin, size: 14, color: AppColors.gold),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.trim().isEmpty ? 'Untitled' : note.title,
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'in ${folder.name}',
                      style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFolderList() {
    if (_folders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.folder_open_outlined,
        title: 'No folders yet',
        subtitle: 'Tap "New Folder" to get started',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotesListScreen(folder: folder)),
            );
            _loadFolders();
          },
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.goldMuted.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(Icons.folder_rounded, color: AppColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_noteCount(folder.id)} ${_noteCount(folder.id) == 1 ? "note" : "notes"}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
                onPressed: () => _deleteFolder(folder),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: AppColors.goldMuted),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  final FolderSort current;
  const _SortSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final options = {
      FolderSort.newest: ('Newest first', Icons.arrow_downward_rounded),
      FolderSort.oldest: ('Oldest first', Icons.arrow_upward_rounded),
      FolderSort.nameAsc: ('Name A → Z', Icons.sort_by_alpha_rounded),
      FolderSort.nameDesc: ('Name Z → A', Icons.sort_by_alpha_rounded),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GlassCard(
        blurSigma: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8, top: 4),
              child: Text('Sort folders', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final entry in options.entries)
              ListTile(
                onTap: () => Navigator.pop(context, entry.key),
                leading: Icon(entry.value.$2, color: current == entry.key ? AppColors.gold : AppColors.textSecondary),
                title: Text(
                  entry.value.$1,
                  style: TextStyle(
                    color: current == entry.key ? AppColors.gold : AppColors.textPrimary,
                    fontWeight: current == entry.key ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: current == entry.key ? const Icon(Icons.check_rounded, color: AppColors.gold) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  const _GlassDialog({required this.title, required this.child, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        blurSigma: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDanger;
  const _DialogButton({required this.label, required this.onTap, this.isPrimary = false, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : (isPrimary ? AppColors.gold : AppColors.textSecondary);
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: TextStyle(color: color, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500)),
    );
  }
}
