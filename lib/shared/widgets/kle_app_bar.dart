import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// KLE HOMECARE — Branded AppBar with gradient background
///
/// Left side  : KLE logo badge + "HOMECARE" wordmark
/// Right side : caller-supplied [actions]
/// [subtitle] : optional small text below the wordmark (role label)
/// [gradient] : gradient override — defaults to role-appropriate gradient
/// [showBack] : show back arrow instead of logo (sub-screens)
class KleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color         roleColor;
  final LinearGradient? gradient;
  final String?       subtitle;
  final List<Widget>  actions;
  final bool          showBack;
  final VoidCallback? onBack;
  final String?       backTitle;

  const KleAppBar({
    super.key,
    this.roleColor  = AppColors.primary,
    this.gradient,
    this.subtitle,
    this.actions    = const [],
    this.showBack   = false,
    this.onBack,
    this.backTitle,
  });

  const KleAppBar.back({
    super.key,
    required String title,
    this.roleColor  = AppColors.primary,
    this.gradient,
    this.actions    = const [],
    this.onBack,
  })  : showBack  = true,
        backTitle = title,
        subtitle  = null;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  LinearGradient _resolveGradient() {
    if (gradient != null) return gradient!;
    if (roleColor == AppColors.adminColor) return AppColors.adminGradient;
    if (roleColor == AppColors.nurseColor) return AppColors.nurseGradient;
    return AppColors.primaryGradient;
  }

  @override
  Widget build(BuildContext context) {
    final grad = _resolveGradient();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness:     Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: grad,
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kToolbarHeight + 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // ── Leading ───────────────────────────────────────────
                  if (showBack)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                    )
                  else
                    const SizedBox(width: 4),

                  // ── KLE logo badge ────────────────────────────────────
                  if (!showBack) ...[
                    _KleBadge(roleColor: roleColor),
                    const SizedBox(width: 10),
                  ],

                  // ── Title / wordmark ──────────────────────────────────
                  Expanded(
                    child: showBack && backTitle != null
                        ? Text(
                            backTitle!,
                            style: GoogleFonts.poppins(
                              color:      Colors.white,
                              fontSize:   17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'KLE ',
                                      style: GoogleFonts.poppins(
                                        color:       Colors.white,
                                        fontSize:    17,
                                        fontWeight:  FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'HOMECARE',
                                      style: GoogleFonts.poppins(
                                        color:       Colors.white.withValues(alpha: 0.9),
                                        fontSize:    17,
                                        fontWeight:  FontWeight.w400,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: GoogleFonts.poppins(
                                    color:       Colors.white.withValues(alpha: 0.70),
                                    fontSize:    10,
                                    fontWeight:  FontWeight.w500,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                            ],
                          ),
                  ),

                  // ── Actions ───────────────────────────────────────────
                  ...actions,
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── KLE logo badge ─────────────────────────────────────────────────────────────
class _KleBadge extends StatelessWidget {
  final Color roleColor;
  const _KleBadge({required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.20),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: Image.asset(
          'assets/images/kle_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
