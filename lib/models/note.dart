
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

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
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String category;

  @HiveField(6)
  bool isPinned;

  @HiveField(7)
  List<String>? imagePaths;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.isPinned,
    this.imagePaths,
  });

  // 获取格式化的创建时间
  String get formattedCreatedAt {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);
  }

  // 获取格式化的更新时间
  String get formattedUpdatedAt {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(updatedAt);
  }

  // 复制方法，用于更新笔记
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    bool? isPinned,
    List<String>? imagePaths,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
