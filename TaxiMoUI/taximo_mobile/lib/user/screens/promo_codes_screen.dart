import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/promo_code_dto.dart';
import '../services/promo_code_service.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  final PromoCodeService _promoCodeService = PromoCodeService();
  late final Future<List<PromoCodeDto>> _promoCodesFuture;

  @override
  void initState() {
    super.initState();
    _promoCodesFuture = _loadPromoCodes();
  }

  Future<List<PromoCodeDto>> _loadPromoCodes() async {
    final promoCodes = await _promoCodeService.getAllPromoCodes();
    
    // Sort by status (active first) and then by validUntil date
    promoCodes.sort((a, b) {
      if (a.status.toLowerCase() == 'active' && b.status.toLowerCase() != 'active') {
        return -1;
      } else if (a.status.toLowerCase() != 'active' && b.status.toLowerCase() == 'active') {
        return 1;
      }
      return b.validUntil.compareTo(a.validUntil);
    });

    return promoCodes;
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  bool _isValid(PromoCodeDto promo, DateTime now) {
    return promo.status.toLowerCase() == 'active' &&
           now.isAfter(promo.validFrom) &&
           now.isBefore(promo.validUntil);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Promo Codes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can use these promo codes when booking a ride',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: FutureBuilder<List<PromoCodeDto>>(
              future: _promoCodesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          snapshot.error.toString().replaceFirst('Exception: ', ''),
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (!mounted) return;
                            setState(() {
                              _promoCodesFuture = _loadPromoCodes();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final promoCodes = snapshot.data ?? [];

                if (promoCodes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No promo codes available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new offers',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: promoCodes.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final promo = promoCodes[index];
                    return _buildPromoCodeCard(promo);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeCard(PromoCodeDto promo) {
    final now = DateTime.now();
    final isValid = _isValid(promo, now);
    final isExpired = now.isAfter(promo.validUntil);
    final isInactive = promo.status.toLowerCase() != 'active';

    return Container(
      key: ValueKey(promo.promoId),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid 
              ? Colors.green[300]! 
              : (isExpired || isInactive) 
                  ? Colors.grey[300]! 
                  : Colors.orange[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isValid 
                              ? Colors.green[100] 
                              : (isExpired || isInactive) 
                                  ? Colors.grey[200] 
                                  : Colors.orange[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          promo.code,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isValid 
                                ? Colors.green[900] 
                                : (isExpired || isInactive) 
                                    ? Colors.grey[700] 
                                    : Colors.orange[900],
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isValid 
                        ? Colors.green[50] 
                        : (isExpired || isInactive) 
                            ? Colors.grey[200] 
                            : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isValid 
                        ? 'Valid' 
                        : (isExpired 
                            ? 'Expired' 
                            : 'Inactive'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isValid 
                          ? Colors.green[800] 
                          : (isExpired || isInactive) 
                              ? Colors.grey[700] 
                              : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description
            if (promo.description != null && promo.description!.isNotEmpty) ...[
              Text(
                promo.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Discount info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.discount, color: Colors.deepPurple[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    promo.isPercentage
                        ? '${promo.discountValue.toStringAsFixed(0)}% OFF'
                        : '${promo.discountValue.toStringAsFixed(2)} EUR OFF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[900],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Validity dates
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Valid: ${_formatDate(promo.validFrom)} - ${_formatDate(promo.validUntil)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            // Usage limit
            if (promo.usageLimit != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Usage limit: ${promo.usageLimit} times',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

