import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlueWeb',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return LoginScreen();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error initializing Firebase'));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('blueweblogo.png'),
              SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600), 
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0), 
                    fillColor: Colors.grey[400], 
                    filled: true, 
                    labelText: 'UFL Email',
                    labelStyle: TextStyle(color: Colors.white), 
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(color: Colors.white), 
                ),
              ),
              SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600), 
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0), 
                    fillColor: Colors.grey[400], 
                    filled: true, 
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white), 
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(color: Colors.white), 
                  obscureText: true,
                ),
              ),
              SizedBox(height: 20),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Dashboard()),
                  );
                },
                icon: Icon(Icons.login, size: 40), 
                color: Colors.blue[800], 
              ),
            ],
          ),
        ),
      ),
    );
  }
}


