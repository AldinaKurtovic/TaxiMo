import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/payment_history_dto.dart';
import '../services/payment_service.dart';
import '../../auth/providers/mobile_auth_provider.dart';
import '../widgets/user_app_bar.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  Future<List<PaymentHistoryDto>>? _paymentsFuture;
  final ValueNotifier<String> _filterNotifier = ValueNotifier<String>('all');
  List<PaymentHistoryDto>? _cachedPayments;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _loadPayments();
  }
  
  @override
  void dispose() {
    _filterNotifier.dispose();
    super.dispose();
  }

  Future<List<PaymentHistoryDto>> _loadPayments() async {
    // Get current user
    final authProvider = Provider.of<MobileAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      throw Exception('Please login to view payment history');
    }

    final paymentsData = await _paymentService.getPayments();
    
    // Filter payments by current user ID and map to DTOs
    final payments = paymentsData
        .where((json) => json['userId'] == currentUser.userId)
        .map((json) => PaymentHistoryDto.fromJson(json))
        .toList();

    // Sort by paid date or payment ID (most recent first)
    payments.sort((a, b) {
      if (a.paidAt != null && b.paidAt != null) {
        return b.paidAt!.compareTo(a.paidAt!);
      } else if (a.paidAt != null) {
        return -1;
      } else if (b.paidAt != null) {
        return 1;
      } else {
        return b.paymentId.compareTo(a.paymentId);
      }
    });

    // Cache the payments
    if (mounted) {
      _cachedPayments = payments;
    }

    return payments;
  }

  List<PaymentHistoryDto> _applyFilter(List<PaymentHistoryDto> allPayments, String filter) {
    if (filter == 'all') {
      return allPayments;
    }
    
    return allPayments.where((payment) {
      return payment.status.toLowerCase() == filter.toLowerCase();
    }).toList();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const UserAppBar(title: 'Payments'),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showFilterDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: _filterNotifier,
                          builder: (context, filter, _) {
                            return Text(
                              _getFilterLabel(filter),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Content
          Expanded(
            child: FutureBuilder<List<PaymentHistoryDto>>(
              future: _paymentsFuture ?? _loadPayments(),
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
                              _paymentsFuture = _loadPayments();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allPayments = snapshot.data ?? [];
                if (allPayments.isNotEmpty && _cachedPayments == null) {
                  _cachedPayments = allPayments;
                }

                return ValueListenableBuilder<String>(
                  valueListenable: _filterNotifier,
                  builder: (context, filter, _) {
                    final paymentsToShow = _cachedPayments ?? allPayments;
                    final filteredPayments = _applyFilter(paymentsToShow, filter);

                    if (filteredPayments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No payments found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your payment history will appear here',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredPayments.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      shrinkWrap: false,
                      itemBuilder: (context, index) {
                        final payment = filteredPayments[index];
                        return _buildPaymentCard(payment);
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

  Widget _buildPaymentCard(PaymentHistoryDto payment) {
    final theme = Theme.of(context);
    
    return Container(
      key: ValueKey(payment.paymentId),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            // Header: Status and Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: payment.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: payment.statusColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        payment.statusIcon,
                        size: 16,
                        color: payment.statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        payment.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: payment.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Payment Method
            Row(
              children: [
                Icon(
                  payment.methodIcon,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  payment.method.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Payment Date
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  payment.paidAt != null
                      ? 'Paid on ${_formatDate(payment.paidAt)}'
                      : 'Not paid yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            // Transaction Reference (if available)
            if (payment.transactionRef != null && payment.transactionRef!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.receipt, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transaction: ${payment.transactionRef}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            // Ride ID
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  'Ride ID: ${payment.rideId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All Payments';
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'All Payments';
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...['all', 'completed', 'pending', 'failed', 'cancelled'].map((status) {
                return ListTile(
                  title: Text(_getFilterLabel(status)),
                  trailing: ValueListenableBuilder<String>(
                    valueListenable: _filterNotifier,
                    builder: (context, currentFilter, _) {
                      return currentFilter == status
                          ? const Icon(Icons.check, color: Colors.deepPurple)
                          : const SizedBox.shrink();
                    },
                  ),
                  onTap: () {
                    _filterNotifier.value = status;
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

