import 'package:flutter/material.dart';
import 'package:todo_api/const/app_color.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLength;
  final int minLines;
  final int? maxLines;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final bool isRequired;
  final String? errorText;
  final Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.maxLength = 200,
    this.minLines = 1,
    this.maxLines,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.isRequired = false,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Jost',
          fontSize: 14,
          color: AppColor.grey,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColor.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColor.purple, width: 2),
        ),
        errorText: errorText,
      ),
    );
  }
}
