import 'package:cloud_firestore/cloud_firestore.dart';

class Folder {
  String id;
  String name;
  DateTime createdAt;

  Folder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Folder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Folder(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
