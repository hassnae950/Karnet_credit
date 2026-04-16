class Client {
  final int? id;
  final String nom;
  final String? telephone;
  final String? adresse;
  final DateTime dateCreation;
  double solde;

  Client({
    this.id,
    required this.nom,
    this.telephone,
    this.adresse,
    required this.dateCreation,
    this.solde = 0.0,
  });

  Client copyWith({
    int? id,
    String? nom,
    String? telephone,
    String? adresse,
    DateTime? dateCreation,
    double? solde,
  }) {
    return Client(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      dateCreation: dateCreation ?? this.dateCreation,
      solde: solde ?? this.solde,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'telephone': telephone,
        'adresse': adresse,
        'dateCreation': dateCreation.toIso8601String(),
      };

  factory Client.fromMap(Map<String, dynamic> map) => Client(
        id: map['id'],
        nom: map['nom'],
        telephone: map['telephone'],
        adresse: map['adresse'],
        dateCreation: DateTime.parse(map['dateCreation']),
      );

  String get initiales => nom.isNotEmpty ? nom[0].toUpperCase() : '?';
}