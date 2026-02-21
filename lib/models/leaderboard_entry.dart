class LeaderboardEntry {
  final String userId;
  final String name;
  final String? photoUrl;
  final int points;
  final String tier;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.points,
    required this.tier,
    required this.rank,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'photoUrl': photoUrl,
      'points': points,
      'tier': tier,
      'rank': rank,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      points: map['points'] ?? 0,
      tier: map['tier'] ?? 'Bronze',
      rank: map['rank'] ?? 0,
    );
  }
}
