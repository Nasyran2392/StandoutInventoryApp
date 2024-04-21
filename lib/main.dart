import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:standoutinventoryapplication/Auth.dart';
// import 'package:standoutinventoryapplication/Login.dart';
import 'package:standoutinventoryapplication/splashScreen.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Platform.isAndroid? {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAAbHogmJjBJXvZ_TE5lUwBR6x01DhyV-A",
        appId: "1:328325402547:android:35723e326e6991eb1ec5c6",
        messagingSenderId: "328325402547",
        projectId: "tutorial-3c284",
        storageBucket: "tutorial-3c284.appspot.com",)
      )
  }
    :await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/':(context)=> splashScreen(),
        '/Auth' : (context)=>Auth(),
      }
      );
      
    }
  }
