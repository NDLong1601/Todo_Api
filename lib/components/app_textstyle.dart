import 'package:flutter/material.dart';
import 'package:todo_api/const/app_color.dart';

class AppTextStyle {
  static TextStyle semiBoldTsSize24White = TextStyle(
    fontFamily: 'Jost',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColor.white,
  );

  static TextStyle semiBoldTsSize13Purple = TextStyle(
    fontFamily: 'Jost',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColor.purple,
  );

  static TextStyle regularTsSize10Black = TextStyle(
    fontFamily: 'Jost',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColor.black,
  );

}