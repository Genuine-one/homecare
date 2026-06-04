import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/patient_provider.dart';
import '../widgets/service_request_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/kle_app_bar.dart';

class PatientDashboard extends ConsumerStatefulWidget {
  const PatientDashboard({super.key});

  @override
  ConsumerState<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends ConsumerState<PatientDashboard> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final authState     = ref.watch(authProvider);
    final requestsState = ref.watch(patientRequestsProvider);
    final user          = authState.valueOrNull?.user;
    final firstName     = user?.fullName.split(' ').first ?? 'Patient';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KleAppBar(
        roleColor: AppColors.primary,
        subtitle:  'Patient Portal',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () => context.go('/patient/notifications'),
          ),
          // Server settings — tap to update ngrok URL without rebuilding APK
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Server Settings',
            onPressed: () => context.push('/settings/server'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: requestsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorBody(
          message: e.toString(),
          onRetry: () => ref.read(patientRequestsProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.error != null && state.requests.isEmpty) {
            return _ErrorBody(
              message: state.error!,
              onRetry: () =>
                  ref.read(patientRequestsProvider.notifier).refresh(),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(patientRequestsProvider.notifier)
                .refresh(status: _statusFilter),
            child: CustomScrollView(
              slivers: [
                // ── Hero header with 2×2 stats grid ───────────────────
                SliverToBoxAdapter(
                  child: _PatientHeader(
                    firstName:       firstName,
                    totalAll:        state.totalAll,
                    totalPending:    state.totalPending,
                    totalInProgress: state.totalInProgress,
                    totalCompleted:  state.totalCompleted,
                    totalCancelled:  state.totalCancelled,
                    onStatTap: (status) {
                      setState(() => _statusFilter = status);
                      ref.read(patientRequestsProvider.notifier)
                          .refresh(status: status);
                    },
                  ),
                ),

                // ── Filter chips ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: _FilterChips(
                    selected: _statusFilter,
                    onChanged: (s) {
                      setState(() => _statusFilter = s);
                      ref.read(patientRequestsProvider.notifier)
                          .refresh(status: s);
                    },
                  ),
                ),

                // ── Section header ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4, height: 16,
                          decoration: BoxDecoration(
                            gradient:     AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusFilter == null
                              ? 'All My Requests'
                              : '${AppHelpers.statusLabel(_statusFilter!)} Requests',
                          style: GoogleFonts.poppins(
                            fontSize:   14,
                            fontWeight: FontWeight.w700,
                            color:      AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient:     AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.requests.length}',
                            style: GoogleFonts.poppins(
                              fontSize:   11,
                              color:      Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Empty state ────────────────────────────────────────
                if (state.requests.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      hasFilter:    _statusFilter != null,
                      onNewRequest: () => context.go('/patient/new-request'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final req = state.requests[i];
                          return ServiceRequestCard(
                            request: req,
                            onTap: () =>
                                context.go('/patient/requests/${req.id}'),
                            onEdit: req.status == 'pending'
                                ? () => _showEditSheet(context, req)
                                : null,
                            onCancel: req.status == 'pending'
                                ? () async {
                                    final ok =
                                        await _confirmCancel(context);
                                    if (ok == true) {
                                      await ref
                                          .read(patientRequestsProvider
                                              .notifier)
                                          .cancelRequest(req.id);
                                    }
                                  }
                                : null,
                          );
                        },
                        childCount: state.requests.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag:         'patient_fab',
        onPressed:       () => context.go('/patient/new-request'),
        backgroundColor: AppColors.primary,
        elevation:       4,
        icon:  const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Request',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  void _showEditSheet(BuildContext context, dynamic req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditRequestSheet(
        request: req,
        onSave: (data) async {
          final ok = await ref
              .read(patientRequestsProvider.notifier)
              .updateRequest(req.id, data);
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Request updated successfully!',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.white)),
              ]),
              backgroundColor: AppColors.success,
              behavior:        SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          }
          return ok;
        },
      ),
    );
  }

  Future<bool?> _confirmCancel(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Request',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to cancel this service request?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(80, 40)),
            child: Text('Yes, Cancel',
                style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Patient header with 2×2 stats grid ───────────────────────────────────────
class _PatientHeader extends StatelessWidget {
  final String firstName;
  final int    totalAll;
  final int    totalPending;
  final int    totalInProgress;
  final int    totalCompleted;
  final int    totalCancelled;
  final void Function(String? status) onStatTap;

  const _PatientHeader({
    required this.firstName,
    required this.totalAll,
    required this.totalPending,
    required this.totalInProgress,
    required this.totalCompleted,
    required this.totalCancelled,
    required this.onStatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome row
          Row(
            children: [
              Container(
                width:  48,
                height: 48,
                decoration: BoxDecoration(
                  color:  Colors.white.withValues(alpha: 0.20),
                  shape:  BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30), width: 2),
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
                  Text('Welcome back,',
                      style: GoogleFonts.poppins(
                        color:      Colors.white.withValues(alpha: 0.75),
                        fontSize:   12,
                      )),
                  Text(firstName,
                      style: GoogleFonts.poppins(
                        color:      Colors.white,
                        fontSize:   20,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
              const Spacer(),
              // Total badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:        Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('$totalAll',
                        style: GoogleFonts.poppins(
                          color:      Colors.white,
                          fontSize:   18,
                          fontWeight: FontWeight.w800,
                          height:     1.1,
                        )),
                    Text('Total',
                        style: GoogleFonts.poppins(
                          color:      Colors.white.withValues(alpha: 0.75),
                          fontSize:   9,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2×2 white KPI grid
          GridView.count(
            crossAxisCount:   2,
            shrinkWrap:       true,
            physics:          const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing:  10,
            childAspectRatio: 1.6,
            children: [
              _StatTile(
                label:       'Pending',
                count:       totalPending,
                icon:        Icons.pending_actions_rounded,
                accentColor: const Color(0xFFF57F17),
                bgTint:      const Color(0xFFFFF3E0),
                onTap:       () => onStatTap('pending'),
                delay:       0,
              ),
              _StatTile(
                label:       'In Progress',
                count:       totalInProgress,
                icon:        Icons.local_hospital_rounded,
                accentColor: const Color(0xFF1565C0),
                bgTint:      const Color(0xFFE3F0FF),
                onTap:       () => onStatTap('in_progress'),
                delay:       80,
              ),
              _StatTile(
                label:       'Completed',
                count:       totalCompleted,
                icon:        Icons.task_alt_rounded,
                accentColor: const Color(0xFF2E7D32),
                bgTint:      const Color(0xFFE8F5E9),
                onTap:       () => onStatTap('completed'),
                delay:       160,
              ),
              _StatTile(
                label:       'Cancelled',
                count:       totalCancelled,
                icon:        Icons.cancel_outlined,
                accentColor: const Color(0xFF546E7A),
                bgTint:      const Color(0xFFECEFF1),
                onTap:       () => onStatTap('cancelled'),
                delay:       240,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _StatTile extends StatelessWidget {
  final String       label;
  final int          count;
  final IconData     icon;
  final Color        accentColor;
  final Color        bgTint;
  final VoidCallback onTap;
  final int          delay;

  const _StatTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.bgTint,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.spaceBetween,
          children: [
            // Icon badge
            Container(
              width:  34,
              height: 34,
              decoration: BoxDecoration(
                color:        bgTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),

            // Number + label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    color:      const Color(0xFF1A202C),
                    fontSize:   22,
                    fontWeight: FontWeight.w800,
                    height:     1.1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color:      const Color(0xFF718096),
                    fontSize:   10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
        .fadeIn(delay: delay.ms, duration: 300.ms)
        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1),
               delay: delay.ms, duration: 260.ms, curve: Curves.easeOut);
  }
}

// ── Filter chips ───────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final String?                    selected;
  final void Function(String?)     onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  static const _filters = <(String?, String)>[
    (null,          'All'),
    ('pending',     'Pending'),
    ('assigned',    'Assigned'),
    ('in_progress', 'In Progress'),
    ('completed',   'Completed'),
    ('cancelled',   'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: _filters.map((f) {
          final (value, label) = f;
          final isSelected     = selected == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label,
                  style: GoogleFonts.poppins(
                    fontSize:   11,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  )),
              selected:        isSelected,
              selectedColor:   AppColors.primary,
              checkmarkColor:  Colors.white,
              backgroundColor: Colors.white,
              side:            BorderSide(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
              padding:    const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (_) => onChanged(value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool         hasFilter;
  final VoidCallback onNewRequest;

  const _EmptyState({required this.hasFilter, required this.onNewRequest});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width:  96,
              height: 96,
              decoration: BoxDecoration(
                color:        AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                hasFilter
                    ? Icons.filter_list_off_rounded
                    : Icons.medical_services_outlined,
                size:  48,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter
                  ? 'No requests with this status.'
                  : AppStrings.noDataFound,
              style: GoogleFonts.poppins(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 8),
              Text(
                'Tap the + button to submit your first service request.',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onNewRequest,
                icon:  const Icon(Icons.add_rounded),
                label: Text('New Request',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
        begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

// ── Error body ─────────────────────────────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: Text('Retry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit Request Sheet (unchanged logic, improved styling) ────────────────────
class _EditRequestSheet extends StatefulWidget {
  final dynamic request;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  const _EditRequestSheet({required this.request, required this.onSave});

  @override
  State<_EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends State<_EditRequestSheet> {
  final _formKey    = GlobalKey<FormState>();
  late final _contactCtrl = TextEditingController(text: widget.request.contactNumber ?? '');
  late final _descCtrl    = TextEditingController(text: widget.request.description ?? '');
  late final _addressCtrl = TextEditingController(text: widget.request.address);
  late final _cityCtrl    = TextEditingController(text: widget.request.city);
  late final _stateCtrl   = TextEditingController(text: widget.request.state ?? '');
  late final _pincodeCtrl = TextEditingController(text: widget.request.pincode ?? '');
  late final _numDaysCtrl = TextEditingController(text: '${widget.request.numDays}');
  late final _notesCtrl   = TextEditingController(text: widget.request.specialNotes ?? '');

  late String  _urgencyLevel  = widget.request.urgencyLevel;
  late String? _preferredTime = widget.request.preferredTime;
  DateTime?    _preferredDate;
  bool         _isLoading     = false;

  static const _timeSlots = [
    'Morning 8-10 AM', 'Morning 10-12 PM',
    'Afternoon 12-2 PM', 'Afternoon 2-4 PM',
    'Evening 4-6 PM',   'Evening 6-8 PM',
  ];

  @override
  void initState() {
    super.initState();
    try {
      _preferredDate = DateTime.parse(widget.request.preferredDate);
    } catch (_) {
      _preferredDate = DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  void dispose() {
    _contactCtrl.dispose(); _descCtrl.dispose(); _addressCtrl.dispose();
    _cityCtrl.dispose();    _stateCtrl.dispose(); _pincodeCtrl.dispose();
    _numDaysCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _preferredDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = <String, dynamic>{};
    if (_contactCtrl.text.trim().isNotEmpty)
      data['contact_number']  = _contactCtrl.text.trim();
    if (_descCtrl.text.trim().isNotEmpty)
      data['description']     = _descCtrl.text.trim();
    data['address']           = _addressCtrl.text.trim();
    data['city']              = _cityCtrl.text.trim();
    if (_stateCtrl.text.trim().isNotEmpty)
      data['state']           = _stateCtrl.text.trim();
    if (_pincodeCtrl.text.trim().isNotEmpty)
      data['pincode']         = _pincodeCtrl.text.trim();
    if (_preferredDate != null)
      data['preferred_date']  = DateFormat('yyyy-MM-dd').format(_preferredDate!);
    data['num_days']          = int.tryParse(_numDaysCtrl.text.trim()) ?? 1;
    data['urgency_level']     = _urgencyLevel;
    if (_preferredTime != null)
      data['preferred_time']  = _preferredTime;
    if (_notesCtrl.text.trim().isNotEmpty)
      data['special_notes']   = _notesCtrl.text.trim();

    final ok = await widget.onSave(data);
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:        AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),

                // Title
                Row(children: [
                  Container(
                    padding:    const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient:     AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Edit: ${AppHelpers.serviceTypeLabel(widget.request.serviceType)}',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  )),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
                const SizedBox(height: 16),

                _field('Contact Number (optional)', _contactCtrl,
                    keyboardType: TextInputType.phone,
                    validator:    Validators.phone),
                const SizedBox(height: 12),
                _field('Description (optional)', _descCtrl, maxLines: 2),
                const SizedBox(height: 12),
                _field('Address *', _addressCtrl,
                    validator: (v) => Validators.required(v, 'Address'),
                    maxLines:  2),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field('City *', _cityCtrl,
                      validator: (v) => Validators.required(v, 'City'))),
                  const SizedBox(width: 10),
                  Expanded(child: _field('State', _stateCtrl)),
                ]),
                const SizedBox(height: 12),
                _field('Pincode', _pincodeCtrl,
                    keyboardType: TextInputType.number,
                    validator:    Validators.pincode),
                const SizedBox(height: 12),

                // Date picker
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color:        AppColors.background,
                      border:       Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _preferredDate == null
                            ? 'Select Date'
                            : DateFormat('dd MMM yyyy').format(_preferredDate!),
                        style: GoogleFonts.poppins(
                          color: _preferredDate == null
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                _field('Number of Days *', _numDaysCtrl,
                    keyboardType: TextInputType.number,
                    validator:    (v) =>
                        Validators.positiveInt(v, min: 1, max: 365)),
                const SizedBox(height: 12),

                DropdownButtonFormField<String?>(
                  initialValue: _preferredTime,
                  decoration: InputDecoration(
                    labelText:  'Preferred Time (optional)',
                    prefixIcon: const Icon(Icons.access_time_outlined),
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: null,
                        child: Text('No preference',
                            style: GoogleFonts.poppins(fontSize: 13))),
                    ..._timeSlots.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t,
                            style: GoogleFonts.poppins(fontSize: 13)))),
                  ],
                  onChanged: (v) => setState(() => _preferredTime = v),
                ),
                const SizedBox(height: 12),

                Text('Urgency Level',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize:   13,
                      color:      AppColors.textSecondary,
                    )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final opt in [
                      ('routine',   'Routine',   AppColors.success),
                      ('urgent',    'Urgent',    AppColors.warning),
                      ('emergency', 'Emergency', AppColors.error),
                    ]) ...[
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _urgencyLevel = opt.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _urgencyLevel == opt.$1
                                ? opt.$3.withValues(alpha: 0.10)
                                : Colors.white,
                            border: Border.all(
                              color: _urgencyLevel == opt.$1
                                  ? opt.$3
                                  : AppColors.divider,
                              width: _urgencyLevel == opt.$1 ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(opt.$2,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize:   12,
                                fontWeight: _urgencyLevel == opt.$1
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _urgencyLevel == opt.$1
                                    ? opt.$3
                                    : AppColors.textHint,
                              )),
                        ),
                      )),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                _field('Special Notes (optional)', _notesCtrl, maxLines: 2),
                const SizedBox(height: 20),

                Container(
                  height:     52,
                  decoration: BoxDecoration(
                    gradient:     _isLoading ? null : AppColors.primaryGradient,
                    color:        _isLoading ? AppColors.textHint : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color:        Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap:        _isLoading ? null : _submit,
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Text('Save Changes',
                                style: GoogleFonts.poppins(
                                  color:      Colors.white,
                                  fontSize:   14,
                                  fontWeight: FontWeight.w600,
                                )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller:   ctrl,
      validator:    validator,
      keyboardType: keyboardType,
      maxLines:     maxLines,
      style:        GoogleFonts.poppins(fontSize: 13),
      decoration:   InputDecoration(
        labelText:  label,
        labelStyle: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }
}
