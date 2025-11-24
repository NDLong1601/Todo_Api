import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_api/components/app_button.dart';
import 'package:todo_api/components/app_text.dart';
import 'package:todo_api/components/app_textfield.dart';
import 'package:todo_api/components/app_textstyle.dart';
import 'package:todo_api/const/app_color.dart';
import 'package:todo_api/models/task_model.dart';
import 'package:todo_api/providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _detailController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _detailController.removeListener(_onTextChanged);
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  bool get _isTitleValid {
    final title = _titleController.text.trim();
    return title.isNotEmpty && title.length <= 100;
  }

  bool get _isDetailValid {
    final detail = _detailController.text;
    return detail.length <= 500;
  }

  Future<void> _onAddPressed() async {
    if (_isSubmitting) return;
    if (!_isTitleValid || !_isDetailValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please check your inputs')));
      return;
    }

    final title = _titleController.text.trim();
    final detail = _detailController.text.trim();

    final task = TaskModel(
      title: title,
      description: detail,
      status: 'pendiente',
    );

    setState(() => _isSubmitting = true);

    try {
      await context.read<TaskProvider>().createTask(task);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add task: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAddEnabled = _isTitleValid && _isDetailValid && !_isSubmitting;

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
          title: 'Add Task',
          style: AppTextStyle.semiBoldTsSize24White,
          textAlign: TextAlign.center,
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
                errorText: !_isTitleValid && _titleController.text.isNotEmpty
                    ? "Title must be 1-100 characters"
                    : null,
              ),
              const SizedBox(height: 8),
              if (!_isTitleValid && _titleController.text.trim().isNotEmpty)
                const Text(
                  'Title must be 1–100 characters',
                  style: TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 12,
                    color: Colors.red,
                  ),
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

              const SizedBox(height: 8),
              if (!_isDetailValid)
                const Text(
                  'Detail must be ≤ 500 characters',
                  style: TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),

              const SizedBox(height: 40),
              AppButton(
                label: "ADD",
                enabled: isAddEnabled,
                isLoading: _isSubmitting,
                onPressed: _onAddPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
