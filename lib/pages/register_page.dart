import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/profile_manager.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedBirthDate;
  int? _selectedColor;
  bool _isVerificationSent = false;
  bool _isCodeVerified = false;
  bool _isLoading = false;
  bool _isVerifyingCode = false;
  bool _showBirthDateError = false;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = _colorOptions[0].value;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _verificationCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final l10n = AppLocalizations.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: l10n.selectBirthDateHelp,
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _showBirthDateError = false;
      });
    }
  }

  Future<void> _sendVerificationCode() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterEmailAddress)),
      );
      return;
    }
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterValidEmail)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileManager = Provider.of<ProfileManager>(context, listen: false);
      final result = await profileManager.sendVerificationCode(email);

      if (result['success'] == true) {
        setState(() {
          _isVerificationSent = true;
          _isCodeVerified = false;
          _verificationCodeController.clear();
        });
        if (mounted) {
          final code = result['code'] as String? ?? '';
          _showVerificationCodeDialog(code);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.errorWithMessage(
                l10n.localizeErrorMessage(
                  e.toString().replaceFirst('Exception: ', ''),
                ),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final l10n = AppLocalizations.of(context);
    if (_verificationCodeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterSixDigitCodeShort),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingCode = true;
    });

    try {
      final profileManager = Provider.of<ProfileManager>(context, listen: false);
      final isValid = await profileManager.verifyEmailCode(
        _emailController.text.trim(),
        _verificationCodeController.text.trim(),
      );

      if (isValid) {
        setState(() {
          _isCodeVerified = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.codeVerified),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.invalidCode),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.errorWithMessage(
                l10n.localizeErrorMessage(
                  e.toString().replaceFirst('Exception: ', ''),
                ),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingCode = false;
        });
      }
    }
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);
    final issues = <String>[];

    final formValid = _formKey.currentState!.validate();
    if (!formValid) {
      issues.add(l10n.fillRequiredFields);
    }

    if (_selectedBirthDate == null) {
      issues.add(l10n.selectBirthDateError);
      setState(() => _showBirthDateError = true);
    }

    if (!_isVerificationSent) {
      issues.add(l10n.sendCodeFirst);
    } else if (!_isCodeVerified) {
      if (_verificationCodeController.text.trim().length != 6) {
        issues.add(l10n.enterSixDigitCode);
      } else {
        issues.add(l10n.verifyCodeFirst);
      }
    }

    if (issues.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(issues.join('\n')),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileManager = Provider.of<ProfileManager>(context, listen: false);
      await profileManager.registerProfile(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthDate: _selectedBirthDate!,
        verificationCode: _verificationCodeController.text.trim(),
        password: _passwordController.text.trim(),
        avatarColor: _selectedColor,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountCreated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.localizeErrorMessage(
                e.toString().replaceFirst('Exception: ', ''),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showVerificationCodeDialog(String code) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.verificationCodeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.yourVerificationCode,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createAccount),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedColor != null
                          ? Color(_selectedColor!)
                          : _colorOptions[0],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  hintText: l10n.emailHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.enterEmail;
                  }
                  if (!value.contains('@')) {
                    return l10n.validEmail;
                  }
                  return null;
                },
                enabled: !_isVerificationSent,
              ),
              const SizedBox(height: 16),
              if (!_isVerificationSent)
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.sendVerificationCode),
                ),
              if (_isVerificationSent) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _verificationCodeController,
                        decoration: InputDecoration(
                          labelText: l10n.verificationCode,
                          hintText: l10n.verificationCodeHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: _isCodeVerified
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        enabled: !_isCodeVerified,
                        validator: (value) {
                          if (!_isCodeVerified) {
                            if (value == null || value.isEmpty) {
                              return l10n.verifyCodeRequired;
                            }
                            if (value.length != 6) {
                              return l10n.codeSixDigits;
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    if (!_isCodeVerified) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isVerifyingCode ? null : _verifyCode,
                        icon: _isVerifyingCode
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        color: const Color(0xFF2E7D32),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  child: Text(l10n.resendCode),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: l10n.firstName,
                  hintText: l10n.firstNameHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.enterFirstName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: l10n.lastName,
                  hintText: l10n.lastNameHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.enterLastName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  hintText: l10n.passwordHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.enterPassword;
                  }
                  if (value.length < 6) {
                    return l10n.passwordMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: l10n.confirmPassword,
                  hintText: l10n.confirmPasswordHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.confirmPasswordRequired;
                  }
                  if (value != _passwordController.text) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.birthDate,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    errorText: _showBirthDateError ? l10n.selectBirthDateError : null,
                  ),
                  child: Text(
                    _selectedBirthDate == null
                        ? l10n.selectBirthDate
                        : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                    style: TextStyle(
                      color: _selectedBirthDate == null
                          ? Colors.grey.shade600
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.chooseAvatarColor,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _colorOptions.map((color) {
                  final isSelected = _selectedColor == color.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color.value;
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 30)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.createAccount,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
