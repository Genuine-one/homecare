import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// MobileWebFrame
///
/// On **web with a wide viewport** (≥ 600 px): renders a phone-sized
/// centered frame (max 430 px wide) with a subtle shadow, giving the
/// patient/nurse UI a mobile-app feel on desktop browsers.
///
/// On **narrow web** (mobile browser) or **native** platforms: renders
/// the child full-screen with no constraints — exactly like a normal app.
///
/// Usage — wrap a Shell widget:
/// ```dart
/// builder: (ctx, state) => const MobileWebFrame(child: PatientShell()),
/// ```
class MobileWebFrame extends StatelessWidget {
  final Widget child;

  /// Maximum width of the phone frame when on wide web.
  static const double _maxWidth = 430;

  const MobileWebFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only apply the frame on web with a wide viewport.
    if (!kIsWeb) return child;

    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < _maxWidth + 40) return child; // already narrow — no frame

    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F6),
      body: Center(
        child: Container(
          width:  _maxWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          // ClipRect so nothing bleeds outside the frame
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}
