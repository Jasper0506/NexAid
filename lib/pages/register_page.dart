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

  final TextEditingController _firstNameController =
  TextEditingController();

  final TextEditingController _middleNameController =
  TextEditingController();

  final TextEditingController _lastNameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _firstNameError = false;
  bool _lastNameError = false;
  bool _genderError = false;
  bool _disabilityError = false;

  bool _emailError = false;
  bool _passwordError = false;
  bool _confirmPasswordError = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _nextPage() {
    setState(() {
      _firstNameError = _firstNameController.text.trim().isEmpty;
      _lastNameError = _lastNameController.text.trim().isEmpty;
      _genderError = _selectedGender == null;
      _disabilityError = _selectedDisability == null;
    });

    if (_firstNameError ||
        _lastNameError ||
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

  void _registerAccount() {
    setState(() {
      _emailError = _emailController.text.trim().isEmpty;
      _passwordError = _passwordController.text.isEmpty;
      _confirmPasswordError = _confirmPasswordController.text.isEmpty;
    });

    if (_emailError || _passwordError || _confirmPasswordError) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = true;
        _confirmPasswordError = true;
      });
      return;
    }

    _showSuccessNotice();
  }

  void _showSuccessNotice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Registration Successful',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Your account has been created successfully. You can now log in.',
            style: TextStyle(
              fontSize: 16,
            ),
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

  InputDecoration _textFieldDecoration({
    required String hintText,
    required bool hasError,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: hasError
          ? const Color(0xFFFFEBEE)
          : Colors.white,
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.grey,
      ),
      errorText: hasError ? errorText : null,
      errorStyle: const TextStyle(
        color: Color(0xFFD32F2F),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      errorMaxLines: 2,
      suffixIcon: hasError
          ? const Icon(
        Icons.error_outline,
        color: Color(0xFFD32F2F),
      )
          : suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError
              ? const Color(0xFFD32F2F)
              : Colors.transparent,
          width: hasError ? 2 : 0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError
              ? const Color(0xFFD32F2F)
              : const Color(0xFFFF3030),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
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
          style: const TextStyle(
            fontSize: 17,
            color: Colors.black,
          ),
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
          style: const TextStyle(
            fontSize: 17,
            color: Colors.black,
          ),
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
          style: const TextStyle(
            fontSize: 17,
            color: Colors.black,
          ),
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
            style: TextStyle(
              fontSize: 17,
              color: Colors.black,
            ),
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
            style: TextStyle(
              fontSize: 17,
              color: Colors.black,
            ),
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
            style: TextStyle(
              fontSize: 17,
              color: Colors.black,
            ),
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
            fillColor: _disabilityError
                ? const Color(0xFFFFEBEE)
                : Colors.white,
            errorText: _disabilityError
                ? 'Please select an option.'
                : null,
            errorStyle: const TextStyle(
              color: Color(0xFFD32F2F),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: _disabilityError
                ? const Icon(
              Icons.error_outline,
              color: Color(0xFFD32F2F),
            )
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
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
                  side: const BorderSide(
                    color: Color(0xFFFF3030),
                  ),
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
    bool passwordMismatch =
        _passwordController.text.isNotEmpty &&
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
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
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
              });
            }
          },
          decoration: _textFieldDecoration(
            hintText: 'Enter your email',
            hasError: _emailError,
            errorText: 'This field is required.',
          ),
          style: const TextStyle(
            fontSize: 17,
            color: Colors.black,
          ),
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
            });
          },
          decoration: _textFieldDecoration(
            hintText: 'Create a password',
            hasError: _passwordError,
            errorText: _passwordError &&
                _confirmPasswordController.text.isNotEmpty &&
                _passwordController.text !=
                    _confirmPasswordController.text
                ? 'Passwords do not match.'
                : 'This field is required.',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          style: const TextStyle(
            fontSize: 17,
            color: Colors.black,
          ),
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
            });
          },
          decoration: _textFieldDecoration(
            hintText: 'Confirm your password',
            hasError: _confirmPasswordError,
            errorText: passwordMismatch
                ? 'Passwords do not match.'
                : 'This field is required.',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword =
                  !_obscureConfirmPassword;
                });
              },
            ),
          ),
          style: const TextStyle(
            fontSize: 17,
            color: Colors.black,
          ),
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
                  side: const BorderSide(
                    color: Color(0xFFFF3030),
                  ),
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
                onPressed: _registerAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3030),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
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
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
              children: [
                const TextSpan(
                  text: 'Already have an account? ',
                ),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
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