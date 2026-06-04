import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';

class AssignNurseScreen extends ConsumerStatefulWidget {
  final String requestId;
  const AssignNurseScreen({super.key, required this.requestId});

  @override
  ConsumerState<AssignNurseScreen> createState() => _AssignNurseScreenState();
}

class _AssignNurseScreenState extends ConsumerState<AssignNurseScreen> {
  String? _selectedNurseId;
  final _notesCtrl = TextEditingController();
  bool _isLoading  = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    if (_selectedNurseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a nurse')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final error = await ref.read(adminProvider.notifier).assignNurse(
      widget.requestId,
      _selectedNurseId!,
      adminNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nurse assigned successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/admin');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final nurses = adminState.valueOrNull?.nurses ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Nurse'),
        backgroundColor: AppColors.adminColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select Nurse',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (nurses.isEmpty)
              const Center(child: Text('No active nurses available'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: nurses.length,
                  itemBuilder: (ctx, i) {
                    final nurse = nurses[i];
                    final id = nurse['id'] as String;
                    final isSelected = _selectedNurseId == id;
                    return Card(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.nurseColor.withValues(alpha: 0.15),
                          child: Text(
                            (nurse['first_name'] as String? ?? 'N')[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.nurseColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          '${nurse['first_name']} ${nurse['last_name']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(nurse['city'] as String? ?? ''),
                        trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                        onTap: () => setState(() => _selectedNurseId = id),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (optional)',
                hintText: 'Any special instructions for the nurse...',
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Assign Nurse',
              onPressed: _isLoading ? null : _assign,
            ),
          ],
        ),
      ),
    );
  }
}
