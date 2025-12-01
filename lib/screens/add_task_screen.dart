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

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _onAddPressed() async {
    final provider = context.read<TaskProvider>();

    final newTask = TaskModel(
      id: null,
      title: provider.addTitle,
      description: provider.addDetail,
      status: "pendiente",
    );

    try {
      await provider.createTask(newTask);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add task: $e")));
    } finally {
      _titleController.clear();
      _detailController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: "Add Task",
          style: AppTextStyle.semiBoldTsSize24White,
        ),
        centerTitle: true,
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Consumer<TaskProvider>(
            builder: (context, provider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _titleController,
                    label: "Title",
                    maxLength: 100,
                    onChanged: provider.setAddTitle,
                  ),

                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _detailController,
                    label: "Detail",
                    minLines: 2,
                    maxLines: null,
                    maxLength: 500,
                    onChanged: provider.setAddDetail,
                  ),

                  const SizedBox(height: 40),
                  AppButton(
                    label: "ADD",
                    enabled: provider.isAddValid && !provider.isAdding,
                    isLoading: provider.isAdding,
                    onPressed: provider.isAddValid ? _onAddPressed : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
