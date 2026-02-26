class BicoOrder {
  final String id;
  final String clientName;
  final String providerId;
  final String providerName;
  final String categoryName;
  final String description;
  final String city;
  final String state;
  final DateTime createdAt;
  final String status; // new | accepted | in_progress | done | canceled

  const BicoOrder({
    required this.id,
    required this.clientName,
    required this.providerId,
    required this.providerName,
    required this.categoryName,
    required this.description,
    required this.city,
    required this.state,
    required this.createdAt,
    required this.status,
  });

  BicoOrder copyWith({
    String? status,
  }) {
    return BicoOrder(
      id: id,
      clientName: clientName,
      providerId: providerId,
      providerName: providerName,
      categoryName: categoryName,
      description: description,
      city: city,
      state: state,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}