import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/trial_notice_dialog.dart';
import 'admin_home_tab.dart';
import 'admin_nurses_tab.dart';
import 'admin_services_tab.dart';
import 'admin_profile_tab.dart';

/// Breakpoint: >= 900px → desktop sidebar; < 900px → mobile bottom nav
const double _kDesktopBreak  = 900;
const double _kSidebarWidth  = 220;   // 220 medium, 240 on large screens

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) TrialNoticeDialog.showIfNeeded(context);
    });
  }

  static const _tabs = [
    AdminHomeTab(),
    AdminNursesTab(),
    AdminServicesTab(),
    AdminProfileTab(),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined,       selectedIcon: Icons.dashboard_rounded,           label: 'Dashboard'),
    _NavItem(icon: Icons.people_outline_rounded,   selectedIcon: Icons.people_rounded,              label: 'Resources'),
    _NavItem(icon: Icons.medical_services_outlined,selectedIcon: Icons.medical_services_rounded,    label: 'Services'),
    _NavItem(icon: Icons.person_outline_rounded,   selectedIcon: Icons.person_rounded,              label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _kDesktopBreak;
        return isDesktop
            ? _DesktopLayout(
                currentIndex: _currentIndex,
                tabs:         _tabs,
                navItems:     _navItems,
                onSelect:     (i) => setState(() => _currentIndex = i),
              )
            : _MobileLayout(
                currentIndex: _currentIndex,
                tabs:         _tabs,
                navItems:     _navItems,
                onSelect:     (i) => setState(() => _currentIndex = i),
              );
      },
    );
  }
}

// ── Desktop layout — fixed sidebar + scrollable content ──────────────────────
class _DesktopLayout extends ConsumerWidget {
  final int               currentIndex;
  final List<Widget>      tabs;
  final List<_NavItem>    navItems;
  final ValueChanged<int> onSelect;

  const _DesktopLayout({
    required this.currentIndex,
    required this.tabs,
    required this.navItems,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final sidebarW = constraints.maxWidth >= 1280 ? 240.0 : _kSidebarWidth;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // ── Sidebar ──────────────────────────────────────────────────
            _AdminSidebar(
              currentIndex: currentIndex,
              navItems:     navItems,
              onSelect:     onSelect,
              width:        sidebarW,
              onLogout: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/admin-login');
              },
            ),

            // ── Vertical divider ──────────────────────────────────────────
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),

            // ── Main content ──────────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: currentIndex,
                children: tabs,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Mobile layout — bottom navigation bar ────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final int               currentIndex;
  final List<Widget>      tabs;
  final List<_NavItem>    navItems;
  final ValueChanged<int> onSelect;

  const _MobileLayout({
    required this.currentIndex,
    required this.tabs,
    required this.navItems,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: tabs,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: List.generate(navItems.length, (i) {
                final item       = navItems[i];
                final isSelected = currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap:    () => onSelect(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve:    Curves.easeInOut,
                      padding:  const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.adminColor.withValues(alpha: 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              key:   ValueKey(isSelected),
                              color: isSelected
                                  ? AppColors.adminColor
                                  : AppColors.textSecondary,
                              size:  22,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: GoogleFonts.poppins(
                              fontSize:   9,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.adminColor
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

// ── Admin sidebar ─────────────────────────────────────────────────────────────
class _AdminSidebar extends StatelessWidget {
  final int               currentIndex;
  final List<_NavItem>    navItems;
  final ValueChanged<int> onSelect;
  final VoidCallback      onLogout;
  final double            width;

  const _AdminSidebar({
    required this.currentIndex,
    required this.navItems,
    required this.onSelect,
    required this.onLogout,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  width,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:      Color(0x0D000000),
            blurRadius: 16,
            offset:     Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo / brand header ──────────────────────────────────────
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              gradient: AppColors.adminGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo — white rounded card, sized to image only
                IntrinsicWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset:     const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/kle_logo.png',
                      height: 45,
                      fit:    BoxFit.fitHeight,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color:        Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_rounded,
                          size: 9, color: Colors.white.withValues(alpha: 0.90)),
                      const SizedBox(width: 4),
                      Text('Admin Panel',
                          style: GoogleFonts.poppins(
                            color:         Colors.white.withValues(alpha: 0.90),
                            fontSize:      9,
                            fontWeight:    FontWeight.w600,
                            letterSpacing: 0.3,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Nav section label ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            child: Text('NAVIGATION',
                style: GoogleFonts.poppins(
                  color:         AppColors.textHint,
                  fontSize:      8,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 1.2,
                )),
          ),

          // ── Nav items ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: List.generate(navItems.length, (i) {
                  final item       = navItems[i];
                  final isSelected = currentIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _SidebarNavItem(
                      item:       item,
                      isSelected: isSelected,
                      onTap:      () => onSelect(i),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── Divider + logout ──────────────────────────────────────────
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _SidebarNavItem(
              item: const _NavItem(
                icon:         Icons.logout_rounded,
                selectedIcon: Icons.logout_rounded,
                label:        'Logout',
              ),
              isSelected: false,
              onTap:      onLogout,
              isLogout:   true,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final _NavItem     item;
  final bool         isSelected;
  final VoidCallback onTap;
  final bool         isLogout;

  const _SidebarNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isLogout
        ? AppColors.error
        : widget.isSelected
            ? AppColors.adminColor
            : AppColors.textSecondary;

    return MouseRegion(
      cursor:    SystemMouseCursors.click,
      onEnter:   (_) => setState(() => _hovered = true),
      onExit:    (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.adminColor.withValues(alpha: 0.10)
                : _hovered
                    ? AppColors.background
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.isSelected
                ? Border.all(
                    color: AppColors.adminColor.withValues(alpha: 0.20))
                : null,
          ),
          child: Row(children: [
            Icon(
              widget.isSelected ? widget.item.selectedIcon : widget.item.icon,
              color: color,
              size:  17,
            ),
            const SizedBox(width: 9),
            Text(
              widget.item.label,
              style: GoogleFonts.poppins(
                color:      color,
                fontSize:   12,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (widget.isSelected) ...[
              const Spacer(),
              Container(
                width:  4,
                height: 4,
                decoration: const BoxDecoration(
                  color:  AppColors.adminColor,
                  shape:  BoxShape.circle,
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String   label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
