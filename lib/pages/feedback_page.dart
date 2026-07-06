import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/feedback_service.dart';
import '../services/profile_manager.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _feedbackService = FeedbackService();

  FeedbackCategory _category = FeedbackCategory.suggestion;
  bool _isSending = false;

  static const _green = Color(0xFF2E7D32);

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _categoryLabel(FeedbackCategory category, AppLocalizations l10n) {
    switch (category) {
      case FeedbackCategory.suggestion:
        return l10n.suggestion;
      case FeedbackCategory.bug:
        return l10n.bugReport;
      case FeedbackCategory.general:
        return l10n.general;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final profileManager = context.read<ProfileManager>();
    final profile = profileManager.currentProfile;

    try {
      await _feedbackService.sendFeedback(
        category: _category,
        message: _messageController.text,
        senderEmail: profile?.email,
        senderName: profile != null
            ? '${profile.firstName} ${profile.lastName}'.trim()
            : null,
      );

      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedbackThanks)),
      );
    } on FeedbackException catch (e) {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.localizeErrorMessage(e.message),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendFeedback),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline, color: _green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.feedbackIntro,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.category,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<FeedbackCategory>(
                value: _category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: FeedbackCategory.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(_categoryLabel(c, l10n)),
                      ),
                    )
                    .toList(),
                onChanged: _isSending
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _category = value);
                        }
                      },
              ),
              const SizedBox(height: 20),
              Text(
                l10n.message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 8,
                enabled: !_isSending,
                decoration: InputDecoration(
                  hintText: l10n.messageHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterMessage;
                  }
                  if (value.trim().length < 10) {
                    return l10n.messageMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSending ? l10n.sending : l10n.sendFeedback),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
