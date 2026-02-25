class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? dietType;
  final String? allergies;
  final String? dietaryGoals;
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String language;
  final bool isEmailVerified;
  final int totalScans;
  final int totalFavorites;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.phone,
    this.dateOfBirth,
    this.dietType,
    this.allergies,
    this.dietaryGoals,
    this.notificationsEnabled = false,
    this.darkModeEnabled = false,
    this.language = 'fr',
    this.isEmailVerified = false,
    this.totalScans = 0,
    this.totalFavorites = 0,
    this.lastLoginAt,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth'] as String) : null,
      dietType: json['dietType'] as String?,
      allergies: json['allergies'] as String?,
      dietaryGoals: json['dietaryGoals'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
      language: json['language'] as String? ?? 'fr',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      totalScans: json['totalScans'] as int? ?? 0,
      totalFavorites: json['totalFavorites'] as int? ?? 0,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get displayName {
    if (firstName != null && lastName != null) return '$firstName $lastName';
    if (firstName != null) return firstName!;
    return username;
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    return username[0].toUpperCase();
  }
}

class UserStats {
  final int totalScans;
  final int totalFavorites;
  final int totalProducts;
  final int scansThisWeek;
  final int scansThisMonth;
  final Map<String, int> nutriScoreDistribution;
  final double averageHealthScore;
  final DateTime memberSince;

  UserStats({
    required this.totalScans,
    required this.totalFavorites,
    required this.totalProducts,
    required this.scansThisWeek,
    required this.scansThisMonth,
    required this.nutriScoreDistribution,
    required this.averageHealthScore,
    required this.memberSince,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalScans: json['totalScans'] as int? ?? 0,
      totalFavorites: json['totalFavorites'] as int? ?? 0,
      totalProducts: json['totalProducts'] as int? ?? 0,
      scansThisWeek: json['scansThisWeek'] as int? ?? 0,
      scansThisMonth: json['scansThisMonth'] as int? ?? 0,
      nutriScoreDistribution: (json['nutriScoreDistribution'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      averageHealthScore: (json['averageHealthScore'] as num?)?.toDouble() ?? 0,
      memberSince: DateTime.parse(json['memberSince'] as String),
    );
  }
}
