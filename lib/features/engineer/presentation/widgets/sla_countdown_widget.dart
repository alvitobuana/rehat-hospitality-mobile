import 'dart:async';
import 'package:flutter/material.dart';

class SlaCountdownWidget extends StatefulWidget {
  final String status;
  final String? claimDeadline;
  final String? completionDeadline;
  final String? createdAt;
  final bool compact;

  const SlaCountdownWidget({
    super.key,
    required this.status,
    this.claimDeadline,
    this.completionDeadline,
    this.createdAt,
    this.compact = false,
  });

  @override
  State<SlaCountdownWidget> createState() => _SlaCountdownWidgetState();
}

class _SlaCountdownWidgetState extends State<SlaCountdownWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isOverdue = false;
  double _ratio = 1.0;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  @override
  void didUpdateWidget(covariant SlaCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateRemaining();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    if (!mounted) return;

    final now = DateTime.now();
    DateTime? target;
    DateTime? start;

    if (widget.status == 'NEW' || widget.status == 'OPEN') {
      if (widget.claimDeadline != null) {
        target = DateTime.tryParse(widget.claimDeadline!);
      }
    } else if (widget.status == 'CLAIMED' || widget.status == 'IN_PROGRESS') {
      if (widget.completionDeadline != null) {
        target = DateTime.tryParse(widget.completionDeadline!);
      }
    }

    if (widget.createdAt != null) {
      start = DateTime.tryParse(widget.createdAt!);
    }

    if (target == null) {
      setState(() {
        _remaining = Duration.zero;
        _isOverdue = false;
        _ratio = 1.0;
      });
      return;
    }

    final diff = target.difference(now);
    final isOverdue = diff.isNegative;
    final absDiff = diff.abs();

    double ratio = 1.0;
    if (start != null) {
      final total = target.difference(start).inSeconds;
      if (total > 0) {
        ratio = diff.inSeconds / total;
        if (ratio < 0) ratio = 0.0;
      }
    }

    setState(() {
      _remaining = absDiff;
      _isOverdue = isOverdue;
      _ratio = ratio;
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // If completed/verified/archived, show closed badge
    if (widget.status == 'COMPLETED' ||
        widget.status == 'VERIFIED' ||
        widget.status == 'ARCHIVED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(26),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
            SizedBox(width: 4),
            Text(
              'SLA Tercapai',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Determine colors
    Color color;
    String label;

    final isNewOrOpen = widget.status == 'NEW' || widget.status == 'OPEN';
    if (_isOverdue) {
      color = Colors.redAccent;
      label = isNewOrOpen ? 'Terlambat Klaim' : 'Terlambat Selesai';
    } else {
      label = isNewOrOpen ? 'SLA Klaim' : 'SLA Perbaikan';
      if (_ratio <= 0.20) {
        color = Colors.redAccent; // Critical
      } else if (_ratio <= 0.50) {
        color = Colors.orange; // Warning
      } else {
        color = const Color(0xFF4CAF50); // Safe (Green)
      }
    }

    final timeStr = _formatDuration(_remaining);
    final displayStr = _isOverdue ? '-$timeStr' : timeStr;

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(60), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, color: color, size: 12),
            const SizedBox(width: 3),
            Text(
              displayStr,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isOverdue ? Icons.error_outline_rounded : Icons.alarm_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayStr,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (!_isOverdue) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                value: _ratio,
                strokeWidth: 3,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
