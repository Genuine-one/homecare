import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.adminColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/admin-login');
            },
          ),
        ],
      ),
      body: adminState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) {
          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(adminProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(adminProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats cards
                  if (state.stats != null) ...[
                    const Text('Overview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [
                        _StatCard('Total Patients',
                          '${state.stats!['total_patients'] ?? 0}',
                          Icons.people_outline, AppColors.patientColor),
                        _StatCard('Total Nurses',
                          '${state.stats!['total_nurses'] ?? 0}',
                          Icons.medical_services_outlined, AppColors.nurseColor),
                        _StatCard('Pending',
                          '${state.stats!['pending_requests'] ?? 0}',
                          Icons.pending_outlined, AppColors.warning),
                        _StatCard('Completed',
                          '${state.stats!['completed_requests'] ?? 0}',
                          Icons.check_circle_outline, AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Recent requests
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Requests',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => context.go('/admin/requests'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.requests.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(AppStrings.noDataFound),
                    ))
                  else
                    ...state.requests.take(5).map((req) => _RequestTile(
                      request: req,
                      nurses: state.nurses,
                      onAssign: (nurseId) => ref.read(adminProvider.notifier)
                        .assignNurse(req['id'] as String, nurseId),
                    )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final Map<String, dynamic> request;
  final List<Map<String, dynamic>> nurses;
  final Future<String?> Function(String nurseId) onAssign;

  const _RequestTile({
    required this.request,
    required this.nurses,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
        ),
        title: Text(
          AppHelpers.serviceTypeLabel(request['service_type'] as String? ?? ''),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${request['patient_name']} • ${request['city']}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isPending && nurses.isNotEmpty
          ? ElevatedButton(
              onPressed: () => _showAssignDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Assign'),
            )
          : Chip(
              label: Text(AppHelpers.statusLabel(status),
                style: const TextStyle(fontSize: 11)),
              backgroundColor: _statusColor(status).withValues(alpha: 0.12),
            ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':     return AppColors.warning;
      case 'assigned':    return AppColors.info;
      case 'in_progress': return AppColors.primary;
      case 'completed':   return AppColors.success;
      default:            return AppColors.textSecondary;
    }
  }

  Future<void> _showAssignDialog(BuildContext context) async {
    String? selectedNurseId;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Assign Nurse'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                hint: const Text('Select a nurse'),
                value: selectedNurseId,
                items: nurses.map((n) => DropdownMenuItem(
                  value: n['id'] as String,
                  child: Text('${n['first_name']} ${n['last_name']}'),
                )).toList(),
                onChanged: (v) => setDialogState(() {
                  selectedNurseId = v;
                  dialogError = null;
                }),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(
                  dialogError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedNurseId == null
                ? null
                : () async {
                    final error = await onAssign(selectedNurseId!);
                    if (error == null) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Nurse assigned successfully!'),
                          backgroundColor: Colors.green,
                        ));
                      }
                    } else {
                      setDialogState(() => dialogError = error);
                    }
                  },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}
