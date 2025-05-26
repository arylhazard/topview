class Client {
  final String id;
  final String? name;
  final DateTime createdAt;
  final DateTime? lastTransactionDate;

  Client({
    required this.id,
    this.name,
    required this.createdAt,
    this.lastTransactionDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'last_transaction_date': lastTransactionDate?.toIso8601String(),
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      lastTransactionDate: json['last_transaction_date'] != null
          ? DateTime.parse(json['last_transaction_date'])
          : null,
    );
  }

  Client copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastTransactionDate,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
    );
  }
}
