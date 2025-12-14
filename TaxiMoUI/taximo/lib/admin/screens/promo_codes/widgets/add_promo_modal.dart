import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/promo_provider.dart';

class AddPromoModal extends StatefulWidget {
  const AddPromoModal({super.key});

  @override
  State<AddPromoModal> createState() => _AddPromoModalState();
}

class _AddPromoModalState extends State<AddPromoModal> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _usageLimitController = TextEditingController();
  
  String _selectedDiscountType = 'Fixed';
  String _selectedStatus = 'Active';
  DateTime? _selectedValidFrom;
  DateTime? _selectedValidUntil;

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _selectValidFrom(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedValidFrom ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _selectedValidFrom) {
      setState(() {
        _selectedValidFrom = picked;
        // If ValidUntil is before ValidFrom, update it
        if (_selectedValidUntil != null && _selectedValidUntil!.isBefore(picked)) {
          _selectedValidUntil = picked.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectValidUntil(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedValidUntil ?? (_selectedValidFrom ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _selectedValidFrom ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _selectedValidUntil) {
      setState(() {
        _selectedValidUntil = picked;
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

    if (_selectedValidFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid From date is required')),
      );
      return;
    }

    if (_selectedValidUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid Until date is required')),
      );
      return;
    }

    if (_selectedValidUntil!.isBefore(_selectedValidFrom!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid Until must be after Valid From')),
      );
      return;
    }

    // ASP.NET Core uses camelCase by default
    final promoData = <String, dynamic>{
      'code': _codeController.text.trim().toUpperCase(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'discountType': _selectedDiscountType,
      'discountValue': double.tryParse(_discountValueController.text.trim()) ?? 0.0,
      'usageLimit': _usageLimitController.text.trim().isEmpty ? null : int.tryParse(_usageLimitController.text.trim()),
      'validFrom': _selectedValidFrom!.toIso8601String(),
      'validUntil': _selectedValidUntil!.toIso8601String(),
      'status': _selectedStatus.toLowerCase(), // Backend expects lowercase: "active" or "inactive"
    };

    try {
      await Provider.of<PromoProvider>(context, listen: false).add(promoData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promo code created successfully')),
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
                  'Add Promo Code',
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
                      // Code
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Code',
                          border: OutlineInputBorder(),
                          helperText: 'Promo code (will be converted to uppercase)',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Code is required';
                          }
                          if (value.length > 50) {
                            return 'Code must be 50 characters or less';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          helperText: 'Optional description',
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                      const SizedBox(height: 16),
                      // Discount Type
                      DropdownButtonFormField<String>(
                        value: _selectedDiscountType,
                        decoration: const InputDecoration(
                          labelText: 'Discount Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Fixed', 'Percentage'].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedDiscountType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Discount Value
                      TextFormField(
                        controller: _discountValueController,
                        decoration: InputDecoration(
                          labelText: 'Discount Value',
                          border: const OutlineInputBorder(),
                          helperText: _selectedDiscountType == 'Percentage' 
                              ? 'Percentage (0-100)' 
                              : 'Fixed amount',
                          prefixText: _selectedDiscountType == 'Percentage' ? null : r'$',
                          suffixText: _selectedDiscountType == 'Percentage' ? '%' : null,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Discount value is required';
                          }
                          final numValue = double.tryParse(value);
                          if (numValue == null) {
                            return 'Invalid number';
                          }
                          if (_selectedDiscountType == 'Percentage' && (numValue < 0 || numValue > 100)) {
                            return 'Percentage must be between 0 and 100';
                          }
                          if (_selectedDiscountType == 'Fixed' && numValue < 0) {
                            return 'Discount value must be positive';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Usage Limit
                      TextFormField(
                        controller: _usageLimitController,
                        decoration: const InputDecoration(
                          labelText: 'Usage Limit',
                          border: OutlineInputBorder(),
                          helperText: 'Optional: Maximum number of times this code can be used',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final intValue = int.tryParse(value);
                            if (intValue == null || intValue < 1) {
                              return 'Usage limit must be a positive integer';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Valid From
                      InkWell(
                        onTap: () => _selectValidFrom(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Valid From',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_formatDate(_selectedValidFrom)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Valid Until
                      InkWell(
                        onTap: () => _selectValidUntil(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Valid Until',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_formatDate(_selectedValidUntil)),
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
                      child: const Text('Create Promo Code'),
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

