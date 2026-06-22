import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  String id;
  String title;
  String content;
  String folderId;
  DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.folderId,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'folderId': folderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPinned': isPinned,
    };
  }

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Note(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      content: (data['content'] ?? '') as String,
      folderId: (data['folderId'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: (data['isPinned'] ?? false) as bool,
    );
  }
}
