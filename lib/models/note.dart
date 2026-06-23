import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  String id;
  String title;
  String content;       // Quill Delta JSON string
  String folderId;
  DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;
  bool isArchived;
  DateTime? deletedAt;          // non-null = in recycle bin
  bool deletedWithFolder;       // true = deleted as part of a folder deletion

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.folderId,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.deletedAt,
    this.deletedWithFolder = false,
  });

  bool get isDeleted => deletedAt != null;

  bool get isExpired {
    if (deletedAt == null) return false;
    return DateTime.now().difference(deletedAt!).inDays >= 30;
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'content': content,
    'folderId': folderId,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'isPinned': isPinned,
    'isArchived': isArchived,
    'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    'deletedWithFolder': deletedWithFolder,
  };

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Note(
      id: doc.id,
      title: (d['title'] ?? '') as String,
      content: (d['content'] ?? '') as String,
      folderId: (d['folderId'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: (d['isPinned'] ?? false) as bool,
      isArchived: (d['isArchived'] ?? false) as bool,
      deletedAt: (d['deletedAt'] as Timestamp?)?.toDate(),
      deletedWithFolder: (d['deletedWithFolder'] ?? false) as bool,
    );
  }

  Note copyWith({
    String? title, String? content, String? folderId,
    bool? isPinned, bool? isArchived, DateTime? deletedAt,
    bool clearDeletedAt = false, bool? deletedWithFolder,
  }) => Note(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    folderId: folderId ?? this.folderId,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    deletedWithFolder: deletedWithFolder ?? this.deletedWithFolder,
  );
}
