import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/promo_provider.dart';
import '../../models/promo_model.dart';
import 'widgets/add_promo_modal.dart';
import 'widgets/edit_promo_modal.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatusFilter; // null = All, true = Active, false = Inactive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PromoProvider>(context, listen: false).fetchAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, PromoModel promo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 48,
        ),
        title: const Text(
          'Warning',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D3F),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is irreversible!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete promo code "${promo.code}"?',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<PromoProvider>(context, listen: false)
                    .delete(promo.promoId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Promo code successfully deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting promo code: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, PromoModel promo) {
    showDialog(
      context: context,
      builder: (context) => EditPromoModal(promo: promo),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddPromoModal(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
                      'Promo Codes',
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
                'Promo Codes',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D3F),
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Header with Add Promo Code button and Search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Add Promo Code Button
              ElevatedButton.icon(
                onPressed: () {
                  _showAddDialog(context);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'ADD PROMO CODE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[50],
                  foregroundColor: Colors.purple[700],
                  side: BorderSide(color: Colors.purple.shade300!, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
              // Search Bar (right side)
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
                    Provider.of<PromoProvider>(context, listen: false)
                        .search(value.isEmpty ? null : value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Data Table
          Expanded(
            child: Consumer<PromoProvider>(
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
                          'Error loading promo codes',
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
                                  'Code',
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
                                    Provider.of<PromoProvider>(context, listen: false).sort('code');
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
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Discount',
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
                                    Provider.of<PromoProvider>(context, listen: false).sort('discount');
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
                              'Valid Period',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Consumer<PromoProvider>(
                              builder: (context, provider, _) {
                                final currentFilter = _selectedStatusFilter ?? 'All';
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      icon: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Icon(Icons.filter_alt, size: 16, color: currentFilter != 'All' ? Colors.blue : Colors.grey[600]),
                                          if (currentFilter != 'All')
                                            Positioned(
                                              right: -4,
                                              top: -4,
                                              child: Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 24,
                                        minHeight: 24,
                                      ),
                                      onSelected: (value) {
                                        bool? isActive;
                                        if (value == 'All') {
                                          setState(() {
                                            _selectedStatusFilter = null;
                                          });
                                          isActive = null;
                                        } else if (value == 'Active') {
                                          setState(() {
                                            _selectedStatusFilter = 'Active';
                                          });
                                          isActive = true;
                                        } else {
                                          setState(() {
                                            _selectedStatusFilter = 'Inactive';
                                          });
                                          isActive = false;
                                        }
                                        provider.setStatusFilter(isActive);
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'All',
                                          child: Text('All'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'Active',
                                          child: Text('Active'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'Inactive',
                                          child: Text('Inactive'),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const DataColumn(
                            label: Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Text(''),
                            ),
                          ),
                        ],
                        rows: provider.currentPagePromoCodes.isEmpty
                            ? [
                                DataRow(
                                  cells: [
                                    const DataCell(SizedBox.shrink()),
                                    DataCell(
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.local_offer_outlined,
                                                size: 32,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'No promo codes found',
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
                                    const DataCell(SizedBox.shrink()),
                                    const DataCell(SizedBox.shrink()),
                                    const DataCell(SizedBox.shrink()),
                                    const DataCell(SizedBox.shrink()),
                                  ],
                                ),
                              ]
                          : provider.currentPagePromoCodes.map((promo) {
                        return DataRow(
                          cells: [
                              DataCell(
                                Text(
                                  promo.code,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF424242),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  promo.description ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  promo.discountDisplay,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  promo.periodDisplay,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getStatusColor(promo.status),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      promo.status,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF424242),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        color: Colors.blue[700],
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                        onPressed: () {
                                          _showEditDialog(context, promo);
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20),
                                        color: Colors.red[700],
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                        onPressed: () {
                                          _showDeleteDialog(context, promo);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
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
            child: Consumer<PromoProvider>(
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

