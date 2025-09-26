import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _isLoading = false;

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // simulate a small delay
      Future.delayed(const Duration(seconds: 1), () {
        if (_usernameC.text.trim() == "admin" &&
            _passwordC.text.trim() == "admin@123") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid username or password")),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Login",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameC,
                    decoration: const InputDecoration(labelText: "Username"),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter username" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordC,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter password" : null,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          child: const Text("Login"),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
