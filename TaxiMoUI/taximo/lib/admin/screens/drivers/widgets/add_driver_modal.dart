import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/drivers_provider.dart';
import 'dart:math';

class AddDriverModal extends StatefulWidget {
  const AddDriverModal({super.key});

  @override
  State<AddDriverModal> createState() => _AddDriverModalState();
}

class _AddDriverModalState extends State<AddDriverModal> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  DateTime? _selectedLicenseExpiry;
  String _selectedStatus = 'Active';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectLicenseExpiry(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _selectedLicenseExpiry) {
      setState(() {
        _selectedLicenseExpiry = picked;
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

    if (_selectedLicenseExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License expiry date is required')),
      );
      return;
    }

    // ASP.NET Core uses camelCase by default and accepts it (case-insensitive)
    final driverData = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'username': _usernameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'licenseNumber': _licenseNumberController.text.trim(),
      'licenseExpiry': _selectedLicenseExpiry!.toIso8601String(),
      'status': _selectedStatus.toLowerCase(), // Backend expects lowercase: "active" or "inactive"
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
    };

    try {
      await Provider.of<DriversProvider>(context, listen: false).createDriver(driverData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
                child: const Text(
                  'Add Driver',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D3F),
                  ),
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  // Validate against LettersOnly regex: ^[a-zA-Z]+$
                  final nameRegex = RegExp(r"^[a-zA-Z]+$");
                  if (!nameRegex.hasMatch(value)) {
                    return 'First name must contain only letters';
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  // Validate against LettersOnly regex: ^[a-zA-Z]+$
                  final nameRegex = RegExp(r"^[a-zA-Z]+$");
                  if (!nameRegex.hasMatch(value)) {
                    return 'Last name must contain only letters';
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
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone is required';
                  }
                  // Basic phone validation (allows digits only)
                  final phoneRegex = RegExp(r'^\d+$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Phone number may contain digits only';
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
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // License Number
              TextFormField(
                controller: _licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'License number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // License Expiry
              InkWell(
                onTap: () => _selectLicenseExpiry(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'License Expiry',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatDate(_selectedLicenseExpiry)),
                ),
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
              // Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
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
                    return 'Password is required';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
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
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
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
                      child: const Text('Create Driver'),
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

