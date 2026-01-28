import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _documentController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();
      final success = await provider.loginWithPin(
        _documentController.text.trim(),
        _pinController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withAlpha(20),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    // Logo Container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withAlpha(200),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withAlpha(80),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Title
                    Text(
                      'ZAFESYS',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Portal de Técnicos',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.badge_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Ingresa tus credenciales',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Campo Cédula
                          TextFormField(
                            controller: _documentController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Número de Cédula',
                              hintText: 'Ingresa tu cédula',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: theme.colorScheme.primary,
                              ),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline.withAlpha(50),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline.withAlpha(50),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu número de cédula';
                              }
                              if (value.length < 6) {
                                return 'La cédula debe tener al menos 6 dígitos';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Campo PIN
                          TextFormField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            obscureText: _obscurePin,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: InputDecoration(
                              labelText: 'PIN',
                              hintText: 'Ingresa tu PIN',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: theme.colorScheme.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin ? Icons.visibility_off : Icons.visibility,
                                  color: theme.colorScheme.primary.withAlpha(150),
                                ),
                                onPressed: () {
                                  setState(() => _obscurePin = !_obscurePin);
                                },
                              ),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline.withAlpha(50),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline.withAlpha(50),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu PIN';
                              }
                              if (value.length < 4) {
                                return 'El PIN debe tener al menos 4 dígitos';
                              }
                              return null;
                            },
                          ),
                          
                          // Error message
                          if (provider.error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      provider.error!,
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => provider.clearError(),
                                    child: Icon(Icons.close, size: 18, color: Colors.red.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: theme.colorScheme.primary.withAlpha(100),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'INGRESAR',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Help text
                    Text(
                      '¿Olvidaste tu PIN? Contacta al administrador',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(100),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(flex: 3),
                    // Footer
                    Text(
                      'Cerraduras Inteligentes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(100),
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
