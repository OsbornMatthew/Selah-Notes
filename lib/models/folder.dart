import 'package:cloud_firestore/cloud_firestore.dart';

class Folder {
  String id;
  String name;
  DateTime createdAt;
  DateTime? deletedAt; // non-null = soft-deleted (in recycle bin)
  bool isPinned;
  bool isArchived;

  Folder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.deletedAt,
    this.isPinned = false,
    this.isArchived = false,
  });

  bool get isDeleted => deletedAt != null;

  bool get isExpired {
    if (deletedAt == null) return false;
    return DateTime.now().difference(deletedAt!).inDays >= 30;
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'createdAt': Timestamp.fromDate(createdAt),
    'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    'isPinned': isPinned,
    'isArchived': isArchived,
  };

  factory Folder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Folder(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedAt: (d['deletedAt'] as Timestamp?)?.toDate(),
      isPinned: (d['isPinned'] ?? false) as bool,
      isArchived: (d['isArchived'] ?? false) as bool,
    );
  }
}
