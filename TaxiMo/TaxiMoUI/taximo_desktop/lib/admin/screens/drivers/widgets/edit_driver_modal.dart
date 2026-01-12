import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/drivers_provider.dart';
import '../../../models/driver_model.dart';

class EditDriverModal extends StatefulWidget {
  final DriverModel driver;

  const EditDriverModal({super.key, required this.driver});

  @override
  State<EditDriverModal> createState() => _EditDriverModalState();
}

class _EditDriverModalState extends State<EditDriverModal> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _licenseNumberController;
  
  DateTime? _selectedLicenseExpiry;
  late String _selectedStatus;
  // Standard Driver role ID (required by DriverUpdateDto)
  static const int _driverRoleId = 3;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _firstNameController = TextEditingController(text: widget.driver.firstName);
    _lastNameController = TextEditingController(text: widget.driver.lastName);
    _emailController = TextEditingController(text: widget.driver.email);
    _licenseNumberController = TextEditingController(text: widget.driver.licenseNumber);
    // Normalize status to capitalize first letter
    final status = widget.driver.status.toLowerCase();
    _selectedStatus = status == 'active' ? 'Active' : 'Inactive';
    _selectedLicenseExpiry = widget.driver.licenseExpiry;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectLicenseExpiry(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedLicenseExpiry ?? DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final driverId = widget.driver.driverId;
    
    if (driverId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Invalid driver ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // ASP.NET Core uses camelCase by default and accepts it (case-insensitive)
    final driverData = <String, dynamic>{
      'driverId': driverId,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'licenseNumber': _licenseNumberController.text.trim(),
      // Preserve existing phone value
      if (widget.driver.phone != null) 'phone': widget.driver.phone,
      // Only send licenseExpiry if it's not null
      if (_selectedLicenseExpiry != null) 'licenseExpiry': _selectedLicenseExpiry!.toIso8601String(),
      'status': _selectedStatus.toLowerCase(), // Backend expects lowercase: "active" or "inactive"
      'roleId': _driverRoleId, // Required by DriverUpdateDto (3 = Driver role)
    };

    try {
      await Provider.of<DriversProvider>(context, listen: false).updateDriver(driverId, driverData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver successfully updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating driver: ${e.toString()}'),
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
                      'Edit Driver',
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
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          helperText: 'Format: example@domain.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          // Proper email regex validation
                          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email format (e.g. user@domain.com)';
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
                      child: const Text('Save Changes'),
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

