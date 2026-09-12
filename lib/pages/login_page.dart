import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';

// ⚠️ IMPORTANT: Adjust this import path if your home_screen.dart is in the same 'pages' folder.
// If it's in the main 'lib' folder, use: import '../home_screen.dart';
import '../home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  bool _googleInitialized = false;

  List<String> _recentEmails = [];

  bool _emailError = false;
  bool _passwordError = false;

  String? _emailErrorText;
  String? _passwordErrorText;

  @override
  void initState() {
    super.initState();
    _loadRecentEmails();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();

      if (!mounted) return;

      setState(() {
        _googleInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _googleInitialized = false;
      });
    }
  }

  Future<void> _loadRecentEmails() async {
    final prefs = await SharedPreferences.getInstance();
    final emails = prefs.getStringList('recent_emails') ?? [];

    if (!mounted) return;

    setState(() {
      _recentEmails = emails;
    });
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> emails = prefs.getStringList('recent_emails') ?? [];

    emails.remove(email);
    emails.insert(0, email);

    if (emails.length > 5) {
      emails = emails.sublist(0, 5);
    }

    await prefs.setStringList('recent_emails', emails);

    if (!mounted) return;

    setState(() {
      _recentEmails = emails;
    });
  }

  List<String> _getSuggestions(String value) {
    if (value.isEmpty) {
      return _recentEmails;
    }

    return _recentEmails
        .where(
          (email) => email.toLowerCase().contains(value.toLowerCase()),
    )
        .toList();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  Future<void> _loginAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty;
      _passwordError = password.isEmpty;

      _emailErrorText = email.isEmpty ? 'This field is required.' : null;
      _passwordErrorText = password.isEmpty ? 'This field is required.' : null;
    });

    if (_emailError || _passwordError) {
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = true;
        _emailErrorText = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveEmail(email);

      if (!mounted) return;

      setState(() {
        _isLoggingIn = false;
      });

      // ✅ NAVIGATE TO HOME DASHBOARD
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingIn = false;
      });

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-email') {
        setState(() {
          _emailError = true;
          _passwordError = true;
          _emailErrorText = 'Incorrect email or password.';
          _passwordErrorText = 'Incorrect email or password.';
        });
      } else if (e.code == 'too-many-requests') {
        _showErrorNotice('Too many login attempts. Please try again later.');
      } else {
        _showErrorNotice(e.message ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingIn = false;
      });

      _showErrorNotice('Something went wrong. Please try again.');
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoggingIn) {
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      }

      final GoogleSignInAccount googleUser =
      await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google did not provide an ID token.');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null && user.email != null) {
        await _saveEmail(user.email!);
      }

      if (!mounted) return;

      setState(() {
        _isLoggingIn = false;
      });

      // ✅ NAVIGATE TO HOME DASHBOARD
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

    } on GoogleSignInException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingIn = false;
      });

      if (e.code == GoogleSignInExceptionCode.canceled) {
        return;
      }

      _showErrorNotice('Google sign-in failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingIn = false;
      });

      _showErrorNotice(e.message ?? 'Google sign-in failed.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingIn = false;
      });

      _showErrorNotice('Google sign-in failed. Please try again.');
    }
  }

  void _showErrorNotice(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Login Failed',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFFFF3030),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _textFieldDecoration({
    required String hintText,
    required bool hasError,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: hasError ? const Color(0xFFFFEBEE) : Colors.white,
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      errorText: hasError ? errorText : null,
      errorStyle: const TextStyle(
        color: Color(0xFFD32F2F),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      errorMaxLines: 2,
      suffixIcon: hasError
          ? const Icon(Icons.error_outline, color: Color(0xFFD32F2F))
          : suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFD32F2F) : Colors.transparent,
          width: hasError ? 2 : 0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFD32F2F) : const Color(0xFFFF3030),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF4B4B),
              Color(0xFFFF8A8A),
              Colors.white,
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 55),
                  const Text(
                    'HI! Welcome to NexAid!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 45),
                  const Text(
                    'Log in your account.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Email:',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      return _getSuggestions(textEditingValue.text);
                    },
                    onSelected: (String selection) {
                      _emailController.text = selection;
                      setState(() {
                        _emailError = false;
                        _emailErrorText = null;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      _emailController.value = controller.value;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() {
                              _emailError = false;
                              _emailErrorText = null;
                            });
                          }
                        },
                        decoration: _textFieldDecoration(
                          hintText: 'Enter your email',
                          hasError: _emailError,
                          errorText: _emailErrorText ?? 'This field is required.',
                        ),
                        style: const TextStyle(fontSize: 17, color: Colors.black),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Password:',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _passwordError = false;
                          _passwordErrorText = null;
                        });
                      }
                    },
                    decoration: _textFieldDecoration(
                      hintText: 'Enter your password',
                      hasError: _passwordError,
                      errorText: _passwordErrorText ?? 'This field is required.',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(fontSize: 17, color: Colors.black),
                  ),
                  const SizedBox(height: 35),
                  Center(
                    child: SizedBox(
                      width: 140,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoggingIn ? null : _loginAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3030),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoggingIn
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isLoggingIn ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google_logo.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: _isLoggingIn
                                  ? null
                                  : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign up Here',
                                style: TextStyle(
                                  color: Color(0xFFFF3030),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}