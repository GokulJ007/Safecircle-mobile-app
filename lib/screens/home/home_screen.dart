import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/journey_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/safety_status_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final homeProvider = context.watch<HomeProvider>();
    final user = authProvider.currentUser;
    final displayName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Alex Morgan';
    final avatarLabel = _initials(displayName);
    final formattedDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFF4F8FE), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final contentWidth = isWide ? 1200.0 : double.infinity;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GreetingBanner(
                          greeting: 'Good Morning',
                          name: displayName,
                          dateLabel: formattedDate,
                          avatarLabel: avatarLabel,
                          userImageUrl: user?.profileImageUrl,
                        ),
                        const SizedBox(height: 20),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: SafetyStatusCard(
                                  hasActiveJourney: homeProvider.hasActiveJourney,
                                  onPrimaryAction: () {
                                    if (homeProvider.hasActiveJourney) {
                                      context.push('/journey');
                                    } else {
                                      context.push('/start-journey');
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 5,
                                child: _SummaryCard(homeProvider: homeProvider),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              SafetyStatusCard(
                                hasActiveJourney: homeProvider.hasActiveJourney,
                                onPrimaryAction: () {
                                  if (homeProvider.hasActiveJourney) {
                                    context.push('/journey');
                                  } else {
                                    context.push('/start-journey');
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              _SummaryCard(homeProvider: homeProvider),
                            ],
                          ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Quick Actions',
                          subtitle: 'Emergency tools and trusted-contact shortcuts',
                        ),
                        const SizedBox(height: 12),
                        _QuickActionsGrid(
                          onSosTap: () => context.push('/sos'),
                          onFakeCallTap: () => context.push('/fake-call'),
                          onContactsTap: () => context.push('/contacts'),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Recent Activity',
                          subtitle: 'Mock previous journeys from your dashboard history',
                        ),
                        const SizedBox(height: 12),
                        _RecentActivityCard(journeys: homeProvider.recentJourneys),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Developer Options',
                          subtitle: 'Temporary integration and test tools',
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(color: Colors.blueGrey.shade50),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => context.push('/map'),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.map_rounded,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Test Google Map',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Open the Google Maps verification screen',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(indent: 20, endIndent: 20, height: 1),
                              InkWell(
                                onTap: () => context.push('/place-search'),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Test Place Search',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Open the Places API Autocomplete screen',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first.characters.first.toUpperCase() : 'S';
    }
    final first = parts.first.isNotEmpty ? parts.first.characters.first : 'S';
    final last = parts.last.isNotEmpty ? parts.last.characters.first : 'C';
    return '${first.toUpperCase()}${last.toUpperCase()}';
  }
}

class _GreetingBanner extends StatelessWidget {
  final String greeting;
  final String name;
  final String dateLabel;
  final String avatarLabel;
  final String? userImageUrl;

  const _GreetingBanner({
    required this.greeting,
    required this.name,
    required this.dateLabel,
    required this.avatarLabel,
    this.userImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.splashGradient,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _BannerChip(icon: Icons.shield_outlined, label: 'Safe mode ready'),
                    _BannerChip(icon: Icons.location_on_outlined, label: 'Mock location tracking'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.24), width: 1.5),
              ),
              child: ClipOval(
                child: userImageUrl != null && userImageUrl!.isNotEmpty
                    ? Image.network(
                        userImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _AvatarFallback(label: avatarLabel),
                      )
                    : _AvatarFallback(label: avatarLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String label;

  const _AvatarFallback({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.white.withOpacity(0.1),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BannerChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final HomeProvider homeProvider;

  const _SummaryCard({required this.homeProvider});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: Colors.blueGrey.shade50),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: "Today's Summary",
              subtitle: 'Quick snapshot of your mock dashboard data',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 340;

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StatCard(
                        icon: Icons.route_rounded,
                        value: '${homeProvider.journeysToday}',
                        label: 'Journeys Today',
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      StatCard(
                        icon: Icons.people_alt_rounded,
                        value: '${homeProvider.trustedContactsCount}',
                        label: 'Trusted Contacts',
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: 12),
                      StatCard(
                        icon: Icons.straighten_rounded,
                        value: '${homeProvider.totalDistanceKm.toStringAsFixed(1)} km',
                        label: 'Total Distance',
                        color: AppColors.warningOrange,
                      ),
                      const SizedBox(height: 12),
                      StatCard(
                        icon: Icons.shield_rounded,
                        value: homeProvider.hasActiveJourney ? 'Live' : 'Idle',
                        label: 'Journey Status',
                        color: homeProvider.hasActiveJourney ? AppColors.warningOrange : AppColors.safeGreen,
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.route_rounded,
                                value: '${homeProvider.journeysToday}',
                                label: 'Journeys Today',
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                icon: Icons.people_alt_rounded,
                                value: '${homeProvider.trustedContactsCount}',
                                label: 'Trusted Contacts',
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.straighten_rounded,
                                value: '${homeProvider.totalDistanceKm.toStringAsFixed(1)} km',
                                label: 'Total Distance',
                                color: AppColors.warningOrange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                icon: Icons.shield_rounded,
                                value: homeProvider.hasActiveJourney ? 'Live' : 'Idle',
                                label: 'Journey Status',
                                color: homeProvider.hasActiveJourney ? AppColors.warningOrange : AppColors.safeGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onSosTap;
  final VoidCallback onFakeCallTap;
  final VoidCallback onContactsTap;

  const _QuickActionsGrid({
    required this.onSosTap,
    required this.onFakeCallTap,
    required this.onContactsTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final itemWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: itemWidth,
              child: QuickActionButton(
                icon: Icons.emergency_rounded,
                label: 'SOS',
                description: 'Alert your circle immediately',
                color: AppColors.sosRed,
                onTap: onSosTap,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: QuickActionButton(
                icon: Icons.call_rounded,
                label: 'Fake Call',
                description: 'Simulate a safe interruption',
                color: AppColors.warningOrange,
                onTap: onFakeCallTap,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: QuickActionButton(
                icon: Icons.people_alt_rounded,
                label: 'Trusted Contacts',
                description: 'Open your emergency network',
                color: AppColors.primary,
                onTap: onContactsTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final List<JourneyModel> journeys;

  const _RecentActivityCard({required this.journeys});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: Colors.blueGrey.shade50),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (journeys.isEmpty)
              _EmptyState(context: context)
            else
              ...journeys.map((journey) {
                final isLast = journeys.last == journey;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: _JourneyTile(journey: journey),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final BuildContext context;

  const _EmptyState({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'No recent journeys yet.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _JourneyTile extends StatelessWidget {
  final JourneyModel journey;

  const _JourneyTile({required this.journey});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(journey.status);
    final statusLabel = _statusLabel(journey.status);
    final dateLabel = DateFormat('MMM d • h:mm a').format(journey.dateTime);

    return GestureDetector(
      onTap: () => context.push('/journey-details/${journey.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: LayoutBuilder(
          builder: (context, tileConstraints) {
            final isNarrow = tileConstraints.maxWidth < 240;

            if (isNarrow) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      journey.status == JourneyStatus.cancelled ? Icons.close_rounded : Icons.route_rounded,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey.destination,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Duration: ${journey.duration}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      journey.status == JourneyStatus.cancelled ? Icons.close_rounded : Icons.route_rounded,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey.destination,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Duration: ${journey.duration}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Color _statusColor(JourneyStatus status) {
    switch (status) {
      case JourneyStatus.completed:
        return AppColors.safeGreen;
      case JourneyStatus.cancelled:
        return AppColors.textSecondary;
      case JourneyStatus.sosTriggered:
        return AppColors.sosRed;
    }
  }

  String _statusLabel(JourneyStatus status) {
    switch (status) {
      case JourneyStatus.completed:
        return 'Completed';
      case JourneyStatus.cancelled:
        return 'Cancelled';
      case JourneyStatus.sosTriggered:
        return 'SOS';
    }
  }
}