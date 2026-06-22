import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import '../models/folder.dart';

class NotesService {
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

  // ── Settings (pattern, etc.) ──────────────────────────────────────────────
  static DocumentReference<Map<String, dynamic>> get _settingsRef =>
      _db.collection('users').doc(_uid);

  static Future<void> saveArchivePattern(String pattern) async {
    await _settingsRef.set({'archivePattern': pattern}, SetOptions(merge: true));
  }

  static Future<String?> getArchivePattern() async {
    final doc = await _settingsRef.get();
    return doc.data()?['archivePattern'] as String?;
  }

  // ── Folders ───────────────────────────────────────────────────────────────
  static Future<List<Folder>> getAllFolders() async {
    final snap = await _foldersRef.get();
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
    // Fetch ALL notes in the folder, then filter in-memory.
    // Firestore equality filters exclude docs where the field is missing,
    // so old notes without 'isArchived' would be invisible if we filter in the query.
    final snap = await _notesRef
        .where('folderId', isEqualTo: folderId)
        .get();
    return snap.docs
        .map((d) => Note.fromDoc(d))
        .where((n) => !n.isDeleted && !n.isArchived)
        .toList();
  }

  static Future<List<Note>> getAllNotes() async {
    // Same reason — fetch all, filter in-memory so old notes are included.
    final snap = await _notesRef.get();
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
    final snap = await _notesRef.get();
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
    final snap = await _notesRef.get();
    final all = snap.docs.map((d) => Note.fromDoc(d)).toList();
    // Auto-purge expired items (>30 days)
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
