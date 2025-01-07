import 'package:flutter/foundation.dart';

@immutable
class User {
  final String id;
  final String fullName;
  final String email;
  final int points;
  final int age;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.age,
    this.points = 100,  
  });

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    int? points,
    int? age,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      points: points ?? this.points,
      age: age ?? this.age,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'points': points,
      'age': age,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      points: json['points'] as int? ?? 100,
      age: json['age'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.points == points &&
        other.age == age;
  }

  @override
  int get hashCode => Object.hash(id, fullName, email, points, age);
}