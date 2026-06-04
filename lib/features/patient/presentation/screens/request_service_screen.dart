import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/patient_provider.dart';
import '../providers/catalogue_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/kle_app_bar.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class RequestServiceScreen extends ConsumerStatefulWidget {
  const RequestServiceScreen({super.key});

  @override
  ConsumerState<RequestServiceScreen> createState() =>
      _RequestServiceScreenState();
}

class _RequestServiceScreenState extends ConsumerState<RequestServiceScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _patientNameCtrl = TextEditingController();
  final _contactCtrl     = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _cityCtrl        = TextEditingController();
  final _stateCtrl       = TextEditingController();
  final _pincodeCtrl     = TextEditingController();
  final _numDaysCtrl     = TextEditingController(text: '1');
  final _notesCtrl       = TextEditingController();

  // Selected service — null until the catalogue loads and user picks one
  CatalogueService? _selectedService;
  String  _urgencyLevel  = 'routine';
  String? _preferredTime;
  DateTime? _preferredDate;
  bool _isSubmitting = false;

  static const _timeSlots = [
    'Morning 8-10 AM',
    'Morning 10-12 PM',
    'Afternoon 12-2 PM',
    'Afternoon 2-4 PM',
    'Evening 4-6 PM',
    'Evening 6-8 PM',
  ];

  @override
  void initState() {
    super.initState();
    // Force a fresh fetch of services every time this screen opens.
    // This ensures newly added services from the admin panel are always visible,
    // regardless of what was cached from a previous visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Invalidate the cache so the next watch triggers a real network call
      ref.invalidate(catalogueProvider);

      // Pre-fill patient name
      final user = ref.read(authProvider).valueOrNull?.user;
      if (user != null) _patientNameCtrl.text = user.fullName;
    });
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _contactCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _numDaysCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
      _showSnack('Please select a service type', isError: true);
      return;
    }
    if (_preferredDate == null) {
      _showSnack('Please select a preferred date', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final ok = await ref.read(patientRequestsProvider.notifier).createRequest({
      'patient_name':   _patientNameCtrl.text.trim(),
      'contact_number': _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      'service_type':   _selectedService!.name,   // send service name to backend
      'description':    _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'address':        _addressCtrl.text.trim(),
      'city':           _cityCtrl.text.trim(),
      'state':          _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      'pincode':        _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
      'preferred_date': DateFormat('yyyy-MM-dd').format(_preferredDate!),
      'num_days':       int.parse(_numDaysCtrl.text.trim()),
      'preferred_time': _preferredTime,
      'urgency_level':  _urgencyLevel,
      'special_notes':  _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    });
    setState(() => _isSubmitting = false);

    if (ok && mounted) {
      _showSnack('Service request submitted successfully!');
      context.go('/patient');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final catalogueAsync = ref.watch(catalogueProvider);

    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: Scaffold(
        appBar: KleAppBar.back(
          title:     'New Service Request',
          roleColor: AppColors.primary,
          onBack:    () => context.go('/patient'),
        ),
        body: catalogueAsync.when(
          // ── Loading catalogue ──────────────────────────────────────────
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading available services…',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),

          // ── Catalogue error ────────────────────────────────────────────
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load services.\nPlease check your connection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(catalogueProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),

          // ── Catalogue loaded ───────────────────────────────────────────
          data: (services) {
            if (services.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.medical_services_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      const Text(
                        'No services are available yet.\nPlease contact the admin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(catalogueProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Patient info ─────────────────────────────────────
                    _SectionHeader('Patient Information'),
                    const SizedBox(height: 12),
                    _buildField(
                      'Patient Name',
                      _patientNameCtrl,
                      prefixIcon: Icons.person_outline,
                      validator: (v) => Validators.required(v, 'Patient name'),
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      'Contact Number',
                      _contactCtrl,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 20),

                    // ── Service selection ─────────────────────────────────
                    _SectionHeader('Select Service'),
                    const SizedBox(height: 12),

                    // Searchable service dropdown
                    _ServiceDropdownField(
                      services: services,
                      selected: _selectedService,
                      onSelected: (svc) =>
                          setState(() => _selectedService = svc),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    _buildField(
                      'Description (optional)',
                      _descCtrl,
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // ── Location ──────────────────────────────────────────
                    _SectionHeader('Location'),
                    const SizedBox(height: 12),
                    _buildField(
                      'Address',
                      _addressCtrl,
                      prefixIcon: Icons.home_outlined,
                      validator: (v) => Validators.required(v, 'Address'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _buildField(
                          'City',
                          _cityCtrl,
                          prefixIcon: Icons.location_city_outlined,
                          validator: (v) => Validators.required(v, 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          'State',
                          _stateCtrl,
                          prefixIcon: Icons.map_outlined,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildField(
                      'Pincode',
                      _pincodeCtrl,
                      prefixIcon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      validator: Validators.pincode,
                    ),
                    const SizedBox(height: 20),

                    // ── Schedule ──────────────────────────────────────────
                    _SectionHeader('Schedule'),
                    const SizedBox(height: 12),

                    // Date picker
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              _preferredDate == null
                                  ? 'Select Preferred Date *'
                                  : DateFormat('dd MMM yyyy')
                                      .format(_preferredDate!),
                              style: TextStyle(
                                color: _preferredDate == null
                                    ? AppColors.textHint
                                    : AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            if (_preferredDate != null)
                              const Icon(Icons.check_circle,
                                  color: AppColors.success, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildField(
                      'Number of Days',
                      _numDaysCtrl,
                      prefixIcon: Icons.timelapse_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          Validators.positiveInt(v, min: 1, max: 365),
                    ),
                    const SizedBox(height: 12),

                    // Preferred time dropdown
                    _buildLabeledDropdown<String?>(
                      label: 'Preferred Time (optional)',
                      icon:  Icons.access_time_outlined,
                      value: _preferredTime,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('No preference')),
                        ..._timeSlots.map((t) =>
                            DropdownMenuItem(value: t, child: Text(t))),
                      ],
                      onChanged: (v) => setState(() => _preferredTime = v),
                    ),
                    const SizedBox(height: 20),

                    // ── Urgency & notes ───────────────────────────────────
                    _SectionHeader('Urgency & Notes'),
                    const SizedBox(height: 12),

                    // Urgency chips
                    _UrgencySelector(
                      selected: _urgencyLevel,
                      onChanged: (v) => setState(() => _urgencyLevel = v),
                    ),
                    const SizedBox(height: 12),

                    _buildField(
                      'Special Notes (optional)',
                      _notesCtrl,
                      prefixIcon: Icons.note_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),

                    CustomButton(
                      label: AppStrings.submitRequest,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF616161))),
        const SizedBox(height: 6),
        TextFormField(
          controller:   ctrl,
          validator:    validator,
          keyboardType: keyboardType,
          maxLines:     maxLines,
          decoration: InputDecoration(
            hintText:   'Enter $label',
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF616161))),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Searchable service dropdown field
// Tapping opens a bottom sheet with a sticky search bar + grouped list.
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceDropdownField extends StatelessWidget {
  final List<CatalogueService> services;
  final CatalogueService?      selected;
  final void Function(CatalogueService) onSelected;

  const _ServiceDropdownField({
    required this.services,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          'Service Type *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF616161),
          ),
        ),
        const SizedBox(height: 6),

        // Tappable field that mimics a dropdown
        GestureDetector(
          onTap: () => _openSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: hasSelection ? AppColors.primary : AppColors.divider,
                width: hasSelection ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 20,
                  color: hasSelection ? AppColors.primary : AppColors.textHint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: hasSelection
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected!.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              selected!.category,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Tap to select a service…',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                        ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasSelection ? AppColors.primary : AppColors.textHint,
                ),
              ],
            ),
          ),
        ),

        // Inline description of selected service
        if (hasSelection) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              selected!.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceSearchSheet(
        services:   services,
        selected:   selected,
        onSelected: (svc) {
          Navigator.pop(context);
          onSelected(svc);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet with sticky search bar + grouped, filterable service list
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceSearchSheet extends StatefulWidget {
  final List<CatalogueService>         services;
  final CatalogueService?              selected;
  final void Function(CatalogueService) onSelected;

  const _ServiceSearchSheet({
    required this.services,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_ServiceSearchSheet> createState() => _ServiceSearchSheetState();
}

class _ServiceSearchSheetState extends State<_ServiceSearchSheet> {
  final _searchCtrl = TextEditingController();
  String _query     = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CatalogueService> get _filtered {
    if (_query.isEmpty) return widget.services;
    final q = _query.toLowerCase();
    return widget.services.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.description.toLowerCase().contains(q) ||
      s.category.toLowerCase().contains(q),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    // Group filtered results by category
    final Map<String, List<CatalogueService>> grouped = {};
    for (final s in filtered) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }
    final sortedCategories = grouped.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.4,
      maxChildSize:     0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Handle ────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Select Service',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Sticky search bar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller:    _searchCtrl,
                autofocus:     true,
                onChanged:     (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText:   'Search services…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled:      true,
                  fillColor:   AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // ── Result count ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} service${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(height: 1),

            // ── Scrollable list ───────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text(
                            'No services match "$_query"',
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final cat in sortedCategories) ...[
                          // Category header
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 14, 20, 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 3, height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${grouped[cat]!.length})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Service tiles
                          for (final svc in grouped[cat]!) ...[
                            _ServiceTile(
                              service:    svc,
                              isSelected: widget.selected?.id == svc.id,
                              query:      _query,
                              onTap:      () => widget.onSelected(svc),
                            ),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual service tile inside the search sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceTile extends StatelessWidget {
  final CatalogueService service;
  final bool             isSelected;
  final String           query;
  final VoidCallback     onTap;

  const _ServiceTile({
    required this.service,
    required this.isSelected,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                )
              : null,
        ),
        child: Row(
          children: [
            // Leading icon
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.background,
              child: Icon(
                Icons.medical_services_outlined,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),

            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightText(
                    text:  service.name,
                    query: query,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _HighlightText(
                    text:  service.description,
                    query: query,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Selected checkmark
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Highlights matching query text in bold+primary color
// ─────────────────────────────────────────────────────────────────────────────
class _HighlightText extends StatelessWidget {
  final String    text;
  final String    query;
  final TextStyle style;
  final int       maxLines;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: maxLines,
          overflow: TextOverflow.ellipsis);
    }

    final lower      = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final spans      = <TextSpan>[];
    int   start      = 0;

    while (true) {
      final idx = lower.indexOf(queryLower, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: style.copyWith(
          color:      AppColors.primary,
          fontWeight: FontWeight.bold,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        ),
      ));
      start = idx + query.length;
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Urgency selector — three colored chips
// ─────────────────────────────────────────────────────────────────────────────
class _UrgencySelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _UrgencySelector({
    required this.selected,
    required this.onChanged,
  });

  static const _options = [
    ('routine',   'Routine',   AppColors.success, Icons.check_circle_outline),
    ('urgent',    'Urgent',    AppColors.warning, Icons.warning_amber_outlined),
    ('emergency', 'Emergency', AppColors.error,   Icons.emergency_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (value, label, color, icon) = opt;
        final isSelected = selected == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? color
                        : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        color: isSelected ? color : AppColors.textHint,
                        size: 20),
                    const SizedBox(height: 4),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? color : AppColors.textHint)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
