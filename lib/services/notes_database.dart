import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import '../models/folder.dart';

class NotesService {

  // In-memory cache for archive password — avoids repeated Firestore reads
  // every time the user opens the archive menu. Cleared on sign-out.
  static String? _cachedArchivePassword;
  static bool _archivePasswordLoaded = false;

  static void clearCache() {
    _cachedArchivePassword = null;
    _archivePasswordLoaded = false;
  }

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No user signed in.');
    return user.uid;
  }

  static CollectionReference<Map<String, dynamic>> get _foldersRef =>
      _db.collection('users').doc(_uid).collection('folders');

  static CollectionReference<Map<String, dynamic>> get _notesRef =>
      _db.collection('users').doc(_uid).collection('notes');

  static DocumentReference<Map<String, dynamic>> get _settingsRef =>
      _db.collection('users').doc(_uid);

  // ── Cache-first helper ────────────────────────────────────────────────────
  // Reads from local Firestore cache instantly, then quietly refreshes from
  // server in the background. This makes every list screen feel instant.
  static Future<QuerySnapshot<Map<String, dynamic>>> _getQuery(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      // Try local cache first — returns in <10 ms when offline or cached
      return await query.get(const GetOptions(source: Source.cache));
    } catch (_) {
      // Cache miss (first launch or cleared) — fall back to network
      return await query.get(const GetOptions(source: Source.server));
    }
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> _getDoc(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return await ref.get(const GetOptions(source: Source.cache));
    } catch (_) {
      return await ref.get(const GetOptions(source: Source.server));
    }
  }

  // Refresh from server in background (fire and forget)
  static void _bgRefreshQuery(Query<Map<String, dynamic>> query) {
    query.get(const GetOptions(source: Source.server)).catchError((_) {});
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  static Future<void> saveArchivePattern(String pattern) async {
    await _settingsRef.set({'archivePattern': pattern}, SetOptions(merge: true));
  }

  static Future<String?> getArchivePattern() async {
    final doc = await _getDoc(_settingsRef);
    return doc.data()?['archivePattern'] as String?;
  }

  static Future<void> saveArchivePassword(String password) async {
    await _settingsRef.set({'archivePassword': password}, SetOptions(merge: true));
    _cachedArchivePassword = password;
    _archivePasswordLoaded = true;
  }

  static Future<String?> getArchivePassword() async {
    if (_archivePasswordLoaded) return _cachedArchivePassword;
    final doc = await _getDoc(_settingsRef);
    _cachedArchivePassword = doc.data()?['archivePassword'] as String?;
    _archivePasswordLoaded = true;
    return _cachedArchivePassword;
  }

  // ── Folders ───────────────────────────────────────────────────────────────
  static Future<List<Folder>> getAllFolders() async {
    final snap = await _getQuery(_foldersRef);
    _bgRefreshQuery(_foldersRef); // refresh in background
    return snap.docs.map((d) => Folder.fromDoc(d)).toList();
  }

  static Future<void> saveFolder(Folder folder) async {
    await _foldersRef.doc(folder.id).set(folder.toMap());
  }

  static Future<void> deleteFolder(String id) async {
    final notesSnap = await _notesRef.where('folderId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in notesSnap.docs) batch.delete(doc.reference);
    batch.delete(_foldersRef.doc(id));
    await batch.commit();
  }

  // ── Notes — active ────────────────────────────────────────────────────────
  static Future<List<Note>> getNotesByFolder(String folderId) async {
    final query = _notesRef.where('folderId', isEqualTo: folderId);
    final snap = await _getQuery(query);
    _bgRefreshQuery(query);
    return snap.docs
        .map((d) => Note.fromDoc(d))
        .where((n) => !n.isDeleted && !n.isArchived)
        .toList();
  }

  static Future<List<Note>> getAllNotes() async {
    final snap = await _getQuery(_notesRef);
    _bgRefreshQuery(_notesRef);
    return snap.docs
        .map((d) => Note.fromDoc(d))
        .where((n) => !n.isDeleted && !n.isArchived)
        .toList();
  }

  static Future<List<Note>> searchNotes(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final all = await getAllNotes();
    return all.where((n) =>
        n.title.toLowerCase().contains(q) ||
        n.content.toLowerCase().contains(q)).toList();
  }

  static Future<void> saveNote(Note note) async {
    await _notesRef.doc(note.id).set(note.toMap());
  }

  // ── Archive ───────────────────────────────────────────────────────────────
  static Future<List<Note>> getArchivedNotes() async {
    final snap = await _getQuery(_notesRef);
    _bgRefreshQuery(_notesRef);
    return snap.docs
        .map((d) => Note.fromDoc(d))
        .where((n) => n.isArchived && !n.isDeleted)
        .toList();
  }

  static Future<void> archiveNote(Note note) async {
    note.isArchived = true;
    note.isPinned = false;
    await saveNote(note);
  }

  static Future<void> unarchiveNote(Note note) async {
    note.isArchived = false;
    await saveNote(note);
  }

  static Future<void> archiveNotes(List<Note> notes) async {
    final batch = _db.batch();
    for (final n in notes) {
      n.isArchived = true;
      n.isPinned = false;
      batch.set(_notesRef.doc(n.id), n.toMap());
    }
    await batch.commit();
  }

  // ── Recycle bin ───────────────────────────────────────────────────────────
  static Future<List<Note>> getDeletedNotes() async {
    final snap = await _getQuery(_notesRef);
    final all = snap.docs.map((d) => Note.fromDoc(d)).toList();
    final expired = all.where((n) => n.isExpired).toList();
    if (expired.isNotEmpty) {
      final batch = _db.batch();
      for (final n in expired) batch.delete(_notesRef.doc(n.id));
      await batch.commit();
    }
    return all.where((n) => n.isDeleted && !n.isExpired).toList();
  }

  static Future<void> softDeleteNote(Note note) async {
    note.deletedAt = DateTime.now();
    note.isArchived = false;
    await saveNote(note);
  }

  static Future<void> softDeleteNotes(List<Note> notes) async {
    final batch = _db.batch();
    final now = DateTime.now();
    for (final n in notes) {
      n.deletedAt = now;
      n.isArchived = false;
      batch.set(_notesRef.doc(n.id), n.toMap());
    }
    await batch.commit();
  }

  static Future<void> restoreNote(Note note) async {
    note.deletedAt = null;
    await saveNote(note);
  }

  static Future<void> permanentDeleteNote(String id) async {
    await _notesRef.doc(id).delete();
  }

  static Future<void> permanentDeleteNotes(List<Note> notes) async {
    final batch = _db.batch();
    for (final n in notes) batch.delete(_notesRef.doc(n.id));
    await batch.commit();
  }
}
