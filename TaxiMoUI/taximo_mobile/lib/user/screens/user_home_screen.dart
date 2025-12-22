import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/mobile_auth_provider.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaxiMo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              final provider = Provider.of<MobileAuthProvider>(context, listen: false);
              provider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Consumer<MobileAuthProvider>(
        builder: (context, provider, child) {
          final user = provider.currentUser;
          
          if (user == null) {
            return const Center(child: Text('No user data available'));
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        child: const Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${user.firstName} 👋',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ready for your next ride?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Primary action
                  _PrimaryActionCard(
                    title: 'Book a Ride',
                    subtitle: 'Choose pickup & destination in seconds',
                    icon: Icons.local_taxi,
                    onTap: () => Navigator.pushNamed(context, '/ride-reservation'),
                  ),

                  const SizedBox(height: 18),

                  // Secondary actions
                  Text(
                    'Quick actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // First row: Trip History and Promo Codes
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Trip History',
                          icon: Icons.history,
                          onTap: () => Navigator.pushNamed(context, '/trip-history'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Promo Codes',
                          icon: Icons.local_offer_outlined,
                          onTap: () => Navigator.pushNamed(context, '/promo-codes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Second row: Reviews and Payment
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Reviews',
                          icon: Icons.star,
                          onTap: () => Navigator.pushNamed(context, '/reviews'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Payment',
                          icon: Icons.credit_card,
                          onTap: () => Navigator.pushNamed(context, '/payment-history'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Optional: light profile summary (downplayed)
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_user_outlined, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text(
                                'Account',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user.email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (user.phone != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.phone!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _PrimaryActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: colorScheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

