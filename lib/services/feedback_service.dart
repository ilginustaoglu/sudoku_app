import '../config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum FeedbackCategory {
  suggestion('Suggestion'),
  bug('Bug Report'),
  general('General');

  const FeedbackCategory(this.label);
  final String label;
}

class FeedbackException implements Exception {
  FeedbackException(this.message);
  final String message;

  @override
  String toString() => message;
}

class FeedbackService {
  /// Geri bildirimi Supabase veritabanına kaydeder.
  Future<void> sendFeedback({
    required FeedbackCategory category,
    required String message,
    String? senderEmail,
    String? senderName,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw FeedbackException(
        'Feedback service is not configured. Please add Supabase credentials.',
      );
    }

    try {
      await Supabase.instance.client.from('feedback').insert({
        'category': category.label,
        'message': message.trim(),
        'sender_email': senderEmail,
        'sender_name': senderName,
      });
    } on PostgrestException catch (e) {
      throw FeedbackException(
        e.message.isNotEmpty ? e.message : 'Could not send feedback.',
      );
    } catch (_) {
      throw FeedbackException(
        'Could not send feedback. Please check your connection.',
      );
    }
  }
}
