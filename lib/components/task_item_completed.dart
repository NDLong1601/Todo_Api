import 'package:flutter/material.dart';
import 'package:todo_api/components/app_text.dart';
import 'package:todo_api/components/app_textstyle.dart';
import 'package:todo_api/const/app_color.dart';
import 'package:todo_api/models/task_model.dart';

class TaskItemCompleted extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onReturn;

  const TaskItemCompleted({
    super.key,
    required this.task,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // -------- LEFT: TITLE + SUBTITLE --------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  title: task.title.toUpperCase() ?? '...',
                  style: AppTextStyle.semiBoldTsSize13Purple,
                ),
                const SizedBox(height: 4),
                AppText(
                  title: task.description ?? '...',
                  style: AppTextStyle.regularTsSize10Black,
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.undo, size: 22, color: AppColor.purple),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: onReturn,
          ),
        ],
      ),
    );
  }
}
