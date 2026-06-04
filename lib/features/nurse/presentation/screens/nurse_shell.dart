import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/trial_notice_dialog.dart';
import 'nurse_dashboard.dart';
import 'nurse_profile_tab.dart';

class NurseShell extends ConsumerStatefulWidget {
  const NurseShell({super.key});

  @override
  ConsumerState<NurseShell> createState() => _NurseShellState();
}

class _NurseShellState extends ConsumerState<NurseShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) TrialNoticeDialog.showIfNeeded(context);
    });
  }

  static const _tabs = [
    NurseDashboard(),
    NurseProfileTab(),
  ];

  static const _destinations = [
    (icon: Icons.work_outline_rounded,   selectedIcon: Icons.work_rounded,    label: 'Jobs'),
    (icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded,  label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset:     const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: List.generate(_destinations.length, (i) {
                final d          = _destinations[i];
                final isSelected = _currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap:    () => setState(() => _currentIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve:    Curves.easeInOut,
                      padding:  const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.nurseColor.withValues(alpha: 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected ? d.selectedIcon : d.icon,
                              key:   ValueKey(isSelected),
                              color: isSelected
                                  ? AppColors.nurseColor
                                  : AppColors.textSecondary,
                              size:  24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.label,
                            style: GoogleFonts.poppins(
                              fontSize:   10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.nurseColor
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
