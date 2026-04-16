class Credit {
  final int? id;
  final int clientId;
  final double montantTotal;
  final double montantRestant;
  final DateTime dateCredit;
  final String? description;
  final String statut;

  Credit({
    this.id,
    required this.clientId,
    required this.montantTotal,
    required this.montantRestant,
    required this.dateCredit,
    this.description,
    this.statut = 'EN_COURS',
  });

  Credit copyWith({
    int? id,
    int? clientId,
    double? montantTotal,
    double? montantRestant,
    DateTime? dateCredit,
    String? description,
    String? statut,
  }) {
    return Credit(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      montantTotal: montantTotal ?? this.montantTotal,
      montantRestant: montantRestant ?? this.montantRestant,
      dateCredit: dateCredit ?? this.dateCredit,
      description: description ?? this.description,
      statut: statut ?? this.statut,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'montantTotal': montantTotal,
        'montantRestant': montantRestant,
        'dateCredit': dateCredit.toIso8601String(),
        'description': description,
        'statut': statut,
      };

  factory Credit.fromMap(Map<String, dynamic> map) => Credit(
        id: map['id'],
        clientId: map['clientId'],
        montantTotal: (map['montantTotal'] as num).toDouble(),
        montantRestant: (map['montantRestant'] as num).toDouble(),
        dateCredit: DateTime.parse(map['dateCredit']),
        description: map['description'],
        statut: map['statut'] ?? 'EN_COURS',
      );

  double get pourcentagePaye =>
      montantTotal > 0 ? ((montantTotal - montantRestant) / montantTotal) : 0;

  bool get estSolde => statut == 'SOLDE' || montantRestant <= 0;
}