import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  bool isValidTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {
        isValidTitle = _titleController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColor.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Task",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Title Field
            const Text(
              "Title",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextField(
              controller: _titleController,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: "Enter task title",
                hintStyle: TextStyle(color: Colors.grey),
                counterText: "",
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Detail Field
            const Text(
              "Detail",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextField(
              controller: _detailController,
              maxLength: 500,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: "Enter task details (optional)",
                hintStyle: TextStyle(color: Colors.grey),
                counterText: "",
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
              ),
            ),

            const Spacer(),

            // ADD Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isValidTitle
                    ? () async {
                        final newTask = TaskModel(
                          title: _titleController.text.trim(),
                          description: _detailController.text.trim(),
                          status: "pendiente",
                        );

                        await taskProvider.createTask(newTask);

                        if (mounted) Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValidTitle
                      ? Colors.deepPurple
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "ADD",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
