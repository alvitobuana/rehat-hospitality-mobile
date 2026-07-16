import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/app_buttons.dart';
import 'auth_controller.dart';

class RegistrationSuccessScreen extends ConsumerStatefulWidget {
  final String email;
  const RegistrationSuccessScreen({super.key, required this.email});

  @override
  ConsumerState<RegistrationSuccessScreen> createState() => _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends ConsumerState<RegistrationSuccessScreen> {
  bool _isChecking = false;
  String _status = 'PENDING';
  String? _rejectionReason;

  void _checkStatus() async {
    setState(() => _isChecking = true);
    
    final result = await ref.read(authControllerProvider.notifier).checkRegistrationStatus(widget.email);
    
    if (mounted) {
      setState(() {
        _isChecking = false;
        _status = result['status'] ?? 'PENDING';
        _rejectionReason = result['reason'];
      });

      final theme = Theme.of(context);
      if (_status == 'APPROVED') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Akun Anda telah disetujui! Mengalihkan ke halaman masuk...'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/login');
          }
        });
      } else if (_status == 'REJECTED') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran ditolak: ${_rejectionReason ?? "Tidak ada alasan spesifik."}'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun Anda masih dalam antrean persetujuan Admin.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      useSafeArea: true,
      scrollable: true,
      padding: AppInsets.page(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppInsets.s24),
          // Status Icon
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _status == 'REJECTED'
                    ? AppColors.danger(context).withAlpha(25)
                    : _status == 'APPROVED'
                        ? AppColors.primary(context).withAlpha(25)
                        : Colors.amber.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _status == 'REJECTED'
                    ? Icons.cancel_outlined
                    : _status == 'APPROVED'
                        ? Icons.check_circle_outline
                        : Icons.schedule_outlined,
                size: 40,
                color: _status == 'REJECTED'
                    ? AppColors.danger(context)
                    : _status == 'APPROVED'
                        ? AppColors.primary(context)
                        : Colors.amber,
              ),
            ),
          ),
          const SizedBox(height: AppInsets.s24),
          
          Text(
            _status == 'REJECTED'
                ? 'Pendaftaran Ditolak'
                : _status == 'APPROVED'
                    ? 'Pendaftaran Disetujui'
                    : 'Pendaftaran Berhasil',
            style: AppTypography.heading(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppInsets.s12),
          
          Text(
            _status == 'REJECTED'
                ? 'Mohon maaf, pengajuan registrasi Anda ditolak oleh administrator hotel.'
                : _status == 'APPROVED'
                    ? 'Selamat! Akun Anda telah diaktifkan oleh admin. Anda sudah bisa masuk sekarang.'
                    : 'Data pendaftaran Anda telah tersimpan di sistem Rehat Hospitality.',
            style: AppTypography.caption(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppInsets.s24),
          
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Akun',
                  style: AppTypography.title(context),
                ),
                const SizedBox(height: AppInsets.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Email Terdaftar:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(widget.email, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Akun:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _status == 'REJECTED'
                            ? AppColors.danger(context).withAlpha(25)
                            : _status == 'APPROVED'
                                ? AppColors.primary(context).withAlpha(25)
                                : Colors.amber.withAlpha(25),
                        border: Border.all(
                          color: _status == 'REJECTED'
                              ? AppColors.danger(context).withAlpha(70)
                              : _status == 'APPROVED'
                                  ? AppColors.primary(context).withAlpha(70)
                                  : Colors.amber.withAlpha(70),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _status == 'REJECTED'
                              ? AppColors.danger(context)
                              : _status == 'APPROVED'
                                  ? AppColors.primary(context)
                                  : Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_status == 'REJECTED') ...[
                  const Divider(height: 20),
                  const Text(
                    'Alasan Penolakan:',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger(context).withAlpha(15),
                      border: Border.all(color: AppColors.danger(context).withAlpha(40)),
                      borderRadius: BorderRadius.circular(AppInsets.r8),
                    ),
                    child: Text(
                      _rejectionReason ?? 'Tidak ada alasan penolakan spesifik yang dicantumkan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.danger(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppInsets.s32),
          
          AppPrimaryButton(
            text: 'CEK STATUS PERSETUJUAN',
            isLoading: _isChecking,
            onPressed: _checkStatus,
          ),
          const SizedBox(height: AppInsets.s12),
          
          AppOutlineButton(
            text: 'KEMBALI KE LOGIN',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
