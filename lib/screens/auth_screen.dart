import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unstop_clone/screens/get_inputs.dart';
import 'package:unstop_clone/screens/home_screen.dart';
// import 'package:students_connect/screens/home.dart';

final _auth = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String username = '';
  bool _isLogin = true;
  bool _isLoading = false; // Loading state

  void onSubmit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential;

      if (!_isLogin) {
        // Sign Up
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user?.sendEmailVerification();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': username,
          'email': email,
        });

        if (!mounted) return;

        // Navigate to GetInputs for new users
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const GetInputs()),
        );
      } else {
        // Login
        userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        if (!mounted) return;

        // Check if user data exists
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          // Navigate to BottomNavApp (main app)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => HomeScreen()),
          );
        } else {
          // Navigate to GetInputs screen for new users
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => const GetInputs()),
          );
        }
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      String errorMessage = "An error occurred. Please try again.";

      if (error.code == 'email-already-in-use') {
        errorMessage = "This email is already in use. Try logging in instead.";
      } else if (error.code == 'weak-password') {
        errorMessage = "The password is too weak.";
      } else if (error.code == 'invalid-email') {
        errorMessage = "Invalid email address.";
      } else if (error.code == 'wrong-password') {
        errorMessage = "Incorrect password. Please try again.";
      } else if (error.code == 'user-not-found') {
        errorMessage = "No user found for this email.";
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unexpected error: ${error.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height, // Full screen height
          alignment: Alignment.center, // Center the content vertically
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isLogin ? 'Login' : 'Sign Up',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Color.fromARGB(255, 79, 78, 78),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!_isLogin)
                            TextFormField(
                              keyboardType: TextInputType.name,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                hintText: 'Enter your username',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 4) {
                                  return 'Enter a valid username (min 4 characters)';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                username = value!;
                              },
                            ),
                          const SizedBox(height: 20),
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'Enter your email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  !value.contains('@') ||
                                  value.trim().isEmpty) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              email = value!;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Enter a strong password (min 6 characters)';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              password = value!;
                            },
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: onSubmit,
                                  child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
                                ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _form.currentState!.reset();
                              });
                            },
                            child: Text(_isLogin
                                ? 'Create new Account'
                                : 'Already have an account?'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
