import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:todo_api/const/app_color.dart';
import 'package:todo_api/views/completed_screen.dart';
import 'package:todo_api/views/todo_list_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Widget> _tabs = [const TodoListScreen(), const CompletedScreen()];
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('TODO'),
        backgroundColor: AppColor.purple,
      ),
      child: CupertinoTabScaffold(
        backgroundColor: AppColor.purple,
        tabBar: CupertinoTabBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All'),
            BottomNavigationBarItem(icon: Icon(Icons.done), label: 'Completed'),
          ],
        ),
        tabBuilder: (BuildContext context, int index) {
          return _tabs[index];
        },
      ),
    );
  }
}
