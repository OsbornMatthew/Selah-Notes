import 'package:hive/hive.dart';

part 'folder.g.dart';

@HiveType(typeId: 1)
class Folder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  Folder({
    required this.id,
    required this.name,
    required this.createdAt,
  });
}
