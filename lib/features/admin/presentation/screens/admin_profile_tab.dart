import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/kle_app_bar.dart';
import '../../../../shared/screens/server_settings_screen.dart';

class AdminProfileTab extends ConsumerStatefulWidget {
  const AdminProfileTab({super.key});

  @override
  ConsumerState<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends ConsumerState<AdminProfileTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProfileProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(adminProfileProvider);
    final authState    = ref.watch(authProvider);
    final user         = authState.valueOrNull?.user;
    final isDesktop    = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : KleAppBar(
        roleColor: AppColors.adminColor,
        subtitle:  'Admin Panel',
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── Gradient hero header ──────────────────────────────
                  _ProfileHero(
                    user:       user,
                    profileMap: profileState.profile,
                    isDesktop:  isDesktop,
                  ),

                  // ── Body content ──────────────────────────────────────
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            isDesktop ? 32 : 16, 24,
                            isDesktop ? 32 : 16, 40),
                        child: Column(
                          children: [
                            // Account info
                            _SectionCard(
                              title: 'Account Information',
                              icon:  Icons.manage_accounts_rounded,
                              color: AppColors.adminColor,
                              children: [
                                _InfoRow(
                                  icon:  Icons.email_outlined,
                                  label: 'Email',
                                  value: user?.email ?? '—',
                                  color: AppColors.adminColor,
                                ),
                                _InfoRow(
                                  icon:  Icons.badge_outlined,
                                  label: 'Role',
                                  value: 'Administrator',
                                  color: const Color(0xFF8E24AA),
                                ),
                                _InfoRow(
                                  icon:  Icons.fingerprint_rounded,
                                  label: 'User ID',
                                  value: _shortId(profileState.profile?['id'] ?? ''),
                                  color: AppColors.textSecondary,
                                  isLast: true,
                                ),
                              ],
                            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 16),

                            // Quick actions
                            _SectionCard(
                              title: 'Quick Actions',
                              icon:  Icons.flash_on_rounded,
                              color: const Color(0xFFF57F17),
                              children: [
                                _ActionRow(
                                  icon:    Icons.lock_reset_rounded,
                                  label:   'Reset Password',
                                  sub:     'Change your account password',
                                  color:   AppColors.primary,
                                  onTap:   () => _showResetPasswordSheet(context),
                                ),
                                _ActionRow(
                                  icon:    Icons.edit_rounded,
                                  label:   'Update Profile',
                                  sub:     'Edit your display name',
                                  color:   AppColors.adminColor,
                                  onTap:   () => _showUpdateProfileSheet(context, user?.fullName ?? ''),
                                ),
                                _ActionRow(
                                  icon:    Icons.dns_rounded,
                                  label:   'Server Settings',
                                  sub:     'Change backend / ngrok URL',
                                  color:   const Color(0xFF00897B),
                                  onTap:   () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const ServerSettingsScreen())),
                                ),
                                _ActionRow(
                                  icon:    Icons.logout_rounded,
                                  label:   'Logout',
                                  sub:     'Sign out of your account',
                                  color:   AppColors.error,
                                  onTap:   () => _confirmLogout(context),
                                  isLast:  true,
                                ),
                              ],
                            ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1, end: 0),

                            // Messages
                            if (profileState.successMessage != null) ...[
                              const SizedBox(height: 16),
                              _Banner(profileState.successMessage!, AppColors.success)
                                  .animate().fadeIn().shake(),
                            ],
                            if (profileState.error != null) ...[
                              const SizedBox(height: 16),
                              _Banner(profileState.error!, AppColors.error)
                                  .animate().fadeIn().shake(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showResetPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResetPasswordSheet(
        onSave: (current, newPass) async =>
            ref.read(adminProfileProvider.notifier)
               .resetPassword(currentPassword: current, newPassword: newPass),
      ),
    );
  }

  void _showUpdateProfileSheet(BuildContext context, String currentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateProfileSheet(currentName: currentName),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Logout'),
        ]),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      context.go('/admin-login');
    }
  }

  String _shortId(String id) =>
      id.length > 14 ? '${id.substring(0, 14)}…' : id;
}

// ── Profile hero header ───────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final dynamic user;
  final Map<String, dynamic>? profileMap;
  final bool isDesktop;

  const _ProfileHero({required this.user, required this.profileMap, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Administrator';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.adminGradient,
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(top: -30,    right: -30,   child: _BgCircle(100, 0.07)),
          Positioned(bottom: -20, left:  -20,   child: _BgCircle(80,  0.05)),
          Positioned(top: 20,     left:  80,    child: _BgCircle(50,  0.04)),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
                isDesktop ? 40 : 20, 32,
                isDesktop ? 40 : 20, 28),
            child: isDesktop
                ? Row(
                    children: [
                      _AvatarWidget(name: name, size: 72),
                      const SizedBox(width: 24),
                      _NameBlock(name: name, email: user?.email ?? ''),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _AvatarWidget(name: name, size: 64),
                      const SizedBox(height: 14),
                      _NameBlock(name: name, email: user?.email ?? '', center: true),
                    ],
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _AvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  const _AvatarWidget({required this.name, required this.size});

  String _initials(String n) {
    final p = n.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : n.isNotEmpty ? n[0].toUpperCase() : 'A';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape:       BoxShape.circle,
        color:       Colors.white.withValues(alpha: 0.20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.50), width: 2.5),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.20),
            blurRadius: 16,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: GoogleFonts.poppins(
            fontSize:   size * 0.32,
            fontWeight: FontWeight.w800,
            color:      Colors.white,
          ),
        ),
      ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  final String name;
  final String email;
  final bool   center;
  const _NameBlock({required this.name, required this.email, this.center = false});

  @override
  Widget build(BuildContext context) {
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(name,
            style: GoogleFonts.poppins(
              color:      Colors.white,
              fontSize:   22,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 3),
        Text(email,
            style: GoogleFonts.poppins(
              color:    Colors.white.withValues(alpha: 0.70),
              fontSize: 12,
            )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:        Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  size: 12, color: Colors.white),
              const SizedBox(width: 5),
              Text('Administrator',
                  style: GoogleFonts.poppins(
                    color:      Colors.white,
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _BgCircle extends StatelessWidget {
  final double size;
  final double alpha;
  const _BgCircle(this.size, this.alpha);

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

// ── Section card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final Color        color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.textPrimary,
                  )),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final bool     isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width:  32, height: 32,
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color:    AppColors.textSecondary,
                        )),
                    Text(value,
                        style: GoogleFonts.poppins(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      AppColors.textPrimary,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 60, color: AppColors.divider),
      ],
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────
class _ActionRow extends StatefulWidget {
  final IconData     icon;
  final String       label;
  final String       sub;
  final Color        color;
  final VoidCallback onTap;
  final bool         isLast;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MouseRegion(
          cursor:  SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit:  (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              color: _hovered
                  ? widget.color.withValues(alpha: 0.04)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width:  36, height: 36,
                    decoration: BoxDecoration(
                      color:        widget.color.withValues(
                          alpha: _hovered ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, size: 16, color: widget.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.label,
                            style: GoogleFonts.poppins(
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                              color:      widget.color,
                            )),
                        Text(widget.sub,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color:    AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 150),
                    offset: _hovered ? const Offset(0.15, 0) : Offset.zero,
                    child: Icon(Icons.chevron_right_rounded,
                        size: 18, color: widget.color.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!widget.isLast)
          const Divider(height: 1, indent: 64, color: AppColors.divider),
      ],
    );
  }
}

// ── Banner ────────────────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  final String message;
  final Color  color;
  const _Banner(this.message, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            color == AppColors.success
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: color, size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.poppins(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Reset password sheet ──────────────────────────────────────────────────────
class _ResetPasswordSheet extends StatefulWidget {
  final Future<bool> Function(String current, String newPass) onSave;
  const _ResetPasswordSheet({required this.onSave});

  @override
  State<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<_ResetPasswordSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCur   = true;
  bool _obscureNew   = true;
  bool _obscureCon   = true;
  bool _isLoading    = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await widget.onSave(_currentCtrl.text, _newCtrl.text);
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Password updated!' : 'Failed to update password.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.adminGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Reset Password',
                    style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),
              _PassField(label: 'Current Password', ctrl: _currentCtrl,
                  obscure: _obscureCur,
                  onToggle: () => setState(() => _obscureCur = !_obscureCur),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
              const SizedBox(height: 12),
              _PassField(label: 'New Password', ctrl: _newCtrl,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: Validators.password),
              const SizedBox(height: 12),
              _PassField(label: 'Confirm Password', ctrl: _confirmCtrl,
                  obscure: _obscureCon,
                  onToggle: () => setState(() => _obscureCon = !_obscureCon),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _newCtrl.text) return 'Passwords do not match';
                    return null;
                  }),
              const SizedBox(height: 20),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: _isLoading ? null : AppColors.adminGradient,
                  color: _isLoading ? AppColors.textHint : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isLoading ? null : _submit,
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Update Password',
                              style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 14,
                                fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PassField({
    required this.label,
    required this.ctrl,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:  ctrl,
      obscureText: obscure,
      validator:   validator,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ── Update profile sheet ──────────────────────────────────────────────────────
class _UpdateProfileSheet extends StatefulWidget {
  final String currentName;
  const _UpdateProfileSheet({required this.currentName});

  @override
  State<_UpdateProfileSheet> createState() => _UpdateProfileSheetState();
}

class _UpdateProfileSheetState extends State<_UpdateProfileSheet> {
  late final _nameCtrl = TextEditingController(text: widget.currentName);

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.adminGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Update Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText:  'Full Name',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient:     AppColors.adminGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Profile updated!',
                          style: GoogleFonts.poppins(color: Colors.white)),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                  child: Center(
                    child: Text('Save Changes',
                        style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
