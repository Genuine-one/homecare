import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/nurse_provider.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const JobDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  Map<String, dynamic>? _job;
  bool    _isLoading  = true;
  String? _error;
  bool    _isUpdating = false;
  final   _notesCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJob() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.instance.get(
        ApiConstants.nurseJob(widget.assignmentId),
      );
      setState(() { _job = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = AppHelpers.friendlyError(e); _isLoading = false; });
    }
  }

  String? get _nextStatus {
    switch (_job?['status']) {
      case 'assigned':    return 'accepted';
      case 'accepted':    return 'in_progress';
      case 'in_progress': return 'completed';
      default:            return null;
    }
  }

  Color get _statusColor {
    switch (_job?['status'] as String? ?? '') {
      case 'assigned':    return AppColors.info;
      case 'accepted':    return AppColors.primary;
      case 'in_progress': return AppColors.warning;
      case 'completed':   return AppColors.success;
      case 'rejected':    return AppColors.error;
      default:            return AppColors.textSecondary;
    }
  }

  Color get _urgencyColor {
    switch (_job?['urgency_level'] as String? ?? 'routine') {
      case 'emergency': return AppColors.error;
      case 'urgent':    return AppColors.warning;
      default:          return AppColors.success;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final ok = await ref.read(nurseProvider.notifier).updateJobStatus(
      widget.assignmentId,
      newStatus,
      nurseNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _isUpdating = false;
      if (ok) _job = {...?_job, 'status': newStatus};
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status updated to ${AppHelpers.statusLabel(newStatus)}'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Job Detail'),
        backgroundColor: AppColors.nurseColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/nurse'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadJob,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _loadJob)
              : _job == null
                  ? const Center(child: Text('Job not found'))
                  : _buildBody(),
    );
  }

  Widget _buildBody() {
    final job    = _job!;
    final status = job['status'] as String? ?? '';
    final next   = _nextStatus;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status banner ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _statusColor.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Icon(_statusIcon(status), color: _statusColor, size: 28),
                const SizedBox(height: 6),
                Text(
                  AppHelpers.statusLabel(status),
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Patient Information ──────────────────────────────────────────
          _Section(
            title: 'Patient Information',
            icon: Icons.person_outline,
            color: AppColors.patientColor,
            children: [
              _DetailRow(Icons.person_outline, 'Name',
                  job['patient_name'] as String? ?? '—'),
              if ((job['contact_number'] as String?) != null)
                _DetailRow(Icons.phone_outlined, 'Contact',
                    job['contact_number'] as String,
                    highlight: true),
              _DetailRow(Icons.location_on_outlined, 'Address',
                  job['address'] as String? ?? '—'),
              _DetailRow(Icons.location_city_outlined, 'City',
                  job['city'] as String? ?? '—'),
              if ((job['state'] as String?) != null)
                _DetailRow(Icons.map_outlined, 'State',
                    job['state'] as String),
              if ((job['pincode'] as String?) != null)
                _DetailRow(Icons.pin_outlined, 'Pincode',
                    job['pincode'] as String),
            ],
          ),
          const SizedBox(height: 12),

          // ── Service Details ──────────────────────────────────────────────
          _Section(
            title: 'Service Details',
            icon: Icons.medical_services_outlined,
            color: AppColors.nurseColor,
            children: [
              _DetailRow(Icons.medical_services_outlined, 'Service',
                  AppHelpers.serviceTypeLabel(
                      job['service_type'] as String? ?? '')),
              _DetailRow(Icons.calendar_today_outlined, 'Preferred Date',
                  job['preferred_date'] as String? ?? '—'),
              _DetailRow(Icons.timelapse_outlined, 'Duration',
                  '${job['num_days'] ?? 1} day(s)'),
              if ((job['preferred_time'] as String?) != null)
                _DetailRow(Icons.access_time_outlined, 'Time Slot',
                    job['preferred_time'] as String),
              _DetailRow(Icons.priority_high_outlined, 'Urgency',
                  AppHelpers.urgencyLabel(
                      job['urgency_level'] as String? ?? 'routine'),
                  valueColor: _urgencyColor),
            ],
          ),
          const SizedBox(height: 12),

          // ── Notes ────────────────────────────────────────────────────────
          if ((job['description'] as String?) != null ||
              (job['special_notes'] as String?) != null) ...[
            _Section(
              title: 'Notes from Patient',
              icon: Icons.notes_outlined,
              color: AppColors.textSecondary,
              children: [
                if ((job['description'] as String?) != null)
                  _NoteBlock('Description', job['description'] as String,
                      AppColors.textSecondary),
                if ((job['special_notes'] as String?) != null)
                  _NoteBlock('Special Notes', job['special_notes'] as String,
                      AppColors.warning),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Assignment Info ──────────────────────────────────────────────
          _Section(
            title: 'Assignment Info',
            icon: Icons.assignment_outlined,
            color: AppColors.adminColor,
            children: [
              _DetailRow(Icons.schedule_outlined, 'Assigned At',
                  _fmtTs(job['assigned_at'] as String?)),
              if ((job['start_date'] as String?) != null)
                _DetailRow(Icons.play_circle_outline, 'Start Date',
                    job['start_date'] as String),
              if ((job['end_date'] as String?) != null)
                _DetailRow(Icons.event_outlined, 'End Date',
                    job['end_date'] as String),
            ],
          ),
          const SizedBox(height: 12),

          // ── Admin / Nurse notes ──────────────────────────────────────────
          if ((job['admin_notes'] as String?) != null) ...[
            _NoteBlock('Admin Notes', job['admin_notes'] as String,
                AppColors.adminColor),
            const SizedBox(height: 8),
          ],
          if ((job['nurse_notes'] as String?) != null) ...[
            _NoteBlock('Your Notes', job['nurse_notes'] as String,
                AppColors.nurseColor),
            const SizedBox(height: 8),
          ],

          // ── Action area ──────────────────────────────────────────────────
          if (next != null) ...[
            const SizedBox(height: 8),
            const Text('Add Notes (optional)',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any notes about this job…',
              ),
            ),
            const SizedBox(height: 16),
            if (status == 'assigned')
              OutlinedButton(
                onPressed: _isUpdating ? null : () => _updateStatus('rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reject Job'),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isUpdating ? null : () => _updateStatus(next),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nurseColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(_actionLabel(next),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _actionLabel(String s) {
    switch (s) {
      case 'accepted':    return 'Accept Job';
      case 'in_progress': return 'Start Job';
      case 'completed':   return 'Mark as Completed';
      default:            return AppHelpers.statusLabel(s);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'assigned':    return Icons.assignment_outlined;
      case 'accepted':    return Icons.check_circle_outline;
      case 'in_progress': return Icons.play_circle_outline;
      case 'completed':   return Icons.check_circle_outline;
      case 'rejected':    return Icons.cancel_outlined;
      default:            return Icons.info_outline;
    }
  }

  String _fmtTs(String? ts) {
    if (ts == null) return '—';
    try {
      return AppHelpers.formatDateTime(DateTime.parse(ts));
    } catch (_) {
      return ts;
    }
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color)),
            ]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  final bool     highlight;

  const _DetailRow(this.icon, this.label, this.value,
      {this.valueColor, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.bold : FontWeight.w500,
                color: valueColor ??
                    (highlight
                        ? AppColors.nurseColor
                        : AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  final String title;
  final String note;
  final Color  color;
  const _NoteBlock(this.title, this.note, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Text(note,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
