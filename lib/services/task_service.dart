import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/user_service.dart';

class TaskService {
  static const String _tasksKey = 'tasks';
  final SharedPreferences _prefs;
  final UserService _userService;
  static const int _pointsForCompletion = 10;
  static const int _pointsPenalty = 15;

  TaskService({required SharedPreferences prefs, required UserService userService})
      : _prefs = prefs,
        _userService = userService;

  Future<List<Task>> getTasks() async {
    final tasksJson = _prefs.getStringList(_tasksKey) ?? [];
    return tasksJson
        .map((json) => Task.fromJson(jsonDecode(json)))
        .toList()
        ..sort((a, b) => a.isCompleted ? 1 : -1);
  }

  Future<void> saveTask(Task task) async {
    final tasks = await getTasks();
    tasks.add(task);
    await _saveTasks(tasks);
  }

  Future<void> updateTask(Task updatedTask) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      final oldTask = tasks[index];
      tasks[index] = updatedTask;
      await _saveTasks(tasks);
      
      // Update points based on task completion status
      if (!oldTask.isCompleted && updatedTask.isCompleted) {
        final currentPoints = await _userService.getPoints();
        await _userService.updatePoints(currentPoints + _pointsForCompletion);
      } else if (oldTask.isCompleted && !updatedTask.isCompleted) {
        final currentPoints = await _userService.getPoints();
        await _userService.updatePoints(currentPoints - _pointsPenalty);
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await getTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks(tasks);
  }

  Future<void> _saveTasks(List<Task> tasks) async {
    final tasksJson = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await _prefs.setStringList(_tasksKey, tasksJson);
  }
}