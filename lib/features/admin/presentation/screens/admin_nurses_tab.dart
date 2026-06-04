import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/nurses_provider.dart';
import '../providers/resource_categories_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/kle_app_bar.dart';

/// Admin — Registered Resources Panel
/// Read-only registry of all resource (nurse) accounts.
/// Admin can: view details, toggle active/inactive, delete.
class AdminNursesTab extends ConsumerStatefulWidget {
  const AdminNursesTab({super.key});

  @override
  ConsumerState<AdminNursesTab> createState() => _AdminNursesTabState();
}

class _AdminNursesTabState extends ConsumerState<AdminNursesTab> {
  String _searchQuery  = '';
  bool?  _activeFilter; // null = all, true = active, false = inactive
  final  _searchCtrl   = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(nursesProvider);
    // Eagerly load categories so they're ready when any sheet opens
    ref.watch(resourceCategoriesProvider);
    final isDesktop  = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : KleAppBar(
        roleColor: AppColors.adminColor,
        subtitle:  'Admin Panel',
        actions: [
          IconButton(
            icon:     const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip:  'Refresh',
            onPressed: () => ref.read(nursesProvider.notifier).refresh(),
          ),
        ],
      ),
      // ── FABs — manage categories + add resource ──────────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Secondary: Manage Categories
          FloatingActionButton.extended(
            heroTag:         'categories_fab',
            onPressed: () => _showCategoriesSheet(context),
            backgroundColor: AppColors.adminColor.withValues(alpha: 0.15),
            foregroundColor: AppColors.adminColor,
            elevation:       0,
            icon:  const Icon(Icons.category_outlined, size: 18),
            label: Text('Categories',
                style: GoogleFonts.poppins(
                    color: AppColors.adminColor, fontWeight: FontWeight.w600,
                    fontSize: 13)),
            tooltip: 'Manage resource categories',
          ),
          const SizedBox(height: 10),
          // Primary: Add Resource
          FloatingActionButton.extended(
            heroTag:         'resources_fab',
            onPressed: () => _showCreateSheet(context),
            backgroundColor: AppColors.adminColor,
            icon:  const Icon(Icons.person_add_rounded, color: Colors.white),
            label: Text('Add Resource',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            tooltip: 'Create new resource account',
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.adminColor)),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(nursesProvider.notifier).refresh(),
        ),
        data: (state) {
          // Snackbar feedback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(_snackBar(state.successMessage!, AppColors.success));
            } else if (state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(_snackBar(state.error!, AppColors.error));
            }
          });

          // Apply filters
          var nurses = state.nurses;
          if (_activeFilter != null) {
            nurses = nurses
                .where((n) => (n['is_active'] as bool? ?? false) == _activeFilter)
                .toList();
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            nurses = nurses.where((n) {
              final name  = '${n['first_name'] ?? ''} ${n['last_name'] ?? ''}'.toLowerCase();
              final email = (n['email'] as String? ?? '').toLowerCase();
              final city  = (n['city']  as String? ?? '').toLowerCase();
              return name.contains(q) || email.contains(q) || city.contains(q);
            }).toList();
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: CustomScrollView(
            slivers: [
              // ── KPI header ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _NursesHeader(state: state),
              ),

              // ── Loading strip ──────────────────────────────────────────
              if (state.isLoading)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(
                    color:           AppColors.adminColor,
                    backgroundColor: AppColors.divider,
                  ),
                ),

              // ── Search ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      isDesktop ? 20 : 16, 4,
                      isDesktop ? 20 : 16, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged:  (v) => setState(() => _searchQuery = v.trim()),
                    style:      GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText:  'Search by name, email, city…',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textSecondary),
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
                          const EdgeInsets.symmetric(vertical: 12),
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
              ),

              // ── Filter chips ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 20 : 16, vertical: 5),
                    children: [
                      _FilterPill(
                        label:    'All  (${state.total})',
                        selected: _activeFilter == null,
                        color:    AppColors.adminColor,
                        onTap:    () => setState(() => _activeFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label:    'Active  (${state.active})',
                        selected: _activeFilter == true,
                        color:    AppColors.success,
                        onTap:    () => setState(() => _activeFilter = true),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label:    'Inactive  (${state.inactive})',
                        selected: _activeFilter == false,
                        color:    AppColors.error,
                        onTap:    () => setState(() => _activeFilter = false),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
              ),

              // ── Count ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      isDesktop ? 20 : 16, 2,
                      isDesktop ? 20 : 16, 4),
                  child: Row(children: [
                    Container(
                      width: 3, height: 13,
                      decoration: BoxDecoration(
                        color:        AppColors.adminColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${nurses.length} registered resource${nurses.length == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    // Desktop: inline Manage Categories + Add Resource buttons
                    if (isDesktop) ...[
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _showCategoriesSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:        AppColors.adminColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.adminColor.withValues(alpha: 0.30)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.category_outlined,
                                  size: 14, color: AppColors.adminColor),
                              const SizedBox(width: 6),
                              Text('Categories',
                                  style: GoogleFonts.poppins(
                                    color:      AppColors.adminColor,
                                    fontSize:   12,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _showCreateSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient:     AppColors.adminGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(
                                color:      AppColors.adminColor
                                    .withValues(alpha: 0.30),
                                blurRadius: 8,
                                offset:     const Offset(0, 3),
                              )],
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.person_add_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text('Add Resource',
                                  style: GoogleFonts.poppins(
                                    color:      Colors.white,
                                    fontSize:   12,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),

              // ── Empty state ────────────────────────────────────────────
              if (nurses.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width:  88,
                          height: 88,
                          decoration: BoxDecoration(
                            color:        AppColors.adminColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.people_outline_rounded,
                              size: 44, color: AppColors.adminColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No nurses match your search.'
                              : 'No nurses registered yet.',
                          style: GoogleFonts.poppins(
                            fontSize:   15,
                            fontWeight: FontWeight.w600,
                            color:      AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nurses will be created by the admin from this screen.',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textHint),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => _showCreateSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient:     AppColors.adminGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.person_add_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('Add First Resource',
                                  style: GoogleFonts.poppins(
                                    color:      Colors.white,
                                    fontSize:   13,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                )
              else if (isDesktop)
                // ── Desktop: table ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    child: _NursesTable(
                      nurses:   nurses,
                      onView:   (n) => _showDetailSheet(context, n),
                      onEdit:   (n) => _showEditSheet(context, n),
                      onToggle: (n) => ref
                          .read(nursesProvider.notifier)
                          .toggleNurse(n['id'] as String),
                      onDelete: (n) => _confirmDelete(context, n),
                    ),
                  ),
                )
              else
                // ── Mobile: card list ───────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _NurseCard(
                        nurse:    nurses[i],
                        index:    i,
                        onView:   () => _showDetailSheet(context, nurses[i]),
                        onEdit:   () => _showEditSheet(context, nurses[i]),
                        onToggle: () => ref
                            .read(nursesProvider.notifier)
                            .toggleNurse(nurses[i]['id'] as String),
                        onDelete: () => _confirmDelete(context, nurses[i]),
                      ),
                      childCount: nurses.length,
                    ),
                  ),
                ),
            ],
              ),     // CustomScrollView
            ),       // ConstrainedBox
          );         // Align
        },
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  SnackBar _snackBar(String msg, Color color) => SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        backgroundColor: color,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  void _showCategoriesSheet(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => const _ManageCategoriesSheet(),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _CreateNurseSheet(
        onSubmit: ({
          required String firstName, required String lastName,
          required String email,     required String phone,
          required String address,   required String city,
          String? nurseState,        String? pincode,
          String? category,
          required String password,
        }) =>
            ref.read(nursesProvider.notifier).createNurse(
              firstName:  firstName,  lastName:   lastName,
              email:      email,      phone:      phone,
              address:    address,    city:       city,
              nurseState: nurseState, pincode:    pincode,
              category:   category,
              password:   password,
            ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, Map<String, dynamic> nurse) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _NurseDetailSheet(
        nurse:    nurse,
        onEdit: () {
          _showEditSheet(context, nurse);
        },
        onToggle: () => ref
            .read(nursesProvider.notifier)
            .toggleNurse(nurse['id'] as String),
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(context, nurse);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, Map<String, dynamic> nurse) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _EditNurseSheet(
        nurse: nurse,
        onSave: (fields) => ref
            .read(nursesProvider.notifier)
            .updateNurse(nurse['id'] as String, fields),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Map<String, dynamic> nurse) async {
    final name = '${nurse['first_name']} ${nurse['last_name']}';
    final ok   = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Resource',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                color: AppColors.textPrimary, fontSize: 13),
            children: [
              const TextSpan(text: 'Permanently remove '),
              TextSpan(
                text: '"$name"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' from the system? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize:     const Size(80, 40)),
            child: Text('Remove', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(nursesProvider.notifier)
          .deleteNurse(nurse['id'] as String, name);
    }
  }
}

// ── KPI header ─────────────────────────────────────────────────────────────────
class _NursesHeader extends StatelessWidget {
  final NursesState state;
  const _NursesHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    final kpiCards = [
      _KpiCard(label: 'Total',    value: '${state.total}',
          icon: Icons.people_rounded,        accentColor: AppColors.adminColor,
          bgTint: const Color(0xFFF3E5F5),   delay: 0),
      _KpiCard(label: 'Active',   value: '${state.active}',
          icon: Icons.check_circle_rounded,  accentColor: AppColors.success,
          bgTint: const Color(0xFFE8F5E9),   delay: 80),
      _KpiCard(label: 'Inactive', value: '${state.inactive}',
          icon: Icons.cancel_rounded,        accentColor: AppColors.error,
          bgTint: const Color(0xFFFFEBEE),   delay: 160),
    ];

    if (isDesktop) {
      return Column(
        children: [
          // Flat compact banner
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: const BoxDecoration(gradient: AppColors.adminGradient),
            child: Row(
              children: [
                Expanded(
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.badge_rounded,
                          color: Colors.white, size: 13),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resource Registry',
                            style: GoogleFonts.poppins(
                              color:      Colors.white.withValues(alpha: 0.70),
                              fontSize:   10, fontWeight: FontWeight.w500,
                            )),
                        Text('Registered Resources',
                            style: GoogleFonts.poppins(
                              color:      Colors.white,
                              fontSize:   18, fontWeight: FontWeight.w700,
                              height: 1.2,
                            )),
                      ],
                    ),
                  ]),
                ),
                Text('${state.total} total',
                    style: GoogleFonts.poppins(
                      color:    Colors.white.withValues(alpha: 0.60),
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          // KPI row
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

    // Mobile: floating cards
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.adminGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
          child: Row(children: [
            Container(
              padding:    const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.badge_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Registered Resources',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11, fontWeight: FontWeight.w500,
                  )),
              Text('All Resources',
                  style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                  )),
            ]),
          ]),
        ),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: kpiCards.asMap().entries.map((e) {
              final isLast = e.key == kpiCards.length - 1;
              return Expanded(child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 10),
                child: e.value,
              ));
            }).toList()),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  34,
            height: 34,
            decoration: BoxDecoration(
              color:        bgTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                color:      const Color(0xFF1A202C),
                fontSize:   22,
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

// ── Nurse card ─────────────────────────────────────────────────────────────────
class _NurseCard extends StatelessWidget {
  final Map<String, dynamic> nurse;
  final int          index;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _NurseCard({
    required this.nurse,
    required this.index,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final firstName  = nurse['first_name'] as String? ?? '';
    final lastName   = nurse['last_name']  as String? ?? '';
    final email      = nurse['email']      as String? ?? '';
    final phone      = nurse['phone']      as String? ?? '';
    final city       = nurse['city']       as String? ?? '';
    final isActive   = nurse['is_active']  as bool?   ?? false;
    final isVerified = nurse['is_verified'] as bool?  ?? false;
    final initials   = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

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
          onTap:        onView,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width:  50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient:     AppColors.adminGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: GoogleFonts.poppins(
                          color:      Colors.white,
                          fontSize:   17,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + badges row
                      Row(
                        children: [
                          Expanded(
                            child: Text('$firstName $lastName',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize:   14,
                                  color:      AppColors.textPrimary,
                                )),
                          ),
                          _Badge(
                            label:    isActive ? 'Active' : 'Inactive',
                            color:    isActive ? AppColors.success : AppColors.error,
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            _Badge(label: 'Verified', color: AppColors.info),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Category badge (if set)
                      if ((nurse['category'] as String?) != null) ...[
                        Row(children: [
                          const Icon(Icons.category_outlined,
                              size: 11, color: AppColors.adminColor),
                          const SizedBox(width: 4),
                          Text(nurse['category'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.adminColor,
                                fontWeight: FontWeight.w600,
                              )),
                        ]),
                        const SizedBox(height: 2),
                      ],

                      // Email
                      Row(children: [
                        const Icon(Icons.email_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(email,
                              style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 2),

                      // Phone + city
                      Row(children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(phone.isNotEmpty ? phone : '—',
                            style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary)),
                        const Spacer(),
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(city.isNotEmpty ? city : '—',
                            style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // 3-dot menu — View / Edit / Toggle / Delete
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'view')   onView();
                    if (v == 'edit')   onEdit();
                    if (v == 'toggle') onToggle();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    _menuItem('view',   Icons.visibility_outlined,
                        'View Details',  AppColors.primary),
                    _menuItem('edit',   Icons.edit_outlined,
                        'Edit',          AppColors.adminColor),
                    _menuItem(
                      'toggle',
                      isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
                      isActive ? 'Deactivate' : 'Activate',
                      isActive ? AppColors.warning : AppColors.success,
                    ),
                    _menuItem('delete', Icons.delete_outline,
                        'Remove',        AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideX(begin: 0.05, end: 0,
                delay: (index * 50).ms, duration: 280.ms);
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.poppins(
              color:      color == AppColors.error
                  ? AppColors.error
                  : AppColors.textPrimary,
              fontSize:   13,
              fontWeight: FontWeight.w500,
            )),
      ]),
    );
  }
}

// ── Desktop nurses table ──────────────────────────────────────────────────────
class _NursesTable extends StatelessWidget {
  final List<Map<String, dynamic>> nurses;
  final void Function(Map<String, dynamic>) onView;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onToggle;
  final void Function(Map<String, dynamic>) onDelete;

  const _NursesTable({
    required this.nurses,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // ── Header row ───────────────────────────────────────────────
            Container(
              color: AppColors.adminColor,
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(44),   // Avatar
                  1: FlexColumnWidth(2.0),   // Name
                  2: FlexColumnWidth(2.2),   // Email
                  3: FlexColumnWidth(1.2),   // Phone
                  4: FlexColumnWidth(1.0),   // City
                  5: FlexColumnWidth(0.9),   // Status
                  6: FlexColumnWidth(0.8),   // Verified
                  7: FlexColumnWidth(1.2),   // Actions
                },
                children: const [
                  TableRow(children: [
                    _TH(''),
                    _TH('Name'),
                    _TH('Email'),
                    _TH('Phone'),
                    _TH('City'),
                    _TH('Status'),
                    _TH('Verified'),
                    _TH('Actions'),
                  ]),
                ],
              ),
            ),

            // ── Data rows ───────────────────────────────────────────────
            ...nurses.asMap().entries.map((entry) {
              final i        = entry.key;
              final nurse    = entry.value;
              final isActive = nurse['is_active']  as bool? ?? false;
              final isVerif  = nurse['is_verified'] as bool? ?? false;
              final first    = nurse['first_name'] as String? ?? '';
              final last     = nurse['last_name']  as String? ?? '';
              final initials = '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'.toUpperCase();
              final isEven   = i.isEven;

              return _NurseTableRow(
                nurse:    nurse,
                initials: initials,
                isActive: isActive,
                isVerif:  isVerif,
                isEven:   isEven,
                onView:   () => onView(nurse),
                onEdit:   () => onEdit(nurse),
                onToggle: () => onToggle(nurse),
                onDelete: () => onDelete(nurse),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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

class _NurseTableRow extends StatefulWidget {
  final Map<String, dynamic> nurse;
  final String   initials;
  final bool     isActive;
  final bool     isVerif;
  final bool     isEven;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _NurseTableRow({
    required this.nurse,
    required this.initials,
    required this.isActive,
    required this.isVerif,
    required this.isEven,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_NurseTableRow> createState() => _NurseTableRowState();
}

class _NurseTableRowState extends State<_NurseTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final nurse = widget.nurse;
    final first = nurse['first_name'] as String? ?? '';
    final last  = nurse['last_name']  as String? ?? '';
    final email = nurse['email']      as String? ?? '—';
    final phone = nurse['phone']      as String? ?? '—';
    final city  = nurse['city']       as String? ?? '—';

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onView,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered
              ? AppColors.adminColor.withValues(alpha: 0.04)
              : (widget.isEven ? Colors.white : const Color(0xFFFAFAFB)),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(44),
              1: FlexColumnWidth(2.0),
              2: FlexColumnWidth(2.2),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(1.0),
              5: FlexColumnWidth(0.9),
              6: FlexColumnWidth(0.8),
              7: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                children: [
                  // Avatar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Container(
                      width:  28, height: 28,
                      decoration: BoxDecoration(
                        gradient:     AppColors.adminGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(widget.initials,
                            style: GoogleFonts.poppins(
                              color:      Colors.white,
                              fontSize:   10,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                  ),

                  // Name
                  _TD(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$first $last',
                          style: GoogleFonts.poppins(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      AppColors.textPrimary,
                          )),
                    ],
                  )),

                  // Email
                  _TD(child: Text(email,
                      style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis)),

                  // Phone
                  _TD(child: Text(phone.isNotEmpty ? phone : '—',
                      style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary))),

                  // City
                  _TD(child: Text(city.isNotEmpty ? city : '—',
                      style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary))),

                  // Status
                  _TD(child: _TableBadge(
                    label: widget.isActive ? 'Active' : 'Inactive',
                    color: widget.isActive ? AppColors.success : AppColors.error,
                  )),

                  // Verified
                  _TD(child: widget.isVerif
                      ? const Icon(Icons.verified_rounded,
                          color: AppColors.info, size: 16)
                      : Icon(Icons.remove_circle_outline_rounded,
                          color: AppColors.textHint, size: 15)),

                  // Actions
                  _TD(child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RowIconBtn(
                        icon:    Icons.visibility_outlined,
                        color:   AppColors.primary,
                        tooltip: 'View',
                        onTap:   widget.onView,
                      ),
                      const SizedBox(width: 4),
                      _RowIconBtn(
                        icon:    Icons.edit_outlined,
                        color:   AppColors.adminColor,
                        tooltip: 'Edit',
                        onTap:   widget.onEdit,
                      ),
                      const SizedBox(width: 4),
                      _RowIconBtn(
                        icon:    widget.isActive
                            ? Icons.toggle_off_rounded
                            : Icons.toggle_on_rounded,
                        color:   widget.isActive
                            ? AppColors.warning
                            : AppColors.success,
                        tooltip: widget.isActive ? 'Deactivate' : 'Activate',
                        onTap:   widget.onToggle,
                      ),
                      const SizedBox(width: 4),
                      _RowIconBtn(
                        icon:    Icons.delete_outline_rounded,
                        color:   AppColors.error,
                        tooltip: 'Remove',
                        onTap:   widget.onDelete,
                      ),
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    child: child,
  );
}

class _TableBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _TableBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
            fontSize:   9,
            fontWeight: FontWeight.w700,
            color:      color,
          )),
    );
  }
}

class _RowIconBtn extends StatefulWidget {
  final IconData     icon;
  final Color        color;
  final String       tooltip;
  final VoidCallback onTap;
  const _RowIconBtn({required this.icon, required this.color,
      required this.tooltip, required this.onTap});

  @override
  State<_RowIconBtn> createState() => _RowIconBtnState();
}

class _RowIconBtnState extends State<_RowIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor:  SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color:        _hovered
                  ? widget.color.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, size: 15, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// ── Nurse detail sheet (read-only + edit/toggle/delete actions) ───────────────
class _NurseDetailSheet extends StatelessWidget {
  final Map<String, dynamic> nurse;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _NurseDetailSheet({
    required this.nurse,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final firstName  = nurse['first_name']  as String? ?? '';
    final lastName   = nurse['last_name']   as String? ?? '';
    final email      = nurse['email']       as String? ?? '';
    final phone      = nurse['phone']       as String? ?? '';
    final address    = nurse['address']     as String? ?? '';
    final city       = nurse['city']        as String? ?? '';
    final stateName  = nurse['state']       as String? ?? '';
    final pincode    = nurse['pincode']     as String? ?? '';
    final isActive   = nurse['is_active']   as bool?   ?? false;
    final isVerified = nurse['is_verified'] as bool?   ?? false;
    final createdAt  = nurse['created_at']  as String? ?? '';
    final initials   =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize:     0.5,
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
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(children: [
                Container(
                  width:  50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient:     AppColors.adminGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: GoogleFonts.poppins(
                          color:      Colors.white,
                          fontSize:   18,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$firstName $lastName',
                          style: GoogleFonts.poppins(
                            fontSize:   17,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, children: [
                        _Badge(
                          label: isActive ? 'Active' : 'Inactive',
                          color: isActive ? AppColors.success : AppColors.error,
                        ),
                        if (isVerified)
                          _Badge(label: 'Verified', color: AppColors.info),
                        _Badge(label: 'Nurse', color: AppColors.adminColor),
                      ]),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  _Section('Contact Information', [
                    _InfoRow(Icons.email_outlined,  'Email',   email),
                    _InfoRow(Icons.phone_outlined,   'Phone',   phone.isNotEmpty   ? phone   : '—'),
                  ]),
                  const SizedBox(height: 16),
                  _Section('Address', [
                    _InfoRow(Icons.home_outlined,          'Address', address.isNotEmpty   ? address   : '—'),
                    _InfoRow(Icons.location_city_outlined, 'City',    city.isNotEmpty      ? city      : '—'),
                    _InfoRow(Icons.map_outlined,            'State',   stateName.isNotEmpty ? stateName : '—'),
                    _InfoRow(Icons.pin_outlined,            'Pincode', pincode.isNotEmpty   ? pincode   : '—'),
                  ]),
                  const SizedBox(height: 16),
                  _Section('Account', [
                    _InfoRow(Icons.category_outlined,  'Category', (nurse['category'] as String?)?.isNotEmpty == true ? nurse['category'] as String : '—'),
                    _InfoRow(Icons.verified_outlined,  'Verified', isVerified ? 'Yes' : 'No'),
                    _InfoRow(Icons.schedule_outlined,  'Joined',   _formatDate(createdAt)),
                  ]),
                  const SizedBox(height: 24),

                  // Actions — Edit + Toggle + Delete
                  Row(children: [
                    Expanded(
                      child: _ActionBtn(
                        label: 'Edit',
                        icon:  Icons.edit_rounded,
                        color: AppColors.adminColor,
                        onTap: () {
                          Navigator.pop(context);
                          onEdit();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionBtn(
                        label: isActive ? 'Deactivate' : 'Activate',
                        icon:  isActive
                            ? Icons.toggle_off_rounded
                            : Icons.toggle_on_rounded,
                        color: isActive ? AppColors.warning : AppColors.success,
                        onTap: () {
                          Navigator.pop(context);
                          onToggle();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Remove',
                        icon:  Icons.delete_rounded,
                        color: AppColors.error,
                        onTap: onDelete,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return ts.isNotEmpty ? ts : '—';
    }
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
            fontSize:   10,
            fontWeight: FontWeight.w700,
            color:      color,
          )),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
              color: selected ? color : AppColors.divider),
          boxShadow: selected
              ? [BoxShadow(
                  color:      color.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
                )]
              : [],
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String       title;
  final List<Widget> rows;
  const _Section(this.title, this.rows);

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
                fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding:    const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoRow(this.icon, this.label, this.value);

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
            width: 72,
            child: Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.textPrimary,
                )),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(label,
                style: GoogleFonts.poppins(
                  color:      color,
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                )),
          ],
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
            const Icon(Icons.error_outline, size: 52, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:      const Icon(Icons.refresh_rounded),
              label:     const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Resource Sheet ─────────────────────────────────────────────────────
typedef _CreateNurseCallback = Future<bool> Function({
  required String firstName,
  required String lastName,
  required String email,
  required String phone,
  required String address,
  required String city,
  String? nurseState,
  String? pincode,
  String? category,
  required String password,
});

class _CreateNurseSheet extends ConsumerStatefulWidget {
  final _CreateNurseCallback onSubmit;
  const _CreateNurseSheet({required this.onSubmit});

  @override
  ConsumerState<_CreateNurseSheet> createState() => _CreateNurseSheetState();
}

class _CreateNurseSheetState extends ConsumerState<_CreateNurseSheet> {
  final _formKey        = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _cityCtrl       = TextEditingController();
  final _stateCtrl      = TextEditingController();
  final _pincodeCtrl    = TextEditingController();
  final _passCtrl       = TextEditingController();
  bool    _obscure      = true;
  bool    _isLoading    = false;
  String? _error;
  String? _selectedCategory;

  @override
  void dispose() {
    for (final c in [_firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl,
      _addressCtrl, _cityCtrl, _stateCtrl, _pincodeCtrl, _passCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    final ok = await widget.onSubmit(
      firstName:  _firstNameCtrl.text.trim(),
      lastName:   _lastNameCtrl.text.trim(),
      email:      _emailCtrl.text.trim(),
      phone:      _phoneCtrl.text.trim(),
      address:    _addressCtrl.text.trim(),
      city:       _cityCtrl.text.trim(),
      nurseState: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      pincode:    _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
      category:   _selectedCategory,
      password:   _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _error = 'Failed to create resource. Check the details and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch categories for the dropdown
    final categoriesAsync = ref.watch(resourceCategoriesProvider);
    final categoryNames   = categoriesAsync.valueOrNull?.activeNames ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize:     0.5,
        maxChildSize:     0.95,
        expand:           false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient:     AppColors.adminGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Resource Account',
                            style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('Creates a pre-verified resource account',
                            style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
              ),
              const Divider(height: 1),
              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.30)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                                style: GoogleFonts.poppins(
                                    color: AppColors.error, fontSize: 12))),
                          ]),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Category dropdown ─────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resource Category',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              )),
                          const SizedBox(height: 6),
                          categoriesAsync.when(
                            loading: () => Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.adminColor),
                                ),
                              ),
                            ),
                            error: (_, __) => _buildCategoryDropdown(
                                categoryNames, noCategories: true),
                            data: (_) => _buildCategoryDropdown(categoryNames),
                          ),
                          if (categoryNames.isEmpty && categoriesAsync.hasValue) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.warning.withValues(alpha: 0.25)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 14, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No categories yet. Go to the Resources tab to create one first.',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11, color: AppColors.warning),
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Name row
                      Row(children: [
                        Expanded(child: _NurseField(
                          label: 'First Name', ctrl: _firstNameCtrl,
                          icon: Icons.badge_outlined,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _NurseField(
                          label: 'Last Name', ctrl: _lastNameCtrl,
                          icon: Icons.badge_outlined,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required' : null,
                        )),
                      ]),                      const SizedBox(height: 12),
                      _NurseField(
                        label: 'Email', ctrl: _emailCtrl,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _NurseField(
                        label: 'Phone (10 digits)', ctrl: _phoneCtrl,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!RegExp(r'^\d{10}$').hasMatch(v.trim()))
                            return '10 digits required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _NurseField(
                        label: 'Address', ctrl: _addressCtrl,
                        icon: Icons.home_outlined,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _NurseField(
                          label: 'City', ctrl: _cityCtrl,
                          icon: Icons.location_city_outlined,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _NurseField(
                          label: 'State (optional)', ctrl: _stateCtrl,
                          icon: Icons.map_outlined,
                        )),
                      ]),
                      const SizedBox(height: 12),
                      _NurseField(
                        label: 'Pincode (optional)', ctrl: _pincodeCtrl,
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _NurseField(
                        label: 'Password', ctrl: _passCtrl,
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 8) return 'Min 8 characters';
                          if (!v.contains(RegExp(r'[A-Z]')))
                            return 'Add an uppercase letter';
                          if (!v.contains(RegExp(r'\d')))
                            return 'Add a digit';
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary, size: 20),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Min 8 chars · 1 uppercase · 1 digit',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: AppColors.textHint),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Submit
                      GestureDetector(
                        onTap: _isLoading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: _isLoading ? null : AppColors.adminGradient,
                            color: _isLoading ? AppColors.textHint : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _isLoading ? [] : [BoxShadow(
                              color: AppColors.adminColor.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            )],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white))
                                : Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.person_add_rounded,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Create Resource Account',
                                        style: GoogleFonts.poppins(
                                          color:      Colors.white,
                                          fontSize:   14,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<String> names, {bool noCategories = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: Text(
            noCategories ? 'No categories available' : 'Select category (optional)',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textHint),
          ),
          isExpanded:  true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.adminColor),
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textPrimary,
              fontWeight: FontWeight.w500),
          items: [
            // "None" option to clear selection
            DropdownMenuItem<String>(
              value: null,
              child: Text('— None —',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
            ...names.map((name) => DropdownMenuItem<String>(
              value: name,
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.adminColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.category_outlined,
                      size: 13, color: AppColors.adminColor),
                ),
                const SizedBox(width: 10),
                Text(name,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
              ]),
            )),
          ],
          onChanged: noCategories
              ? null
              : (v) => setState(() => _selectedCategory = v),
        ),
      ),
    );
  }
}

class _NurseField extends StatelessWidget {
  final String                      label;
  final TextEditingController       ctrl;
  final IconData                    icon;
  final String? Function(String?)?  validator;
  final bool                        obscureText;
  final Widget?                     suffixIcon;
  final TextInputType               keyboardType;

  const _NurseField({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.validator,
    this.obscureText  = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   ctrl,
      validator:    validator,
      obscureText:  obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
          fontSize: 13, color: AppColors.textPrimary,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: GoogleFonts.poppins(
            fontSize: 12, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.adminColor, size: 18),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.adminColor, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Manage Categories Sheet ───────────────────────────────────────────────────
/// Full CRUD for resource categories — shown via the "Categories" button.
class _ManageCategoriesSheet extends ConsumerStatefulWidget {
  const _ManageCategoriesSheet();

  @override
  ConsumerState<_ManageCategoriesSheet> createState() =>
      _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState
    extends ConsumerState<_ManageCategoriesSheet> {
  // ── Add-new form state ──────────────────────────────────────────────────────
  final _addKey         = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _descCtrl       = TextEditingController();
  bool  _addLoading     = false;
  String? _addError;
  bool  _showAddForm    = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_addKey.currentState!.validate()) return;
    setState(() { _addLoading = true; _addError = null; });
    final ok = await ref
        .read(resourceCategoriesProvider.notifier)
        .createCategory(_nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim());
    if (!mounted) return;
    setState(() => _addLoading = false);
    if (ok) {
      _nameCtrl.clear();
      _descCtrl.clear();
      setState(() => _showAddForm = false);
    } else {
      setState(() =>
          _addError = ref.read(resourceCategoriesProvider).valueOrNull?.error ??
              'Failed to create category.');
    }
  }

  Future<void> _delete(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Category',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                color: AppColors.textPrimary, fontSize: 13),
            children: [
              const TextSpan(text: 'Delete category '),
              TextSpan(
                text: '"$name"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                  text: '? Resources in this category will not be deleted.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(80, 40)),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(resourceCategoriesProvider.notifier)
          .deleteCategory(id, name);
    }
  }

  Future<void> _toggleActive(
      String id, String name, bool currentlyActive) async {
    await ref.read(resourceCategoriesProvider.notifier).updateCategory(
          id,
          isActive: !currentlyActive,
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(resourceCategoriesProvider);
    final categories = asyncState.valueOrNull?.categories ?? [];

    // Show snackbar for success/error
    asyncState.whenData((s) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (s.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(s.successMessage!,
                  style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
        }
      });
    });

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.70,
        minChildSize:     0.40,
        maxChildSize:     0.92,
        expand:           false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle ────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient:     AppColors.adminGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.category_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resource Categories',
                            style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('${categories.length} categor${categories.length == 1 ? 'y' : 'ies'}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                  // Add-new toggle button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showAddForm
                        ? IconButton(
                            key: const ValueKey('close'),
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textSecondary),
                            onPressed: () =>
                                setState(() => _showAddForm = false),
                          )
                        : TextButton.icon(
                            key: const ValueKey('add'),
                            onPressed: () =>
                                setState(() => _showAddForm = true),
                            icon: const Icon(Icons.add_rounded,
                                size: 16, color: AppColors.adminColor),
                            label: Text('Add New',
                                style: GoogleFonts.poppins(
                                  color: AppColors.adminColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.adminColor
                                  .withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
              ),
              const Divider(height: 1),

              // ── Inline add-category form ───────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve:    Curves.easeInOut,
                child: _showAddForm
                    ? _AddCategoryForm(
                        formKey:    _addKey,
                        nameCtrl:   _nameCtrl,
                        descCtrl:   _descCtrl,
                        isLoading:  _addLoading,
                        error:      _addError,
                        onSubmit:   _create,
                        onCancel:   () => setState(() {
                          _showAddForm = false;
                          _addError    = null;
                          _nameCtrl.clear();
                          _descCtrl.clear();
                        }),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Category list ─────────────────────────────────────────
              Expanded(
                child: asyncState.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.adminColor)),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text(e.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(resourceCategoriesProvider.notifier)
                                .refresh(),
                            icon:  const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.adminColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (_) => categories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.category_outlined,
                                    size: 56,
                                    color: AppColors.textHint),
                                const SizedBox(height: 14),
                                Text('No categories yet.',
                                    style: GoogleFonts.poppins(
                                      fontSize:   15,
                                      fontWeight: FontWeight.w600,
                                      color:      AppColors.textSecondary,
                                    )),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap "Add New" above to create your first category.',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textHint),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: ctrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final cat      = categories[i];
                            final id       = cat['id'] as String;
                            final name     = cat['name'] as String;
                            final desc     = cat['description'] as String?;
                            final isActive = cat['is_active'] as bool? ?? true;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: isActive
                                        ? AppColors.adminColor
                                            .withValues(alpha: 0.20)
                                        : AppColors.divider),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                leading: Container(
                                  width:  40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.adminColor
                                            .withValues(alpha: 0.10)
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.category_outlined,
                                      color: isActive
                                          ? AppColors.adminColor
                                          : AppColors.textHint,
                                      size: 20),
                                ),
                                title: Row(children: [
                                  Expanded(
                                    child: Text(name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize:   14,
                                          color: isActive
                                              ? AppColors.textPrimary
                                              : AppColors.textHint,
                                        )),
                                  ),
                                  // Active / Inactive badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.success
                                              .withValues(alpha: 0.10)
                                          : AppColors.error
                                              .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isActive
                                            ? AppColors.success
                                                .withValues(alpha: 0.35)
                                            : AppColors.error
                                                .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: GoogleFonts.poppins(
                                        fontSize:   9,
                                        fontWeight: FontWeight.w700,
                                        color: isActive
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ]),
                                subtitle: desc != null && desc.isNotEmpty
                                    ? Text(desc,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines:  2,
                                        overflow:  TextOverflow.ellipsis)
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Toggle active
                                    Tooltip(
                                      message: isActive
                                          ? 'Deactivate'
                                          : 'Activate',
                                      child: IconButton(
                                        icon: Icon(
                                          isActive
                                              ? Icons.toggle_on_rounded
                                              : Icons.toggle_off_rounded,
                                          color: isActive
                                              ? AppColors.success
                                              : AppColors.textHint,
                                          size: 28,
                                        ),
                                        onPressed: () => _toggleActive(
                                            id, name, isActive),
                                      ),
                                    ),
                                    // Delete
                                    Tooltip(
                                      message: 'Delete',
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.error,
                                            size: 20),
                                        onPressed: () => _delete(id, name),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

// ── Inline add-category form ──────────────────────────────────────────────────
class _AddCategoryForm extends StatelessWidget {
  final GlobalKey<FormState>   formKey;
  final TextEditingController  nameCtrl;
  final TextEditingController  descCtrl;
  final bool                   isLoading;
  final String?                error;
  final VoidCallback           onSubmit;
  final VoidCallback           onCancel;

  const _AddCategoryForm({
    required this.formKey,
    required this.nameCtrl,
    required this.descCtrl,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Category',
                style: GoogleFonts.poppins(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      AppColors.textPrimary,
                )),
            const SizedBox(height: 10),

            if (error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.30)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(error!,
                        style: GoogleFonts.poppins(
                            color: AppColors.error, fontSize: 11)),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],

            // Name field
            TextFormField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText:  'Category Name *',
                labelStyle: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.category_outlined,
                    color: AppColors.adminColor, size: 18),
                filled:    true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.adminColor, width: 1.8)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.error)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'At least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Description field
            TextFormField(
              controller: descCtrl,
              maxLines: 2,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText:  'Description (optional)',
                labelStyle: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.description_outlined,
                    color: AppColors.adminColor, size: 18),
                alignLabelWithHint: true,
                filled:    true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.adminColor, width: 1.8)),
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                        color:      AppColors.textSecondary,
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: isLoading ? null : onSubmit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height:   46,
                    decoration: BoxDecoration(
                      gradient: isLoading ? null : AppColors.adminGradient,
                      color:    isLoading ? AppColors.textHint : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.adminColor
                                    .withValues(alpha: 0.30),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text('Create Category',
                                    style: GoogleFonts.poppins(
                                      color:      Colors.white,
                                      fontSize:   13,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Edit Resource Sheet ───────────────────────────────────────────────────────
/// Pre-fills all fields with the existing resource data.
/// Only sends changed fields to the backend (dirty-tracking).
class _EditNurseSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>           nurse;
  final Future<bool> Function(Map<String, dynamic> fields) onSave;

  const _EditNurseSheet({required this.nurse, required this.onSave});

  @override
  ConsumerState<_EditNurseSheet> createState() => _EditNurseSheetState();
}

class _EditNurseSheetState extends ConsumerState<_EditNurseSheet> {
  final _formKey = GlobalKey<FormState>();

  // Controllers — pre-filled from existing data
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;

  // Category selection
  String? _selectedCategory;

  bool    _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final n = widget.nurse;
    _firstNameCtrl = TextEditingController(text: n['first_name'] as String? ?? '');
    _lastNameCtrl  = TextEditingController(text: n['last_name']  as String? ?? '');
    _phoneCtrl     = TextEditingController(text: n['phone']      as String? ?? '');
    _addressCtrl   = TextEditingController(text: n['address']    as String? ?? '');
    _cityCtrl      = TextEditingController(text: n['city']       as String? ?? '');
    _stateCtrl     = TextEditingController(text: n['state']      as String? ?? '');
    _pincodeCtrl   = TextEditingController(text: n['pincode']    as String? ?? '');
    _selectedCategory = n['category'] as String?;
  }

  @override
  void dispose() {
    for (final c in [_firstNameCtrl, _lastNameCtrl, _phoneCtrl,
        _addressCtrl, _cityCtrl, _stateCtrl, _pincodeCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    // Build only the fields that actually changed
    final original = widget.nurse;
    final fields   = <String, dynamic>{};

    void addIfChanged(String key, String ctrl, String? orig) {
      final trimmed = ctrl.trim();
      if (trimmed != (orig ?? '')) fields[key] = trimmed.isEmpty ? null : trimmed;
    }

    addIfChanged('first_name', _firstNameCtrl.text, original['first_name'] as String?);
    addIfChanged('last_name',  _lastNameCtrl.text,  original['last_name']  as String?);
    addIfChanged('phone',      _phoneCtrl.text,     original['phone']      as String?);
    addIfChanged('address',    _addressCtrl.text,   original['address']    as String?);
    addIfChanged('city',       _cityCtrl.text,      original['city']       as String?);
    addIfChanged('state',      _stateCtrl.text,     original['state']      as String?);
    addIfChanged('pincode',    _pincodeCtrl.text,   original['pincode']    as String?);

    // Category — compare with original
    if (_selectedCategory != (original['category'] as String?)) {
      fields['category'] = _selectedCategory;
    }

    if (fields.isEmpty) {
      // Nothing changed
      if (mounted) Navigator.pop(context);
      return;
    }

    final ok = await widget.onSave(fields);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _error = 'Failed to update resource. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(resourceCategoriesProvider);
    final categoryNames   = categoriesAsync.valueOrNull?.activeNames ?? [];
    final firstName = widget.nurse['first_name'] as String? ?? '';
    final lastName  = widget.nurse['last_name']  as String? ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize:     0.5,
        maxChildSize:     0.95,
        expand:           false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient:     AppColors.adminGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Resource',
                            style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('$firstName $lastName',
                            style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
              ),
              const Divider(height: 1),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.all(20),
                    children: [

                      // Error banner
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.30)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                                style: GoogleFonts.poppins(
                                    color: AppColors.error, fontSize: 12))),
                          ]),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Category dropdown ─────────────────────────────
                      Text('Resource Category',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          )),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            hint: Text(
                              categoryNames.isEmpty
                                  ? 'No categories available'
                                  : 'Select category (optional)',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.textHint),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.adminColor),
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text('— None —',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.textSecondary)),
                              ),
                              ...categoryNames.map((name) =>
                                  DropdownMenuItem<String>(
                                    value: name,
                                    child: Row(children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppColors.adminColor
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                            Icons.category_outlined,
                                            size: 13,
                                            color: AppColors.adminColor),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(name,
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500)),
                                    ]),
                                  )),
                            ],
                            onChanged: categoryNames.isEmpty
                                ? null
                                : (v) =>
                                    setState(() => _selectedCategory = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Name row ──────────────────────────────────────
                      Row(children: [
                        Expanded(child: _NurseField(
                          label: 'First Name',
                          ctrl:  _firstNameCtrl,
                          icon:  Icons.badge_outlined,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _NurseField(
                          label: 'Last Name',
                          ctrl:  _lastNameCtrl,
                          icon:  Icons.badge_outlined,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        )),
                      ]),
                      const SizedBox(height: 12),

                      // ── Phone ─────────────────────────────────────────
                      _NurseField(
                        label: 'Phone (10 digits)',
                        ctrl:  _phoneCtrl,
                        icon:  Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!RegExp(r'^\d{10}$').hasMatch(v.trim()))
                            return '10 digits required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ── Address ───────────────────────────────────────
                      _NurseField(
                        label: 'Address',
                        ctrl:  _addressCtrl,
                        icon:  Icons.home_outlined,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // ── City / State row ──────────────────────────────
                      Row(children: [
                        Expanded(child: _NurseField(
                          label: 'City',
                          ctrl:  _cityCtrl,
                          icon:  Icons.location_city_outlined,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _NurseField(
                          label: 'State (optional)',
                          ctrl:  _stateCtrl,
                          icon:  Icons.map_outlined,
                        )),
                      ]),
                      const SizedBox(height: 12),

                      // ── Pincode ───────────────────────────────────────
                      _NurseField(
                        label: 'Pincode (optional)',
                        ctrl:  _pincodeCtrl,
                        icon:  Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      // ── Save button ───────────────────────────────────
                      GestureDetector(
                        onTap: _isLoading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : AppColors.adminGradient,
                            color: _isLoading ? AppColors.textHint : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _isLoading
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppColors.adminColor
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    )
                                  ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white))
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.save_rounded,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Save Changes',
                                          style: GoogleFonts.poppins(
                                            color:      Colors.white,
                                            fontSize:   14,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
