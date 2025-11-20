import 'package:flutter/material.dart';
import 'package:todo_api/const/app_color.dart';
import 'package:todo_api/screens/add_task.dart';

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ListView.separated(itemBuilder: itemBuilder, separatorBuilder: separatorBuilder, itemCount: itemCount),
          Positioned(
            right: 22,
            bottom: 89,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddTask()),
                );
              },
              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: AppColor.purple,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: Colors.white, size: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
