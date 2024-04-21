import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add import for FirebaseAuth
import 'package:standoutinventoryapplication/MyButtom.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  // Implement sign-in functionality here
  Future<void> signIn() async { // Add 'async' keyword here
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim()
      );
      // Navigate to the next screen after successful sign-in
    } catch (e) {
      // Handle sign-in errors here
      print('Sign-in error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 233, 233, 233),
      body: SingleChildScrollView( // Wrap your Column with SingleChildScrollView
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 50),
              Container(
                height: 190,
                child: Image.asset('images/LoginLogo.png'),
              ),
              SizedBox(height: 50),
              Text(
                'Standout Inventory App',
                style: TextStyle(
                  fontSize: 30,
                ),
              ),
              Text(
                '(For Storekeeper)',
                style: TextStyle(
                  fontSize: 23,
                ),
              ),
              SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                    ),
                    fillColor: Colors.grey[50],
                    filled: true,
                    hintText: "Email",
                    hintStyle: TextStyle(color: Color.fromARGB(174, 0, 0, 0)),
                  ),
                ),
              ),
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true, // Set obscureText to true for password masking
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                    ),
                    fillColor: Colors.grey[50],
                    filled: true,
                    hintText: "Password",
                    hintStyle: TextStyle(color: Color.fromARGB(174, 0, 0, 0)),
                  ),
                ),
              ),

              SizedBox(height: 10,),
              MyButton(
                onTap: signIn,
              ),
              SizedBox(height: 10,),
              // Text('or continue with'),
              SizedBox(height: 10,),
            ],
          ),
        ),
      ),
    );
  }
}
