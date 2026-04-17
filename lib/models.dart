import 'package:flutter/material.dart';

class Category {
  int? id;
  String name;
  String type;

  Category({
    this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: map['type'],
    );
  }
}

class Client {
  int? id;
  String nom;
  String? telephone;
  String? adresse;
  DateTime dateCreation;
  double solde;
  String type;
  int? categoryId;
  String? company;
  String? notes;

  Client({
    this.id,
    required this.nom,
    this.telephone,
    this.adresse,
    required this.dateCreation,
    this.solde = 0,
    required this.type,
    this.categoryId,
    this.company,
    this.notes,
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
      'solde': solde,
      'type': type,
      'categoryId': categoryId,
      'company': company,
      'notes': notes,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      nom: map['nom'],
      telephone: map['telephone'],
      adresse: map['adresse'],
      dateCreation: DateTime.parse(map['dateCreation']),
      solde: map['solde']?.toDouble() ?? 0,
      type: map['type'] ?? 'CLIENT',
      categoryId: map['categoryId'],
      company: map['company'],
      notes: map['notes'],
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
  String? imagePath;  // حقل الصورة

  Credit({
    this.id,
    required this.clientId,
    required this.montantTotal,
    required this.montantRestant,
    required this.dateCredit,
    this.description,
    this.imagePath,
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
      'imagePath': imagePath,
    };
  }

  factory Credit.fromMap(Map<String, dynamic> map) {
    return Credit(
      id: map['id'],
      clientId: map['clientId'],
      montantTotal: map['montantTotal']?.toDouble() ?? 0,
      montantRestant: map['montantRestant']?.toDouble() ?? 0,
      dateCredit: DateTime.parse(map['dateCredit']),
      description: map['description'],
      imagePath: map['imagePath'],
    );
  }
}

class Paiement {
  int? id;
  int creditId;
  double montant;
  DateTime datePaiement;
  String? note;
  String? imagePath;  // حقل الصورة

  Paiement({
    this.id,
    required this.creditId,
    required this.montant,
    required this.datePaiement,
    this.note,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creditId': creditId,
      'montant': montant,
      'datePaiement': datePaiement.toIso8601String(),
      'note': note,
      'imagePath': imagePath,
    };
  }

  factory Paiement.fromMap(Map<String, dynamic> map) {
    return Paiement(
      id: map['id'],
      creditId: map['creditId'],
      montant: map['montant']?.toDouble() ?? 0,
      datePaiement: DateTime.parse(map['datePaiement']),
      note: map['note'],
      imagePath: map['imagePath'],
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
      montant: map['montant']?.toDouble() ?? 0,
      dateEcheance: DateTime.parse(map['dateEcheance']),
      banque: map['banque'],
      imagePath: map['imagePath'],
      statut: map['statut'] ?? 'EN_ATTENTE',
      dateCreation: DateTime.parse(map['dateCreation']),
    );
  }
}