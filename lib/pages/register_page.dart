import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentPage = 1;

  String? _selectedGender;
  String? _selectedDisability;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // ✅ NEW: Age Controller
  final TextEditingController _ageController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegistering = false;

  bool _firstNameError = false;
  bool _lastNameError = false;

  // ✅ NEW: Age Error Variables
  bool _ageError = false;
  String? _ageErrorText;

  bool _genderError = false;
  bool _disabilityError = false;

  bool _emailError = false;
  bool _passwordError = false;
  bool _confirmPasswordError = false;

  String? _emailErrorText;
  String? _passwordErrorText;
  String? _confirmPasswordErrorText;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose(); // ✅ Dispose Age Controller
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _nextPage() {
    setState(() {
      _firstNameError = _firstNameController.text.trim().isEmpty;
      _lastNameError = _lastNameController.text.trim().isEmpty;

      // ✅ NEW: Age Validation
      String ageText = _ageController.text.trim();
      if (ageText.isEmpty) {
        _ageError = true;
        _ageErrorText = 'This field is required.';
      } else if (int.tryParse(ageText) == null) {
        _ageError = true;
        _ageErrorText = 'Please enter a valid number.';
      } else {
        _ageError = false;
        _ageErrorText = null;
      }

      _genderError = _selectedGender == null;
      _disabilityError = _selectedDisability == null;
    });

    // ✅ Updated condition to include _ageError
    if (_firstNameError ||
        _lastNameError ||
        _ageError ||
        _genderError ||
        _disabilityError) {
      return;
    }

    setState(() {
      _currentPage = 2;
    });
  }

  void _backPage() {
    if (_currentPage == 2) {
      setState(() {
        _currentPage = 1;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _registerAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _emailError = email.isEmpty;
      _passwordError = password.isEmpty;
      _confirmPasswordError = confirmPassword.isEmpty;

      _emailErrorText = email.isEmpty ? 'This field is required.' : null;
      _passwordErrorText = password.isEmpty ? 'This field is required.' : null;
      _confirmPasswordErrorText = confirmPassword.isEmpty ? 'This field is required.' : null;
    });

    if (_emailError || _passwordError || _confirmPasswordError) {
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = true;
        _emailErrorText = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _passwordError = true;
        _passwordErrorText = 'Password must be at least 6 characters.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _passwordError = true;
        _confirmPasswordError = true;
        _passwordErrorText = 'Passwords do not match.';
        _confirmPasswordErrorText = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message: 'Unable to create the account.',
        );
      }

      final DatabaseReference userReference =
      FirebaseDatabase.instance.ref('users/${user.uid}');

      await userReference.set({
        'uid': user.uid,
        'firstName': _firstNameController.text.trim(),
        'middleName': _middleNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0, // ✅ Save Age to Firebase
        'gender': _selectedGender,
        'typeOfDisability': _selectedDisability,
        'email': email,
        'createdAt': ServerValue.timestamp,
      });

      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      _showSuccessNotice();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      if (e.code == 'email-already-in-use') {
        setState(() {
          _emailError = true;
          _emailErrorText = 'This email is already registered.';
        });
      } else if (e.code == 'invalid-email') {
        setState(() {
          _emailError = true;
          _emailErrorText = 'Please enter a valid email address.';
        });
      } else if (e.code == 'weak-password') {
        setState(() {
          _passwordError = true;
          _passwordErrorText = 'Password is too weak.';
        });
      } else {
        _showErrorNotice(e.message ?? 'Registration failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      _showErrorNotice('Something went wrong while creating your account.');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _showSuccessNotice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Registration Successful',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Your account has been created successfully. You can now log in.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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

  void _showErrorNotice(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Registration Failed',
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
              child: _currentPage == 1
                  ? _buildFirstRegistrationPage()
                  : _buildSecondRegistrationPage(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFirstRegistrationPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 45),
        const Text(
          'Create an Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 35),
        const Text(
          'First Name:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _firstNameController,
          onChanged: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                _firstNameError = false;
              });
            }
          },
          decoration: _textFieldDecoration(
            hintText: 'Enter your first name',
            hasError: _firstNameError,
            errorText: 'This field is required.',
          ),
          style: const TextStyle(fontSize: 17, color: Colors.black),
        ),
        const SizedBox(height: 22),
        const Text(
          'Middle Name (Optional):',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _middleNameController,
          decoration: _textFieldDecoration(
            hintText: 'Enter your middle name',
            hasError: false,
          ),
          style: const TextStyle(fontSize: 17, color: Colors.black),
        ),
        const SizedBox(height: 22),
        const Text(
          'Last Name:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _lastNameController,
          onChanged: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                _lastNameError = false;
              });
            }
          },
          decoration: _textFieldDecoration(
            hintText: 'Enter your last name',
            hasError: _lastNameError,
            errorText: 'This field is required.',
          ),
          style: const TextStyle(fontSize: 17, color: Colors.black),
        ),

        // ✅ NEW: Age Field UI
        const SizedBox(height: 22),
        const Text(
          'Age:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number, // Opens number pad
          onChanged: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                _ageError = false;
                _ageErrorText = null;
              });
            }
          },
          decoration: _textFieldDecoration(
            hintText: 'Enter your age',
            hasError: _ageError,
            errorText: _ageErrorText ?? 'This field is required.',
          ),
          style: const TextStyle(fontSize: 17, color: Colors.black),
        ),

        const SizedBox(height: 25),
        const Text(
          'Gender:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        RadioListTile<String>(
          value: 'Male',
          groupValue: _selectedGender,
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
              _genderError = false;
            });
          },
          title: const Text(
            'Male',
            style: TextStyle(fontSize: 17, color: Colors.black),
          ),
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFFFF3030),
        ),
        RadioListTile<String>(
          value: 'Female',
          groupValue: _selectedGender,
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
              _genderError = false;
            });
          },
          title: const Text(
            'Female',
            style: TextStyle(fontSize: 17, color: Colors.black),
          ),
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFFFF3030),
        ),
        RadioListTile<String>(
          value: 'Prefer not to say',
          groupValue: _selectedGender,
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
              _genderError = false;
            });
          },
          title: const Text(
            'Prefer not to say',
            style: TextStyle(fontSize: 17, color: Colors.black),
          ),
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFFFF3030),
        ),
        if (_genderError)
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Color(0xFFD32F2F),
                  size: 18,
                ),
                SizedBox(width: 5),
                Text(
                  'Please select an option.',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 15),
        const Text(
          'Type of Disability:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedDisability,
          decoration: InputDecoration(
            filled: true,
            fillColor:
            _disabilityError ? const Color(0xFFFFEBEE) : Colors.white,
            errorText: _disabilityError ? 'Please select an option.' : null,
            errorStyle: const TextStyle(
              color: Color(0xFFD32F2F),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: _disabilityError
                ? const Icon(Icons.error_outline, color: Color(0xFFD32F2F))
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _disabilityError
                    ? const Color(0xFFD32F2F)
                    : Colors.transparent,
                width: _disabilityError ? 2 : 0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _disabilityError
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFFFF3030),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 5,
            ),
          ),
          hint: const Text(
            'Select type of disability',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Visual Disability',
              child: Text('Visual Disability'),
            ),
            DropdownMenuItem(
              value: 'Hearing Disability',
              child: Text('Hearing Disability'),
            ),
            DropdownMenuItem(
              value: 'Physical Disability',
              child: Text('Physical Disability'),
            ),
            DropdownMenuItem(
              value: 'Speech Disability',
              child: Text('Speech Disability'),
            ),
            DropdownMenuItem(
              value: 'Multiple Disabilities',
              child: Text('Multiple Disabilities'),
            ),
            DropdownMenuItem(
              value: 'Other',
              child: Text('Other'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDisability = value;
              _disabilityError = false;
            });
          },
        ),
        const SizedBox(height: 35),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 120,
              height: 50,
              child: OutlinedButton(
                onPressed: _backPage,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFF3030)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF3030),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 120,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3030),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSecondRegistrationPage() {
    final bool passwordMismatch = _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 45),
        const Text(
          'Create an Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Set up your account.',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        const SizedBox(height: 35),
        const Text(
          'Email:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
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
            setState(() {
              _passwordError = false;
              _confirmPasswordError = false;
              _passwordErrorText = null;
              _confirmPasswordErrorText = null;
            });
          },
          decoration: _textFieldDecoration(
            hintText: 'Create a password',
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
        const SizedBox(height: 25),
        const Text(
          'Confirm Password:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          onChanged: (value) {
            setState(() {
              _confirmPasswordError = false;
              _confirmPasswordErrorText = null;
            });
          },
          decoration: _textFieldDecoration(
            hintText: 'Confirm your password',
            hasError: _confirmPasswordError || passwordMismatch,
            errorText: _confirmPasswordErrorText ??
                (passwordMismatch
                    ? 'Passwords do not match.'
                    : 'This field is required.'),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          style: const TextStyle(fontSize: 17, color: Colors.black),
        ),
        const SizedBox(height: 35),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 120,
              height: 50,
              child: OutlinedButton(
                onPressed: _isRegistering ? null : _backPage,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFF3030)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF3030),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 120,
              height: 50,
              child: ElevatedButton(
                onPressed: _isRegistering ? null : _registerAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3030),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isRegistering
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 15),
              children: [
                const TextSpan(text: 'Already have an account? '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: _isRegistering
                        ? null
                        : () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Log in Here',
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
    );
  }
}