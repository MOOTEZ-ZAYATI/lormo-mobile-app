import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/notification_service.dart';

class UserService {
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  static const String _userKey = 'user_data';
  static const String _firstLaunchKey = 'first_launch';
  static const int _initialPoints = 100;

  UserService(this._prefs, this._notificationService);

  Future<bool> isFirstLaunch() async {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_firstLaunchKey, false);
  }

  Future<void> saveUser(User user) async {
    try {
      if (await getUser() == null) {
        user = user.copyWith(points: _initialPoints);
      }
      final userJson = jsonEncode({
        'id': user.id,
        'fullName': user.fullName,
        'email': user.email,
        'age': user.age,
        'points': user.points,
      });
      await _prefs.setString(_userKey, userJson);
      await _notificationService.initialize();
    } catch (e) {
      debugPrint('Error saving user: $e');
      throw Exception('Failed to save user data');
    }
  }

  Future<User?> getUser() async {
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson == null) return null;
      
      final Map<String, dynamic> userData = jsonDecode(userJson);
      if (!userData.containsKey('id') || !userData.containsKey('fullName') || 
          !userData.containsKey('email') || !userData.containsKey('age')) {
        return null;
      }
      
      return User.fromJson(userData);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<int> getPoints() async {
    final user = await getUser();
    return user?.points ?? _initialPoints;
  }

  Future<void> updatePoints(int newPoints) async {
    try {
      final user = await getUser();
      if (user == null) return;

      if (newPoints <= 0) {
        // Game Over
        await _notificationService.createGameOverNotification();
        // Clear user data
        await _prefs.clear();
        return;
      }

      final updatedUser = user.copyWith(points: newPoints);
      await saveUser(updatedUser);
    } catch (e) {
      debugPrint('Error updating points: $e');
      throw Exception('Failed to update points');
    }
  }

  Future<void> updateUserProfile({
    required String fullName,
    required String email,
    required int age,
  }) async {
    final currentUser = await getUser();
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        fullName: fullName,
        email: email,
        age: age,
      );
      await saveUser(updatedUser);
    }
  }

  Future<void> clearUserData() async {
    await _prefs.remove(_userKey);
    await _prefs.remove(_firstLaunchKey);
  }
}
