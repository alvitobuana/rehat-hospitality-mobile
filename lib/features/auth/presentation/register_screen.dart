import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _employeeIdController = TextEditingController();

  String _selectedHotel = 'dagosky';
  String _selectedDept = 'Housekeeping';
  String _selectedPosition = 'Staff';

  final List<Map<String, String>> _hotels = [
    {'id': 'dagosky', 'name': 'Dago Sky'},
    {'id': 'paskal', 'name': 'Paskal Pelangi'},
    {'id': 'patradisa', 'name': 'Patra Disa'},
    {'id': 'sukajadi', 'name': 'Sukajadi'},
  ];

  final List<String> _departments = [
    'Housekeeping',
    'Front Office',
    'Food & Beverage',
    'Engineering',
    'Security',
  ];

  final List<String> _positions = [
    'Staff',
    'Leader',
    'Manager',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authControllerProvider.notifier).register(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            hotelId: _selectedHotel,
            department: _selectedDept,
            position: _selectedPosition,
            employeeId: _employeeIdController.text.trim().isEmpty 
                ? null 
                : _employeeIdController.text.trim(),
          );
          
      if (success && mounted) {
        context.go('/registration-success?email=${Uri.encodeComponent(_emailController.text.trim())}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final bool isLoading = authState.status == AuthStatus.authenticating;

    // Listen to error snackbar
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(authControllerProvider.notifier).resetError();
      }
    });

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Mendaftarkan akun...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Akun Baru'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bergabung dengan Rehat',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lengkapi formulir di bawah untuk pendaftaran staf housekeeping',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            controller: _fullNameController,
                            labelText: 'Nama Lengkap',
                            hintText: 'Masukkan nama lengkap...',
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama lengkap wajib diisi';
                              }
                              return null;
                            },
                          ),
                          
                          AppTextField(
                            controller: _emailController,
                            labelText: 'Alamat Email',
                            hintText: 'Masukkan email...',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email wajib diisi';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          
                          AppTextField(
                            controller: _phoneController,
                            labelText: 'Nomor HP',
                            hintText: 'Contoh: 08123456789',
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nomor HP wajib diisi';
                              }
                              return null;
                            },
                          ),

                          AppTextField(
                            controller: _employeeIdController,
                            labelText: 'ID Karyawan (Opsional)',
                            hintText: 'Masukkan ID karyawan jika ada...',
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedHotel,
                            decoration: InputDecoration(
                              labelText: 'Hotel Penugasan',
                              prefixIcon: const Icon(Icons.hotel_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _hotels.map((h) {
                              return DropdownMenuItem<String>(
                                value: h['id'],
                                child: Text(h['name']!),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedHotel = val);
                              }
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedDept,
                            decoration: InputDecoration(
                              labelText: 'Departemen',
                              prefixIcon: const Icon(Icons.business_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _departments.map((d) {
                              return DropdownMenuItem<String>(
                                value: d,
                                child: Text(d),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDept = val);
                              }
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedPosition,
                            decoration: InputDecoration(
                              labelText: 'Jabatan',
                              prefixIcon: const Icon(Icons.work_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _positions.map((p) {
                              return DropdownMenuItem<String>(
                                value: p,
                                child: Text(p),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPosition = val);
                              }
                            },
                          ),
                          
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _passwordController,
                            labelText: 'Kata Sandi',
                            hintText: 'Minimal 8 karakter...',
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Kata sandi wajib diisi';
                              }
                              if (val.length < 8) {
                                return 'Kata sandi minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          
                          AppTextField(
                            controller: _confirmPasswordController,
                            labelText: 'Konfirmasi Kata Sandi',
                            hintText: 'Ulangi kata sandi...',
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Konfirmasi kata sandi wajib diisi';
                              }
                              if (val != _passwordController.text) {
                                return 'Konfirmasi kata sandi tidak cocok';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'DAFTAR SEKARANG',
                            isLoading: isLoading,
                            onPressed: _onRegisterPressed,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
