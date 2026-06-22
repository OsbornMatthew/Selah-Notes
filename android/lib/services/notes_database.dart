import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import '../models/folder.dart';

/// All reads/writes are scoped under users/{uid}/... so each signed-in
/// person only ever sees their own folders and notes. Firestore's offline
/// persistence (enabled in main.dart) means this also works without
/// internet — writes queue locally and sync automatically once back online.
class NotesService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('NotesService used while no user is signed in.');
    }
    return user.uid;
  }

  static CollectionReference<Map<String, dynamic>> get _foldersRef =>
      _db.collection('users').doc(_uid).collection('folders');

  static CollectionReference<Map<String, dynamic>> get _notesRef =>
      _db.collection('users').doc(_uid).collection('notes');

  // ---------------- Folders ----------------

  static Future<List<Folder>> getAllFolders() async {
    final snap = await _foldersRef.get();
    return snap.docs.map((d) => Folder.fromDoc(d)).toList();
  }

  static Stream<List<Folder>> watchFolders() {
    return _foldersRef.snapshots().map(
          (snap) => snap.docs.map((d) => Folder.fromDoc(d)).toList(),
        );
  }

  static Future<void> saveFolder(Folder folder) async {
    await _foldersRef.doc(folder.id).set(folder.toMap());
  }

  static Future<void> deleteFolder(String id) async {
    // Delete all notes within this folder first
    final notesSnap = await _notesRef.where('folderId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in notesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_foldersRef.doc(id));
    await batch.commit();
  }

  // ---------------- Notes ----------------

  static Future<List<Note>> getNotesByFolder(String folderId) async {
    final snap = await _notesRef.where('folderId', isEqualTo: folderId).get();
    return snap.docs.map((d) => Note.fromDoc(d)).toList();
  }

  static Stream<List<Note>> watchNotesByFolder(String folderId) {
    return _notesRef.where('folderId', isEqualTo: folderId).snapshots().map(
          (snap) => snap.docs.map((d) => Note.fromDoc(d)).toList(),
        );
  }

  static Future<List<Note>> getAllNotes() async {
    final snap = await _notesRef.get();
    return snap.docs.map((d) => Note.fromDoc(d)).toList();
  }

  static Future<List<Note>> searchNotes(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    // Firestore doesn't support full-text search natively, so for a
    // personal-scale notes app we fetch this user's notes and filter
    // client-side. Fine for hundreds of notes; would need Algolia/
    // a search extension if this ever needs to scale to thousands.
    final all = await getAllNotes();
    return all
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q))
        .toList();
  }

  static Future<void> saveNote(Note note) async {
    await _notesRef.doc(note.id).set(note.toMap());
  }

  static Future<void> deleteNote(String id) async {
    await _notesRef.doc(id).delete();
  }
}
