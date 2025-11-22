import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_api/components/app_text.dart';
import 'package:todo_api/components/app_textstyle.dart';
import 'package:todo_api/const/app_color.dart';
import 'package:todo_api/providers/task_provider.dart';
import 'package:todo_api/screens/add_task_screen.dart';
import 'package:todo_api/screens/edit_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VoidCallback onEdit;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().getAllTasks();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColor.purple1,
      appBar: AppBar(
        title: AppText(
          title: 'TODO APP',
          style: AppTextStyle.semiBoldTsSize24White,
        ),
        backgroundColor: AppColor.purple,
      ),
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
          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: screenHeight * (22 / 896)),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: taskProvider.pendingTasks.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 15),
                        itemBuilder: (context, index) {
                          final item = taskProvider.pendingTasks[index];
                          return Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * (7 / 414),
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColor.white,
                            ),
                            height: screenHeight * (82 / 896),
                            width: screenWidth * (400 / 414),
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * (12 / 896),
                              horizontal: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: AppText(
                                          title: item.title ?? '...',
                                          maxLines: 1,
                                          // overflow: TextOverflow.ellipsis,
                                          style: AppTextStyle
                                              .semiBoldTsSize13Purple,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Flexible(
                                        child: AppText(
                                          title: item.description ?? '...',
                                          maxLines: 1,
                                          // overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTextStyle.regularTsSize10Black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Icon(Icons.edit, color: AppColor.purple),
                                Icon(Icons.delete, color: AppColor.purple),
                                Icon(
                                  Icons.check_circle_outline,
                                  color: AppColor.purple,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
            backgroundColor: AppColor.purple,
          ),
          BottomNavigationBarItem(icon: Icon(Icons.done), label: 'Completed'),
        ],
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }
}
