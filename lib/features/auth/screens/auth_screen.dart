import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rientro/core/theme/app_theme.dart';
import 'package:rientro/core/constants/app_strings.dart';
import 'package:rientro/core/utils/haptics.dart';
import 'package:rientro/features/auth/providers/auth_provider.dart';
import 'package:rientro/widgets/common/app_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _showEmailForm = false;
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _error;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authActionsProvider).signInAnonymously();
    } catch (e) {
      setState(() => _error = AppStrings.errorGeneric);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitEmailForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authActions = ref.read(authActionsProvider);
      if (_isSignUp) {
        await authActions.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await authActions.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      setState(() => _error = AppStrings.errorGeneric);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: AppTheme.paddingPage,
          child: Column(
            children: [
              const Spacer(),
              
              // Logo e titolo
              _buildHeader(),
              
              const SizedBox(height: 48),
              
              // Form o pulsanti
              if (_showEmailForm)
                _buildEmailForm()
              else
                _buildButtons(),
              
              const Spacer(),
              
              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.accent.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 48,
              color: AppTheme.accent,
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Titolo
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            children: [
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.welcomeSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          // Errore
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: AppTheme.borderRadiusMedium,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Pulsante principale - Anonimo
          AppPrimaryButton(
            label: AppStrings.continueAnonymously,
            icon: Icons.arrow_forward,
            onPressed: _isLoading ? null : _signInAnonymously,
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Pulsante secondario - Email
          AppButton(
            label: AppStrings.signInWithEmail,
            isOutlined: true,
            onPressed: () {
              Haptics.light();
              setState(() => _showEmailForm = true);
            },
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Torna indietro
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                Haptics.light();
                setState(() {
                  _showEmailForm = false;
                  _error = null;
                });
              },
              icon: const Icon(Icons.arrow_back),
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Errore
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: AppTheme.borderRadiusMedium,
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: AppStrings.email,
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci email';
              }
              if (!value.contains('@')) {
                return 'Email non valida';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: AppStrings.password,
              prefixIcon: Icon(Icons.lock_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci password';
              }
              if (value.length < 6) {
                return 'Minimo 6 caratteri';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Submit
          AppPrimaryButton(
            label: _isSignUp ? AppStrings.signUp : AppStrings.signIn,
            onPressed: _isLoading ? null : _submitEmailForm,
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Toggle sign up / sign in
          TextButton(
            onPressed: () {
              Haptics.light();
              setState(() {
                _isSignUp = !_isSignUp;
                _error = null;
              });
            },
            child: Text(
              _isSignUp 
                  ? 'Hai già un account? Accedi' 
                  : 'Non hai un account? Registrati',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'La tua sicurezza, la nostra priorità',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textTertiary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

