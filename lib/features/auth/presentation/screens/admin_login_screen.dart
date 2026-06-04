import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';

const double _kDesktopBreak = 900;
const double _kTabletBreak  = 600;

// Admin gradient — purple
const _kGrad = LinearGradient(
  begin: Alignment.topLeft,
  end:   Alignment.bottomRight,
  colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A), Color(0xFF4A148C)],
);

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure   = true;

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
      allowedRole: 'admin',   // only admin accounts allowed here
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;
    final error     = authState.valueOrNull?.error;

    // Redirect after successful admin login
    ref.listen(authProvider, (_, next) {
      final user = next.valueOrNull?.user;
      if (user != null && user.role == 'admin') {
        context.go('/admin');
      } else if (user != null) {
        // Non-admin tried to use admin login — log them out
        ref.read(authProvider.notifier).logout();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Access denied. Admin accounts only.',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return width >= _kDesktopBreak
          ? _DesktopLayout(
              formKey: _formKey, emailCtrl: _emailCtrl, passCtrl: _passCtrl,
              obscure: _obscure, isLoading: isLoading, error: error,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
            )
          : _MobileLayout(
              formKey: _formKey, emailCtrl: _emailCtrl, passCtrl: _passCtrl,
              obscure: _obscure, isLoading: isLoading, error: error,
              isTablet: width >= _kTabletBreak,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
            );
        },
      ),
    );
  }
}

// ── Desktop layout ────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscure, isLoading;
  final String? error;
  final VoidCallback onToggleObscure, onSubmit;

  const _DesktopLayout({
    required this.formKey, required this.emailCtrl, required this.passCtrl,
    required this.obscure, required this.isLoading, required this.error,
    required this.onToggleObscure, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left branded panel ─────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(gradient: _kGrad),
              child: Stack(
                children: [
                  _Bubble(size: 340, top: -90,    right: -90,  alpha: 0.07),
                  _Bubble(size: 220, bottom: -70, left:  -70,  alpha: 0.06),
                  _Bubble(size: 150, top:  220,   left:  -50,  alpha: 0.05),
                  _Bubble(size: 100, bottom: 140, right:  60,  alpha: 0.04),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo card
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 28, offset: const Offset(0, 10),
                              )],
                            ),
                            child: Image.asset('assets/images/kle_logo.png',
                                height: 64, fit: BoxFit.contain),
                          ).animate()
                              .fadeIn(duration: 700.ms)
                              .scale(begin: const Offset(0.85, 0.85)),
                          const SizedBox(height: 28),
                          Text('KLE HOMECARE',
                              style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 26,
                                fontWeight: FontWeight.w800, letterSpacing: 2,
                              )).animate().fadeIn(delay: 150.ms),
                          const SizedBox(height: 6),
                          Text('Admin Portal',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13, letterSpacing: 1,
                              )).animate().fadeIn(delay: 220.ms),
                          const SizedBox(height: 40),
                          ...[
                            (Icons.admin_panel_settings_outlined, 'Full System Control'),
                            (Icons.people_outline_rounded,        'Manage Patients & Nurses'),
                            (Icons.bar_chart_rounded,             'Dashboard & Analytics'),
                            (Icons.assignment_ind_outlined,       'Assign & Track Cases'),
                          ].asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FeatureTile(
                                    icon: e.value.$1, label: e.value.$2)
                                .animate()
                                .fadeIn(delay: (300 + e.key * 90).ms,
                                    duration: 500.ms)
                                .slideX(begin: -0.12, end: 0),
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
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 48),
                    child: _AdminLoginForm(
                      formKey: formKey, emailCtrl: emailCtrl,
                      passCtrl: passCtrl, obscure: obscure,
                      isLoading: isLoading, error: error, isDesktop: true,
                      onToggleObscure: onToggleObscure, onSubmit: onSubmit,
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

// ── Mobile / tablet layout ────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscure, isLoading, isTablet;
  final String? error;
  final VoidCallback onToggleObscure, onSubmit;

  const _MobileLayout({
    required this.formKey, required this.emailCtrl, required this.passCtrl,
    required this.obscure, required this.isLoading, required this.isTablet,
    required this.error, required this.onToggleObscure, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: const BoxDecoration(gradient: _kGrad)),
        _Bubble(size: 240, top: -60,    right: -60,  alpha: 0.06),
        _Bubble(size: 300, bottom: -80, left:  -60,  alpha: 0.05),
        _Bubble(size: 130, top:  200,   left:  -40,  alpha: 0.04),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: isTablet ? 480 : double.infinity),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 0 : 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isTablet ? 40 : 28),
                    // Logo + title
                    Column(children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 20, offset: const Offset(0, 8),
                          )],
                        ),
                        child: ClipOval(child: Image.asset(
                          'assets/images/kle_logo.png',
                          width: isTablet ? 70 : 60, fit: BoxFit.contain,
                        )),
                      ).animate().fadeIn(duration: 600.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 14),
                      Text('KLE HOMECARE',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isTablet ? 26 : 22,
                            fontWeight: FontWeight.w800, letterSpacing: 2,
                          )).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 4),
                      Text('Admin Portal',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          )).animate().fadeIn(delay: 200.ms),
                    ]),
                    SizedBox(height: isTablet ? 32 : 24),
                    // Form card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30, offset: const Offset(0, 10),
                        )],
                      ),
                      padding: EdgeInsets.all(isTablet ? 32 : 24),
                      child: _AdminLoginForm(
                        formKey: formKey, emailCtrl: emailCtrl,
                        passCtrl: passCtrl, obscure: obscure,
                        isLoading: isLoading, error: error, isDesktop: false,
                        onToggleObscure: onToggleObscure, onSubmit: onSubmit,
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

// ── Admin login form ──────────────────────────────────────────────────────────
class _AdminLoginForm extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscure, isLoading, isDesktop;
  final String? error;
  final VoidCallback onToggleObscure, onSubmit;

  const _AdminLoginForm({
    required this.formKey, required this.emailCtrl, required this.passCtrl,
    required this.obscure, required this.isLoading, required this.isDesktop,
    required this.error, required this.onToggleObscure, required this.onSubmit,
  });

  @override
  ConsumerState<_AdminLoginForm> createState() => _AdminLoginFormState();
}

class _AdminLoginFormState extends ConsumerState<_AdminLoginForm> {
  bool _showForgotPassword = false;
  final _resetEmailCtrl = TextEditingController();
  bool  _resetSent      = false;

  @override
  void dispose() {
    _resetEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showForgotPassword
          ? _buildForgotPassword()
          : _buildLoginForm(),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Admin badge
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.adminGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin Access',
                  style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              Text('Restricted to administrators only',
                  style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary,
                  )),
            ]),
          ]).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Error banner
          if (widget.error != null) ...[
            _ErrorBanner(message: widget.error!)
                .animate().fadeIn(duration: 300.ms).shake(duration: 400.ms),
            const SizedBox(height: 14),
          ],

          // Email
          _AdminInputField(
            label: 'Admin Email', controller: widget.emailCtrl,
            icon: Icons.alternate_email_rounded,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
          ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
          const SizedBox(height: 14),

          // Password
          _AdminInputField(
            label: 'Password', controller: widget.passCtrl,
            icon: Icons.lock_outline_rounded,
            obscureText: widget.obscure,
            validator: (v) =>
                v == null || v.isEmpty ? 'Password is required' : null,
            suffixIcon: IconButton(
              icon: Icon(
                widget.obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary, size: 20,
              ),
              onPressed: widget.onToggleObscure,
            ),
            onFieldSubmitted: (_) => widget.onSubmit(),
          ).animate().fadeIn(delay: 140.ms, duration: 400.ms),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _showForgotPassword = true),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.adminColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4)),
              child: Text('Forgot password?',
                  style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.adminColor,
                  )),
            ),
          ).animate().fadeIn(delay: 180.ms, duration: 400.ms),

          const SizedBox(height: 8),

          // Login button
          _AdminButton(
            onPressed: widget.isLoading ? null : widget.onSubmit,
            isLoading: widget.isLoading,
            label: 'Sign In as Admin',
            icon: Icons.login_rounded,
          ).animate().fadeIn(delay: 220.ms, duration: 400.ms)
              .slideY(begin: 0.15, end: 0),

          const SizedBox(height: 20),

          // Security note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.adminColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.adminColor.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              Icon(Icons.security_rounded,
                  size: 14, color: AppColors.adminColor),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'This portal is restricted to authorised administrators.',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.adminColor),
              )),
            ]),
          ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back button
        Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColors.adminColor),
            onPressed: () => setState(() {
              _showForgotPassword = false;
              _resetSent = false;
              _resetEmailCtrl.clear();
            }),
          ),
          Text('Reset Password',
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
        ]).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 8),

        if (_resetSent) ...[
          // Success state
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.30)),
            ),
            child: Column(children: [
              const Icon(Icons.mark_email_read_rounded,
                  color: AppColors.success, size: 48),
              const SizedBox(height: 12),
              Text('Reset link sent!',
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 6),
              Text(
                'Check your email inbox for the password reset link.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ]),
          ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => setState(() {
              _showForgotPassword = false;
              _resetSent = false;
              _resetEmailCtrl.clear();
            }),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.adminColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('Back to Login',
                style: GoogleFonts.poppins(
                    color: AppColors.adminColor,
                    fontWeight: FontWeight.w600)),
          ),
        ] else ...[
          // Reset form
          Text(
            'Enter your admin email address and we will send you a link to reset your password.',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
          ).animate().fadeIn(delay: 50.ms),
          const SizedBox(height: 20),
          _AdminInputField(
            label: 'Admin Email', controller: _resetEmailCtrl,
            icon: Icons.alternate_email_rounded,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
          ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
          const SizedBox(height: 20),
          _AdminButton(
            onPressed: () {
              // In production this would call an API endpoint.
              // For now, simulate the success state.
              if (_resetEmailCtrl.text.trim().isNotEmpty) {
                setState(() => _resetSent = true);
              }
            },
            isLoading: false,
            label: 'Send Reset Link',
            icon: Icons.send_rounded,
          ).animate().fadeIn(delay: 140.ms, duration: 400.ms),
        ],
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _FeatureTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.90),
              fontSize: 12, fontWeight: FontWeight.w500,
            ))),
        Icon(Icons.check_circle_rounded,
            color: Colors.white.withValues(alpha: 0.35), size: 14),
      ]),
    );
  }
}

class _AdminInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onFieldSubmitted;

  const _AdminInputField({
    required this.label, required this.controller, required this.icon,
    this.validator, this.obscureText = false, this.suffixIcon,
    this.keyboardType = TextInputType.text, this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, validator: validator,
      obscureText: obscureText, keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.adminColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.adminColor, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _AdminButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final IconData icon;

  const _AdminButton({
    required this.onPressed, required this.isLoading,
    required this.label, required this.icon,
  });

  @override
  State<_AdminButton> createState() => _AdminButtonState();
}

class _AdminButtonState extends State<_AdminButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    return MouseRegion(
      cursor: enabled
          ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.adminGradient : null,
          color: enabled ? null : AppColors.textHint,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled ? [BoxShadow(
            color: AppColors.adminColor.withValues(
                alpha: _hovered ? 0.55 : 0.30),
            blurRadius: _hovered ? 20 : 12,
            offset: const Offset(0, 6),
          )] : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(widget.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(widget.label,
                          style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final double? top, bottom, left, right;
  final double alpha;

  const _Bubble({required this.size, required this.alpha,
      this.top, this.bottom, this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
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
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
            style: GoogleFonts.poppins(
                color: AppColors.error, fontSize: 12))),
      ]),
    );
  }
}
