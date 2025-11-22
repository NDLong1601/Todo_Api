import 'package:flutter/material.dart';
import 'package:todo_api/components/app_textstyle.dart';

class AppText extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;
  final TextOverflow? overflow;

  const AppText({
    required this.title,
    this.style,
    this.textAlign,
    this.overflow,
    super.key,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style ?? AppTextStyle.semiBoldTsSize13Purple,
      textAlign: textAlign ?? TextAlign.center,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }
}
