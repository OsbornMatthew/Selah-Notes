import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/note.dart';
import '../models/folder.dart';
import 'auth_service.dart';
import 'notes_database.dart';

class FirebaseSyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _foldersRef(String uid) =>
      _db.collection('users').doc(uid).collection('folders');

  static CollectionReference<Map<String, dynamic>> _notesRef(String uid) =>
      _db.collection('users').doc(uid).collection('notes');

  /// Check if device is online
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ─── FOLDERS ────────────────────────────────────────────────

  static Future<void> uploadFolder(Folder folder) async {
    final uid = AuthService.uid;
    if (uid == null) return;
    await _foldersRef(uid).doc(folder.id).set({
      'id': folder.id,
      'name': folder.name,
      'createdAt': folder.createdAt.toIso8601String(),
    });
  }

  static Future<void> deleteFolder(String folderId) async {
    final uid = AuthService.uid;
    if (uid == null) return;
    await _foldersRef(uid).doc(folderId).delete();
    // also delete child notes from Firestore
    final notes = await _notesRef(uid)
        .where('folderId', isEqualTo: folderId)
        .get();
    for (final doc in notes.docs) {
      await doc.reference.delete();
    }
  }

  // ─── NOTES ──────────────────────────────────────────────────

  static Future<void> uploadNote(Note note) async {
    final uid = AuthService.uid;
    if (uid == null) return;
    await _notesRef(uid).doc(note.id).set({
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'folderId': note.folderId,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
      'isPinned': note.isPinned,
    });
  }

  static Future<void> deleteNote(String noteId) async {
    final uid = AuthService.uid;
    if (uid == null) return;
    await _notesRef(uid).doc(noteId).delete();
  }

  // ─── FULL SYNC (pull from Firestore → Hive) ─────────────────

  static Future<void> syncFromFirestore() async {
    final uid = AuthService.uid;
    if (uid == null) return;
    if (!await isOnline()) return;

    // Sync folders
    final folderSnap = await _foldersRef(uid).get();
    for (final doc in folderSnap.docs) {
      final data = doc.data();
      final folder = Folder(
        id: data['id'],
        name: data['name'],
        createdAt: DateTime.parse(data['createdAt']),
      );
      await NotesDatabase.saveFolder(folder);
    }

    // Sync notes
    final noteSnap = await _notesRef(uid).get();
    for (final doc in noteSnap.docs) {
      final data = doc.data();
      final note = Note(
        id: data['id'],
        title: data['title'],
        content: data['content'],
        folderId: data['folderId'],
        createdAt: DateTime.parse(data['createdAt']),
        updatedAt: DateTime.parse(data['updatedAt']),
        isPinned: data['isPinned'] ?? false,
      );
      await NotesDatabase.saveNote(note);
    }
  }

  // ─── FULL PUSH (Hive → Firestore) ───────────────────────────

  static Future<void> pushLocalToFirestore() async {
    final uid = AuthService.uid;
    if (uid == null) return;
    if (!await isOnline()) return;

    for (final folder in NotesDatabase.getAllFolders()) {
      await uploadFolder(folder);
    }
    for (final note in NotesDatabase.getAllNotes()) {
      await uploadNote(note);
    }
  }
}
