import 'package:enmkit/models/users_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/home/home.dart';
import 'package:enmkit/viewmodels/authViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final PageController _pageController = PageController();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;
  int _currentPage = 0;

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }

      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),

                /// LOGO
                Image.asset(
                  'asset/images/logo.png',
                  height: 72,
                ),

                const SizedBox(height: 12),

                /// APP NAME
                const Text(
                  'L\'energie responsable pour un monde plus meilleur',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Gestion intelligente de l’énergie',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 36),

                /// CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      /// TAB SWITCH
                      Row(
                        children: [
                          _AuthTab(
                            title: "Connexion",
                            active: _currentPage == 0,
                            onTap: () => _goToPage(0),
                          ),
                          _AuthTab(
                            title: "Inscription",
                            active: _currentPage == 1,
                            onTap: () => _goToPage(1),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 320,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          children: [
                            _loginForm(authState),
                            _registerForm(authState),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= LOGIN =================
  Widget _loginForm(AuthState authState) {
    return Column(
      children: [
        _inputField(
          controller: _phoneController,
          label: 'Numéro de téléphone',
          icon: Icons.phone,
        ),
        const SizedBox(height: 16),
        _inputField(
          controller: _passwordController,
          label: 'Mot de passe',
          icon: Icons.lock,
          obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 24),
        _primaryButton(
          text: 'Se connecter',
          loading: authState.isLoading,
          onPressed: () {
            ref.read(authProvider.notifier).login(
                  _phoneController.text.trim(),
                  _passwordController.text.trim(),
                );
          },
        ),
      ],
    );
  }

  /// ================= REGISTER =================
  Widget _registerForm(AuthState authState) {
    return Column(
      children: [
        _inputField(
          controller: _phoneController,
          label: 'Numéro de téléphone',
          icon: Icons.phone,
        ),
        const SizedBox(height: 16),
        _inputField(
          controller: _passwordController,
          label: 'Mot de passe',
          icon: Icons.lock,
          obscure: _obscurePassword,
        ),
        const SizedBox(height: 16),
        _inputField(
          controller: _confirmPasswordController,
          label: 'Confirmer le mot de passe',
          icon: Icons.lock_outline,
          obscure: _obscureConfirmPassword,
        ),
        const SizedBox(height: 24),
        _primaryButton(
          text: 'Créer un compte',
          loading: authState.isLoading,
          onPressed: () {
            if (_passwordController.text !=
                _confirmPasswordController.text) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Mots de passe non identiques")),
              );
              return;
            }
            ref.read(authProvider.notifier).registerUser(
                  UserModel(
                    phoneNumber: _phoneController.text.trim(),
                    password: _passwordController.text.trim(),
                  ),
                );
          },
        ),
      ],
    );
  }

  /// ================= COMPONENTS =================
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

/// ================= TAB =================
class _AuthTab extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _AuthTab({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFF2563EB) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF2563EB) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
