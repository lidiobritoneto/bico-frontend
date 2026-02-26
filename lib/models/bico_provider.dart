class BicoProvider {
  final String id; // userId no backend
  final String name;
  final String city;
  final String state;

  // rating vindo do backend (ratingAvg + ratingCount)
  final double rating;
  final int reviewsCount;

  final double priceBase;
  final String priceType;

  final List<String> categories;
  final String bio;
  final bool isActive;

  // NOVOS
  final String? avatarBase64;
  final bool? isOnline;

  const BicoProvider({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.rating,
    required this.reviewsCount,
    required this.priceBase,
    required this.priceType,
    required this.categories,
    required this.bio,
    required this.isActive,
    this.avatarBase64,
    this.isOnline,
  });

  factory BicoProvider.fromJson(Map<String, dynamic> json) {
    final catsAny = (json['categories'] ?? []);
    final cats = (catsAny is List) ? catsAny.map((e) => e.toString()).toList() : <String>[];

    return BicoProvider(
      id: (json['userId'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      rating: (json['ratingAvg'] ?? json['rating'] ?? 0).toDouble(),
      reviewsCount: (json['ratingCount'] ?? json['reviewsCount'] ?? 0) as int,
      priceBase: (json['priceBase'] ?? 0).toDouble(),
      priceType: (json['priceType'] ?? '').toString(),
      categories: cats,
      bio: (json['bio'] ?? '').toString(),
      isActive: (json['isActive'] ?? true) as bool,
      avatarBase64: json['avatarBase64']?.toString(),
      isOnline: json['isOnline'] is bool ? (json['isOnline'] as bool) : null,
    );
  }
}