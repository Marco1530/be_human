import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class ConnectScreen extends StatefulWidget {
  final UserModel currentUser;

  const ConnectScreen({super.key, required this.currentUser});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _emailController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  String _message = '';

  Future<void> _searchAndConnect() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    final email = _emailController.text.trim();

    if (email == widget.currentUser.email) {
      setState(() {
        _message = 'No puedes conectarte contigo mismo 😅';
        _isLoading = false;
      });
      return;
    }

    final otherUser = await _firestoreService.getUserByEmail(email);

    if (otherUser == null) {
      setState(() {
        _message = 'No se encontró ningún usuario con ese correo';
        _isLoading = false;
      });
      return;
    }

    await _firestoreService.connectUsers(widget.currentUser, otherUser);

    setState(() {
      _message = '¡Conectado con ${otherUser.displayName}! 🎉';
      _isLoading = false;
    });

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE91E8C),
        foregroundColor: Colors.white,
        title: const Text('Conectar con alguien'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💌', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Busca a tu persona especial',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escribe el correo con el que se registró en BeHuman',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('🎉') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _searchAndConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Conectar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}