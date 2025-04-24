import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/signup.dart';
import 'pages/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC1Ckhshn50G9MZBRiYywVR_74fCA6zD0o",
      authDomain: "eventdb-96b1b.firebaseapp.com",
      projectId: "eventdb-96b1b",
      storageBucket: "eventdb-96b1b.appspot.com",
      messagingSenderId: "1056571082983",
      appId: "1:1056571082983:web:cafd84479f0bc21e66ba42",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Event App',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: HomePage(),
      routes: {
        '/login': (_) => LoginPage(),
        '/signup': (_) => SignupPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Login'),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Sign Up'),
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
            ),
          ],
        ),
      ),
    );
  }
}
