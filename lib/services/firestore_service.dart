import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Crear o actualizar usuario en Firestore
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Obtener usuario por ID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Buscar usuario por email
  Future<UserModel?> getUserByEmail(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  // Conectar dos usuarios
  Future<void> connectUsers(UserModel currentUser, UserModel otherUser) async {
    await _db.collection('users').doc(currentUser.uid).update({
      'connectedUserId': otherUser.uid,
      'connectedUserEmail': otherUser.email,
    });
    await _db.collection('users').doc(otherUser.uid).update({
      'connectedUserId': currentUser.uid,
      'connectedUserEmail': currentUser.email,
    });
  }

  // Agregar post al board de alguien
  Future<void> addPost(PostModel post) async {
    await _db
        .collection('boards')
        .doc(post.boardOwnerId)
        .collection('posts')
        .doc(post.id)
        .set(post.toMap());
  }

  // Obtener posts del board en tiempo real
  Stream<List<PostModel>> getBoardPosts(String boardOwnerId) {
    return _db
        .collection('boards')
        .doc(boardOwnerId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromMap(doc.data()))
            .toList());
  }

  // Eliminar post
  Future<void> deletePost(String boardOwnerId, String postId) async {
    await _db
        .collection('boards')
        .doc(boardOwnerId)
        .collection('posts')
        .doc(postId)
        .delete();
  }
}