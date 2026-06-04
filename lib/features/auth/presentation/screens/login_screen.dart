import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';

// ── Breakpoints ───────────────────────────────────────────────────────────────
const double _kTabletBreak  = 600;   // single-col centered card
const double _kDesktopBreak = 900;   // two-col split layout

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool  _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      email:       _emailCtrl.text.trim(),
      password:    _passCtrl.text,
      allowedRole: 'patient',   // only patients; nurses and admins are blocked
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;
    final error     = authState.valueOrNull?.error;

    ref.listen(authProvider, (_, next) {
      final user = next.valueOrNull?.user;
      if (user != null) {
        if (user.role == 'patient') {
          context.go('/patient');
        }
        // nurses and admins are blocked by the role gate in the notifier;
        // no other role should reach here.
      }
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return width >= _kDesktopBreak
          ? _DesktopLayout(
              formKey:   _formKey,
              emailCtrl: _emailCtrl,
              passCtrl:  _passCtrl,
              obscure:   _obscure,
              isLoading: isLoading,
              error:     error,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit:  _submit,
              onRegister: () => context.go('/register'),
              onAdminLogin: () => context.go('/admin-login'),
              onNurseLogin: () => context.go('/nurse-login'),
            )
          : _MobileLayout(
              formKey:   _formKey,
              emailCtrl: _emailCtrl,
              passCtrl:  _passCtrl,
              obscure:   _obscure,
              isLoading: isLoading,
              error:     error,
              isTablet:  width >= _kTabletBreak,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit:  _submit,
              onRegister: () => context.go('/register'),
              onAdminLogin: () => context.go('/admin-login'),
              onNurseLogin: () => context.go('/nurse-login'),
            );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESKTOP LAYOUT  (≥ 900px)
// Left panel: branded gradient  |  Right panel: white form
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool   obscure;
  final bool   isLoading;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onRegister;
  final VoidCallback onAdminLogin;
  final VoidCallback onNurseLogin;

  const _DesktopLayout({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLoading,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onRegister,
    required this.onAdminLogin,
    required this.onNurseLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // ── Left branded panel ─────────────────────────────────────────────
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1A237E)],
                stops:  [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
                _Circle(size: 320, top: -80,  right: -80,  alpha: 0.07),
                _Circle(size: 200, bottom: -60, left: -60, alpha: 0.06),
                _Circle(size: 140, top: 200,  left: -40,   alpha: 0.05),
                _Circle(size: 100, bottom: 120, right: 60, alpha: 0.04),

                // Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 44, vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // KLES logo in white card
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color:        Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color:      Colors.black.withValues(alpha: 0.20),
                                blurRadius: 24,
                                offset:     const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/kle_logo.png',
                            height: 60,
                            fit:    BoxFit.contain,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 700.ms)
                            .scale(begin: const Offset(0.85, 0.85)),

                        const SizedBox(height: 28),

                        // Tagline
                        Text(
                          'Quality Care at Your Doorstep',
                          style: GoogleFonts.poppins(
                            color:         Colors.white,
                            fontSize:      18,
                            fontWeight:    FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                        const SizedBox(height: 6),
                        Text(
                          AppStrings.appTagline,
                          style: GoogleFonts.poppins(
                            color:    Colors.white.withValues(alpha: 0.60),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                        const SizedBox(height: 40),

                        // Feature rows
                        ...[
                          (Icons.home_outlined,            'Home Healthcare Services'),
                          (Icons.assignment_ind_outlined, 'Certified Nursing Staff'),
                          (Icons.schedule_rounded,        '24/7 Patient Support'),
                        ].asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FeaturePill(
                            icon:  e.value.$1,
                            label: e.value.$2,
                          ).animate()
                              .fadeIn(delay: (350 + e.key * 100).ms, duration: 500.ms)
                              .slideX(begin: -0.12, end: 0),
                        )),

                        const SizedBox(height: 32),

                        // Divider
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.15),
                        ).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 20),

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatPill('200+', 'Patients'),
                            _StatPill('50+',  'Nurses'),
                            _StatPill('24/7', 'Support'),
                          ],
                        ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Right form panel ───────────────────────────────────────────────
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 48),
                  child: _LoginForm(
                    formKey:         formKey,
                    emailCtrl:       emailCtrl,
                    passCtrl:        passCtrl,
                    obscure:         obscure,
                    isLoading:       isLoading,
                    error:           error,
                    onToggleObscure: onToggleObscure,
                    onSubmit:        onSubmit,
                    onRegister:      onRegister,
                    onAdminLogin:    onAdminLogin,
                    onNurseLogin:    onNurseLogin,
                    isDesktop:       true,
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

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE / TABLET LAYOUT  (< 900px)
// Full gradient background + centered card
// ─────────────────────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool   obscure;
  final bool   isLoading;
  final bool   isTablet;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onRegister;
  final VoidCallback onAdminLogin;
  final VoidCallback onNurseLogin;

  const _MobileLayout({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLoading,
    required this.isTablet,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onRegister,
    required this.onAdminLogin,
    required this.onNurseLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin:  Alignment.topLeft,
              end:    Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1A237E)],
              stops:  [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Decorative circles
        _Circle(size: 220, top: -60,    right: -60,   alpha: 0.06),
        _Circle(size: 280, bottom: -80, left: -60,    alpha: 0.05),
        _Circle(size: 120, top: 200,    left: -40,    alpha: 0.04),

        // Content
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              // Tablet: narrower card, phone: full width with padding
              constraints: BoxConstraints(
                maxWidth: isTablet ? 480 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 0 : 24,
                  vertical:   24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isTablet ? 40 : 32),

                    // Logo + wordmark
                    Column(
                      children: [
                        _LogoBadge(size: isTablet ? 90 : 80)
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(begin: const Offset(0.8, 0.8)),
                        const SizedBox(height: 14),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: 'KLE ',
                              style: GoogleFonts.poppins(
                                color:         Colors.white,
                                fontSize:      isTablet ? 28 : 24,
                                fontWeight:    FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                            ),
                            TextSpan(
                              text: 'HOMECARE',
                              style: GoogleFonts.poppins(
                                color:         Colors.white.withValues(alpha: 0.85),
                                fontSize:      isTablet ? 28 : 24,
                                fontWeight:    FontWeight.w400,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ]),
                        ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.appTagline,
                          style: GoogleFonts.poppins(
                            color:    Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                      ],
                    ),

                    SizedBox(height: isTablet ? 36 : 28),

                    // Form card
                    Container(
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset:     const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(isTablet ? 32 : 24),
                      child: _LoginForm(
                        formKey:         formKey,
                        emailCtrl:       emailCtrl,
                        passCtrl:        passCtrl,
                        obscure:         obscure,
                        isLoading:       isLoading,
                        error:           error,
                        onToggleObscure: onToggleObscure,
                        onSubmit:        onSubmit,
                        onRegister:      onRegister,
                        onAdminLogin:    onAdminLogin,
                        onNurseLogin:    onNurseLogin,
                        isDesktop:       false,
                      ),
                    ).animate()
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared login form — used by both layouts
// ─────────────────────────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool   obscure;
  final bool   isLoading;
  final bool   isDesktop;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onRegister;
  final VoidCallback onAdminLogin;
  final VoidCallback onNurseLogin;

  const _LoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLoading,
    required this.isDesktop,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onRegister,
    required this.onAdminLogin,
    required this.onNurseLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo (desktop only — already shown on left panel on mobile)
          if (isDesktop) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Image.asset(
                  'assets/images/kle_logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 24),
          ],

          // Title
          Text(
            'Welcome Back',
            style: GoogleFonts.poppins(
              fontSize:   isDesktop ? 24 : 22,
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Sign in to your patient account',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color:    AppColors.textSecondary,
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

          // Email
          _InputField(
            label:        'Email Address',
            controller:   emailCtrl,
            validator:    Validators.email,
            icon:         Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms)
              .slideX(begin: -0.08, end: 0),

          const SizedBox(height: 16),

          // Password
          _InputField(
            label:       'Password',
            controller:  passCtrl,
            validator:   (v) =>
                v == null || v.isEmpty ? 'Password is required' : null,
            icon:        Icons.lock_outline_rounded,
            obscureText: obscure,
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size:  20,
              ),
              onPressed: onToggleObscure,
            ),
            onFieldSubmitted: (_) => onSubmit(),
          ).animate().fadeIn(delay: 180.ms, duration: 400.ms)
              .slideX(begin: -0.08, end: 0),

          const SizedBox(height: 28),

          // Login button
          _GradientButton(
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
            label:     AppStrings.login,
          ).animate().fadeIn(delay: 260.ms, duration: 400.ms)
              .slideY(begin: 0.15, end: 0),

          const SizedBox(height: 20),

          // Register link
          Center(
            child: TextButton(
              onPressed: onRegister,
              style: TextButton.styleFrom(
                foregroundColor: isDesktop
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        color:    isDesktop
                            ? AppColors.textSecondary
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: 'Register',
                      style: GoogleFonts.poppins(
                        color:      AppColors.primary,
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 320.ms, duration: 400.ms),

          // Nurse + Admin login links — discreet, side by side at the bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onNurseLogin,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        size: 13, color: AppColors.nurseColor),
                    const SizedBox(width: 4),
                    Text('Resource Login',
                        style: GoogleFonts.poppins(
                          color:      AppColors.nurseColor,
                          fontSize:   11,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 14,
                color: AppColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              TextButton(
                onPressed: onAdminLogin,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text('Admin Login',
                        style: GoogleFonts.poppins(
                          color:      AppColors.textHint,
                          fontSize:   11,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(delay: 380.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

/// KLE logo badge — shows the real KLES hospital logo
class _LogoBadge extends StatelessWidget {
  final double size;
  const _LogoBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset:     const Offset(0, 8),
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

/// Feature pill shown on the desktop left panel
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color:      Colors.white.withValues(alpha: 0.90),
                fontSize:   12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: Colors.white.withValues(alpha: 0.40), size: 14),
        ],
      ),
    );
  }
}

/// Stat pill on bottom of left panel
class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
              color:      Colors.white,
              fontSize:   20,
              fontWeight: FontWeight.w800,
            )),
        Text(label,
            style: GoogleFonts.poppins(
              color:    Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}

/// Decorative background circle
class _Circle extends StatelessWidget {
  final double  size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double  alpha;

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
      top:    top,
      bottom: bottom,
      left:   left,
      right:  right,
      child: Container(
        width:  size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
    );
  }
}

/// Text input field
class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final IconData icon;
  final bool   obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onFieldSubmitted;

  const _InputField({
    required this.label,
    required this.controller,
    required this.icon,
    this.validator,
    this.obscureText       = false,
    this.suffixIcon,
    this.keyboardType      = TextInputType.text,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:       controller,
      validator:        validator,
      obscureText:      obscureText,
      keyboardType:     keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.poppins(
        fontSize:   14,
        color:      AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color:    AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}

/// Gradient login button with hover effect
class _GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool   isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
      height: 50,
      decoration: BoxDecoration(
        gradient: widget.onPressed == null ? null : AppColors.primaryGradient,
        color:    widget.onPressed == null ? AppColors.textHint : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: widget.onPressed == null
            ? []
            : [
                BoxShadow(
                  color:      AppColors.primary.withValues(
                      alpha: _hovered ? 0.55 : 0.30),
                  blurRadius: _hovered ? 20 : 12,
                  offset:     const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap:        widget.onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width:  22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          color:         Colors.white,
                          fontSize:      14,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 180),
                        offset: _hovered
                            ? const Offset(0.3, 0)
                            : Offset.zero,
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 16),
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

/// Error banner
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.08),
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
