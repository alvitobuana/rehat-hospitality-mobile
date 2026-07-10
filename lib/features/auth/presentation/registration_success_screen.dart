import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_button.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _status == 'REJECTED'
                          ? theme.colorScheme.error.withOpacity(0.1)
                          : _status == 'APPROVED'
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : Colors.amber.withOpacity(0.1),
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
                          ? theme.colorScheme.error
                          : _status == 'APPROVED'
                              ? theme.colorScheme.primary
                              : Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  _status == 'REJECTED'
                      ? 'Pendaftaran Ditolak'
                      : _status == 'APPROVED'
                          ? 'Pendaftaran Disetujui'
                          : 'Pendaftaran Berhasil',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  _status == 'REJECTED'
                      ? 'Mohon maaf, pengajuan registrasi Anda ditolak oleh administrator hotel.'
                      : _status == 'APPROVED'
                          ? 'Selamat! Akun Anda telah diaktifkan oleh admin. Anda sudah bisa masuk sekarang.'
                          : 'Data pendaftaran Anda telah tersimpan di sistem Rehat Hospitality.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                                  ? theme.colorScheme.error.withOpacity(0.12)
                                  : _status == 'APPROVED'
                                      ? theme.colorScheme.primary.withOpacity(0.12)
                                      : Colors.amber.withOpacity(0.12),
                              border: Border.all(
                                color: _status == 'REJECTED'
                                    ? theme.colorScheme.error.withOpacity(0.3)
                                    : _status == 'APPROVED'
                                        ? theme.colorScheme.primary.withOpacity(0.3)
                                        : Colors.amber.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _status == 'REJECTED'
                                    ? theme.colorScheme.error
                                    : _status == 'APPROVED'
                                        ? theme.colorScheme.primary
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
                            color: theme.colorScheme.error.withOpacity(0.06),
                            border: Border.all(color: theme.colorScheme.error.withOpacity(0.15)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _rejectionReason ?? 'Tidak ada alasan penolakan spesifik yang dicantumkan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.error,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                CustomButton(
                  text: 'CEK STATUS PERSETUJUAN',
                  isLoading: _isChecking,
                  onPressed: _checkStatus,
                ),
                const SizedBox(height: 12),
                
                OutlinedButton(
                  onPressed: () => context.go('/login'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: Text(
                    'KEMBALI KE LOGIN',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
