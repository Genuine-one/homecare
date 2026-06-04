import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/nurse_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/kle_app_bar.dart';

class NurseDashboard extends ConsumerStatefulWidget {
  const NurseDashboard({super.key});

  @override
  ConsumerState<NurseDashboard> createState() => _NurseDashboardState();
}

class _NurseDashboardState extends ConsumerState<NurseDashboard> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final nurseState = ref.watch(nurseProvider);
    final user       = ref.watch(authProvider).valueOrNull?.user;
    final firstName  = user?.fullName.split(' ').first ?? 'Resource';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KleAppBar(
        roleColor: AppColors.nurseColor,
        subtitle:  'Resource Portal',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => context.go('/nurse/notifications'),
          ),
          IconButton(
            icon:    const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/nurse-login');
            },
          ),
        ],
      ),
      body: nurseState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.nurseColor)),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(nurseProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.error != null) {
            return _ErrorView(
              message: state.error!,
              onRetry: () => ref.read(nurseProvider.notifier).refresh(),
            );
          }

          return RefreshIndicator(
            color: AppColors.nurseColor,
            onRefresh: () =>
                ref.read(nurseProvider.notifier).refresh(status: _statusFilter),
            child: CustomScrollView(
              slivers: [
                // ── Header + KPI cards (scrolls with page) ──────────────
                SliverToBoxAdapter(
                  child: _NurseHeader(
                    firstName:  firstName,
                    nurseState: nurseState,
                  ),
                ),

                // ── Filter chips ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      children: [
                        null, 'assigned', 'accepted',
                        'in_progress', 'completed', 'rejected',
                      ].map((s) {
                        final label    = s == null ? 'All' : AppHelpers.statusLabel(s);
                        final selected = _statusFilter == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(label,
                                style: GoogleFonts.poppins(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                )),
                            selected:        selected,
                            selectedColor:   AppColors.nurseColor,
                            checkmarkColor:  Colors.white,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.nurseColor
                                  : AppColors.divider,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onSelected: (_) {
                              setState(() => _statusFilter = s);
                              ref
                                  .read(nurseProvider.notifier)
                                  .refresh(status: s);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                ),

                // ── Section label ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                    child: Row(children: [
                      Container(
                        width: 3, height: 14,
                        decoration: BoxDecoration(
                          gradient:     AppColors.nurseGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusFilter == null
                            ? 'My Assignments'
                            : '${AppHelpers.statusLabel(_statusFilter!)} Jobs',
                        style: GoogleFonts.poppins(
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                          color:      AppColors.textPrimary,
                        ),
                      ),
                    ]),
                  ),
                ),

                // ── Empty state ───────────────────────────────────────────
                if (state.jobs.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width:  88,
                            height: 88,
                            decoration: BoxDecoration(
                              color:        AppColors.nurseColor
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(Icons.work_outline_rounded,
                                size: 44, color: AppColors.nurseColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusFilter == null
                                ? 'No jobs assigned yet'
                                : 'No ${AppHelpers.statusLabel(_statusFilter!).toLowerCase()} jobs',
                            style: GoogleFonts.poppins(
                              color:    AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                  )
                else
                  // ── Job cards ───────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final job = state.jobs[i];
                          return _JobCard(
                            job:   job,
                            index: i,
                            onTap: () =>
                                context.go('/nurse/jobs/${job['id']}'),
                            onStatusUpdate: (newStatus) =>
                                ref.read(nurseProvider.notifier)
                                    .updateJobStatus(
                                        job['id'] as String, newStatus),
                          );
                        },
                        childCount: state.jobs.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Nurse header — banner + floating white KPI cards ──────────────────────────
class _NurseHeader extends StatelessWidget {
  final String              firstName;
  final AsyncValue<dynamic> nurseState;

  const _NurseHeader({
    required this.firstName,
    required this.nurseState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Teal gradient banner
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.nurseGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 52),
          child: Row(
            children: [
              // Avatar
              Container(
                width:  52,
                height: 52,
                decoration: BoxDecoration(
                  color:  Colors.white.withValues(alpha: 0.20),
                  shape:  BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35), width: 2),
                ),
                child: Center(
                  child: Text(
                    firstName[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      color:      Colors.white,
                      fontSize:   20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome,',
                      style: GoogleFonts.poppins(
                        color:    Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      )),
                  Text(firstName,
                      style: GoogleFonts.poppins(
                        color:      Colors.white,
                        fontSize:   20,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 4),
                  nurseState.when(
                    loading: () => const SizedBox.shrink(),
                    error:   (_, __) => const SizedBox.shrink(),
                    data: (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${s.total} job${s.total == 1 ? '' : 's'} assigned',
                        style: GoogleFonts.poppins(
                          color:      Colors.white.withValues(alpha: 0.90),
                          fontSize:   11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // White KPI cards floating over the banner
        Transform.translate(
          offset: const Offset(0, -32),
          child: nurseState.when(
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
            data: (s) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _NurseKpiCard(
                      label:       'Pending',
                      value:       '${s.pending}',
                      icon:        Icons.pending_actions_rounded,
                      accentColor: const Color(0xFFF57F17),
                      bgTint:      const Color(0xFFFFF3E0),
                      delay:       0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NurseKpiCard(
                      label:       'Active',
                      value:       '${s.inProgress}',
                      icon:        Icons.play_circle_outline_rounded,
                      accentColor: const Color(0xFF1565C0),
                      bgTint:      const Color(0xFFE3F0FF),
                      delay:       80,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NurseKpiCard(
                      label:       'Done',
                      value:       '${s.completed}',
                      icon:        Icons.check_circle_outline_rounded,
                      accentColor: const Color(0xFF2E7D32),
                      bgTint:      const Color(0xFFE8F5E9),
                      delay:       160,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── White KPI card for nurse dashboard ───────────────────────────────────────
class _NurseKpiCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    accentColor;
  final Color    bgTint;
  final int      delay;

  const _NurseKpiCard({
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  32,
            height: 32,
            decoration: BoxDecoration(
              color:        bgTint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accentColor, size: 17),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                color:      const Color(0xFF1A202C),
                fontSize:   20,
                fontWeight: FontWeight.w800,
                height:     1.1,
              )),
          Text(label,
              style: GoogleFonts.poppins(
                color:      const Color(0xFF718096),
                fontSize:   10,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    ).animate()
        .fadeIn(delay: delay.ms, duration: 300.ms)
        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1),
               delay: delay.ms, duration: 260.ms, curve: Curves.easeOut);
  }
}

// ── Job card ──────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final int                  index;
  final VoidCallback         onTap;
  final Future<bool> Function(String) onStatusUpdate;

  const _JobCard({
    required this.job,
    required this.index,
    required this.onTap,
    required this.onStatusUpdate,
  });

  String? get _nextStatus {
    switch (job['status']) {
      case 'assigned':    return 'accepted';
      case 'accepted':    return 'in_progress';
      case 'in_progress': return 'completed';
      default:            return null;
    }
  }

  Color get _statusColor {
    switch (job['status'] as String? ?? '') {
      case 'assigned':    return AppColors.info;
      case 'accepted':    return AppColors.primary;
      case 'in_progress': return AppColors.warning;
      case 'completed':   return AppColors.success;
      case 'rejected':    return AppColors.error;
      default:            return AppColors.textSecondary;
    }
  }

  Color get _urgencyColor {
    switch (job['urgency_level'] as String? ?? 'routine') {
      case 'emergency': return AppColors.error;
      case 'urgent':    return AppColors.warning;
      default:          return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status      = job['status']         as String? ?? '';
    final patientName = job['patient_name']   as String? ?? '—';
    final contact     = job['contact_number'] as String?;
    final serviceType = job['service_type']   as String? ?? '';
    final address     = job['address']        as String? ?? '';
    final city        = job['city']           as String? ?? '';
    final prefDate    = job['preferred_date'] as String? ?? '';
    final urgency     = job['urgency_level']  as String? ?? 'routine';
    final next        = _nextStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow:    AppColors.softShadow,
      ),
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: service + status ──────────────────────────────
                Row(
                  children: [
                    Container(
                      padding:    const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:        AppColors.nurseColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.medical_services_rounded,
                          color: AppColors.nurseColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppHelpers.serviceTypeLabel(serviceType),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize:   14,
                          color:      AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _StatusBadge(AppHelpers.statusLabel(status), _statusColor),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Row 2: patient + contact ─────────────────────────────
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
                    if (contact != null) ...[
                      const Icon(Icons.phone_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(contact,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:    AppColors.textSecondary,
                          )),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // ── Row 3: address ───────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        city.isNotEmpty ? '$address, $city' : address,
                        style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Row 4: date + urgency ────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(prefDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    _StatusBadge(
                        AppHelpers.urgencyLabel(urgency), _urgencyColor,
                        small: true),
                  ],
                ),

                // ── Action buttons ───────────────────────────────────────
                if (next != null) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (status == 'assigned') ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onStatusUpdate('rejected'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              minimumSize: const Size(0, 40),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Reject',
                                style: GoogleFonts.poppins(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        flex: 2,
                        child: Container(
                          height:     40,
                          decoration: BoxDecoration(
                            gradient:     AppColors.nurseGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color:        Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap:        () => onStatusUpdate(next),
                              child: Center(
                                child: Text(_actionLabel(next),
                                    style: GoogleFonts.poppins(
                                      color:      Colors.white,
                                      fontSize:   13,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Tap hint ─────────────────────────────────────────────
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Tap for full details',
                        style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.textHint)),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right,
                        size: 14, color: AppColors.textHint),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
        .fadeIn(delay: (index * 60).ms, duration: 300.ms)
        .slideX(begin: 0.05, end: 0,
                delay: (index * 60).ms, duration: 300.ms);
  }

  String _actionLabel(String s) {
    switch (s) {
      case 'accepted':    return 'Accept Job';
      case 'in_progress': return 'Start Job';
      case 'completed':   return 'Mark Complete';
      default:            return AppHelpers.statusLabel(s);
    }
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   small;
  const _StatusBadge(this.label, this.color, {this.small = false});

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
            const Icon(Icons.error_outline, size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
