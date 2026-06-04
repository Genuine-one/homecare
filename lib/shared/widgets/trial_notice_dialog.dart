import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

// ── Session key ───────────────────────────────────────────────────────────────
const _kTrialShownKey = 'trial_notice_shown';

/// Call once on app logout to reset the flag so the notice re-appears on the
/// next login.
Future<void> clearTrialNoticeFlag() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kTrialShownKey);
}

/// KLE HOMECARE — IntelliCraft Trial Notice
///
/// Shows once per login session.  On logout call [clearTrialNoticeFlag] so the
/// dialog reappears after the next sign-in.
///
/// Usage from a shell's initState:
/// ```dart
/// WidgetsBinding.instance.addPostFrameCallback((_) {
///   if (mounted) TrialNoticeDialog.showIfNeeded(context);
/// });
/// ```
class TrialNoticeDialog {
  TrialNoticeDialog._();

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_kTrialShownKey) ?? false;
    if (alreadyShown) return;

    await prefs.setBool(_kTrialShownKey, true);

    if (!context.mounted) return;
    _openDialog(context);
  }

  static void _openDialog(BuildContext context) {
    // Use a Navigator.push with an opaque-overlay route so the scrim is
    // guaranteed to paint on all platforms including Flutter Web.
    Navigator.of(context, rootNavigator: true).push(
      _TrialNoticeRoute(),
    );
  }
}

// ── Custom page route — full-screen overlay ───────────────────────────────────
class _TrialNoticeRoute extends PageRoute<void> {
  _TrialNoticeRoute()
      : super(settings: const RouteSettings(name: 'trial-notice'));

  @override
  bool get opaque => false;          // let the page below show through

  @override
  bool get maintainState => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'trial-notice';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return const _TrialNoticeWidget();
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isWide  = screenW >= 520;

    final fade  = FadeTransition(opacity: animation, child: child);

    if (isWide) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: fade,
      );
    } else {
      // Slide up from bottom for mobile
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end:   Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: fade,
      );
    }
  }
}

// ── Root widget ───────────────────────────────────────────────────────────────
class _TrialNoticeWidget extends StatelessWidget {
  const _TrialNoticeWidget();

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isWide  = screenW >= 520;

    return Scaffold(
      // Transparent scaffold — the route's barrierColor paints the scrim
      backgroundColor: Colors.transparent,
      body: isWide ? _desktopLayout(context) : _mobileLayout(context),
    );
  }

  Widget _desktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Material(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            elevation:    24,
            shadowColor:  Colors.black45,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _DialogCard(
                onClose: () => Navigator.of(context).pop(),
                compact: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color:        AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        elevation:    24,
        shadowColor:  Colors.black45,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
              maxWidth:  double.infinity,
            ),
            child: _DialogCard(
              onClose: () => Navigator.of(context).pop(),
              compact: true,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared card body ──────────────────────────────────────────────────────────
class _DialogCard extends StatelessWidget {
  final VoidCallback onClose;
  final bool         compact;

  const _DialogCard({required this.onClose, required this.compact});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // Explicit opaque background so nothing bleeds through
      color: AppColors.surface,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle (mobile only) ────────────────────────────
            if (compact)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width:  40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:        AppColors.textHint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            // ── Gradient header ──────────────────────────────────────
            Container(
              width:   double.infinity,
              padding: EdgeInsets.fromLTRB(
                  24, compact ? 20 : 28, 24, compact ? 18 : 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF4A148C)],
                ),
              ),
              child: Column(
                children: [
                  // Icon ring
                  Container(
                    width:  compact ? 52 : 64,
                    height: compact ? 52 : 64,
                    decoration: BoxDecoration(
                      color:  Colors.white.withValues(alpha: 0.15),
                      shape:  BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.40),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.verified_outlined,
                      color: Colors.white,
                      size:  compact ? 26 : 32,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 14),

                  // Brand name
                  Text(
                    'IntelliCraft',
                    style: GoogleFonts.poppins(
                      color:         Colors.white,
                      fontSize:      compact ? 20 : 22,
                      fontWeight:    FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color:        Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30)),
                    ),
                    child: Text(
                      'TRIAL VERSION',
                      style: GoogleFonts.poppins(
                        color:         Colors.white,
                        fontSize:      compact ? 10 : 11,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, compact ? 18 : 24, 20, compact ? 6 : 8),
              child: Column(
                children: [
                  Text(
                    'This is a product of',
                    style: GoogleFonts.poppins(
                      fontSize:   13,
                      fontWeight: FontWeight.w400,
                      color:      AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'IntelliCraft',
                    style: GoogleFonts.poppins(
                      fontSize:      compact ? 18 : 20,
                      fontWeight:    FontWeight.w800,
                      color:         AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Divider
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Notice',
                        style: GoogleFonts.poppins(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      AppColors.textHint,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 14),

                  // Info cards
                  const _InfoCard(
                    icon:  Icons.science_outlined,
                    color: AppColors.warning,
                    title: 'Running as Trial Version',
                    body:  'Some features may be limited. '
                           'Contact IntelliCraft to upgrade to the full license.',
                  ),
                  const SizedBox(height: 10),
                  const _InfoCard(
                    icon:  Icons.support_agent_outlined,
                    color: AppColors.primary,
                    title: 'Support & Licensing',
                    body:  'For licensing, support or custom development, '
                           'reach out to the IntelliCraft team.',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── CTA button ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, compact ? 28 : 24),
              child: Column(
                children: [
                  SizedBox(
                    width:  double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF4A148C)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:      AppColors.primary
                                .withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset:     const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color:        Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap:        onClose,
                          child: Center(
                            child: Text(
                              'I Understand — Continue',
                              style: GoogleFonts.poppins(
                                color:      Colors.white,
                                fontSize:   14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '© 2025 IntelliCraft. All rights reserved.',
                    style: GoogleFonts.poppins(
                      fontSize:   10,
                      fontWeight: FontWeight.w400,
                      color:      AppColors.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   body;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    fontSize:   11,
                    fontWeight: FontWeight.w400,
                    color:      AppColors.textSecondary,
                    height:     1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
