class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String? avatarPath; // Avatar resmi yolu (opsiyonel)
  final String? coverImagePath; // Kapak resmi yolu (opsiyonel)
  final String? displayName; // Görünen kullanıcı adı (opsiyonel)
  final int? avatarColor; // Avatar rengi (opsiyonel, Color.value olarak saklanır)
  final int? coverImageColor; // Kapak resmi rengi (opsiyonel, Color.value olarak saklanır)
  final DateTime createdAt;
  final DateTime? lastPlayedAt;
  final bool emailVerified;
  final String passwordHash; // Şifre hash'i (güvenlik için)

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    this.avatarPath,
    this.coverImagePath,
    this.displayName,
    this.avatarColor,
    this.coverImageColor,
    required this.createdAt,
    this.lastPlayedAt,
    this.emailVerified = false,
    required this.passwordHash,
  });

  String get fullName => '$firstName $lastName';

  // JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'avatarPath': avatarPath,
      'coverImagePath': coverImagePath,
      'displayName': displayName,
      'avatarColor': avatarColor,
      'coverImageColor': coverImageColor,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'emailVerified': emailVerified,
      'passwordHash': passwordHash,
    };
  }

  // JSON'dan oluştur
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      avatarPath: json['avatarPath'] as String?,
      coverImagePath: json['coverImagePath'] as String?,
      displayName: json['displayName'] as String?,
      avatarColor: json['avatarColor'] as int?,
      coverImageColor: json['coverImageColor'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'] as String)
          : null,
      emailVerified: json['emailVerified'] as bool? ?? false,
      passwordHash: json['passwordHash'] as String? ?? '',
    );
  }

  // Kopya oluştur
  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? avatarPath,
    String? coverImagePath,
    String? displayName,
    int? avatarColor,
    int? coverImageColor,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    bool? emailVerified,
    String? passwordHash,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      avatarPath: avatarPath ?? this.avatarPath,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      displayName: displayName ?? this.displayName,
      avatarColor: avatarColor ?? this.avatarColor,
      coverImageColor: coverImageColor ?? this.coverImageColor,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      emailVerified: emailVerified ?? this.emailVerified,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }
}
