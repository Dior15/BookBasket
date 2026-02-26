import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'animations/shake.dart';
import 'navigation/drawer_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _hidePassword = true;
  bool _loading = false;
  String? _errorText;

  int _shakeKey = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _errorText = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final success = await AuthService.login(
      _emailCtrl.text,
      _passwordCtrl.text,
    );

    setState(() => _loading = false);

    if (!success) {
      setState(() {
        _errorText = 'Wrong email or password (demo accounts only).';
        _shakeKey++;
      });
      return;
    }

    final admin = await AuthService.isAdmin();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DrawerShell(isAdmin: admin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // No AppBar to match your “Catalog” style (clean top space)
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Hero card (matches your screenshots vibe)
                  _HeroCard(
                    title: 'Welcome to BookBasket',
                    subtitle: 'Sign in to your digital bookshelf',
                    icon: Icons.menu_book_rounded,
                  ),

                  const SizedBox(height: 14),

                  // Login form card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Login',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          if (_errorText != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.error.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: cs.error.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                _errorText!,
                                style: TextStyle(
                                  color: cs.error,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          Shake(
                            shakeKey: _shakeKey,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon:
                                      Icon(Icons.email_outlined),
                                    ),
                                    validator: (v) {
                                      final value = (v ?? '').trim();
                                      if (value.isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordCtrl,
                                    obscureText: _hidePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon:
                                      const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                              () => _hidePassword = !_hidePassword,
                                        ),
                                        icon: Icon(
                                          _hidePassword
                                              ? Icons.visibility_outlined
                                              : Icons
                                              .visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      final value = (v ?? '').trim();
                                      if (value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (value.length < 4) {
                                        return 'Password is too short';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                      _loading ? null : _handleLogin,
                                      child: _loading
                                          ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : const Text('Login'),
                                    ),
                                  ),

                                  const SizedBox(height: 14),
                                  Divider(color: cs.outlineVariant),
                                  const SizedBox(height: 10),

                                  Text(
                                    'Demo accounts',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Admin: ${AuthService.adminEmail} / ${AuthService.adminPassword}\n'
                                        'User:  ${AuthService.userEmail} / ${AuthService.userPassword}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Optional: small “back to catalog” style hint / footer
                  Text(
                    'Tip: use the demo accounts above to explore the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.secondary.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.18),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.90),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}