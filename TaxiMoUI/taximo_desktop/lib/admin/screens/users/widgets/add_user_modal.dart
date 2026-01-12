import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/users_provider.dart';
import 'dart:math';

class AddUserModal extends StatefulWidget {
  const AddUserModal({super.key});

  @override
  State<AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends State<AddUserModal> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  DateTime? _selectedDateOfBirth;
  String _selectedStatus = 'Active';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month/$day/$year';
  }


  String _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      12, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Default RoleId = 2 (User role) based on seed data
    // ASP.NET Core uses camelCase by default and accepts it (case-insensitive)
    final userData = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'username': _usernameController.text.trim(),
      'phone': _phoneController.text.trim(),
      // Only include dateOfBirth if it's not null (optional field)
      if (_selectedDateOfBirth != null) 'dateOfBirth': _selectedDateOfBirth!.toIso8601String(),
      'status': _selectedStatus.toLowerCase(), // Backend expects lowercase: "active" or "inactive"
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'roleId': 2, // Default to User role (2 = "User" role based on seed data)
    };

    try {
      await Provider.of<UsersProvider>(context, listen: false).createUser(userData);
      if (mounted) {
        // Clear form fields after successful creation
        _firstNameController.clear();
        _lastNameController.clear();
        _usernameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _selectedDateOfBirth = null;
        _selectedStatus = 'Active';
        _formKey.currentState?.reset();
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Korisnik je uspješno kreiran'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri kreiranju korisnika: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (fixed)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D3F),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First Name
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                          helperText: 'Samo slova, razmaci, crtice i apostrofi',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ime je obavezno';
                  }
                  final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
                  if (!nameRegex.hasMatch(value.trim())) {
                    return 'Ime može sadržavati samo slova, razmake, crtice i apostrofe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
                      // Last Name
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                          helperText: 'Samo slova, razmaci, crtice i apostrofi',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Prezime je obavezno';
                  }
                  final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
                  if (!nameRegex.hasMatch(value.trim())) {
                    return 'Prezime može sadržavati samo slova, razmake, crtice i apostrofe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
                      // Username
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          helperText: 'Only letters, spaces, hyphens, and apostrophes allowed',
                          prefixIcon: Icon(Icons.account_circle_outlined),
                        ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required';
                  }
                  // Validate against LettersOnly regex: ^[a-zA-Z\s\-']+$
                  final usernameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
                  if (!usernameRegex.hasMatch(value)) {
                    return 'Username can only contain letters, spaces, hyphens, and apostrophes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                          helperText: 'Format: +387 61 123 456 ili 061 123 456',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Telefon je obavezan';
                  }
                  // Phone validation (allows digits, spaces, hyphens, parentheses, plus)
                  final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Unesite validan broj telefona (dozvoljeni su brojevi, razmaci, crtice, zagrade i +)';
                  }
                  // Check minimum length (at least 6 digits)
                  final digitsOnly = value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
                  if (digitsOnly.length < 6) {
                    return 'Broj telefona mora imati najmanje 6 cifara';
                  }
                  if (digitsOnly.length > 15) {
                    return 'Broj telefona ne može imati više od 15 cifara';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          helperText: 'Format: example@domain.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email je obavezan';
                  }
                  // Proper email regex validation
                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Unesite validan email format (npr. korisnik@domena.com)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Status Dropdown
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['Active', 'Inactive'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
                      // Date of Birth
                      InkWell(
                        onTap: () => _selectDateOfBirth(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                  child: Text(_formatDate(_selectedDateOfBirth)),
                ),
              ),
              const SizedBox(height: 16),
                      // Password
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          helperText: 'Lozinka mora imati najmanje 8 karaktera',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                    icon: const Icon(Icons.autorenew),
                    onPressed: () {
                      final password = _generatePassword();
                      _passwordController.text = password;
                      _confirmPasswordController.text = password;
                    },
                    tooltip: 'Generate password',
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lozinka je obavezna';
                  }
                  if (value.length < 8) {
                    return 'Lozinka mora imati najmanje 8 karaktera';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                          helperText: 'Potvrdite lozinku',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Potvrda lozinke je obavezna';
                  }
                  if (value != _passwordController.text) {
                    return 'Lozinke se ne poklapaju';
                  }
                  return null;
                },
              ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Footer with buttons (fixed at bottom)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Create User'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

