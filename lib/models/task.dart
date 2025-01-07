import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final String category;
  final String emoji;
  final bool isCompleted;
  final DateTime createdAt;

  Task({
    String? id,
    required this.title,
    required this.category,
    required this.emoji,
    this.isCompleted = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? category,
    String? emoji,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'emoji': emoji,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      emoji: json['emoji'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          category == other.category &&
          emoji == other.emoji &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      category.hashCode ^
      emoji.hashCode ^
      isCompleted.hashCode;
}