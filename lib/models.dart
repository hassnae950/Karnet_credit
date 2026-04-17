import 'package:flutter/material.dart';

class Client {
  int? id;
  String nom;
  String? telephone;
  String? adresse;
  DateTime dateCreation;
  double solde;

  Client({
    this.id,
    required this.nom,
    this.telephone,
    this.adresse,
    required this.dateCreation,
    this.solde = 0,
  });

  String get initiales {
    final parts = nom.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'adresse': adresse,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      nom: map['nom'],
      telephone: map['telephone'],
      adresse: map['adresse'],
      dateCreation: DateTime.parse(map['dateCreation']),
    );
  }
}

class Credit {
  int? id;
  int clientId;
  double montantTotal;
  double montantRestant;
  DateTime dateCredit;
  String? description;

  Credit({
    this.id,
    required this.clientId,
    required this.montantTotal,
    required this.montantRestant,
    required this.dateCredit,
    this.description,
  });

  bool get estSolde => montantRestant <= 0;

  double get pourcentagePaye {
    if (montantTotal <= 0) return 0;
    return (montantTotal - montantRestant) / montantTotal;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'montantTotal': montantTotal,
      'montantRestant': montantRestant,
      'dateCredit': dateCredit.toIso8601String(),
      'description': description,
    };
  }

  factory Credit.fromMap(Map<String, dynamic> map) {
    return Credit(
      id: map['id'],
      clientId: map['clientId'],
      montantTotal: map['montantTotal'],
      montantRestant: map['montantRestant'],
      dateCredit: DateTime.parse(map['dateCredit']),
      description: map['description'],
    );
  }
}

class Paiement {
  int? id;
  int creditId;
  double montant;
  DateTime datePaiement;
  String? note;

  Paiement({
    this.id,
    required this.creditId,
    required this.montant,
    required this.datePaiement,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creditId': creditId,
      'montant': montant,
      'datePaiement': datePaiement.toIso8601String(),
      'note': note,
    };
  }

  factory Paiement.fromMap(Map<String, dynamic> map) {
    return Paiement(
      id: map['id'],
      creditId: map['creditId'],
      montant: map['montant'],
      datePaiement: DateTime.parse(map['datePaiement']),
      note: map['note'],
    );
  }
}

class Cheque {
  int? id;
  int creditId;
  String numero;
  double montant;
  DateTime dateEcheance;
  String? banque;
  String? imagePath;
  String statut;
  DateTime dateCreation;

  Cheque({
    this.id,
    required this.creditId,
    required this.numero,
    required this.montant,
    required this.dateEcheance,
    this.banque,
    this.imagePath,
    this.statut = 'EN_ATTENTE',
    required this.dateCreation,
  });

  String get statutLabel {
    switch (statut) {
      case 'ENCAISSE':
        return 'محصّل';
      case 'REFUSE':
        return 'مرفوض';
      default:
        return 'قيد الانتظار';
    }
  }

  Color get statutColor {
    switch (statut) {
      case 'ENCAISSE':
        return const Color(0xFF388E3C);
      case 'REFUSE':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFFFFA000);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creditId': creditId,
      'numero': numero,
      'montant': montant,
      'dateEcheance': dateEcheance.toIso8601String(),
      'banque': banque,
      'imagePath': imagePath,
      'statut': statut,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  factory Cheque.fromMap(Map<String, dynamic> map) {
    return Cheque(
      id: map['id'],
      creditId: map['creditId'],
      numero: map['numero'],
      montant: map['montant'],
      dateEcheance: DateTime.parse(map['dateEcheance']),
      banque: map['banque'],
      imagePath: map['imagePath'],
      statut: map['statut'] ?? 'EN_ATTENTE',
      dateCreation: DateTime.parse(map['dateCreation']),
    );
  }
}
