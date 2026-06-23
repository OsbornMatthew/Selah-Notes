import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../services/notes_database.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dialogs.dart';
import 'notes_list_screen.dart';
import 'note_view_screen.dart';
import 'archive_screen.dart';
import 'recycle_bin_screen.dart';
import 'pattern_lock_screen.dart';

enum FolderSort { nameAsc, nameDesc, newest, oldest }
enum ViewMode { list, grid, details }

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final _uuid = const Uuid();
  final _searchController = TextEditingController();

  List<Folder> _folders = [];
  Map<String, int> _noteCounts = {};
  List<Note> _searchResults = [];
  FolderSort _sort = FolderSort.newest;
  ViewMode _view = ViewMode.list;
  bool _isSearching = false;
  bool _isLoading = true;
  final Set<String> _selected = {};
  bool _isSelecting = false;

  @override
  void initState() { super.initState(); _loadFolders(); }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    final folders = await NotesService.getAllFolders();
    final allNotes = await NotesService.getAllNotes();
    final counts = <String, int>{};
    for (final n in allNotes) counts[n.folderId] = (counts[n.folderId] ?? 0) + 1;
    if (!mounted) return;
    setState(() { _folders = _sortFolders(folders); _noteCounts = counts; _isLoading = false; });
  }

  List<Folder> _sortFolders(List<Folder> f) {
    final list = [...f];
    switch (_sort) {
      case FolderSort.nameAsc: list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); break;
      case FolderSort.nameDesc: list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase())); break;
      case FolderSort.newest: list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); break;
      case FolderSort.oldest: list.sort((a, b) => a.createdAt.compareTo(b.createdAt)); break;
    }
    return list;
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) _selected.remove(id); else _selected.add(id);
      _isSelecting = _selected.isNotEmpty;
    });
  }

  void _clearSelection() => setState(() { _selected.clear(); _isSelecting = false; });

  Future<void> _deleteSelected() async {
    final confirm = await showConfirmDialog(context,
      title: 'Delete Folders?',
      message: 'Delete ${_selected.length} folder(s) and all notes inside them?',
      confirmLabel: 'Delete', isDanger: true);
    if (confirm != true) return;
    for (final id in _selected) await NotesService.deleteFolder(id);
    _clearSelection(); _loadFolders();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _isSearching = false; _searchResults = []; }); return;
    }
    setState(() => _isSearching = true);
    final results = await NotesService.searchNotes(query);
    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(context: context,
      builder: (ctx) => GlassDialog(
        title: 'New Folder',
        child: TextField(controller: ctrl, autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Folder name')),
        actions: [
          GlassDialogButton(label: 'Cancel', onTap: () => Navigator.pop(ctx)),
          GlassDialogButton(label: 'Create', isPrimary: true, onTap: () => Navigator.pop(ctx, ctrl.text.trim())),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final f = Folder(id: _uuid.v4(), name: name, createdAt: DateTime.now());
      await NotesService.saveFolder(f); _loadFolders();
    }
  }

  Future<void> _openArchive() async {
    final savedPassword = await NotesService.getArchivePassword();
    if (savedPassword == null) {
      // First time: prompt to set a password
      final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const PatternLockScreen(mode: PatternLockMode.setup)));
      if (result != true) return;
    } else {
      // Verify password
      final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const PatternLockScreen(mode: PatternLockMode.verify)));
      if (result != true) return;
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchiveScreen()));
  }

  Future<void> _changeArchivePassword() async {
    final savedPassword = await NotesService.getArchivePassword();
    if (savedPassword == null) {
      // No password set yet, just set one directly
      await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const PatternLockScreen(mode: PatternLockMode.setup)));
      return;
    }
    await Navigator.push(context,
      MaterialPageRoute(builder: (_) => const PatternLockScreen(mode: PatternLockMode.change)));
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showConfirmDialog(context,
      title: 'Log out?',
      message: "Your notes are safely saved to your account.",
      confirmLabel: 'Log out', isDanger: true);
    if (confirm == true) await AuthService.signOut();
  }

  void _showSortMenu() async {
    final sel = await showModalBottomSheet<FolderSort>(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => buildSortSheet<FolderSort>(ctx, title: 'Sort folders', current: _sort, options: {
        FolderSort.newest: ('Newest first', Icons.arrow_downward_rounded),
        FolderSort.oldest: ('Oldest first', Icons.arrow_upward_rounded),
        FolderSort.nameAsc: ('Name A → Z', Icons.sort_by_alpha_rounded),
        FolderSort.nameDesc: ('Name Z → A', Icons.sort_by_alpha_rounded),
      }),
    );
    if (sel != null) setState(() { _sort = sel; _folders = _sortFolders(_folders); });
  }

  Widget _buildAccountIcon() {
    // Inverted: filled gold circle with a dark icon, instead of a gold icon
    // on a transparent background.
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: Colors.black, size: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '';
    return Scaffold(
      extendBodyBehindAppBar: true, backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSelecting ? Text('${_selected.length} selected') : const Text('Selah Notes'),
        centerTitle: false,
        leading: _isSelecting ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection) : null,
        actions: _isSelecting ? [
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), onPressed: _deleteSelected),
          const SizedBox(width: 4),
        ] : [
          IconButton(icon: const Icon(Icons.sort_rounded), onPressed: _showSortMenu),
          IconButton(
            icon: Icon(_view == ViewMode.list ? Icons.grid_view_rounded : _view == ViewMode.grid ? Icons.view_list_rounded : Icons.view_agenda_rounded),
            onPressed: () => setState(() => _view = ViewMode.values[(_view.index + 1) % 3]),
          ),
          PopupMenuButton<String>(
            icon: _buildAccountIcon(),
            color: AppColors.bgTop, surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.glassBorder)),
            onSelected: (v) {
              if (v == 'archive') _openArchive();
              if (v == 'change_password') _changeArchivePassword();
              if (v == 'bin') Navigator.push(context, MaterialPageRoute(builder: (_) => const RecycleBinScreen()));
              if (v == 'logout') _confirmSignOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'archive', child: Row(children: [Icon(Icons.archive_outlined, size: 18, color: AppColors.gold), SizedBox(width: 10), Text('Archive', style: TextStyle(color: AppColors.textPrimary))])),
              const PopupMenuItem(value: 'change_password', child: Row(children: [Icon(Icons.password_rounded, size: 18, color: AppColors.gold), SizedBox(width: 10), Text('Change Archive Password', style: TextStyle(color: AppColors.textPrimary))])),
              const PopupMenuItem(value: 'bin', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.gold), SizedBox(width: 10), Text('Recycle Bin', style: TextStyle(color: AppColors.textPrimary))])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout_rounded, size: 18, color: AppColors.danger), SizedBox(width: 10), Text('Log out', style: TextStyle(color: AppColors.danger))])),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          top: false,
          child: Column(children: [
            SizedBox(height: kToolbarHeight + 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 6), borderRadius: 16,
                child: TextField(
                  controller: _searchController, onChanged: _onSearchChanged,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search folders and notes...', border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
                    suffixIcon: _isSearching ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: () { _searchController.clear(); _onSearchChanged(''); }) : null,
                    filled: false, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : (_isSearching ? _buildSearchResults() : _buildFolderView())),
          ]),
        ),
      ),
      floatingActionButton: (_isSearching || _isSelecting) ? null :
        FloatingActionButton.extended(onPressed: _createFolder,
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text('New Folder', style: TextStyle(fontWeight: FontWeight.w600))),
    );
  }

  Widget _buildFolderView() {
    if (_folders.isEmpty) return _buildEmpty(Icons.folder_open_outlined, 'No folders yet', 'Tap "New Folder" to get started');
    return RefreshIndicator(
      onRefresh: _loadFolders, color: AppColors.gold, backgroundColor: AppColors.bgTop,
      child: _view == ViewMode.grid ? _buildGrid() : _buildList(),
    );
  }

  Widget _buildList() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
    itemCount: _folders.length,
    itemBuilder: (ctx, i) {
      final f = _folders[i];
      final sel = _selected.contains(f.id);
      final count = _noteCounts[f.id] ?? 0;
      final showDetails = _view == ViewMode.details;
      return GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderColor: sel ? AppColors.gold : AppColors.glassBorder,
        onLongPress: () => _toggleSelect(f.id),
        onTap: () {
          if (_isSelecting) { _toggleSelect(f.id); return; }
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => NotesListScreen(folder: f))).then((_) => _loadFolders());
        },
        child: Row(children: [
          if (_isSelecting)
            Padding(padding: const EdgeInsets.only(right: 12),
              child: Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: sel ? AppColors.gold : AppColors.textSecondary)),
          Container(width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.goldMuted.withOpacity(0.18),
              borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.glassBorder)),
            child: const Icon(Icons.folder_rounded, color: AppColors.gold)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 3),
            Text('$count ${count == 1 ? "note" : "notes"}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            if (showDetails) ...[
              const SizedBox(height: 2),
              Text('Created ${f.createdAt.day}/${f.createdAt.month}/${f.createdAt.year}',
                style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
            ],
          ])),
          if (!_isSelecting)
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
              onPressed: () async {
                final ok = await showConfirmDialog(context,
                  title: 'Delete Folder?', message: 'This will delete "${f.name}" and all notes inside.',
                  confirmLabel: 'Delete', isDanger: true);
                if (ok == true) { await NotesService.deleteFolder(f.id); _loadFolders(); }
              }),
        ]),
      );
    },
  );

  Widget _buildGrid() => GridView.builder(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1),
    itemCount: _folders.length,
    itemBuilder: (ctx, i) {
      final f = _folders[i];
      final sel = _selected.contains(f.id);
      final count = _noteCounts[f.id] ?? 0;
      return GlassCard(
        borderColor: sel ? AppColors.gold : AppColors.glassBorder,
        padding: const EdgeInsets.all(14),
        onTap: () {
          if (_isSelecting) { _toggleSelect(f.id); return; }
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => NotesListScreen(folder: f))).then((_) => _loadFolders());
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (_isSelecting) Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: sel ? AppColors.gold : AppColors.textSecondary, size: 18)
            else const Icon(Icons.folder_rounded, color: AppColors.gold, size: 28),
            const Spacer(),
            Text('$count', style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
          ]),
          const Spacer(),
          Text(f.name, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 3),
          Text('${count} ${count == 1 ? "note" : "notes"}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
        ]),
      );
    },
  );

  Widget _buildSearchResults() {
    // Search folders
    final folderQuery = _searchController.text.trim().toLowerCase();
    final matchedFolders = _folders.where((f) => f.name.toLowerCase().contains(folderQuery)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (matchedFolders.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text('Folders', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
          ...matchedFolders.map((f) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotesListScreen(folder: f))).then((_) => _loadFolders()),
            child: Row(children: [
              const Icon(Icons.folder_rounded, color: AppColors.gold, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(f.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
            ]),
          )),
          const SizedBox(height: 8),
        ],
        if (_searchResults.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text('Notes', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
          ..._searchResults.map((n) {
            final folder = _folders.firstWhere((f) => f.id == n.folderId,
              orElse: () => Folder(id: '', name: 'Unknown', createdAt: DateTime.now()));
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteViewScreen(note: n, startInEditMode: false))).then((_) { _loadFolders(); _onSearchChanged(_searchController.text); }),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.title.isEmpty ? 'Untitled' : n.title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('in ${folder.name}', style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5)),
              ]),
            );
          }),
        ],
        if (matchedFolders.isEmpty && _searchResults.isEmpty)
          _buildEmpty(Icons.search_off_rounded, 'No results', 'Try a different search term'),
      ],
    );
  }

  Widget _buildEmpty(IconData icon, String title, String sub) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 72, color: AppColors.goldMuted),
    const SizedBox(height: 16),
    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Text(sub, style: const TextStyle(color: AppColors.textSecondary)),
  ]));
}
