import 'package:navistfind/core/navigation/app_routes.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/features/auth/application/auth_provider.dart';
import 'package:navistfind/core/utils/password_validator.dart';
import 'package:navistfind/widgets/password_strength_indicator.dart';
import 'package:navistfind/features/notifications/data/device_token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final contactNumberController = TextEditingController();
  final otherUserTypeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _selectedUserType;
  String? _selectedGradeLevel;

  final List<String> _userTypes = [
    'Student',
    'Teacher',
    'Parent',
    'Staff',
    'Other',
  ];

  final List<String> _gradeLevels = [
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    otherUserTypeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(registerStateProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Transform.scale(
                        scale: 1.2,
                        child: Image.asset(
                          'assets/images/navistfind_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Welcome text
                  Text(
                    'Create Account',
                    style: AppTheme.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Register to start exploring campus nav',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textGray,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Full Name input field
                  TextFormField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'John Doe',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: AppTheme.primaryBlue,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().split(' ').length < 2) {
                        return 'Please enter your first and last name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email input with border
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'example@email.com',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: AppTheme.primaryBlue,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Contact Number input (optional)
                  TextFormField(
                    controller: contactNumberController,
                    decoration: InputDecoration(
                      labelText: 'Contact Number (Optional)',
                      hintText: '09XXXXXXXXX',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: AppTheme.primaryBlue,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  // User Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedUserType,
                    decoration: InputDecoration(
                      labelText: 'User Type',
                      prefixIcon: Icon(
                        Icons.person_pin_outlined,
                        color: Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: AppTheme.primaryBlue,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    items: _userTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value;
                        if (value != 'Student') {
                          _selectedGradeLevel = null;
                        }
                        if (value != 'Other') {
                          otherUserTypeController.clear();
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a user type';
                      }
                      return null;
                    },
                  ),

                  // Grade Level Dropdown (shown only for Students)
                  if (_selectedUserType == 'Student') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGradeLevel,
                      decoration: InputDecoration(
                        labelText: 'Grade Level',
                        prefixIcon: Icon(
                          Icons.school_outlined,
                          color: Colors.grey.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          borderSide: BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        floatingLabelStyle: TextStyle(
                          color: AppTheme.primaryBlue,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      items: _gradeLevels.map((grade) {
                        return DropdownMenuItem(
                          value: grade,
                          child: Text(grade),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGradeLevel = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedUserType == 'Student' &&
                            (value == null || value.isEmpty)) {
                          return 'Please select your grade level';
                        }
                        return null;
                      },
                    ),
                  ],

                  // Other User Type Text Field (shown only for "Other")
                  if (_selectedUserType == 'Other') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: otherUserTypeController,
                      decoration: InputDecoration(
                        labelText: 'Please specify',
                        hintText: 'Enter your user type',
                        prefixIcon: Icon(
                          Icons.edit_outlined,
                          color: Colors.grey.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          borderSide: BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        floatingLabelStyle: TextStyle(
                          color: AppTheme.primaryBlue,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (_selectedUserType == 'Other' &&
                            (value == null || value.isEmpty)) {
                          return 'Please specify your user type';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Password input with visibility toggle and strength indicator
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter a strong password',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey.shade600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: AppTheme.primaryBlue,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    obscureText: _obscurePassword,
                    onChanged: (value) {
                      setState(() {}); // Trigger rebuild for strength indicator
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      final validation = PasswordValidator.validatePassword(
                        value,
                      );
                      if (!validation.isValid) {
                        return validation.errors.first;
                      }
                      return null;
                    },
                  ),

                  // Password strength indicator
                  if (passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    PasswordStrengthIndicator(
                      password: passwordController.text,
                      showRequirements: true,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Confirm Password input with visibility toggle
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey.shade600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: AppTheme.primaryBlue,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Register button with sky blue color
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                ref.read(registerStateProvider.notifier).state =
                                    true;
                                final error = await ref
                                    .read(authProvider)
                                    .register(
                                      name: fullNameController.text.trim(),
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                      userType: _selectedUserType!,
                                      gradeLevel: _selectedUserType == 'Student'
                                          ? _selectedGradeLevel
                                          : null,
                                      otherUserType: _selectedUserType == 'Other'
                                          ? otherUserTypeController.text.trim()
                                          : null,
                                      contactNumber: contactNumberController
                                              .text
                                              .trim()
                                              .isNotEmpty
                                          ? contactNumberController.text.trim()
                                          : null,
                                    );
                                ref.read(registerStateProvider.notifier).state =
                                    false;

                                if (error == null) {
                                  // Register device token after successful registration
                                  try {
                                    final fcmToken = await FirebaseMessaging
                                        .instance
                                        .getToken();
                                    if (fcmToken != null) {
                                      await DeviceTokenService().registerToken(
                                        fcmToken,
                                      );
                                    }
                                  } catch (_) {}

                                  if (mounted) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      AppRoutes.home,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 12),
                                            Text('Registration successful'),
                                          ],
                                        ),
                                        backgroundColor: AppTheme.successGreen,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  error,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        backgroundColor: AppTheme.errorRed,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(
                                          seconds: error.length > 100 ? 6 : 4,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      style: AppTheme.getPrimaryButtonStyle(),
                      child: isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textGray,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          );
                        },
                        child: Text(
                          'Login here',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
