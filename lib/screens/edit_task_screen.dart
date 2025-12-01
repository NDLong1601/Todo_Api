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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showTaskNotFoundDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Task not found"),
        content: const Text(
          "This task no longer exists on the server.\n"
          "It may have been deleted or modified elsewhere.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _onUpdatePressed() async {
    if (_isSubmitting) return;

    final provider = context.read<TaskProvider>();

    final title = _titleController.text.trim();
    final detail = _detailController.text.trim();

    // Title required
    if (title.isEmpty) {
      _showError("Title is required.");
      return;
    }
    if (title.length > 100) {
      _showError("Title cannot exceed 100 characters.");
      return;
    }

    // Description required
    if (detail.isEmpty) {
      _showError("Description is required.");
      return;
    }
    if (detail.length > 500) {
      _showError("Description cannot exceed 500 characters.");
      return;
    }

    // No changes
    if (title == widget.task.title.trim() &&
        detail == (widget.task.description).trim()) {
      _showError("There are no changes to update.");
      return;
    }

    final updatedTask = widget.task.copyWith(title: title, description: detail);

    setState(() => _isSubmitting = true);

    try {
      await provider.updateTask(updatedTask);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      final msg = e.toString();

      if (msg.contains("Failed host lookup") ||
          msg.contains("SocketException")) {
        _showError("No internet connection. Changes saved locally.");
      } else if (msg.contains("404") ||
          msg.toLowerCase().contains("not found")) {
        _showTaskNotFoundDialog();
      } else if (msg.toLowerCase().contains("timeout")) {
        _showError("Request timed out. Please try again.");
      } else if (msg.toLowerCase().contains("hive")) {
        _showError("Local storage error. Please restart the app.");
      } else {
        _showError("Failed to update task: $msg");
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _titleController.text.trim();
    final detailText = _detailController.text.trim();

    final hasChanged =
        titleText != widget.task.title.trim() ||
        detailText != widget.task.description.trim();

    final isFormValid =
        titleText.isNotEmpty &&
        titleText.length <= 100 &&
        detailText.isNotEmpty &&
        detailText.length <= 500;

    final canSubmit = hasChanged && isFormValid && !_isSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColor.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: AppText(
          title: "Edit Task",
          style: AppTextStyle.semiBoldTsSize24White,
        ),
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
                onChanged: (_) {
                  setState(() {});
                },
                errorText: titleText.isEmpty
                    ? "Title is required"
                    : (titleText.length > 100
                          ? "Title cannot exceed 100 characters"
                          : null),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _detailController,
                label: "Detail",
                minLines: 2,
                maxLines: null,
                maxLength: 500,
                onChanged: (_) {
                  setState(() {});
                },
                errorText: detailText.isEmpty
                    ? "Description is required"
                    : (detailText.length > 500
                          ? "Description cannot exceed 500 characters"
                          : null),
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: "UPDATE",
                      enabled: canSubmit,
                      isLoading: _isSubmitting,
                      onPressed: canSubmit ? _onUpdatePressed : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: "CANCEL",
                      enabled: !_isSubmitting,
                      isLoading: false,
                      onPressed: () {
                        if (_isSubmitting) return;
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
