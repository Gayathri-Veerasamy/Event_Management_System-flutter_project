import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(
              username: doc['name'],
              email: email,
              password: password,
              userId: doc.id,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid credentials')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final r = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return r.hasMatch(v) ? null : 'Enter a valid email';
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return (v.length >= 8 && v.length <= 15)
        ? null
        : 'Password must be 8–15 characters';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Log in to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 30),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: true,
                        validator: _validatePassword,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.purple,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                        : Text(
                            'Log In',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),

                SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account? '),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushReplacementNamed(context, '/signup');
                            },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
