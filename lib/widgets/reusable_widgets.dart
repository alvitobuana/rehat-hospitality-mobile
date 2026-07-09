import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── PRIMARY BUTTON ───
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final bool isLoading;

  const PrimaryButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;
    final textCol = textColor ?? Colors.white;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textCol,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: textCol),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(color: textCol),
                ),
              ],
            ),
    );
  }
}

// ─── STAT CARD ───
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2B4A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9AA3B2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ROOM CARD ───
class RoomCard extends StatelessWidget {
  final String roomNumber;
  final String roomType;
  final String workType;
  final String status;
  final String verifiedStatus;
  final String staffName;
  final String timeText;
  final String defectNote;
  final VoidCallback? onTap;

  const RoomCard({
    Key? key,
    required this.roomNumber,
    required this.roomType,
    required this.workType,
    required this.status,
    required this.verifiedStatus,
    required this.staffName,
    required this.timeText,
    required this.defectNote,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get color according to room status
    Color statusColor;
    Color statusBgColor;
    switch (status) {
      case 'Occupied':
        statusColor = const Color(0xFF2A4E9A);
        statusBgColor = const Color(0xFFEEF3FB);
        break;
      case 'Vacant Clean':
        statusColor = const Color(0xFF15803D);
        statusBgColor = const Color(0xFFDCFCE7);
        break;
      case 'Vacant Dirty':
        statusColor = const Color(0xFFB91C1C);
        statusBgColor = const Color(0xFFFEE2E2);
        break;
      case 'Out of Order':
        statusColor = const Color(0xFF92400E);
        statusBgColor = const Color(0xFFFEF9C3);
        break;
      default:
        statusColor = const Color(0xFF5A6478);
        statusBgColor = const Color(0xFFE4E8F0);
    }

    // Get verified badge color
    Color vColor;
    Color vBgColor;
    String vLabel = verifiedStatus;
    switch (verifiedStatus) {
      case 'Verified':
        vColor = const Color(0xFF065F46);
        vBgColor = const Color(0xFFD1FAE5);
        vLabel = '✓ Verified';
        break;
      case 'Not Verified':
        vColor = const Color(0xFFB91C1C);
        vBgColor = const Color(0xFFFEE2E2);
        vLabel = '✗ Rejected';
        break;
      default:
        vColor = const Color(0xFF92400E);
        vBgColor = const Color(0xFFFEF9C3);
        vLabel = '⏳ Pending';
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Number Circle
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  roomNumber,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Room Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kamar $roomNumber · $roomType',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Verified Status Badge
                        _badge(vLabel, vColor, vBgColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Meta row
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _metaInfo(Icons.cleaning_services, workType),
                        _metaInfo(Icons.person, staffName),
                        if (timeText.isNotEmpty) _metaInfo(Icons.access_time, timeText),
                      ],
                    ),
                    if (defectNote.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⚠️ Defect: $defectNote',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Room Status Badge
                    _badge(status, statusColor, statusBgColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9AA3B2)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF5A6478),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── VALIDATION CARD (For Leader) ───
class ValidationCard extends StatelessWidget {
  final String roomNumber;
  final String roomType;
  final String staffName;
  final String workType;
  final String duration;
  final String defectNote;
  final String hotelUnit;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onTap;

  const ValidationCard({
    Key? key,
    required this.roomNumber,
    required this.roomType,
    required this.staffName,
    required this.workType,
    required this.duration,
    required this.defectNote,
    required this.hotelUnit,
    required this.onApprove,
    required this.onReject,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      roomNumber,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kamar $roomNumber · $roomType',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Staff: $staffName',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5A6478),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          children: [
                            _miniMeta(Icons.work_outline, workType),
                            _miniMeta(Icons.timer_outlined, duration),
                            _miniMeta(Icons.hotel_class_outlined, hotelUnit),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (defectNote.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    'Catatan Defect: $defectNote',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE4E8F0), height: 1),
              const SizedBox(height: 12),
              // Action buttons (Approve & Reject)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reject (Not Verified)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Approve (Verified)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9AA3B2)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF5A6478)),
        ),
      ],
    );
  }
}

// ─── PROJECT CARD ───
class ProjectCard extends StatelessWidget {
  final String name;
  final String area;
  final String category;
  final String status;
  final String priority;
  final int progress;
  final String pic;
  final double cost;
  final String dateText;
  final VoidCallback? onTap;

  const ProjectCard({
    Key? key,
    required this.name,
    required this.area,
    required this.category,
    required this.status,
    required this.priority,
    required this.progress,
    required this.pic,
    required this.cost,
    required this.dateText,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    Color statusBgColor;
    switch (status) {
      case 'Selesai':
        statusColor = const Color(0xFF15803D);
        statusBgColor = const Color(0xFFDCFCE7);
        break;
      case 'Sedang Berlangsung':
        statusColor = AppTheme.primaryColor;
        statusBgColor = const Color(0xFFEEF3FB);
        break;
      default: // 'Akan Dikerjakan'
        statusColor = const Color(0xFF92400E);
        statusBgColor = const Color(0xFFFEF9C3);
    }

    Color priorityColor;
    Color priorityBgColor;
    switch (priority) {
      case 'Tinggi':
        priorityColor = const Color(0xFFB91C1C);
        priorityBgColor = const Color(0xFFFEE2E2);
        break;
      case 'Rendah':
        priorityColor = const Color(0xFF065F46);
        priorityBgColor = const Color(0xFFD1FAE5);
        break;
      default: // 'Sedang'
        priorityColor = const Color(0xFF7C3AED);
        priorityBgColor = const Color(0xFFEDE9FE);
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _badge(status, statusColor, statusBgColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                area,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _badge(category, const Color(0xFF5A6478), const Color(0xFFE4E8F0)),
                  _badge('Prio: $priority', priorityColor, priorityBgColor),
                  _badge('PIC: $pic', const Color(0xFF0E9F7E), const Color(0xFFD1FAE5)),
                ],
              ),
              const SizedBox(height: 14),
              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress Kerja',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5A6478)),
                  ),
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: const Color(0xFFE4E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    status == 'Selesai' ? const Color(0xFF22C55E) : AppTheme.primaryColor,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tgl: $dateText',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9AA3B2)),
                  ),
                  if (cost > 0)
                    Text(
                      'Biaya: Rp ${_formatCost(cost)}',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B4A),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCost(double cost) {
    if (cost >= 1000000) {
      return '${(cost / 1000000).toStringAsFixed(1)} jt';
    }
    return '${(cost / 1000).toStringAsFixed(0)}k';
  }

  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── LOST & FOUND CARD ───
class LostFoundCard extends StatelessWidget {
  final String itemName;
  final String roomNumber;
  final String category;
  final String status;
  final String reportedBy;
  final String date;
  final VoidCallback? onTap;

  const LostFoundCard({
    Key? key,
    required this.itemName,
    required this.roomNumber,
    required this.category,
    required this.status,
    required this.reportedBy,
    required this.date,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData catIcon;
    Color catBg;
    Color catColor;

    switch (category) {
      case 'Elektronik':
        catIcon = Icons.devices;
        catBg = const Color(0xFFEDE9FE);
        catColor = const Color(0xFF7C3AED);
        break;
      case 'Dokumen / ID':
        catIcon = Icons.badge_outlined;
        catBg = const Color(0xFFEEF3FB);
        catColor = AppTheme.primaryColor;
        break;
      case 'Uang / Dompet':
        catIcon = Icons.account_balance_wallet_outlined;
        catBg = const Color(0xFFFEF9C3);
        catColor = const Color(0xFF92400E);
        break;
      case 'Perhiasan / Aksesori':
        catIcon = Icons.watch_outlined;
        catBg = const Color(0xFFFFEDD5);
        catColor = const Color(0xFFC2410C);
        break;
      default:
        catIcon = Icons.search;
        catBg = const Color(0xFFE4E8F0);
        catColor = const Color(0xFF5A6478);
    }

    Color statusColor;
    Color statusBgColor;
    switch (status) {
      case 'Diklaim':
        statusColor = const Color(0xFF15803D);
        statusBgColor = const Color(0xFFDCFCE7);
        break;
      case 'Diserahkan ke FO':
        statusColor = const Color(0xFF0E9F7E);
        statusBgColor = const Color(0xFFD1FAE5);
        break;
      default: // 'Disimpan'
        statusColor = AppTheme.primaryColor;
        statusBgColor = const Color(0xFFEEF3FB);
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: catBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            itemName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _badge(status, statusColor, statusBgColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kamar $roomNumber · Ditemukan oleh $reportedBy',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5A6478)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9AA3B2)),
                        ),
                        Text(
                          category,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: catColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── CUSTOM TEXT FIELD ───
class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9AA3B2),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A2B4A), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF9AA3B2), size: 20) : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
