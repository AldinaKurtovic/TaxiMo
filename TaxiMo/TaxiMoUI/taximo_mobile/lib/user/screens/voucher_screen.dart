import 'package:flutter/material.dart';
import '../models/promo_code_dto.dart';
import '../services/promo_code_service.dart';
import '../../config/api_config.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final PromoCodeService _promoCodeService = PromoCodeService();
  final TextEditingController _codeController = TextEditingController();
  late final Future<List<PromoCodeDto>> _promoCodesFuture;
  List<PromoCodeDto> _filteredPromoCodes = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _promoCodesFuture = _fetchPromoCodes();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<List<PromoCodeDto>> _fetchPromoCodes() async {
    final promoCodes = await _promoCodeService.getActivePromoCodes();
    if (mounted) {
      setState(() {
        _filteredPromoCodes = promoCodes;
      });
    }
    return promoCodes;
  }

  void _filterPromoCodes(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _promoCodesFuture.then((codes) {
          if (mounted) {
            setState(() {
              _filteredPromoCodes = codes;
            });
          }
        });
      } else {
        _promoCodesFuture.then((codes) {
          if (mounted) {
            setState(() {
              _filteredPromoCodes = codes
                  .where((code) =>
                      code.code.toLowerCase().contains(query.toLowerCase()) ||
                      (code.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
                  .toList();
            });
          }
        });
      }
    });
  }

  String _formatDiscount(PromoCodeDto promo) {
    if (promo.isPercentage) {
      return '${promo.discountValue.toStringAsFixed(0)}% off';
    } else {
      return '${promo.discountValue.toStringAsFixed(2)} EUR off';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Have a promo code? enter it here',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _codeController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _codeController.clear();
                          _filterPromoCodes('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              onChanged: _filterPromoCodes,
            ),
          ),

          // Promo codes list
          Expanded(
            child: FutureBuilder<List<PromoCodeDto>>(
              future: _promoCodesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading vouchers',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final promoCodes = _isSearching
                    ? _filteredPromoCodes
                    : (snapshot.data ?? []);

                if (promoCodes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 48, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching
                              ? 'No vouchers found'
                              : 'No active vouchers available',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: promoCodes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final promo = promoCodes[index];
                    return _VoucherCard(
                      promo: promo,
                      formatDiscount: _formatDiscount,
                      formatDate: _formatDate,
                      onUse: () {
                        Navigator.pop(context, promo);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final PromoCodeDto promo;
  final String Function(PromoCodeDto) formatDiscount;
  final String Function(DateTime) formatDate;
  final VoidCallback onUse;

  const _VoucherCard({
    required this.promo,
    required this.formatDiscount,
    required this.formatDate,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    promo.code,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatDiscount(promo),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (promo.description != null && promo.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                promo.description!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Valid until ${formatDate(promo.validUntil)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onUse,
                child: const Text('Use this'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

