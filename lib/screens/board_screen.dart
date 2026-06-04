import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import 'package:home_widget/home_widget.dart';


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
  final List<Color> postColors = [
    Color(0xFFFFF59D), // amarillo
    Color(0xFFF8BBD0), // rosa
    Color(0xFFC5CAE9), // azul
    Color(0xFFB2DFDB), // verde
    Color(0xFFD1C4E9), // lila
    Color(0xFFFFCCBC), // naranja
    Color(0xFFFFE0B2), // durazno
    Color(0xFFDCEDC8), // lima suave
    Color(0xFFB3E5FC), // celeste
    Color(0xFFE6EE9C), // amarillo verdoso
  ]; //estos son los colores que se usaran para selecciona los post its
  bool _isMyBoard = false;

  @override
  void initState() {
    super.initState();
    _isMyBoard = widget.boardOwner.uid == widget.currentUser.uid;
  }

  Future<void> _addTextPost() async {
    int selectedColor = 0; //esto ubica el color indefinido antes crear un post

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo post'), //titulo de la ventana emergente
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Escribe algo bonito...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text('Color del post-it'),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    children: List.generate(postColors.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = index;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: postColors[index],
                          child: selectedColor == index
                              ? const Icon(
                            Icons.check,
                            color: Colors.black,
                          )
                              : null,
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_textController.text.trim().isEmpty) return;

              final now = DateTime.now();

              print("CREATED AT: $now");
              print(
                "EXPIRES AT: ${now.add(const Duration(hours: 24))}",
              );

              final post = PostModel(
                id: const Uuid().v4(),
                authorId: widget.currentUser.uid,
                authorName: widget.currentUser.displayName,
                boardOwnerId: widget.boardOwner.uid,
                text: _textController.text.trim(),
                expiresAt: now.add(
                  const Duration(hours: 24),
                ),
                colorIndex: selectedColor,
                createdAt: now,
              );

              await _firestoreService.addPost(post);

              await HomeWidget.saveWidgetData<String>(
                'author',
                post.authorName,
              );

              await HomeWidget.saveWidgetData<String>(
                'message',
                post.text ?? '',
              );

              await HomeWidget.updateWidget(
                androidName: 'BeHumanWidgetProvider',
              );

              _textController.clear();

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Publicar'),
          )
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
        expiresAt: DateTime.now().add(
          const Duration(hours: 24),
        ),
        colorIndex: 0,
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFE91E8C), //Cambia el tapBar de los post its
        foregroundColor: Colors.white,
        title: Text(
          isMyBoard ? 'Mi board' : 'Board de ${widget.boardOwner.displayName}',
        ),
      ),

      body: Container(

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFF), //color de fondo de post it
              Color(0xFFFFFF), //degradado
            ],
          ),
        ),

        child: StreamBuilder<List<PostModel>>(
          stream: _firestoreService.getBoardPosts(widget.boardOwner.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('ERROR: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final posts = (snapshot.data ?? [])
                .where((post) => post.expiresAt.isAfter(DateTime.now()))
                .toList();

            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('📭', style: TextStyle(fontSize: 64)),
                    SizedBox(height: 16),
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
                return TweenAnimationBuilder(
                  duration: Duration(
                    milliseconds: 300 + (index * 80),
                  ),
                  tween: Tween<double>(
                    begin: 0,
                    end: 1,
                  ),
                  builder: (context, value, child) { //esto hace la animacion de caida
                    final bounce =
                    Curves.elasticOut.transform(value);

                    return Transform.translate(
                      offset: Offset(
                        0,
                        (1 - value) * -120,
                      ),
                      child: Transform.scale(
                        scale: bounce,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _buildPostCard(posts[index]),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: !_isMyBoard //EL botton de agregar un post it
          ? FloatingActionButton.extended(
        onPressed: _showPostOptions,
        backgroundColor: const Color(0xFFE91E8C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Dejar post'),
      )
          : null,
    );
  }

  Widget _buildPostCard(PostModel post) { //esto es el formato del post It
    final rotation = ((post.id.hashCode % 10) - 5) * 0.01;


    return Transform.rotate(
      angle: rotation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: postColors[post.colorIndex],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(3, 5),
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
                            fontSize: 13,
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
          ),


          Positioned( //aca se define la cinta sobre los post it
            top: -8,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: -0.08,
                child: Container(
                  width: 50,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.7),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 3,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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