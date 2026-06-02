class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? connectedUserId;
  final String? connectedUserEmail;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.connectedUserId,
    this.connectedUserEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'connectedUserId': connectedUserId,
      'connectedUserEmail': connectedUserEmail,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      displayName: map['displayName'] ?? '',
      connectedUserId: map['connectedUserId'],
      connectedUserEmail: map['connectedUserEmail'],
    );
  }
}