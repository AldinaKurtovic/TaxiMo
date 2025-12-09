import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/drivers_provider.dart';
import '../../models/driver_model.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriversProvider>(context, listen: false).loadDrivers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, DriverModel driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Are you sure you want to delete ${driver.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<DriversProvider>(context, listen: false)
                  .deleteDriver(driver.driverId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Drivers',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D3F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          // Header with add button and search
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Add Driver Button
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add Driver - Coming soon')),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'ADD DRIVERS',
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
              const SizedBox(width: 16),
              // Search Bar
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
                    Provider.of<DriversProvider>(context, listen: false)
                        .setSearchQuery(value.isEmpty ? null : value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Data Table
          Expanded(
            child: Consumer<DriversProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${provider.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadDrivers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.currentPageDrivers.isEmpty) {
                  return const Center(
                    child: Text('No drivers found'),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 56,
                        dataRowHeight: 64,
                        headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                        columnSpacing: 40,
                        horizontalMargin: 24,
                        columns: [
                        DataColumn(
                          label: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Driver ID',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Driver Name',
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
                                  provider.sort('name');
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
                            'License Number',
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
                                'E-Mail',
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
                                  provider.sort('email');
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
                            'Phone',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                        const DataColumn(
                          label: Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Text(''),
                          ),
                        ),
                      ],
                      rows: provider.currentPageDrivers.map((driver) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  driver.driverId.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                driver.fullName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                driver.licenseNumber,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                driver.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                driver.phone ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                ),
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Edit ${driver.fullName} - Coming soon'),
                                          ),
                                        );
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
                                        _showDeleteDialog(context, driver);
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
                ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Pagination
          Center(
            child: Consumer<DriversProvider>(
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

