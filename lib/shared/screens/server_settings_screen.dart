import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/dio_client.dart';

/// Debug screen to update the backend URL at runtime.
/// Accessible from the patient dashboard (long-press the AppBar title)
/// or from the nurse/admin profile.
///
/// This solves the ngrok URL-change problem without rebuilding the APK.
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final _urlCtrl = TextEditingController(text: ApiConstants.baseUrl);
  bool _isSaving = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() { _message = 'URL cannot be empty'; _isError = true; });
      return;
    }
    if (!url.startsWith('http')) {
      setState(() { _message = 'URL must start with http:// or https://'; _isError = true; });
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ApiConstants.setBaseUrl(url);
      // Re-initialise Dio with the new URL immediately
      DioClient.instance.updateBaseUrl(ApiConstants.baseUrl);
      setState(() {
        _isSaving = false;
        _message  = 'Server URL updated successfully!\nNew URL: ${ApiConstants.baseUrl}';
        _isError  = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _message  = 'Failed to save: $e';
        _isError  = true;
      });
    }
  }

  Future<void> _reset() async {
    await ApiConstants.resetBaseUrl();
    DioClient.instance.updateBaseUrl(ApiConstants.baseUrl);
    setState(() {
      _urlCtrl.text = ApiConstants.baseUrl;
      _message      = 'Reset to default: ${ApiConstants.baseUrl}';
      _isError      = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 16),
                    SizedBox(width: 8),
                    Text('When to use this',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                            fontSize: 13)),
                  ]),
                  SizedBox(height: 6),
                  Text(
                    'Update this URL when your ngrok tunnel changes.\n'
                    'Format: https://xxxx.ngrok-free.app/api/v1\n'
                    'Changes take effect immediately — no rebuild needed.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Current URL label
            const Text('Backend API URL',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF616161))),
            const SizedBox(height: 8),

            // URL input
            TextFormField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'https://xxxx.ngrok-free.app/api/v1',
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => _urlCtrl.clear(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving…' : 'Save & Apply'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 12),

            // Reset button
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Reset to Default'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.textSecondary),
                foregroundColor: AppColors.textSecondary,
              ),
            ),

            // Result message
            if (_message != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isError ? AppColors.error : AppColors.success)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_isError ? AppColors.error : AppColors.success)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _isError ? AppColors.error : AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isError ? AppColors.error : AppColors.success,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
