import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';

class BoardScreen extends StatefulWidget {
  final UserModel boardOwner;
  final UserModel currentUser;

  const BoardScreen({
    super.key,
    required this.boardOwner,
    required this.currentUser,
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _firestoreService = FirestoreService();
  final _textController = TextEditingController();
  bool _isMyBoard = false;

  @override
  void initState() {
    super.initState();
    _isMyBoard = widget.boardOwner.uid == widget.currentUser.uid;
  }

  Future<void> _addTextPost() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo post'),
        content: TextField(
          controller: _textController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Escribe algo bonito...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_textController.text.trim().isEmpty) return;
              final post = PostModel(
                id: const Uuid().v4(),
                authorId: widget.currentUser.uid,
                authorName: widget.currentUser.displayName,
                boardOwnerId: widget.boardOwner.uid,
                text: _textController.text.trim(),
                createdAt: DateTime.now(),
              );
              await _firestoreService.addPost(post);
              _textController.clear();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E8C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addImagePost() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    try {
      final postId = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('boards/${widget.boardOwner.uid}/$postId.jpg');
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      final post = PostModel(
        id: postId,
        authorId: widget.currentUser.uid,
        authorName: widget.currentUser.displayName,
        boardOwnerId: widget.boardOwner.uid,
        imageUrl: url,
        createdAt: DateTime.now(),
      );
      await _firestoreService.addPost(post);
    } catch (e) {
        print("ERROR STORAGE: $e");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir imagen: $e')),
          );
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    final isMyBoard = widget.boardOwner.uid == widget.currentUser.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE91E8C),
        foregroundColor: Colors.white,
        title: Text(
          isMyBoard ? 'Mi board' : 'Board de ${widget.boardOwner.displayName}',
        ),
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: _firestoreService.getBoardPosts(widget.boardOwner.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📭', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    isMyBoard
                        ? 'Aun no tienes posts'
                        : 'Se el primero en dejar un post',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _buildPostCard(posts[index]);
            },
          );
        },
      ),
      floatingActionButton: !_isMyBoard
          ? FloatingActionButton.extended(
              onPressed: () => _showPostOptions(),
              backgroundColor: const Color(0xFFE91E8C),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Dejar post'),
            )
          : null,
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Container(
      decoration: BoxDecoration(
        color: _getPostColor(post.authorId),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Text(
                    post.authorName.isNotEmpty
                        ? post.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Text(
                post.text ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatDate(post.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPostColor(String authorId) {
    final colors = [
      const Color(0xFFFFF59D), // amarillo pastel
      const Color(0xFFFFCCBC), // naranja pastel
      const Color(0xFFF8BBD0), // rosa pastel
      const Color(0xFFB2DFDB), // verde pastel
      const Color(0xFFC5CAE9), // azul pastel
      const Color(0xFFD1C4E9), // lila pastel
    ];

    return colors[authorId.hashCode.abs() % colors.length];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showComingSoon() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('💌 Próximamente'),
        content: const Text(
          'Muy pronto podrás compartir fotos y videos con las personas que más quieres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('¡Qué emoción!'),
          ),
        ],
      ),
    );
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Qué quieres dejar?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE91E8C),
                child: Icon(Icons.text_fields, color: Colors.white),
              ),
              title: const Text('Mensaje de texto'),
              onTap: () {
                Navigator.pop(context);
                _addTextPost();
              },
            ),

            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF9C27B0),
                child: Icon(Icons.photo, color: Colors.white),
              ),
              title: const Text('Foto'),
              subtitle: const Text('Próximamente'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon();
              },
            ),

            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF3F51B5),
                child: Icon(Icons.videocam, color: Colors.white),
              ),
              title: const Text('Video'),
              subtitle: const Text('Próximamente'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon();
              },
            ),
          ],
        ),
      ),
    );
  }
  }