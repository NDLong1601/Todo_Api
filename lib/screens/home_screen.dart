import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_api/const/app_color.dart';
import 'package:todo_api/providers/task_provider.dart';
import 'package:todo_api/screens/completed_screen.dart';
import 'package:todo_api/screens/todo_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _tabs = [const TodoListScreen(), const CompletedScreen()];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().getAllTasks();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TODO APP')),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          /// Loading state:
          if (taskProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          /// Error Message state:
          if (taskProvider.errorMsg.isNotEmpty) {
            return Center(child: Text('Error: ${taskProvider.errorMsg}'));
          }

          /// Empty List
          if (taskProvider.pendingTasks.isEmpty) {
            return Center(
              child: Text('There is no task, please create your first task'),
            );
          }

          /// List Task with data
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: taskProvider.pendingTasks.length,
                  separatorBuilder: (context, index) => SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final item = taskProvider.pendingTasks[index];
                    return Container(
                      color: Colors.black12,
                      height: 50,
                      child: Text(item.title),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
    // return CupertinoPageScaffold(
    //   navigationBar: CupertinoNavigationBar(
    //     middle: Text('TODO'),
    //     backgroundColor: AppColor.purple,
    //   ),
    //   child: CupertinoTabScaffold(
    //     backgroundColor: AppColor.purple,
    //     tabBar: CupertinoTabBar(
    //       items: const [
    //         BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All'),
    //         BottomNavigationBarItem(icon: Icon(Icons.done), label: 'Completed'),
    //       ],
    //     ),
    //     tabBuilder: (BuildContext context, int index) {
    //       return _tabs[index];
    //     },
    //   ),
    // );
  }
}
