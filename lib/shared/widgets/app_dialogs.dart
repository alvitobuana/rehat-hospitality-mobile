import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_insets.dart';
import 'app_buttons.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Konfirmasi',
    this.cancelText = 'Batal',
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppInsets.r12)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    );
  }
}

class AppDeleteDialog extends StatelessWidget {
  final String title;
  final String content;
  final String deleteText;
  final String cancelText;
  final VoidCallback onDelete;

  const AppDeleteDialog({
    super.key,
    required this.title,
    required this.content,
    this.deleteText = 'Hapus',
    this.cancelText = 'Batal',
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: TextStyle(color: AppColors.danger(context))),
      content: Text(content),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppInsets.r12)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
        AppDangerButton(
          text: deleteText,
          width: 100,
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
        ),
      ],
    );
  }
}

class AppLoadingDialog extends StatelessWidget {
  final String message;

  const AppLoadingDialog({
    super.key,
    this.message = 'Memuat...',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppInsets.r12)),
      child: Padding(
        padding: AppInsets.dialog,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: AppInsets.s20),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class AppErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const AppErrorDialog({
    super.key,
    this.title = 'Terjadi Kesalahan',
    required this.message,
    this.buttonText = 'Mengerti',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger(context)),
          const SizedBox(width: AppInsets.s8),
          Text(title),
        ],
      ),
      content: Text(message),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppInsets.r12)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

class AppSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const AppSuccessDialog({
    super.key,
    this.title = 'Berhasil',
    required this.message,
    this.buttonText = 'Selesai',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: AppColors.success(context)),
          const SizedBox(width: AppInsets.s8),
          Text(title),
        ],
      ),
      content: Text(message),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppInsets.r12)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(buttonText),
        ),
      ],
    );
  }
}
