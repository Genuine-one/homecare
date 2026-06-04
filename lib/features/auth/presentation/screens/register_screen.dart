import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';

const double _kDesktopBreak = 900;
const double _kTabletBreak  = 600;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _addressCtrl   = TextEditingController();
  final _cityCtrl      = TextEditingController();
  final _stateCtrl     = TextEditingController();
  final _pincodeCtrl   = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  String _role           = 'patient';
  bool   _obscurePass    = true;
  bool   _obscureConfirm = true;

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl,
      _addressCtrl, _cityCtrl, _stateCtrl, _pincodeCtrl,
      _passCtrl, _confirmCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
      firstName:       _firstNameCtrl.text.trim(),
      lastName:        _lastNameCtrl.text.trim(),
      email:           _emailCtrl.text.trim(),
      phone:           _phoneCtrl.text.trim(),
      address:         _addressCtrl.text.trim(),
      city:            _cityCtrl.text.trim(),
      state_:          _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      pincode:         _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
      password:        _passCtrl.text,
      confirmPassword: _confirmCtrl.text,
      role:            _role,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Registration successful! Please login.'),
        backgroundColor: AppColors.success,
      ));
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;
    final error     = authState.valueOrNull?.error;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return width >= _kDesktopBreak
          ? _DesktopLayout(
              formKey: _formKey,
              controllers: _Controllers(
                firstName: _firstNameCtrl, lastName: _lastNameCtrl,
                email: _emailCtrl, phone: _phoneCtrl,
                address: _addressCtrl, city: _cityCtrl,
                state: _stateCtrl, pincode: _pincodeCtrl,
                pass: _passCtrl, confirm: _confirmCtrl,
              ),
              role: _role, obscurePass: _obscurePass,
              obscureConfirm: _obscureConfirm, isLoading: isLoading, error: error,
              onRoleChanged:    (r) => setState(() => _role = r),
              onTogglePass:     () => setState(() => _obscurePass = !_obscurePass),
              onToggleConfirm:  () => setState(() => _obscureConfirm = !_obscureConfirm),
              onSubmit: _submit, onLogin: () => context.go('/login'),
            )
          : _MobileLayout(
              formKey: _formKey,
              controllers: _Controllers(
                firstName: _firstNameCtrl, lastName: _lastNameCtrl,
                email: _emailCtrl, phone: _phoneCtrl,
                address: _addressCtrl, city: _cityCtrl,
                state: _stateCtrl, pincode: _pincodeCtrl,
                pass: _passCtrl, confirm: _confirmCtrl,
              ),
              role: _role, obscurePass: _obscurePass,
              obscureConfirm: _obscureConfirm, isLoading: isLoading, error: error,
              isTablet: width >= _kTabletBreak,
              onRoleChanged:    (r) => setState(() => _role = r),
              onTogglePass:     () => setState(() => _obscurePass = !_obscurePass),
              onToggleConfirm:  () => setState(() => _obscureConfirm = !_obscureConfirm),
              onSubmit: _submit, onLogin: () => context.go('/login'),
            );
        },
      ),
    );
  }
}

// ── Controller bundle ─────────────────────────────────────────────────────────
class _Controllers {
  final TextEditingController firstName, lastName, email, phone;
  final TextEditingController address, city, state, pincode;
  final TextEditingController pass, confirm;
  const _Controllers({
    required this.firstName, required this.lastName,
    required this.email,     required this.phone,
    required this.address,   required this.city,
    required this.state,     required this.pincode,
    required this.pass,      required this.confirm,
  });
}

// ── Desktop layout ────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final _Controllers controllers;
  final String role;
  final bool obscurePass, obscureConfirm, isLoading;
  final String? error;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit, onLogin;

  const _DesktopLayout({
    required this.formKey, required this.controllers,
    required this.role, required this.obscurePass,
    required this.obscureConfirm, required this.isLoading,
    required this.error, required this.onRoleChanged,
    required this.onTogglePass, required this.onToggleConfirm,
    required this.onSubmit, required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left branded panel ─────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1A237E)],
                ),
              ),
              child: Stack(
                children: [
                  _Circle(size: 300, top: -70,   right: -70,  alpha: 0.07),
                  _Circle(size: 200, bottom: -50, left: -50,  alpha: 0.06),
                  _Circle(size: 130, top: 220,   left: -40,   alpha: 0.05),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LogoBadge(size: 96)
                              .animate().fadeIn(duration: 700.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                          const SizedBox(height: 24),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(text: 'KLE ',
                                  style: GoogleFonts.poppins(color: Colors.white,
                                      fontSize: 32, fontWeight: FontWeight.w800,
                                      letterSpacing: 2.5)),
                              TextSpan(text: 'HOMECARE',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 32, fontWeight: FontWeight.w400,
                                      letterSpacing: 2.0)),
                            ]),
                          ).animate().fadeIn(delay: 150.ms, duration: 600.ms),
                          const SizedBox(height: 8),
                          Text(AppStrings.appTagline,
                              style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 13),
                              textAlign: TextAlign.center)
                              .animate().fadeIn(delay: 250.ms, duration: 600.ms),
                          const SizedBox(height: 48),
                          ...[
                            (Icons.how_to_reg_outlined,     'Quick & Easy Registration'),
                            (Icons.verified_user_outlined,  'Secure & Private'),
                            (Icons.support_agent_outlined,  'Dedicated Care Support'),
                          ].asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _FeaturePill(icon: e.value.$1, label: e.value.$2)
                                .animate()
                                .fadeIn(delay: (300 + e.key * 100).ms, duration: 500.ms)
                                .slideX(begin: -0.15, end: 0),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Right form panel ───────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                    child: _RegisterForm(
                      formKey: formKey, controllers: controllers,
                      role: role, obscurePass: obscurePass,
                      obscureConfirm: obscureConfirm, isLoading: isLoading,
                      error: error, isDesktop: true,
                      onRoleChanged: onRoleChanged,
                      onTogglePass: onTogglePass, onToggleConfirm: onToggleConfirm,
                      onSubmit: onSubmit, onLogin: onLogin,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile / Tablet layout ────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final _Controllers controllers;
  final String role;
  final bool obscurePass, obscureConfirm, isLoading, isTablet;
  final String? error;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit, onLogin;

  const _MobileLayout({
    required this.formKey,
    required this.controllers,
    required this.role,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.isLoading,
    required this.isTablet,
    required this.error,
    required this.onRoleChanged,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1A237E)],
            ),
          ),
        ),
        _Circle(size: 220, top: -60,    right: -60,  alpha: 0.06),
        _Circle(size: 280, bottom: -80, left: -60,   alpha: 0.05),
        _Circle(size: 120, top: 200,    left: -40,   alpha: 0.04),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 520 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 0 : 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isTablet ? 40 : 24),
                    // Logo + wordmark
                    Column(
                      children: [
                        _LogoBadge(size: isTablet ? 90 : 76)
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(begin: const Offset(0.8, 0.8)),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: 'KLE ',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isTablet ? 28 : 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                            ),
                            TextSpan(
                              text: 'HOMECARE',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: isTablet ? 28 : 22,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ]),
                        ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.appTagline,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                      ],
                    ),
                    SizedBox(height: isTablet ? 32 : 20),
                    // Form card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(isTablet ? 32 : 24),
                      child: _RegisterForm(
                        formKey: formKey,
                        controllers: controllers,
                        role: role,
                        obscurePass: obscurePass,
                        obscureConfirm: obscureConfirm,
                        isLoading: isLoading,
                        error: error,
                        isDesktop: false,
                        onRoleChanged: onRoleChanged,
                        onTogglePass: onTogglePass,
                        onToggleConfirm: onToggleConfirm,
                        onSubmit: onSubmit,
                        onLogin: onLogin,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Register form ─────────────────────────────────────────────────────────────
class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final _Controllers controllers;
  final String role;
  final bool obscurePass, obscureConfirm, isLoading, isDesktop;
  final String? error;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit, onLogin;

  const _RegisterForm({
    required this.formKey,
    required this.controllers,
    required this.role,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.isLoading,
    required this.isDesktop,
    required this.error,
    required this.onRoleChanged,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create Account',
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 26 : 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fill in the details below to get started',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Error banner
          if (error != null) ...[
            _ErrorBanner(message: error!)
                .animate()
                .fadeIn(duration: 300.ms)
                .shake(duration: 400.ms),
            const SizedBox(height: 16),
          ],

          // Role is fixed to 'patient' — nurses are created by admin only.
          // No role selector shown.

          // Name row
          Row(
            children: [
              Expanded(
                child: _InputField(
                  label: 'First Name',
                  controller: controllers.firstName,
                  icon: Icons.badge_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputField(
                  label: 'Last Name',
                  controller: controllers.lastName,
                  icon: Icons.badge_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _InputField(
            label: 'Email Address',
            controller: controllers.email,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ).animate().fadeIn(delay: 120.ms, duration: 400.ms),
          const SizedBox(height: 14),

          _InputField(
            label: 'Phone Number',
            controller: controllers.phone,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Phone is required' : null,
          ).animate().fadeIn(delay: 140.ms, duration: 400.ms),
          const SizedBox(height: 14),

          _InputField(
            label: 'Address',
            controller: controllers.address,
            icon: Icons.home_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Address is required' : null,
          ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _InputField(
                  label: 'City',
                  controller: controllers.city,
                  icon: Icons.location_city_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputField(
                  label: 'State (optional)',
                  controller: controllers.state,
                  icon: Icons.map_outlined,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _InputField(
            label: 'Pincode (optional)',
            controller: controllers.pincode,
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
          ).animate().fadeIn(delay: 220.ms, duration: 400.ms),
          const SizedBox(height: 14),

          _InputField(
            label: 'Password',
            controller: controllers.pass,
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePass,
            validator: Validators.password,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onTogglePass,
            ),
          ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
          const SizedBox(height: 14),

          _InputField(
            label: 'Confirm Password',
            controller: controllers.confirm,
            icon: Icons.lock_outline_rounded,
            obscureText: obscureConfirm,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != controllers.pass.text) return 'Passwords do not match';
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onToggleConfirm,
            ),
            onFieldSubmitted: (_) => onSubmit(),
          ).animate().fadeIn(delay: 260.ms, duration: 400.ms),
          const SizedBox(height: 28),

          _GradientButton(
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
            label: 'Create Account',
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.15, end: 0),

          const SizedBox(height: 20),

          Center(
            child: TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Already have an account? ',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: 'Sign In',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 340.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Role chip ─────────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  final double size;
  const _LogoBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: ClipOval(
        child: Image.asset(
          'assets/images/kle_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double? top, bottom, left, right;
  final double alpha;

  const _Circle({
    required this.size,
    required this.alpha,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onFieldSubmitted;

  const _InputField({
    required this.label,
    required this.controller,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppColors.primaryGradient,
        color: onPressed == null ? AppColors.textHint : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.40),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                  color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
