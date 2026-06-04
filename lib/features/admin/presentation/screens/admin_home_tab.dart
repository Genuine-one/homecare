import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import '../providers/resource_categories_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/kle_app_bar.dart';

class AdminHomeTab extends ConsumerStatefulWidget {
  const AdminHomeTab({super.key});

  @override
  ConsumerState<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends ConsumerState<AdminHomeTab> {
  String? _statusFilter;
  final _searchCtrl  = TextEditingController();
  String _searchQuery = '';

  /// Tracks when data was last fetched so we can show "Updated X ago".
  DateTime _lastUpdated = DateTime.now();
  Timer?   _clockTimer;

  @override
  void initState() {
    super.initState();
    // Tick every 30 s to keep the "last updated" label fresh.
    _clockTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) { if (mounted) setState(() {}); },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _updatedAgo {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 10)  return 'just now';
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final isDesktop  = MediaQuery.sizeOf(context).width >= 900;

    // Stamp the last-updated time whenever fresh data arrives.
    if (adminState is AsyncData) {
      _lastUpdated = DateTime.now();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      // On desktop the sidebar handles branding/navigation — no AppBar needed
      appBar: isDesktop ? null : KleAppBar(
        roleColor: AppColors.adminColor,
        subtitle:  'Admin Panel',
        actions: [
          // "Updated X ago" label
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync_rounded, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _updatedAgo,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.read(adminProvider.notifier).refresh(),
          ),
        ],
      ),
      body: adminState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.adminColor)),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(adminProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.error != null) {
            return _ErrorView(
              message: state.error!,
              onRetry: () => ref.read(adminProvider.notifier).refresh(),
            );
          }

          var requests = state.requests;
          if (_statusFilter != null) {
            requests = requests
                .where((r) => r['status'] == _statusFilter)
                .toList();
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            requests = requests.where((r) {
              final name = (r['patient_name'] as String? ?? '').toLowerCase();
              final city = (r['city']         as String? ?? '').toLowerCase();
              final type = (r['service_type'] as String? ?? '').toLowerCase();
              return name.contains(q) || city.contains(q) || type.contains(q);
            }).toList();
          }

          return LayoutBuilder(builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 600;

            // RefreshIndicator only works on mobile (touch). On web/desktop
            // we show an explicit refresh button instead.
            final scrollView = CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // KPI header
                            if (state.stats != null)
                              _AdminHeader(stats: state.stats!),

                            // Search bar
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  isDesktop ? 20 : 12, 4,
                                  isDesktop ? 20 : 12, 0),
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged:  (v) => setState(() => _searchQuery = v.trim()),
                                style: GoogleFonts.poppins(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Search by name, city, service…',
                                  hintStyle: GoogleFonts.poppins(
                                      fontSize: 12, color: AppColors.textHint),
                                  prefixIcon: const Icon(Icons.search_rounded,
                                      color: AppColors.textSecondary, size: 18),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded,
                                              color: AppColors.textSecondary),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  filled:    true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: AppColors.adminColor, width: 1.5)),
                                ),
                              ),
                            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                            // Filter chips
                            SizedBox(
                              height: 48,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 20 : 12, vertical: 4),
                                children: [
                                  null, 'pending', 'assigned',
                                  'in_progress', 'completed', 'cancelled',
                                ].map((s) {
                                  final label      = s == null ? 'All' : AppHelpers.statusLabel(s);
                                  final isSelected = _statusFilter == s;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(label,
                                          style: GoogleFonts.poppins(
                                            fontSize:   11,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                          )),
                                      selected:        isSelected,
                                      selectedColor:   AppColors.adminColor,
                                      checkmarkColor:  Colors.white,
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.adminColor
                                            : AppColors.divider,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      onSelected: (_) =>
                                          setState(() => _statusFilter = s),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                            // Count row + refresh button (web/desktop)
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  isDesktop ? 20 : 12, 0,
                                  isDesktop ? 20 : 12, 2),
                              child: Row(children: [
                                Container(
                                  width: 3, height: 14,
                                  decoration: BoxDecoration(
                                    color:        AppColors.adminColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${requests.length} request${requests.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.poppins(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w600,
                                    color:      AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                // ── Refresh button — always visible on web/desktop;
                                //    hidden on mobile (pull-to-refresh is used there)
                                if (kIsWeb || isDesktop)
                                  _RefreshButton(
                                    updatedAgo: _updatedAgo,
                                    onRefresh:  () => ref.read(adminProvider.notifier).refresh(),
                                  ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Empty state ──────────────────────────────────────────
                if (requests.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 72, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('No requests found',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          const SizedBox(height: 16),
                          // Web/desktop: show a centred refresh button
                          if (kIsWeb || isDesktop)
                            OutlinedButton.icon(
                              onPressed: () => ref.read(adminProvider.notifier).refresh(),
                              icon:  const Icon(Icons.refresh_rounded,
                                  color: AppColors.adminColor, size: 18),
                              label: Text('Refresh',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.adminColor, fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.adminColor),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            )
                          else
                            Text('Pull down to refresh',
                                style: GoogleFonts.poppins(
                                    color: AppColors.textHint, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                else
                  // ── Request cards ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: isDesktop
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                                child: _RequestsTable(
                                  requests: requests,
                                  nurses:   state.nurses,
                                  onAssign: (requestId, nurseId, notes) =>
                                      ref.read(adminProvider.notifier).assignNurse(
                                        requestId, nurseId, adminNotes: notes),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                                child: Column(
                                  children: requests.asMap().entries.map((e) =>
                                    _RequestCard(
                                      request:  e.value,
                                      nurses:   state.nurses,
                                      index:    e.key,
                                      onAssign: (nurseId, notes) =>
                                          ref.read(adminProvider.notifier).assignNurse(
                                            e.value['id'] as String,
                                            nurseId,
                                            adminNotes: notes,
                                          ),
                                    ),
                                  ).toList(),
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            );

            // On mobile: wrap with RefreshIndicator for pull-to-refresh.
            // On web/desktop: RefreshIndicator doesn't support mouse/pointer
            // gestures — use the explicit refresh button instead.
            if (!kIsWeb) {
              return RefreshIndicator(
                color:     AppColors.adminColor,
                onRefresh: () => ref.read(adminProvider.notifier).refresh(),
                child:     scrollView,
              );
            }
            return scrollView;
          });
        },
      ),
    );
  }
}

// ── Refresh button — used on web/desktop in place of pull-to-refresh ─────────
class _RefreshButton extends StatefulWidget {
  final String     updatedAgo;
  final VoidCallback onRefresh;
  const _RefreshButton({required this.updatedAgo, required this.onRefresh});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync:    this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _onTap() {
    _spin.forward(from: 0);
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:        AppColors.adminColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.adminColor.withValues(alpha: 0.20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _spin,
                child: const Icon(Icons.refresh_rounded,
                    size: 14, color: AppColors.adminColor),
              ),
              const SizedBox(width: 5),
              Text(
                widget.updatedAgo == 'just now'
                    ? 'Refresh'
                    : 'Updated ${widget.updatedAgo}',
                style: GoogleFonts.poppins(
                  color:      AppColors.adminColor,
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Admin header — responsive gradient banner + KPI cards ────────────────────
class _AdminHeader extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _AdminHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    final kpiCards = [
      _KpiCard(
        label:       'Total Patients',
        value:       '${stats['total_patients'] ?? 0}',
        icon:        Icons.people_alt_rounded,
        accentColor: const Color(0xFF1565C0),
        bgTint:      const Color(0xFFE3F0FF),
        delay:       0,
      ),
      _KpiCard(
        label:       'Active Nurses',
        value:       '${stats['total_nurses'] ?? 0}',
        icon:        Icons.medical_services_rounded,
        accentColor: const Color(0xFF00897B),
        bgTint:      const Color(0xFFE0F5F3),
        delay:       80,
      ),
      _KpiCard(
        label:       'Pending',
        value:       '${stats['pending_requests'] ?? 0}',
        icon:        Icons.pending_actions_rounded,
        accentColor: const Color(0xFFF57F17),
        bgTint:      const Color(0xFFFFF3E0),
        delay:       160,
      ),
      _KpiCard(
        label:       'Completed',
        value:       '${stats['completed_requests'] ?? 0}',
        icon:        Icons.task_alt_rounded,
        accentColor: const Color(0xFF2E7D32),
        bgTint:      const Color(0xFFE8F5E9),
        delay:       240,
      ),
    ];

    if (isDesktop) {
      // ── Desktop: flat banner + 4-column KPI row ────────────────────────
      final now = DateTime.now();
      final dateStr = '${_monthName(now.month)} ${now.day}, ${now.year}';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner — compact, title left, date right
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: const BoxDecoration(
              gradient: AppColors.adminGradient,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left — title
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color:        Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.dashboard_rounded,
                            color: Colors.white, size: 13),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dashboard Overview',
                              style: GoogleFonts.poppins(
                                color:      Colors.white.withValues(alpha: 0.70),
                                fontSize:   10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              )),
                          Text('Service Requests',
                              style: GoogleFonts.poppins(
                                color:      Colors.white,
                                fontSize:   18,
                                fontWeight: FontWeight.w700,
                                height:     1.2,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right — date pill + total count + live indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.85)),
                          const SizedBox(width: 5),
                          Text(dateStr,
                              style: GoogleFonts.poppins(
                                color:      Colors.white.withValues(alpha: 0.90),
                                fontSize:   11,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF69F0AE),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live · auto-refreshes every 15s',
                          style: GoogleFonts.poppins(
                            color:    Colors.white.withValues(alpha: 0.60),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4-col KPI row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: kpiCards.asMap().entries.map((e) {
                final isLast = e.key == kpiCards.length - 1;
                return Expanded(child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 10),
                  child: e.value,
                ));
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ).animate().fadeIn(duration: 400.ms);
    }

    // ── Mobile: gradient banner + floating 2×2 grid ───────────────────────
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.adminGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color:        Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Dashboard',
                      style: GoogleFonts.poppins(
                        color:         Colors.white.withValues(alpha: 0.72),
                        fontSize:      11,
                        fontWeight:    FontWeight.w500,
                        letterSpacing: 0.6,
                      )),
                  Text('Overview',
                      style: GoogleFonts.poppins(
                        color:      Colors.white,
                        fontSize:   20,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ],
          ),
        ),

        // KPI cards float over the banner
        Transform.translate(
          offset: const Offset(0, -32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Compute card width: (total - spacing) / 2 columns
                final cardW = (constraints.maxWidth - 12) / 2;
                // Card height: icon(32) + gap(8) + value(~26) + gap(1) + label(~14) + padding(24) = ~105
                // Add a small buffer → 110
                final ratio = cardW / 110;
                return GridView.count(
                  crossAxisCount:   2,
                  shrinkWrap:       true,
                  physics:          const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing:  12,
                  childAspectRatio: ratio,
                  children: [
                    _KpiCard(
                      label:     'Total Patients',
                      value:     '${stats['total_patients'] ?? 0}',
                      icon:      Icons.people_alt_rounded,
                      accentColor: const Color(0xFF1565C0),
                      bgTint:    const Color(0xFFE3F0FF),
                      delay:     0,
                    ),
                    _KpiCard(
                      label:     'Active Nurses',
                      value:     '${stats['total_nurses'] ?? 0}',
                      icon:      Icons.medical_services_rounded,
                      accentColor: const Color(0xFF00897B),
                      bgTint:    const Color(0xFFE0F5F3),
                      delay:     80,
                    ),
                    _KpiCard(
                      label:     'Pending',
                      value:     '${stats['pending_requests'] ?? 0}',
                      icon:      Icons.pending_actions_rounded,
                      accentColor: const Color(0xFFF57F17),
                      bgTint:    const Color(0xFFFFF3E0),
                      delay:     160,
                    ),
                    _KpiCard(
                      label:     'Completed',
                      value:     '${stats['completed_requests'] ?? 0}',
                      icon:      Icons.task_alt_rounded,
                      accentColor: const Color(0xFF2E7D32),
                      bgTint:    const Color(0xFFE8F5E9),
                      delay:     240,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

String _monthName(int m) => const [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
][m];

/// Formats an ISO-8601 datetime string to a readable form like "Jun 4, 2026 · 10:30 AM"
String _formatDateTime(String raw) {
  try {
    final dt = DateTime.parse(raw).toLocal();
    final month = _monthName(dt.month);
    final hour  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min   = dt.minute.toString().padLeft(2, '0');
    final ampm  = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, ${dt.year} · $hour:$min $ampm';
  } catch (_) {
    return raw;
  }
}

// ── White KPI card with coloured icon badge ───────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    accentColor;
  final Color    bgTint;
  final int      delay;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.bgTint,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon badge
          Container(
            width:  26,
            height: 26,
            decoration: BoxDecoration(
              color:        bgTint,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: accentColor, size: 14),
          ),
          const SizedBox(height: 6),

          // Number
          FittedBox(
            fit:       BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color:      const Color(0xFF1A202C),
                fontSize:   18,
                fontWeight: FontWeight.w800,
                height:     1.1,
              ),
            ),
          ),
          const SizedBox(height: 1),

          // Label
          Text(
            label,
            style: GoogleFonts.poppins(
              color:      const Color(0xFF718096),
              fontSize:   9,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate()
        .fadeIn(delay: delay.ms, duration: 350.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          end:   const Offset(1.0, 1.0),
          delay: delay.ms,
          duration: 280.ms,
          curve:  Curves.easeOut,
        );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final List<Map<String, dynamic>> nurses;
  final int index;
  final Future<String?> Function(String nurseId, String? notes) onAssign;

  const _RequestCard({
    required this.request,
    required this.nurses,
    required this.index,
    required this.onAssign,
  });

  Color get _statusColor {
    switch (request['status'] as String? ?? '') {
      case 'pending':     return AppColors.warning;
      case 'assigned':    return AppColors.info;
      case 'in_progress': return AppColors.primary;
      case 'completed':   return AppColors.success;
      case 'cancelled':   return AppColors.textSecondary;
      default:            return AppColors.textSecondary;
    }
  }

  Color get _urgencyColor {
    switch (request['urgency_level'] as String? ?? 'routine') {
      case 'emergency': return AppColors.error;
      case 'urgent':    return AppColors.warning;
      default:          return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status      = request['status']        as String? ?? 'pending';
    final patientName = request['patient_name']  as String? ?? '—';
    final serviceType = request['service_type']  as String? ?? '';
    final city        = request['city']          as String? ?? '';
    final date        = request['preferred_date'] as String? ?? '';
    final urgency     = request['urgency_level'] as String? ?? 'routine';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow:    AppColors.softShadow,
      ),
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap:        () => _showDetailSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1 — service type + status chip
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.adminColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.medical_services_rounded,
                          color: AppColors.adminColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppHelpers.serviceTypeLabel(serviceType),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize:   14,
                          color:      AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _Chip(AppHelpers.statusLabel(status), _statusColor),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2 — patient + contact
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(patientName,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.textPrimary)),
                    ),
                    const Icon(Icons.phone_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      request['contact_number'] as String? ?? 'N/A',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Row 3 — city + date
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(city,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(date,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),

                // Divider
                Container(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),

                // Row 4 — urgency + assign button
                Row(
                  children: [
                    _Chip(AppHelpers.urgencyLabel(urgency), _urgencyColor,
                        small: true),
                    const Spacer(),
                    if (status == 'pending' || status == 'assigned')
                      _AssignButton(
                        isReassign: status == 'assigned',
                        onTap: nurses.isEmpty
                            ? null
                            : () => _showAssignSheet(context),
                      ),
                  ],
                ),

                // Assigned nurse row
                if ((request['assigned_nurse_name'] as String?) != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.nurseColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_ind_rounded,
                            size: 14, color: AppColors.nurseColor),
                        const SizedBox(width: 6),
                        Text(
                          'Assigned: ${request['assigned_nurse_name']}',
                          style: GoogleFonts.poppins(
                            fontSize:   12,
                            color:      AppColors.nurseColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideX(begin: 0.05, end: 0, delay: (index * 50).ms, duration: 300.ms);
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestDetailSheet(
        request: request,
        nurses:  nurses,
        onAssign: onAssign,
      ),
    );
  }

  void _showAssignSheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignNurseSheet(
        request:  request,
        nurses:   nurses,
        onAssign: onAssign,
      ),
    ).then((success) {
      if (success == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Nurse assigned successfully!',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white)),
          ]),
          backgroundColor: AppColors.success,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    });
  }
}

// ── Assign button ─────────────────────────────────────────────────────────────
class _AssignButton extends StatelessWidget {
  final bool isReassign;
  final VoidCallback? onTap;
  const _AssignButton({required this.isReassign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: onTap != null ? AppColors.adminGradient : null,
          color:    onTap == null ? AppColors.textHint : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_ind_outlined,
                size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              isReassign ? 'Reassign' : 'Assign',
              style: GoogleFonts.poppins(
                color:      Colors.white,
                fontSize:   12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request detail sheet ───────────────────────────────────────────────────────
class _RequestDetailSheet extends StatelessWidget {
  final Map<String, dynamic> request;
  final List<Map<String, dynamic>> nurses;
  final Future<String?> Function(String, String?) onAssign;

  const _RequestDetailSheet({
    required this.request,
    required this.nurses,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.4,
      maxChildSize:     0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding:    const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:        AppColors.adminColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.medical_services_rounded,
                        color: AppColors.adminColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppHelpers.serviceTypeLabel(
                          request['service_type'] as String? ?? ''),
                      style: GoogleFonts.poppins(
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  _DetailSection('Patient Information', [
                    _DetailRow(Icons.person_outline, 'Name',
                        request['patient_name'] as String? ?? '—'),
                    _DetailRow(Icons.phone_outlined, 'Contact',
                        request['contact_number'] as String? ?? 'N/A'),
                    _DetailRow(Icons.location_on_outlined, 'Address',
                        request['address'] as String? ?? '—'),
                    _DetailRow(Icons.location_city_outlined, 'City',
                        request['city'] as String? ?? '—'),
                    if (request['state'] != null)
                      _DetailRow(Icons.map_outlined, 'State',
                          request['state'] as String),
                    if (request['pincode'] != null)
                      _DetailRow(Icons.pin_outlined, 'Pincode',
                          request['pincode'] as String),
                  ]),
                  const SizedBox(height: 16),
                  _DetailSection('Service Details', [
                    _DetailRow(Icons.medical_services_outlined, 'Service',
                        AppHelpers.serviceTypeLabel(
                            request['service_type'] as String? ?? '')),
                    _DetailRow(Icons.calendar_today_outlined, 'Date',
                        request['preferred_date'] as String? ?? '—'),
                    _DetailRow(Icons.timelapse_outlined, 'Duration',
                        '${request['num_days'] ?? 1} day(s)'),
                    if (request['preferred_time'] != null)
                      _DetailRow(Icons.access_time_outlined, 'Time Slot',
                          request['preferred_time'] as String),
                    _DetailRow(Icons.priority_high_outlined, 'Urgency',
                        AppHelpers.urgencyLabel(
                            request['urgency_level'] as String? ?? 'routine')),
                    _DetailRow(Icons.info_outline, 'Status',
                        AppHelpers.statusLabel(status)),
                    if ((request['description'] as String?)?.isNotEmpty == true)
                      _DetailRow(Icons.notes_outlined, 'Description',
                          request['description'] as String),
                    if ((request['special_notes'] as String?)?.isNotEmpty == true)
                      _DetailRow(Icons.sticky_note_2_outlined, 'Special Notes',
                          request['special_notes'] as String),
                  ]),
                  const SizedBox(height: 16),
                  _DetailSection('Request Timeline', [
                    if (request['created_at'] != null)
                      _DetailRow(Icons.schedule_outlined, 'Submitted',
                          _formatDateTime(request['created_at'].toString())),
                    if (request['updated_at'] != null)
                      _DetailRow(Icons.update_outlined, 'Last Updated',
                          _formatDateTime(request['updated_at'].toString())),
                    _DetailRow(Icons.fingerprint_outlined, 'Request ID',
                        (() {
                          final id = request['id'] as String? ?? '—';
                          return id.length > 8 ? '…${id.substring(id.length - 8)}' : id;
                        })()),
                  ]),
                  if ((request['assigned_nurse_name'] as String?) != null) ...[
                    const SizedBox(height: 16),
                    _DetailSection('Assigned Resource', [
                      _DetailRow(Icons.assignment_ind_outlined, 'Resource',
                          request['assigned_nurse_name'] as String,
                          valueColor: AppColors.nurseColor),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  if ((status == 'pending' || status == 'assigned') &&
                      nurses.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        gradient:     AppColors.adminGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color:        Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.pop(context);
                            showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _AssignNurseSheet(
                                request:  request,
                                nurses:   nurses,
                                onAssign: onAssign,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.assignment_ind_outlined,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  status == 'assigned'
                                      ? 'Reassign Resource'
                                      : 'Assign a Resource',
                                  style: GoogleFonts.poppins(
                                    color:      Colors.white,
                                    fontSize:   14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

// ── Assign nurse sheet ─────────────────────────────────────────────────────────
class _AssignNurseSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> request;
  final List<Map<String, dynamic>> nurses;
  final Future<String?> Function(String, String?) onAssign;

  const _AssignNurseSheet({
    required this.request,
    required this.nurses,
    required this.onAssign,
  });

  @override
  ConsumerState<_AssignNurseSheet> createState() => _AssignNurseSheetState();
}

class _AssignNurseSheetState extends ConsumerState<_AssignNurseSheet> {
  String? _selectedNurseId;
  String? _selectedCategory;     // null = show all nurses
  final _notesCtrl = TextEditingController();
  bool    _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Nurses filtered by the selected category.
  List<Map<String, dynamic>> get _filteredNurses {
    if (_selectedCategory == null) return widget.nurses;
    return widget.nurses
        .where((n) => (n['category'] as String?) == _selectedCategory)
        .toList();
  }

  Future<void> _submit() async {
    if (_selectedNurseId == null) return;
    setState(() { _isLoading = true; _error = null; });

    final errorMsg = await widget.onAssign(
      _selectedNurseId!,
      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMsg == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(resourceCategoriesProvider);
    final categoryNames   = categoriesAsync.valueOrNull?.activeNames ?? [];
    final filtered        = _filteredNurses;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:        AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet header
            Row(
              children: [
                Container(
                  padding:    const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient:     AppColors.adminGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_ind_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign Resource',
                        style: GoogleFonts.poppins(
                          fontSize:   16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${AppHelpers.serviceTypeLabel(widget.request['service_type'] as String? ?? '')}  •  ${widget.request['city'] ?? ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color:    AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Category filter chips ─────────────────────────────────────
            if (categoryNames.isNotEmpty) ...[
              Text('Filter by Category',
                  style: GoogleFonts.poppins(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      AppColors.textSecondary,
                  )),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // "All" chip
                    _CategoryChip(
                      label:    'All  (${widget.nurses.length})',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() {
                        _selectedCategory = null;
                        _selectedNurseId  = null;
                      }),
                    ),
                    ...categoryNames.map((cat) {
                      final count = widget.nurses
                          .where((n) => (n['category'] as String?) == cat)
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _CategoryChip(
                          label:    '$cat  ($count)',
                          selected: _selectedCategory == cat,
                          onTap: () => setState(() {
                            _selectedCategory = cat;
                            _selectedNurseId  = null; // reset selection on filter change
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Error banner
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color:        AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                color: AppColors.error, fontSize: 13))),
                    GestureDetector(
                      onTap: () => setState(() => _error = null),
                      child: Icon(Icons.close,
                          color: AppColors.error, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Resource list
            if (widget.nurses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No active resources available.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded,
                          size: 36, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      Text(
                        'No resources in the "$_selectedCategory" category.',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final n        = filtered[i];
                    final id       = n['id'] as String;
                    final selected = _selectedNurseId == id;
                    final category = n['category'] as String?;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.adminColor.withValues(alpha: 0.06)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.adminColor.withValues(alpha: 0.3)
                              : AppColors.divider,
                        ),
                      ),
                      child: ListTile(
                        dense:  true,
                        shape:  RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        leading: CircleAvatar(
                          radius:          18,
                          backgroundColor:
                              AppColors.nurseColor.withValues(alpha: 0.15),
                          child: Text(
                            (n['first_name'] as String? ?? 'N')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              color:      AppColors.nurseColor,
                              fontWeight: FontWeight.bold,
                              fontSize:   14,
                            ),
                          ),
                        ),
                        title: Text(
                          '${n['first_name']} ${n['last_name']}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize:   13,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            if (category != null) ...[
                              const Icon(Icons.category_outlined,
                                  size: 10, color: AppColors.adminColor),
                              const SizedBox(width: 3),
                              Text(category,
                                  style: GoogleFonts.poppins(
                                    fontSize:   10,
                                    color:      AppColors.adminColor,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                n['city'] as String? ?? '',
                                style: GoogleFonts.poppins(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.adminColor)
                            : null,
                        onTap: () => setState(() {
                          _selectedNurseId = id;
                          _error           = null;
                        }),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),

            TextField(
              controller: _notesCtrl,
              maxLines:   2,
              style:      GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Admin notes (optional)',
                hintText:  'Any special instructions…',
                labelStyle: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Submit button
            Container(
              height:     52,
              decoration: BoxDecoration(
                gradient: (_selectedNurseId == null || _isLoading ||
                        widget.nurses.isEmpty)
                    ? null
                    : AppColors.adminGradient,
                color: (_selectedNurseId == null || _isLoading ||
                        widget.nurses.isEmpty)
                    ? AppColors.textHint
                    : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color:        Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap:        (_selectedNurseId == null || _isLoading ||
                          widget.nurses.isEmpty)
                      ? null
                      : _submit,
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                        : Text(
                            'Confirm Assignment',
                            style: GoogleFonts.poppins(
                              color:      Colors.white,
                              fontSize:   15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

// ── Category chip ─────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.adminColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppColors.adminColor
                  : AppColors.divider),
          boxShadow: selected
              ? [BoxShadow(
                  color:      AppColors.adminColor.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset:     const Offset(0, 2),
                )]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   small;
  const _Chip(this.label, this.color, {this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
            color:      color,
            fontSize:   small ? 10 : 11,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String       title;
  final List<Widget> children;
  const _DetailSection(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              gradient:     AppColors.adminGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize:   13,
              )),
        ]),
        const SizedBox(height: 10),
        Container(
          padding:     const EdgeInsets.all(14),
          decoration:  BoxDecoration(
            color:        AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  const _DetailRow(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.adminColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color:    AppColors.textSecondary,
                )),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      valueColor ?? AppColors.textPrimary,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Desktop requests table ────────────────────────────────────────────────────
class _RequestsTable extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final List<Map<String, dynamic>> nurses;
  final Future<String?> Function(String requestId, String nurseId, String? notes) onAssign;

  const _RequestsTable({
    required this.requests,
    required this.nurses,
    required this.onAssign,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':     return AppColors.warning;
      case 'assigned':    return AppColors.info;
      case 'in_progress': return AppColors.primary;
      case 'completed':   return AppColors.success;
      case 'cancelled':   return AppColors.textSecondary;
      default:            return AppColors.textSecondary;
    }
  }

  Color _urgencyColor(String u) {
    switch (u) {
      case 'emergency': return AppColors.error;
      case 'urgent':    return AppColors.warning;
      default:          return AppColors.success;
    }
  }

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.8),  // Patient
            1: FlexColumnWidth(1.5),  // Service
            2: FlexColumnWidth(1.0),  // City
            3: FlexColumnWidth(1.0),  // Date
            4: FlexColumnWidth(0.9),  // Urgency
            5: FlexColumnWidth(0.9),  // Status
            6: FlexColumnWidth(1.1),  // Action
          },
          children: [
            // ── Header ──────────────────────────────────────────────────
            TableRow(
              decoration: const BoxDecoration(color: AppColors.adminColor),
              children: [
                _TH('Patient'),
                _TH('Service'),
                _TH('City'),
                _TH('Date'),
                _TH('Urgency'),
                _TH('Status'),
                _TH('Action'),
              ],
            ),
            // ── Data rows ────────────────────────────────────────────────
            ...requests.asMap().entries.map((entry) {
              final i       = entry.key;
              final req     = entry.value;
              final status  = req['status']        as String? ?? '';
              final urgency = req['urgency_level'] as String? ?? 'routine';
              final isEven  = i.isEven;

              void openDetail() => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _RequestDetailSheet(
                  request:  req,
                  nurses:   nurses,
                  onAssign: (nurseId, notes) =>
                      onAssign(req['id'] as String, nurseId, notes),
                ),
              );

              return TableRow(
                decoration: BoxDecoration(
                  color: isEven ? Colors.white : const Color(0xFFFAFAFB),
                ),
                children: [
                  _TD(onTap: openDetail, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(req['patient_name'] as String? ?? '—',
                          style: GoogleFonts.poppins(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      AppColors.textPrimary,
                          )),
                      Text(req['contact_number'] as String? ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color:    AppColors.textSecondary,
                          )),
                    ],
                  )),
                  _TD(onTap: openDetail, child: Text(
                    AppHelpers.serviceTypeLabel(req['service_type'] as String? ?? ''),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color:    AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )),
                  _TD(onTap: openDetail, child: Text(
                    req['city'] as String? ?? '—',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary),
                  )),
                  _TD(onTap: openDetail, child: Text(
                    req['preferred_date'] as String? ?? '—',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary),
                  )),
                  _TD(onTap: openDetail, child: _Chip(
                    AppHelpers.urgencyLabel(urgency),
                    _urgencyColor(urgency),
                    small: true,
                  )),
                  _TD(onTap: openDetail, child: _Chip(
                    AppHelpers.statusLabel(status),
                    _statusColor(status),
                    small: true,
                  )),
                  _TD(child: (status == 'pending' || status == 'assigned') && nurses.isNotEmpty
                      ? _TableAssignBtn(
                          isReassign: status == 'assigned',
                          request:    req,
                          nurses:     nurses,
                          onAssign:   (nurseId, notes) =>
                              onAssign(req['id'] as String, nurseId, notes),
                        )
                      : MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: openDetail,
                            child: Text('View',
                                style: GoogleFonts.poppins(
                                  fontSize:   11,
                                  color:      AppColors.adminColor,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        )),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text,
          style: GoogleFonts.poppins(
            color:      Colors.white,
            fontSize:   11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          )),
    );
  }
}

class _TD extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TD({required this.child, this.onTap});
  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: child,
    );
    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}

class _TableAssignBtn extends StatelessWidget {
  final bool                     isReassign;
  final Map<String, dynamic>     request;
  final List<Map<String, dynamic>> nurses;
  final Future<String?> Function(String nurseId, String? notes) onAssign;

  const _TableAssignBtn({
    required this.isReassign,
    required this.request,
    required this.nurses,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showModalBottomSheet<bool>(
          context:            context,
          isScrollControlled: true,
          backgroundColor:    Colors.transparent,
          builder: (_) => _AssignNurseSheet(
            request:  request,
            nurses:   nurses,
            onAssign: onAssign,
          ),
        ).then((ok) {
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Assigned successfully!',
                  style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: AppColors.success,
              behavior:        SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient:     AppColors.adminGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isReassign ? 'Reassign' : 'Assign',
            style: GoogleFonts.poppins(
              color:      Colors.white,
              fontSize:   11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
