import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unstop_clone/screens/get_inputs.dart';
import 'firebase_options.dart';
import 'package:unstop_clone/screens/home_screen.dart';
import 'package:unstop_clone/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unstop_clone/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              final user = snapshot.data!;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (userSnapshot.hasData) {
                    Map<String, dynamic> map =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    // print(map);
                    if (!map.containsKey('name') ||
                        !map.containsKey('rollNo') ||
                        !map.containsKey('collegeName') ||
                        !map.containsKey('dateOfBirth')) {
                      return GetInputs();
                    }
                  }
                  return HomeScreen();
                },
              );
            }
            return const AuthScreen();
          }),
      theme: AppTheme.getLightTheme(),
      title: 'Unlock',
      debugShowCheckedModeBanner: false,
    );
  }
}
