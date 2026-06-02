class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String boardOwnerId;
  final String? text;
  final String? imageUrl;
  final String? videoUrl;

  final DateTime createdAt;


  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.boardOwnerId,
    this.text,
    this.imageUrl,
    this.videoUrl,
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
      'createdAt': createdAt.toIso8601String(),
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
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}