import 'dart:convert';

class CharityEntry {
  final String id;
  final double amount;
  final DateTime date;
  final String? purpose;
  final DateTime lastModified;

  CharityEntry({
    required this.id,
    required this.amount,
    required this.date,
    this.purpose,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  CharityEntry copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? purpose,
    DateTime? lastModified,
  }) {
    return CharityEntry(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      purpose: purpose ?? this.purpose,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'purpose': purpose,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory CharityEntry.fromMap(Map<String, dynamic> map) {
    return CharityEntry(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      purpose: map['purpose'],
      lastModified: DateTime.tryParse(map['lastModified'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CharityEntry.fromJson(String source) =>
      CharityEntry.fromMap(json.decode(source));
}
