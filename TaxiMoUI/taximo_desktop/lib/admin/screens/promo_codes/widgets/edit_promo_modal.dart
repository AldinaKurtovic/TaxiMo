import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/promo_provider.dart';
import '../../../models/promo_model.dart';

class EditPromoModal extends StatefulWidget {
  final PromoModel promo;

  const EditPromoModal({super.key, required this.promo});

  @override
  State<EditPromoModal> createState() => _EditPromoModalState();
}

class _EditPromoModalState extends State<EditPromoModal> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _usageLimitController;
  
  late String _selectedDiscountType;
  late String _selectedStatus;
  late DateTime? _selectedValidFrom;
  late DateTime? _selectedValidUntil;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _codeController = TextEditingController(text: widget.promo.code);
    _descriptionController = TextEditingController(text: widget.promo.description ?? '');
    _discountValueController = TextEditingController(text: widget.promo.discountValue.toStringAsFixed(2));
    _usageLimitController = TextEditingController(
      text: widget.promo.usageLimit?.toString() ?? '',
    );
    
    // Normalize discount type (capitalize first letter)
    final discountType = widget.promo.discountType.toLowerCase();
    _selectedDiscountType = discountType == 'percentage' ? 'Percentage' : 'Fixed';
    
    // Normalize status to capitalize first letter
    final status = widget.promo.status.toLowerCase();
    _selectedStatus = status == 'active' ? 'Active' : 'Inactive';
    
    _selectedValidFrom = widget.promo.validFrom;
    _selectedValidUntil = widget.promo.validUntil;
  }

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

  String? _validateValidFrom() {
    if (_selectedValidFrom == null) {
      return 'Datum početka važenja je obavezan';
    }
    return null;
  }

  String? _validateValidUntil() {
    if (_selectedValidUntil == null) {
      return 'Datum završetka važenja je obavezan';
    }
    if (_selectedValidFrom != null && _selectedValidUntil!.isBefore(_selectedValidFrom!)) {
      return 'Datum završetka mora biti nakon datuma početka';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate dates
    final validFromError = _validateValidFrom();
    final validUntilError = _validateValidUntil();
    
    if (validFromError != null || validUntilError != null) {
      setState(() {}); // Trigger rebuild to show errors
      return;
    }

    // ASP.NET Core uses camelCase by default
    final promoData = <String, dynamic>{
      'promoId': widget.promo.promoId,
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
      await Provider.of<PromoProvider>(context, listen: false).update(widget.promo.promoId, promoData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promo kod je uspješno ažuriran'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri ažuriranju promo koda: ${e.toString()}'),
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
                      'Edit Promo Code',
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
                          if (value == null || value.trim().isEmpty) {
                            return 'Kod je obavezan';
                          }
                          if (value.trim().length > 50) {
                            return 'Kod ne može imati više od 50 karaktera';
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
                          if (value == null || value.trim().isEmpty) {
                            return 'Vrijednost popusta je obavezna';
                          }
                          final numValue = double.tryParse(value.trim());
                          if (numValue == null) {
                            return 'Unesite validan broj';
                          }
                          if (_selectedDiscountType == 'Percentage' && (numValue < 0 || numValue > 100)) {
                            return 'Postotak mora biti između 0 i 100';
                          }
                          if (_selectedDiscountType == 'Fixed' && numValue < 0) {
                            return 'Vrijednost popusta mora biti pozitivna';
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
                          if (value != null && value.trim().isNotEmpty) {
                            final intValue = int.tryParse(value.trim());
                            if (intValue == null || intValue < 1) {
                              return 'Limit korištenja mora biti pozitivan cijeli broj';
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
                          decoration: InputDecoration(
                            labelText: 'Valid From',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                            helperText: 'Datum početka važenja promo koda',
                            errorText: _validateValidFrom(),
                          ),
                          child: Text(_formatDate(_selectedValidFrom)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Valid Until
                      InkWell(
                        onTap: () => _selectValidUntil(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Valid Until',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                            helperText: 'Datum završetka važenja promo koda',
                            errorText: _validateValidUntil(),
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
                      child: const Text('Update Promo Code'),
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

