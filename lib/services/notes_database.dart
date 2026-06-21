import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../models/folder.dart';
import 'firebase_sync_service.dart';

class NotesDatabase {
  static const String notesBoxName = 'notes';
  static const String foldersBoxName = 'folders';

  static Box<Note>? _notesBox;
  static Box<Folder>? _foldersBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(FolderAdapter());
    _notesBox = await Hive.openBox<Note>(notesBoxName);
    _foldersBox = await Hive.openBox<Folder>(foldersBoxName);
  }

  static Box<Note> get notesBox => _notesBox!;
  static Box<Folder> get foldersBox => _foldersBox!;

  // ─── NOTES ──────────────────────────────────────────────────

  static List<Note> getAllNotes() => notesBox.values.toList();

  static List<Note> getNotesByFolder(String folderId) =>
      notesBox.values.where((n) => n.folderId == folderId).toList();

  static List<Note> searchNotes(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return notesBox.values
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q))
        .toList();
  }

  static Future<void> saveNote(Note note) async {
    await notesBox.put(note.id, note);
    // Sync to Firebase in background (won't block UI)
    FirebaseSyncService.uploadNote(note).catchError((_) {});
  }

  static Future<void> deleteNote(String id) async {
    await notesBox.delete(id);
    FirebaseSyncService.deleteNote(id).catchError((_) {});
  }

  // ─── FOLDERS ────────────────────────────────────────────────

  static List<Folder> getAllFolders() => foldersBox.values.toList();

  static Future<void> saveFolder(Folder folder) async {
    await foldersBox.put(folder.id, folder);
    FirebaseSyncService.uploadFolder(folder).catchError((_) {});
  }

  static Future<void> deleteFolder(String id) async {
    // Also delete all notes within this folder
    final notesToDelete =
        notesBox.values.where((n) => n.folderId == id).map((n) => n.id).toList();
    for (final noteId in notesToDelete) {
      await notesBox.delete(noteId);
    }
    await foldersBox.delete(id);
    FirebaseSyncService.deleteFolder(id).catchError((_) {});
  }
}
