import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payments_provider.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentsProvider>(context, listen: false).fetchAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'completed') {
      return Colors.green;
    } else if (statusLower == 'pending') {
      return Colors.orange;
    } else if (statusLower == 'failed' || statusLower == 'cancelled' || statusLower == 'refunded') {
      return Colors.red;
    }
    return Colors.grey;
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final statusDisplay = status.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusDisplay,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Back Button (only if navigated from home page via quick access)
          Builder(
            builder: (context) {
              final canPop = Navigator.canPop(context);
              if (canPop) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 24),
                      color: const Color(0xFF2D2D3F),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back to Home',
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Payments',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D3F),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                );
              }
              return const Text(
                'Payments',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D3F),
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Search Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.purple.shade300!, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    Provider.of<PaymentsProvider>(context, listen: false).search(value.isEmpty ? null : value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Data Table
          Expanded(
            child: Consumer<PaymentsProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading payments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48.0),
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(color: Colors.red[700], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => provider.fetchAll(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowHeight: 56,
                          dataRowHeight: 64,
                          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                          columnSpacing: 32,
                          horizontalMargin: 24,
                          columns: [
                            DataColumn(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Payment ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                                    onPressed: () {
                                      provider.sort('paymentId');
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataColumn(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ride ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                                    onPressed: () {
                                      provider.sort('rideId');
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataColumn(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'User ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                                    onPressed: () {
                                      provider.sort('userId');
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataColumn(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                                    onPressed: () {
                                      provider.sort('amount');
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Currency',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Method',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                          ],
                          rows: provider.currentPagePayments.isEmpty
                              ? [
                                  DataRow(
                                    cells: [
                                      DataCell(Container()),
                                      DataCell(
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.payment_outlined,
                                                  size: 32,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'No payments found',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Container()),
                                      DataCell(Container()),
                                      DataCell(Container()),
                                      DataCell(Container()),
                                      DataCell(Container()),
                                    ],
                                  ),
                                ]
                              : provider.currentPagePayments.map((payment) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          payment.paymentId.toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          payment.rideId.toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          payment.userId.toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF424242),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          payment.currency,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          payment.method,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        _buildStatusBadge(payment.status),
                                      ),
                                    ],
                                  );
                                }).toList(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Pagination
          Center(
            child: Consumer<PaymentsProvider>(
              builder: (context, provider, _) {
                if (provider.totalPages <= 1) {
                  return const SizedBox.shrink();
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: provider.currentPage > 1
                          ? () => provider.previousPage()
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Page ${provider.currentPage} of ${provider.totalPages}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                    ...List.generate(
                      provider.totalPages > 4 ? 4 : provider.totalPages,
                      (index) {
                        int page;
                        if (provider.totalPages <= 4) {
                          page = index + 1;
                        } else {
                          if (provider.currentPage <= 2) {
                            page = index + 1;
                          } else if (provider.currentPage >=
                              provider.totalPages - 1) {
                            page = provider.totalPages - 3 + index;
                          } else {
                            page = provider.currentPage - 1 + index;
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: TextButton(
                            onPressed: () => provider.goToPage(page),
                            style: TextButton.styleFrom(
                              backgroundColor: provider.currentPage == page
                                  ? Colors.blue
                                  : null,
                              foregroundColor: provider.currentPage == page
                                  ? Colors.white
                                  : Colors.black,
                              minimumSize: const Size(40, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text(page.toString()),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: provider.currentPage < provider.totalPages
                          ? () => provider.nextPage()
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

