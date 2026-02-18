import 'dart:math';

class EmailVerificationService {
  // Mock email verification service
  // Gerçek uygulamada backend API'ye istek gönderilecek
  
  static final Map<String, String> _verificationCodes = {};
  static final Map<String, DateTime> _codeExpiry = {};
  static final Map<String, bool> _verifiedEmails = {}; // Doğrulanmış email'ler

  // Email'e doğrulama kodu gönder
  Future<bool> sendVerificationCode(String email) async {
    // Gerçek uygulamada burada email gönderme API'si çağrılacak
    // Şimdilik mock olarak kod üretiyoruz
    
    final emailKey = email.toLowerCase();
    
    // Yeni kod gönderildiğinde önceki doğrulama durumunu sıfırla
    _verifiedEmails.remove(emailKey);
    
    final code = _generateCode();
    _verificationCodes[emailKey] = code;
    _codeExpiry[emailKey] = DateTime.now().add(const Duration(minutes: 10));
    
    // Debug için konsola yazdırıyoruz
    print('Verification code for $email: $code');
    
    // Simüle edilmiş network delay
    await Future.delayed(const Duration(seconds: 1));
    
    return true;
  }

  // Son gönderilen kodu al (development için)
  Future<String?> getLastCode(String email) async {
    return _verificationCodes[email.toLowerCase()];
  }

  // Doğrulama kodunu kontrol et
  Future<bool> verifyCode(String email, String code) async {
    final emailKey = email.toLowerCase();
    
    // Eğer daha önce doğrulanmışsa true döndür
    if (_verifiedEmails[emailKey] == true) {
      return true;
    }
    
    if (!_verificationCodes.containsKey(emailKey)) {
      return false;
    }

    final expiry = _codeExpiry[emailKey];
    if (expiry == null || DateTime.now().isAfter(expiry)) {
      _verificationCodes.remove(emailKey);
      _codeExpiry.remove(emailKey);
      return false;
    }

    final isValid = _verificationCodes[emailKey] == code;
    
    if (isValid) {
      // Kod doğru, doğrulanmış olarak işaretle (silme)
      _verifiedEmails[emailKey] = true;
      // Kodları temizle (güvenlik için)
      _verificationCodes.remove(emailKey);
      _codeExpiry.remove(emailKey);
    }
    
    return isValid;
  }

  // 6 haneli kod üret
  String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Kod süresini kontrol et
  bool isCodeExpired(String email) {
    final emailKey = email.toLowerCase();
    final expiry = _codeExpiry[emailKey];
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }
}
