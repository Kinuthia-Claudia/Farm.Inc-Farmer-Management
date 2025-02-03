import 'package:flutter/material.dart';
import 'package:farmerapplication/auth/auth_service.dart';
import 'home_screen.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final AuthService auth = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwdController = TextEditingController();
  bool rememberMe = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  bool _validateEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> _loginUser(BuildContext context) async {
    setState(() => isLoading = true);

    if (emailController.text.isEmpty || pwdController.text.isEmpty) {
      _showErrorDialog(context, "Please enter your email and password.");
      return;
    }

    if (!_validateEmail(emailController.text)) {
      _showErrorDialog(context, "Please enter a valid email address.");
      return;
    }

    bool loginSuccess = await auth.login(emailController.text, pwdController.text);
    
    setState(() => isLoading = false);

    if (loginSuccess) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      _showErrorDialog(context, "Incorrect email or password. Please try again.");
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(content: Text(message)),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Forgot Password"),
        content: const Text("Please contact support to reset your password."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _header(context),
                const SizedBox(height: 40),
                _inputField(context),
                const SizedBox(height: 20),
                _forgotPassword(context),
                const SizedBox(height: 40),
                _signup(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/ethoslogo.png',
          height: 170,
          width: 280,
        ),
      ],
    );
  }

  Widget _inputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Email Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () {
            setState(() {
              emailController.text = "test@gmail.com";
            });
          },
          child: TextField(
            controller: emailController,
            decoration: _inputDecoration("you@example.com", Icons.person),      
            enabled: false, // Disable manual input for demonstration
          ),
        ),
        const SizedBox(height: 20),
        const Text("Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () {
            setState(() {
              pwdController.text = "123456";
            });
          },
          child: TextField(
            controller: pwdController,
            obscureText: true,
            decoration: _inputDecoration("**********", Icons.lock),
            enabled: false, // Disable manual input for demonstration
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isLoading ? null : () => _loginUser(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Login", style: TextStyle(fontSize: 20, color: Colors.white)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
      fillColor: Colors.white,
      filled: true,
      prefixIcon: Icon(icon),
    );
  }

  Widget _forgotPassword(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [],
        ),
        TextButton(
          onPressed: () => _showForgotPasswordDialog(context),
          child: const Text("Forgot password?", style: TextStyle(color: Colors.green)),
        ),
      ],
    );
  }

  Widget _signup(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, '/signup'),
      child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.green)),
    );
  }
}