import 'package:flutter/material.dart';
import '../../data/models/service_request_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';

/// Service request card shown on the patient dashboard.
/// Shows full request info + Edit / Cancel actions for pending requests.
class ServiceRequestCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const ServiceRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onEdit,
    this.onCancel,
  });

  Color get _statusColor {
    switch (request.status) {
      case 'pending':     return AppColors.warning;
      case 'assigned':    return AppColors.info;
      case 'in_progress': return AppColors.primary;
      case 'completed':   return AppColors.success;
      case 'cancelled':   return AppColors.textSecondary;
      default:            return AppColors.textSecondary;
    }
  }

  Color get _urgencyColor {
    switch (request.urgencyLevel) {
      case 'emergency': return AppColors.error;
      case 'urgent':    return AppColors.warning;
      default:          return AppColors.success;
    }
  }

  bool get _isPending => request.status == 'pending';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: service type + status ──────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppHelpers.serviceTypeLabel(request.serviceType),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _Chip(
                    label: AppHelpers.statusLabel(request.status),
                    color: _statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Row 2: patient name ────────────────────────────────────
              _InfoRow(Icons.person_outline, request.patientName),

              // ── Row 3: location ────────────────────────────────────────
              _InfoRow(
                Icons.location_on_outlined,
                [request.city, if (request.state != null) request.state!]
                    .join(', '),
              ),

              // ── Row 4: date + days ─────────────────────────────────────
              _InfoRow(
                Icons.calendar_today_outlined,
                'Date: ${request.preferredDate}  •  ${request.numDays} day(s)',
              ),

              // ── Row 5: preferred time (if set) ─────────────────────────
              if (request.preferredTime != null)
                _InfoRow(Icons.access_time_outlined, request.preferredTime!),

              const SizedBox(height: 10),

              // ── Row 6: urgency badge + action buttons ──────────────────
              Row(
                children: [
                  // Urgency badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _urgencyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _urgencyColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      AppHelpers.urgencyLabel(request.urgencyLevel),
                      style: TextStyle(
                        color: _urgencyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Edit button — only for pending requests
                  if (_isPending && onEdit != null) ...[
                    _ActionButton(
                      icon:  Icons.edit_outlined,
                      label: 'Edit',
                      color: AppColors.primary,
                      onTap: onEdit!,
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Cancel button — only for pending requests
                  if (_isPending && onCancel != null)
                    _ActionButton(
                      icon:  Icons.cancel_outlined,
                      label: 'Cancel',
                      color: AppColors.error,
                      onTap: onCancel!,
                    ),
                ],
              ),

              // ── Special notes preview ──────────────────────────────────
              if (request.specialNotes != null &&
                  request.specialNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          request.specialNotes!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}

// ── Small action button ───────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
