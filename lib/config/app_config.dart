/// Uygulama genelinde kullanılan sabitler.
class AppConfig {
  AppConfig._();

  /// Geri bildirimlerin gönderileceği admin e-posta adresi.
  static const String adminEmail = 'filginustaoglu@gmail.com';

  /// Supabase proje URL'si (Project Settings → API → Project URL).
  /// Data API adresindeki /rest/v1/ kısmını ekleme.
  static const String supabaseUrl =
      'https://exchgupikfqjvtylvkfu.supabase.co';

  /// Supabase publishable key (Project Settings → API).
  static const String supabaseAnonKey =
      'sb_publishable_eMB3uGSFBLbbczkMYsgH7Q_t8wJ4e0z';

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
