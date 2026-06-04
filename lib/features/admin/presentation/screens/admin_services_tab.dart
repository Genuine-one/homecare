import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/services_provider.dart';
import '../../data/models/service_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/kle_app_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Services Tab
// Fetches services from /api/v1/services on load.
// Admin can Create, Edit, Toggle active/inactive, Delete.
// ─────────────────────────────────────────────────────────────────────────────
class AdminServicesTab extends ConsumerStatefulWidget {
  const AdminServicesTab({super.key});

  @override
  ConsumerState<AdminServicesTab> createState() => _AdminServicesTabState();
}

class _AdminServicesTabState extends ConsumerState<AdminServicesTab> {
  String _searchQuery = '';
  final _searchCtrl   = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(servicesProvider);
    final isDesktop  = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : KleAppBar(
        roleColor: AppColors.adminColor,
        subtitle:  'Admin Panel',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () => ref.read(servicesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(servicesProvider.notifier).refresh(),
        ),
        data: (state) {
          // Show persistent snackbar for success / error messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 3),
                ));
            } else if (state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.error!),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 4),
                ));
            }
          });

          if (state.error != null && state.services.isEmpty) {
            return _ErrorView(
              message: state.error!,
              onRetry: () => ref.read(servicesProvider.notifier).refresh(),
            );
          }

          // Apply search filter
          var services = state.services;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            services = services.where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q),
            ).toList();
          }

          // Group by category
          final Map<String, List<ServiceModel>> grouped = {};
          for (final s in services) {
            grouped.putIfAbsent(s.category, () => []).add(s);
          }
          final sortedCategories = grouped.keys.toList()..sort();

          final totalServices    = state.services.length;
          final activeServices   = state.services.where((s) => s.isActive).length;
          final inactiveServices = state.services.where((s) => !s.isActive).length;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
            children: [
              // ── Loading indicator strip ──────────────────────────────
              if (state.isLoading)
                const LinearProgressIndicator(
                  color: AppColors.adminColor,
                  backgroundColor: AppColors.divider,
                ),

              // ── Stats header — white KPI cards on desktop, pill bar on mobile
              _ServicesHeader(
                total:    totalServices,
                active:   activeServices,
                inactive: inactiveServices,
                isDesktop: isDesktop,
                onRefresh: () => ref.read(servicesProvider.notifier).refresh(),
              ),

              // ── Search ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    isDesktop ? 24 : 16, 12,
                    isDesktop ? 24 : 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search services…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // ── List / Table ──────────────────────────────────────────
              Expanded(
                child: services.isEmpty
                    ? _EmptyView(
                        hasSearch: _searchQuery.isNotEmpty,
                        onAdd: () => _showServiceSheet(context, null),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(servicesProvider.notifier).refresh(),
                        child: isDesktop
                            // ── Desktop: table view ──────────────────────
                            ? _ServicesTable(
                                services:  services,
                                onEdit:    (s) => _showServiceSheet(context, s),
                                onToggle:  (s) => ref.read(servicesProvider.notifier).toggleService(s.id),
                                onDelete:  (s) => _confirmDelete(context, s),
                              )
                            // ── Mobile: card list ─────────────────────────
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                                children: [
                                  for (final cat in sortedCategories) ...[
                                    _CategoryHeader(
                                      category: cat,
                                      count: grouped[cat]!.length,
                                    ),
                                    const SizedBox(height: 6),
                                    for (final svc in grouped[cat]!)
                                      _ServiceCard(
                                        service: svc,
                                        onEdit: () =>
                                            _showServiceSheet(context, svc),
                                        onToggle: () => ref
                                            .read(servicesProvider.notifier)
                                            .toggleService(svc.id),
                                        onDelete: () =>
                                            _confirmDelete(context, svc),
                                      ),
                                    const SizedBox(height: 16),
                                  ],
                                ],
                              ),
                      ),
              ),
            ],
              ),   // Column
            ),     // ConstrainedBox
          );       // Align
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag:         'services_fab',
        onPressed: () => _showServiceSheet(context, null),
        backgroundColor: AppColors.adminColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Service',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Show create / edit sheet ──────────────────────────────────────────────
  void _showServiceSheet(BuildContext context, ServiceModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceFormSheet(
        existing: existing,
        onSave: (name, desc, cat, icon) async {
          if (existing == null) {
            return ref.read(servicesProvider.notifier).createService(
                  name:        name,
                  description: desc,
                  category:    cat,
                  icon:        icon,
                );
          } else {
            return ref.read(servicesProvider.notifier).updateService(
                  existing.id,
                  name:        name,
                  description: desc,
                  category:    cat,
                  icon:        icon,
                );
          }
        },
      ),
    );
  }

  // ── Confirm delete ────────────────────────────────────────────────────────
  Future<void> _confirmDelete(BuildContext context, ServiceModel svc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Service'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            children: [
              const TextSpan(text: 'Permanently remove '),
              TextSpan(
                text: '"${svc.name}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(80, 40)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(servicesProvider.notifier)
          .deleteService(svc.id, svc.name);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Services Header — desktop: page title + KPI cards; mobile: gradient pill bar
// ─────────────────────────────────────────────────────────────────────────────
class _ServicesHeader extends StatelessWidget {
  final int  total;
  final int  active;
  final int  inactive;
  final bool isDesktop;
  final VoidCallback onRefresh;

  const _ServicesHeader({
    required this.total,
    required this.active,
    required this.inactive,
    required this.isDesktop,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page banner
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: const BoxDecoration(gradient: AppColors.adminGradient),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service Catalogue',
                          style: GoogleFonts.poppins(
                            color:      Colors.white.withValues(alpha: 0.72),
                            fontSize:   12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          )),
                      Text('Manage Services',
                          style: GoogleFonts.poppins(
                            color:      Colors.white,
                            fontSize:   22,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: onRefresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          // White KPI cards
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                _KpiCard(label: 'Total Services', value: '$total',
                    icon: Icons.medical_services_rounded,
                    accentColor: AppColors.adminColor,
                    bgTint: const Color(0xFFF3E5F5)),
                const SizedBox(width: 16),
                _KpiCard(label: 'Active', value: '$active',
                    icon: Icons.check_circle_rounded,
                    accentColor: AppColors.success,
                    bgTint: const Color(0xFFE8F5E9)),
                const SizedBox(width: 16),
                _KpiCard(label: 'Inactive', value: '$inactive',
                    icon: Icons.cancel_rounded,
                    accentColor: AppColors.error,
                    bgTint: const Color(0xFFFFEBEE)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    // Mobile: gradient pill bar
    return Container(
      color:   AppColors.adminColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _MobilePill('Total',    '$total',    Colors.white),
          const SizedBox(width: 8),
          _MobilePill('Active',   '$active',   Colors.green.shade300),
          const SizedBox(width: 8),
          _MobilePill('Inactive', '$inactive', Colors.orange.shade300),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    accentColor;
  final Color    bgTint;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.bgTint,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color:        bgTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                      color:      const Color(0xFF1A202C),
                      fontSize:   24,
                      fontWeight: FontWeight.w800,
                      height:     1.1,
                    )),
                Text(label,
                    style: GoogleFonts.poppins(
                      color:      const Color(0xFF718096),
                      fontSize:   11,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobilePill extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _MobilePill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop services table
// ─────────────────────────────────────────────────────────────────────────────
class _ServicesTable extends StatelessWidget {
  final List<ServiceModel> services;
  final void Function(ServiceModel) onEdit;
  final void Function(ServiceModel) onToggle;
  final void Function(ServiceModel) onDelete;

  const _ServicesTable({
    required this.services,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
      child: Container(
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
              0: FlexColumnWidth(2.5),   // Name
              1: FlexColumnWidth(1.2),   // Category
              2: FlexColumnWidth(3.0),   // Description
              3: FlexColumnWidth(0.8),   // Status
              4: FlexColumnWidth(1.0),   // Actions
            },
            children: [
              // ── Header row ─────────────────────────────────────────────
              TableRow(
                decoration: const BoxDecoration(
                  color: AppColors.adminColor,
                ),
                children: [
                  _TH('Service Name'),
                  _TH('Category'),
                  _TH('Description'),
                  _TH('Status'),
                  _TH('Actions'),
                ],
              ),
              // ── Data rows ──────────────────────────────────────────────
              ...services.asMap().entries.map((entry) {
                final i   = entry.key;
                final svc = entry.value;
                final isEven = i.isEven;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven ? Colors.white : const Color(0xFFFAFAFB),
                  ),
                  children: [
                    _TD(
                      child: Row(children: [
                        Container(
                          width:  36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.adminColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.medical_services_outlined,
                              color: AppColors.adminColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(svc.name,
                              style: GoogleFonts.poppins(
                                fontSize:   13,
                                fontWeight: FontWeight.w600,
                                color:      AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),
                    _TD(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.adminColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(svc.category,
                            style: GoogleFonts.poppins(
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              color:      AppColors.adminColor,
                            )),
                      ),
                    ),
                    _TD(
                      child: Text(svc.description,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:    AppColors.textSecondary,
                          ),
                          maxLines:  2,
                          overflow:  TextOverflow.ellipsis),
                    ),
                    _TD(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: svc.isActive
                              ? AppColors.success.withValues(alpha: 0.10)
                              : AppColors.error.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: svc.isActive
                                ? AppColors.success.withValues(alpha: 0.35)
                                : AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          svc.isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.poppins(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color: svc.isActive
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    _TD(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TableAction(
                            icon:    Icons.edit_outlined,
                            color:   AppColors.adminColor,
                            tooltip: 'Edit',
                            onTap:   () => onEdit(svc),
                          ),
                          const SizedBox(width: 4),
                          _TableAction(
                            icon: svc.isActive
                                ? Icons.toggle_off_outlined
                                : Icons.toggle_on_outlined,
                            color:   svc.isActive
                                ? AppColors.warning
                                : AppColors.success,
                            tooltip: svc.isActive ? 'Deactivate' : 'Activate',
                            onTap:   () => onToggle(svc),
                          ),
                          const SizedBox(width: 4),
                          _TableAction(
                            icon:    Icons.delete_outline,
                            color:   AppColors.error,
                            tooltip: 'Delete',
                            onTap:   () => onDelete(svc),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(text,
          style: GoogleFonts.poppins(
            color:      Colors.white,
            fontSize:   12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          )),
    );
  }
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: child,
    );
  }
}

class _TableAction extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   tooltip;
  final VoidCallback onTap;
  const _TableAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width:  32,
            height: 32,
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category header
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryHeader extends StatelessWidget {
  final String category;
  final int    count;
  const _CategoryHeader({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            color: AppColors.adminColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(category,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.adminColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.adminColor,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service card
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = service.isActive;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: active
              ? AppColors.adminColor.withValues(alpha: 0.12)
              : AppColors.divider,
          child: Icon(
            Icons.medical_services_outlined,
            color: active ? AppColors.adminColor : AppColors.textHint,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                service.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ),
            // Active / Inactive badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                active ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            service.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'edit')   onEdit();
            if (v == 'toggle') onToggle();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.edit_outlined,
                    color: AppColors.primary),
                title: Text('Edit'),
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                dense: true,
                leading: Icon(
                  active
                      ? Icons.toggle_off_outlined
                      : Icons.toggle_on_outlined,
                  color: active ? AppColors.warning : AppColors.success,
                ),
                title: Text(active ? 'Deactivate' : 'Activate'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Delete',
                    style: TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create / Edit form sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceFormSheet extends StatefulWidget {
  final ServiceModel? existing;
  final Future<bool> Function(
    String name,
    String description,
    String category,
    String? icon,
  ) onSave;

  const _ServiceFormSheet({this.existing, required this.onSave});

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey  = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(
      text: widget.existing?.name ?? '');
  late final _descCtrl = TextEditingController(
      text: widget.existing?.description ?? '');
  late final _catCtrl  = TextEditingController(
      text: widget.existing?.category ?? '');
  late final _iconCtrl = TextEditingController(
      text: widget.existing?.icon ?? '');

  bool _isLoading = false;

  // Preset categories for quick selection
  static const _presetCategories = [
    'Nursing', 'Therapy', 'Medical', 'Care', 'Diagnostic', 'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final ok = await widget.onSave(
      _nameCtrl.text.trim(),
      _descCtrl.text.trim(),
      _catCtrl.text.trim(),
      _iconCtrl.text.trim().isEmpty ? null : _iconCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
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
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.adminColor.withValues(alpha: 0.12),
                      child: const Icon(Icons.medical_services_outlined,
                          color: AppColors.adminColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEdit ? 'Edit Service' : 'Add New Service',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Service Name *',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'At least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Description is required';
                    }
                    if (v.trim().length < 5) return 'At least 5 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Category — text field + preset chips
                TextFormField(
                  controller: _catCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category_outlined),
                    hintText: 'e.g. Nursing, Therapy…',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Category is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Quick-pick chips
                Wrap(
                  spacing: 6,
                  children: _presetCategories.map((cat) {
                    final selected = _catCtrl.text.trim() == cat;
                    return ChoiceChip(
                      label: Text(cat,
                          style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                      selected: selected,
                      selectedColor: AppColors.adminColor,
                      onSelected: (_) =>
                          setState(() => _catCtrl.text = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Icon (optional)
                TextFormField(
                  controller: _iconCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Icon name / URL (optional)',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          isEdit ? 'Save Changes' : 'Create Service',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;
  const _EmptyView({required this.hasSearch, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.medical_services_outlined,
              size: 72,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch
                  ? 'No services match your search.'
                  : 'No services yet.',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 8),
              const Text(
                'Tap the + button below to add your first service.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Service'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
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
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      ),
    );
  }
}
