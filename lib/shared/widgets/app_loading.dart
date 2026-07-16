import 'package:flutter/material.dart';
import '../../core/design_system/app_insets.dart';

class AppLoading extends StatelessWidget {
  final String message;

  const AppLoading({
    super.key,
    this.message = 'Memuat data...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppInsets.s16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppInsets.r8,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class AppProgress extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? backgroundColor;

  const AppProgress({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: LinearProgressIndicator(
        value: value,
        color: color,
        backgroundColor: backgroundColor ?? Colors.grey.shade200,
        minHeight: 8,
      ),
    );
  }
}
