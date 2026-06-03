//imports
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String boardOwnerId;
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime expiresAt;

  // NUEVO
  final int colorIndex;

  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.boardOwnerId,
    required this.expiresAt,
    this.text,
    this.imageUrl,
    this.videoUrl,

    // NUEVO
    required this.colorIndex,

    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'boardOwnerId': boardOwnerId,
      'text': text,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,

      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'colorIndex': colorIndex,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'],
      authorId: map['authorId'],
      authorName: map['authorName'],
      boardOwnerId: map['boardOwnerId'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],

      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 24)),

      colorIndex: map['colorIndex'] ?? 0,

      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}