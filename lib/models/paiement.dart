class Paiement {
  final int? id;
  final int creditId;
  final double montant;
  final DateTime datePaiement;
  final String? note;

  Paiement({
    this.id,
    required this.creditId,
    required this.montant,
    required this.datePaiement,
    this.note,
  });

  Paiement copyWith({
    int? id,
    int? creditId,
    double? montant,
    DateTime? datePaiement,
    String? note,
  }) {
    return Paiement(
      id: id ?? this.id,
      creditId: creditId ?? this.creditId,
      montant: montant ?? this.montant,
      datePaiement: datePaiement ?? this.datePaiement,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'creditId': creditId,
        'montant': montant,
        'datePaiement': datePaiement.toIso8601String(),
        'note': note,
      };

  factory Paiement.fromMap(Map<String, dynamic> map) => Paiement(
        id: map['id'],
        creditId: map['creditId'],
        montant: (map['montant'] as num).toDouble(),
        datePaiement: DateTime.parse(map['datePaiement']),
        note: map['note'],
      );
}