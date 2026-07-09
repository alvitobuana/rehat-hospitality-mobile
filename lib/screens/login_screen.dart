import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../theme/app_theme.dart';
import '../widgets/reusable_widgets.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MockState _state = MockState();

  // Login controllers
  final TextEditingController _loginEmailCtrl = TextEditingController(text: 'staff@rehat.co.id');
  final TextEditingController _loginPassCtrl = TextEditingController(text: 'rehat123');

  // Signup controllers
  final TextEditingController _suNameCtrl = TextEditingController();
  final TextEditingController _suEmailCtrl = TextEditingController();
  final TextEditingController _suPassCtrl = TextEditingController();

  String _selectedDept = 'Housekeeping';
  String _selectedRole = 'Staff';
  String _selectedHotel = 'Kurnia';

  final List<String> _departments = [
    'Housekeeping',
    'Front Office',
    'Food & Beverage',
    'Engineering',
    'Security',
    'Administration'
  ];

  final List<String> _roles = ['Staff', 'Leader', 'Manager'];

  final List<String> _hotels = [
    'Dago Sky', 'Patradisa Iskat', 'Paskal Pelangi', 'Graha Sartika',
    'Hotel 10 Buah Batu', 'Abadi Tasikmalaya', 'Wahidin', 'Ottenville Boutique',
    'Siliwangi GH', 'Kurnia', 'Sabang', 'Gania'
  ];

  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _suNameCtrl.dispose();
    _suEmailCtrl.dispose();
    _suPassCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final success = _state.login(
        _loginEmailCtrl.text.trim(),
        _loginPassCtrl.text.trim(),
      );

      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email atau password salah!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _handleSignup() {
    if (_suNameCtrl.text.isEmpty || _suEmailCtrl.text.isEmpty || _suPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final success = _state.signup(
        _suNameCtrl.text.trim(),
        _suEmailCtrl.text.trim(),
        _suPassCtrl.text.trim(),
        _selectedDept,
        _selectedRole,
        _selectedHotel,
      );

      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email sudah terdaftar!'), backgroundColor: Colors.red),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A2B4A),
              Color(0xFF2A3F6A),
              Color(0xFF1A4A5C),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 12,
                shadowColor: Colors.black45,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Box
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'RH',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rehat HK System',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Housekeeping Management · PT. Putra Pasundan',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2), fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Tabs (Masuk / Daftar)
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: const Color(0xFF1A2B4A),
                          unselectedLabelColor: const Color(0xFF9AA3B2),
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          tabs: const [
                            Tab(text: 'Masuk'),
                            Tab(text: 'Daftar'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tab Contents
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: SizedBox(
                          height: _tabController.index == 0 ? 360 : 490,
                          child: TabBarView(
                            controller: _tabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              // LOGIN TAB
                              _buildLoginTab(theme),
                              // SIGNUP TAB
                              _buildSignupTab(theme),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          label: 'Email',
          hintText: 'nama@rehat.co.id',
          controller: _loginEmailCtrl,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Password',
          hintText: '••••••••',
          controller: _loginPassCtrl,
          obscureText: _obscurePass,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF9AA3B2),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Masuk →',
          onPressed: _handleLogin,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        const Text(
          'Demo Accounts (Password: rehat123):',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('• Staff: staff@rehat.co.id', style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 11, color: Color(0xFF5A6478))),
              Text('• Leader: leader@rehat.co.id', style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 11, color: Color(0xFF5A6478))),
              Text('• Manager: manager@rehat.co.id', style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 11, color: Color(0xFF5A6478))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignupTab(ThemeData theme) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            label: 'Nama Lengkap',
            hintText: 'Nama karyawan...',
            controller: _suNameCtrl,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Email',
            hintText: 'email@rehat.co.id',
            controller: _suEmailCtrl,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Password',
            hintText: 'Min. 6 karakter',
            controller: _suPassCtrl,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DEPARTEMEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDept,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                          onChanged: (val) => setState(() => _selectedDept = val!),
                          items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LEVEL AKSES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                          onChanged: (val) => setState(() => _selectedRole = val!),
                          items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('UNIT HOTEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedHotel,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                    onChanged: (val) => setState(() => _selectedHotel = val!),
                    items: _hotels.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Buat Akun →',
            onPressed: _handleSignup,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
