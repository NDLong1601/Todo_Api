import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_api/components/task_item_completed.dart';
import 'package:todo_api/components/app_text.dart';
import 'package:todo_api/components/app_textstyle.dart';
import 'package:todo_api/const/app_color.dart';
import 'package:todo_api/providers/task_provider.dart';

class CompletedScreen extends StatelessWidget {
  const CompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.purple1,
      appBar: AppBar(
        backgroundColor: AppColor.purple,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: AppText(
          title: "Completed Task",
          style: AppTextStyle.semiBoldTsSize24White,
        ),
        centerTitle: true,
      ),

      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.errorMsg.isNotEmpty) {
            return Center(child: Text("Error: ${taskProvider.errorMsg}"));
          }

          if (taskProvider.completedTasks.isEmpty) {
            return const Center(child: Text("There is no completed task"));
          }

          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: taskProvider.completedTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final task = taskProvider.completedTasks[index];

                return TaskItemCompleted(
                  task: task,
                  onReturn: () async {
                    final taskNeedsUpdate = task.copyWith(status: 'pendiente');
                    await taskProvider.updateTask(taskNeedsUpdate);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Task returned to pending"),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
