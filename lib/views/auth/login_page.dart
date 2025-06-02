import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  void login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.login(username, password);
      final role = result['role'];
      final data = result['data'];

      // arahkan ke dashboard
      switch (role) {
        case 'pembeli':
          Navigator.pushReplacementNamed(context, "/dashboardPembeli");
          break;
        case 'penitip':
          Navigator.pushReplacementNamed(context, "/dashboardPenitip");
          break;
        case 'hunter':
          Navigator.pushReplacementNamed(context, "/dashboardHunter");
          break;
        case 'kurir':
          Navigator.pushReplacementNamed(context, "/dashboardKurir");
          break;
        default:
          setState(() {
            errorMessage = "Role tidak dikenali.";
          });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll("Exception:", "").trim();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login ReuseMart")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
