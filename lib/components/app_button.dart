import 'package:flutter/material.dart';
import 'package:todo_api/components/app_textstyle.dart';
import 'package:todo_api/const/app_color.dart';

class AppButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.purple,
          disabledBackgroundColor: AppColor.purple.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: AppTextStyle.semiBoldTsSize20White.copyWith(
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
