import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  String folderId;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
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
}
