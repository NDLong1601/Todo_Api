import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_api/components/app_button.dart';
import 'package:todo_api/components/app_text.dart';
import 'package:todo_api/components/app_textfield.dart';
import 'package:todo_api/components/app_textstyle.dart';
import 'package:todo_api/const/app_color.dart';
import 'package:todo_api/models/task_model.dart';
import 'package:todo_api/providers/task_provider.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _detailController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.task.title);
    _detailController = TextEditingController(text: widget.task.description);

    _titleController.addListener(() => setState(() {}));
    _detailController.addListener(() => setState(() {}));
  }

  bool get _isTitleValid =>
      _titleController.text.trim().isNotEmpty &&
      _titleController.text.trim().length <= 100;

  bool get _isDetailValid => _detailController.text.length <= 500;

  Future<void> _onUpdateTask() async {
    if (_isSubmitting) return;

    if (!_isTitleValid || !_isDetailValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please check your inputs")));
      return;
    }

    setState(() => _isSubmitting = true);

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _detailController.text.trim(),
    );

    try {
      await context.read<TaskProvider>().updateTask(updatedTask);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update task: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdateEnabled = _isTitleValid && _isDetailValid && !_isSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColor.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          title: "Edit Task",
          style: AppTextStyle.semiBoldTsSize24White,
        ),
        centerTitle: true,
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _titleController,
                label: "Title",
                maxLength: 100,
                errorText:
                    !_isTitleValid && _titleController.text.trim().isNotEmpty
                    ? "Title must be 1–100 characters"
                    : null,
              ),

              const SizedBox(height: 24),
              AppTextField(
                controller: _detailController,
                label: "Detail",
                minLines: 2,
                maxLines: null,
                maxLength: 500,
                keyboardType: TextInputType.multiline,
                errorText: !_isDetailValid
                    ? "Detail must be <= 500 characters"
                    : null,
              ),

              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: "Update",
                      enabled: isUpdateEnabled,
                      isLoading: _isSubmitting,
                      onPressed: _onUpdateTask,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: "Cancel",
                      enabled: true,
                      isLoading: false,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
