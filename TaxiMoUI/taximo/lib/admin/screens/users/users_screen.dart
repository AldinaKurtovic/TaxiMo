import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/users_provider.dart';
import '../../models/user_model.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  bool? _statusFilter;

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
            onPressed: () {
              Provider.of<UsersProvider>(context, listen: false)
                  .deleteUser(user.userId);
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header with title and search
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Users',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      Provider.of<UsersProvider>(context, listen: false)
                          .setSearchQuery(value.isEmpty ? null : value);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _statusFilter = null);
                      Provider.of<UsersProvider>(context, listen: false)
                          .setStatusFilter(null);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Active'),
                  selected: _statusFilter == true,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _statusFilter = true);
                      Provider.of<UsersProvider>(context, listen: false)
                          .setStatusFilter(true);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Inactive'),
                  selected: _statusFilter == false,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _statusFilter = false);
                      Provider.of<UsersProvider>(context, listen: false)
                          .setStatusFilter(false);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                        Text(
                          'Error: ${provider.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadUsers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.currentPageUsers.isEmpty) {
                  return const Center(
                    child: Text('No users found'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                      columns: [
                        DataColumn(
                          label: const Text('User ID'),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('User Name'),
                              IconButton(
                                icon: const Icon(Icons.filter_list, size: 18),
                                onPressed: () {
                                  provider.sort('name');
                                },
                              ),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Status'),
                              IconButton(
                                icon: const Icon(Icons.filter_list, size: 18),
                                onPressed: () {
                                  provider.sort('status');
                                },
                              ),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('E-Mail'),
                              IconButton(
                                icon: const Icon(Icons.filter_list, size: 18),
                                onPressed: () {
                                  provider.sort('email');
                                },
                              ),
                            ],
                          ),
                        ),
                        const DataColumn(
                          label: Text('Date of Birth'),
                        ),
                        const DataColumn(
                          label: Text(''),
                        ),
                      ],
                      rows: provider.currentPageUsers.map((user) {
                        return DataRow(
                          cells: [
                            DataCell(Text(user.userId.toString())),
                            DataCell(Text(user.fullName)),
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
                                  Text(user.status),
                                ],
                              ),
                            ),
                            DataCell(Text(user.email)),
                            DataCell(Text(_formatDate(user.dateOfBirth))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: Colors.blue,
                                    onPressed: () {
                                      // TODO: Implement edit functionality
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Edit ${user.fullName} - Coming soon'),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    color: Colors.red,
                                    onPressed: () {
                                      _showDeleteDialog(context, user);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
          // Pagination
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Consumer<UsersProvider>(
              builder: (context, provider, _) {
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
                                  ? Colors.deepPurple
                                  : null,
                              foregroundColor: provider.currentPage == page
                                  ? Colors.white
                                  : Colors.black,
                              minimumSize: const Size(40, 40),
                            ),
                            child: Text(page.toString()),
                          ),
                        );
                      },
                    ),
                    if (provider.totalPages > 4 &&
                        provider.currentPage < provider.totalPages - 1)
                      const Text('...'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement add user functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add User - Coming soon')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('ADD USER'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}

