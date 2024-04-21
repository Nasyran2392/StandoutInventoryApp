import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:standoutinventoryapplication/login.dart'; // Assuming Login widget is defined here
import 'package:standoutinventoryapplication/Homepage.dart'; // Assuming Chat widget is defined here

class Auth extends StatelessWidget {
  const Auth({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Homepage(); // Use the correct method or widget name (Chat instead of chat)
          } else {
            return Login(); // Assuming Login widget is defined here
          }
        },
      ),
    );
  }
}
