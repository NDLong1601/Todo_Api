import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_api/components/app_text.dart';
import 'package:todo_api/components/app_textstyle.dart';
import 'package:todo_api/const/app_color.dart';
import 'package:todo_api/providers/task_provider.dart';
import 'package:todo_api/screens/add_task_screen.dart';
import 'package:todo_api/screens/completed_screen.dart';
import 'package:todo_api/screens/edit_task_screen.dart';
import 'package:todo_api/components/task_item_home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<TaskProvider>().init(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.purple1,
      appBar: AppBar(
        backgroundColor: AppColor.purple,
        title: AppText(
          title: 'TODO APP',
          style: AppTextStyle.semiBoldTsSize24White,
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.errorMsg.isNotEmpty) {
            return Center(child: Text('Error: ${taskProvider.errorMsg}'));
          }

          if (taskProvider.pendingTasks.isEmpty) {
            return const Center(
              child: Text(
                'There is no task, please create your first task',
                textAlign: TextAlign.center,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: taskProvider.pendingTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final task = taskProvider.pendingTasks[index];

                return TaskItemHome(
                  task: task,
                  onEdit: () async {
                    final confirm = await showConfirmDialog(
                      context: context,
                      title: "Confirm Edit",
                      message: "Do you want to edit this task?",
                    );

                    if (confirm && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditTaskScreen(task: task),
                        ),
                      );
                    }
                  },
                  onDelete: () async {
                    final confirm = await showConfirmDialog(
                      context: context,
                      title: "Confirm Delete",
                      message: "Are you sure you want to delete this task?",
                    );

                    if (confirm) {
                      /// Always need to check task.id is not null
                      /// because task.id is nullable -> crash the app if null
                      if (task.id == null) return;
                      taskProvider.deleteTask(task.id!);
                    }
                  },
                  onComplete: () {
                    if (task.id == null) return;
                    final taskNeedsUpdate = task.copyWith(status: 'completada');
                    taskProvider.updateTask(taskNeedsUpdate);
                  },
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.purple,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
      ),

      bottomNavigationBar: _buildBottomNavigationBarWidget(context),
    );
  }
}

Container _buildBottomNavigationBarWidget(BuildContext context) {
  return Container(
    color: AppColor.purple,
    padding: EdgeInsets.symmetric(vertical: 15),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.list, color: Colors.white),
                AppText(title: 'All', style: AppTextStyle.regularTsSize10White),
              ],
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompletedScreen()),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: Colors.white),
                AppText(
                  title: 'Completed',
                  style: AppTextStyle.regularTsSize10White,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Jost',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Jost', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(fontSize: 14)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "OK",
              style: TextStyle(
                fontSize: 14,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
