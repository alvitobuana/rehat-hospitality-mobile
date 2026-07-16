import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../core/storage/session_manager.dart';
import '../data/profile_repository.dart';
import 'edit_profile_controller.dart';
import 'profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController();
    _emailCtrl    = TextEditingController();
    _phoneCtrl    = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Save profile
  // ---------------------------------------------------------------------------
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(editProfileControllerProvider.notifier).saveProfile(
      fullName: _fullNameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      phone:    _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.'), backgroundColor: Colors.green),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Change password dialog
  // ---------------------------------------------------------------------------
  Future<void> _showChangePasswordDialog() async {
    final oldCtrl     = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld  = true;
    bool obscureNew  = true;
    bool obscureConf = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppInsets.r12)),
          title: const Text('Ganti Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pwField(
                context,
                ctrl: oldCtrl,
                label: 'Password Saat Ini',
                obscure: obscureOld,
                onToggle: () => setDlg(() => obscureOld = !obscureOld),
              ),
              const SizedBox(height: AppInsets.s12),
              _pwField(
                context,
                ctrl: newCtrl,
                label: 'Password Baru',
                obscure: obscureNew,
                onToggle: () => setDlg(() => obscureNew = !obscureNew),
              ),
              const SizedBox(height: AppInsets.s12),
              _pwField(
                context,
                ctrl: confirmCtrl,
                label: 'Konfirmasi Password Baru',
                obscure: obscureConf,
                onToggle: () => setDlg(() => obscureConf = !obscureConf),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            Consumer(builder: (ctx2, ref2, _) {
              final pwState = ref2.watch(editProfileControllerProvider);
              final isSaving = pwState.passwordStatus == PasswordStatus.saving;
              return TextButton(
                onPressed: isSaving ? null : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);

                  final ok = await ref2.read(editProfileControllerProvider.notifier).changePassword(
                    currentPassword: oldCtrl.text,
                    newPassword:     newCtrl.text,
                    confirmPassword: confirmCtrl.text,
                  );
                  
                  nav.pop();
                  if (ok) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Password berhasil diubah.'), backgroundColor: Colors.green),
                    );
                  } else {
                    final errMsg = ref2.read(editProfileControllerProvider).passwordError ?? 'Gagal mengubah password.';
                    messenger.showSnackBar(
                      SnackBar(content: Text(errMsg), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Simpan', style: TextStyle(color: AppColors.primary(context))),
              );
            }),
          ],
        ),
      ),
    );
    oldCtrl.dispose(); newCtrl.dispose(); confirmCtrl.dispose();
  }

  Widget _pwField(
    BuildContext context, {
    required TextEditingController ctrl,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppInsets.r12),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
          onPressed: onToggle,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final sessionAsync  = ref.watch(sessionDataProvider);
    final editState     = ref.watch(editProfileControllerProvider);
    final photoState    = ref.watch(profilePhotoControllerProvider);
    final photoCtrl     = ref.read(profilePhotoControllerProvider.notifier);
    final theme = Theme.of(context);

    final isSaving = editState.profileStatus == EditProfileStatus.saving;

    // Show error snackbars
    ref.listen<EditProfileState>(editProfileControllerProvider, (prev, next) {
      if (next.profileStatus == EditProfileStatus.error && next.profileError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.profileError!), backgroundColor: Colors.redAccent),
        );
      }
    });
    ref.listen<ProfilePhotoState>(profilePhotoControllerProvider, (prev, next) {
      if (next.status == ProfilePhotoStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.redAccent),
        );
        photoCtrl.resetState();
      }
      if (next.status == ProfilePhotoStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil diperbarui.'), backgroundColor: Colors.green),
        );
        photoCtrl.resetState();
      }
    });

    return AppPage(
      title: 'Edit Profil',
      useSafeArea: true,
      scrollable: true,
      padding: EdgeInsets.only(
        left: AppInsets.s24,
        right: AppInsets.s24,
        top: AppInsets.s24,
        bottom: AppInsets.s24 + AppInsets.bottomSafe(context),
      ),
      child: sessionAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppInsets.s24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (session) {
          // Pre-fill once
          if (!_loaded) {
            _fullNameCtrl.text = session.fullName ?? '';
            _emailCtrl.text    = session.email ?? '';
            _phoneCtrl.text    = session.phone ?? '';
            _loaded = true;
          }

          final photoPath = session.profilePhoto ?? '';
          final photoUrl  = ProfileRepository.buildPhotoUrl(photoPath);
          final isPhotoLoading = photoState.status == ProfilePhotoStatus.uploading ||
              photoState.status == ProfilePhotoStatus.deleting ||
              photoState.status == ProfilePhotoStatus.picking;

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Avatar ────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: isPhotoLoading
                        ? null
                        : () => _showPhotoMenu(context, ref, photoUrl: photoUrl, hasPhoto: photoPath.isNotEmpty),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.primaryColor.withAlpha(100), width: 2.5),
                          ),
                          child: isPhotoLoading
                              ? CircleAvatar(
                                  radius: 48,
                                  backgroundColor: theme.primaryColor.withAlpha(25),
                                  child: const CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : ClipOval(
                                  child: photoUrl.isNotEmpty
                                      ? Image.network(photoUrl, width: 96, height: 96, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _defaultAvatar(theme))
                                      : _defaultAvatar(theme),
                                ),
                        ),
                        if (!isPhotoLoading)
                          Container(
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppInsets.s32),

                // ── Editable Fields ───────────────────────────
                _sectionLabel('Informasi Pribadi'),
                const SizedBox(height: AppInsets.s12),

                _editField(
                  controller: _fullNameCtrl,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
                    if (v.trim().length < 2) return 'Nama minimal 2 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: AppInsets.s12),

                _editField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
                    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-z]{2,}$', caseSensitive: false);
                    if (!regex.hasMatch(v.trim())) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: AppInsets.s12),

                _editField(
                  controller: _phoneCtrl,
                  label: 'Nomor HP',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.isEmpty) return 'Nomor HP tidak boleh kosong';
                    if (digits.length < 10 || digits.length > 15) return 'Nomor HP harus 10–15 digit';
                    return null;
                  },
                ),
                const SizedBox(height: AppInsets.s24),

                // ── Read-Only Fields ──────────────────────────
                _sectionLabel('Informasi Jabatan (Read Only)'),
                const SizedBox(height: AppInsets.s12),

                _readOnlyField(
                  label: 'ID Karyawan',
                  value: session.employeeId?.isNotEmpty == true ? session.employeeId! : '—',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: AppInsets.s8),
                _readOnlyField(
                  label: 'Hotel Penugasan',
                  value: session.hotelName?.isNotEmpty == true ? session.hotelName! : '—',
                  icon: Icons.hotel_rounded,
                ),
                const SizedBox(height: AppInsets.s8),
                _readOnlyField(
                  label: 'Departemen',
                  value: session.level?.isNotEmpty == true ? session.level! : '—',
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: AppInsets.s24),

                // ── Change Password ───────────────────────────
                AppOutlineButton(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock_outline_rounded),
                  text: 'Ganti Password',
                ),
                const SizedBox(height: AppInsets.s20),

                // ── Save Button ───────────────────────────────
                AppPrimaryButton(
                  text: isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                  icon: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                  onPressed: isSaving ? null : _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.8),
  );

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _readOnlyField({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(60)),
        color: Colors.grey.withAlpha(15),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ])),
        const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
      ]),
    );
  }

  Widget _defaultAvatar(ThemeData theme) => CircleAvatar(
    radius: 48,
    backgroundColor: theme.primaryColor.withAlpha(30),
    child: Icon(Icons.person, size: 52, color: theme.primaryColor),
  );

  void _showPhotoMenu(BuildContext context, WidgetRef ref, {required String photoUrl, required bool hasPhoto}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final ctrl = ref.read(profilePhotoControllerProvider.notifier);
        return SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(80), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Text('Foto Profil', style: AppTypography.title(context).copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (hasPhoto) _menuBtn(ctx, Icons.photo_outlined, 'Lihat Foto', Colors.blue, () {
              Navigator.pop(ctx);
              _viewPhoto(context, photoUrl);
            }),
            if (hasPhoto) const SizedBox(height: 12),
            _menuBtn(ctx, Icons.camera_alt_rounded, 'Ganti Foto', Colors.green, () {
              Navigator.pop(ctx);
              ctrl.showPhotoSourceSheet(context);
            }),
            if (hasPhoto) const SizedBox(height: 12),
            if (hasPhoto) _menuBtn(ctx, Icons.delete_outline_rounded, 'Hapus Foto', Colors.redAccent, () {
              Navigator.pop(ctx);
              ctrl.deletePhoto();
            }),
            const SizedBox(height: 8),
          ]),
        ));
      },
    );
  }

  Widget _menuBtn(BuildContext ctx, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _viewPhoto(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(children: [
          Center(child: Image.network(photoUrl, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 80))),
          Positioned(top: 8, right: 8, child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(ctx),
          )),
        ]),
      ),
    );
  }
}
