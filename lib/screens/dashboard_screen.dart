import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_service.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import '../widgets/add_task_dialog.dart';
import 'profile_screen.dart';
import 'support_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserService userService;
  final TaskService taskService;

  const DashboardScreen({
    super.key,
    required this.userService,
    required this.taskService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  int _points = 0;
  List<Task> _tasks = [];
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Personal', 'Work', 'Shopping', 'Health'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadPoints(),
        _loadTasks(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPoints() async {
    try {
      final points = await widget.userService.getPoints();
      if (mounted) {
        setState(() {
          _points = points;
        });
      }
    } catch (e) {
      debugPrint('Error loading points: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await widget.taskService.getTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _addTask(Task task) async {
    await widget.taskService.saveTask(task);
    await _loadTasks();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    if (!task.isCompleted) {
      // Show confirmation dialog
      if (!mounted) return;
      final result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(
            'Complete Task',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Did you complete this task?',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'forgot'),
              child: Text(
                'I Forgot/Didn\'t Do It',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'completed'),
              child: Text(
                'Yes, Completed!',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );

      if (result == null) return; // Dialog was dismissed

      try {
        if (result == 'completed') {
          // Mark task as completed
          final updatedTask = task.copyWith(isCompleted: true);
          await widget.taskService.updateTask(updatedTask);
          
          // Add points
          await widget.userService.updatePoints(_points + 10);
          
          // Show success message
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Task completed! +10 points!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Delete the task after a short delay
          await Future.delayed(const Duration(seconds: 2));
          await widget.taskService.deleteTask(task.id);
        } else if (result == 'forgot') {
          // Deduct points for forgetting
          await widget.userService.updatePoints(_points - 10);
          
          // Delete the task
          await widget.taskService.deleteTask(task.id);
          
          // Show message
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Task removed. -10 points',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        
        await _loadPoints();
        await _loadTasks();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating task. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Task> _getFilteredTasks() {
    if (_selectedCategory == 'All') {
      return _tasks;
    }
    return _tasks.where((task) => task.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          actions: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$_points pts',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(category),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._getFilteredTasks().map((task) => _buildTaskItem(task)),
                    ],
                  ),
                ),
              ],
            ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AddTaskDialog(
                onTaskAdded: _addTask,
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) async {
            if (index == _selectedIndex) return;
            
            if (index == 1) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userService: widget.userService),
                ),
              );
              if (result == true) {
                await _loadPoints();
              }
            } else if (index == 2) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SupportScreen(userService: widget.userService),
                ),
              );
            }
            
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.task),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite),
              label: 'Support',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          task.emoji,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(task.category),
        trailing: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _toggleTaskCompletion(task),
        ),
      ),
    );
  }
}