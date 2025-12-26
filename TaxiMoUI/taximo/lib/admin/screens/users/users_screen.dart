import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/users_provider.dart';
import '../../models/user_model.dart';
import 'widgets/add_user_modal.dart';
import 'widgets/edit_user_modal.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatusFilter; // null = All, true = Active, false = Inactive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsersProvider>(context, listen: false).loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month/$day/$year';
  }

  void _showDeleteDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              print('Delete button clicked for user ID: ${user.userId}'); // Debug log
              try {
                if (user.userId <= 0) {
                  throw Exception('Invalid user ID: ${user.userId}');
                }
                
                await Provider.of<UsersProvider>(context, listen: false)
                    .deleteUser(user.userId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully')),
                  );
                }
              } catch (e) {
                print('Delete user error: $e'); // Debug log
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddUserModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddUserModal(),
    );
  }

  void _showEditUserModal(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => EditUserModal(user: user),
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
          // Title
          const Text(
            'Users',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D3F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          // Header with Add User button and Search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Add User Button
              ElevatedButton.icon(
                onPressed: () => _showAddUserModal(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'ADD USER',
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
                    Provider.of<UsersProvider>(context, listen: false)
                        .setSearchQuery(value.isEmpty ? null : value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Data Table
          Expanded(
            child: Consumer<UsersProvider>(
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
                        const Text(
                          'Error loading users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
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
                          onPressed: () => provider.loadUsers(),
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
                          label: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              'User ID',
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
                                'User Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(Icons.sort, size: 16, color: Colors.grey[600]),
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
                        DataColumn(
                          label: Consumer<UsersProvider>(
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
                                icon: Icon(Icons.sort, size: 16, color: Colors.grey[600]),
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
                            'Date of Birth',
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
                            child: Text(
                              'Actions',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ),
                        ),
                      ],
                      rows: provider.currentPageUsers.isEmpty
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
                                              Icons.people_outline,
                                              size: 32,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'No users found',
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
                                ],
                              ),
                            ]
                          : provider.currentPageUsers.map((user) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  user.userId.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                user.fullName,
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
                                      color: user.isActive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    user.status,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatDate(user.dateOfBirth),
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
                                        _showEditUserModal(context, user);
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
                                        _showDeleteDialog(context, user);
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
            child: Consumer<UsersProvider>(
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

