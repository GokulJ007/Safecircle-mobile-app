import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/journey_model.dart';
import '../../providers/home_provider.dart';

class JourneyDetailsScreen extends StatelessWidget {
  final String journeyId;

  const JourneyDetailsScreen({
    super.key,
    required this.journeyId,
  });

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    
    // Find the journey matching the ID
    final journey = homeProvider.recentJourneys.firstWhere(
      (j) => j.id == journeyId,
      orElse: () => JourneyModel(
        id: 'mock',
        destination: 'Mock Destination',
        dateTime: DateTime.now(),
        duration: '15 min',
        distanceKm: 3.5,
        status: JourneyStatus.completed,
        eta: '6:00 PM',
        sharedContactIds: [],
        startBattery: 90,
        endBattery: 85,
      ),
    );

    final contacts = homeProvider.contacts;
    final sharedContacts = contacts.where((c) => journey.sharedContactIds.contains(c.id)).toList();

    final dateLabel = DateFormat('MMMM d, yyyy').format(journey.dateTime);
    final timeLabel = DateFormat('h:mm a').format(journey.dateTime);
    final statusColor = _statusColor(journey.status);
    final statusText = _statusText(journey.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Details', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFF4F8FE), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMockMapCard(journey.destination),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Colors.blueGrey.shade50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                journey.destination,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$dateLabel at $timeLabel',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        if (journey.notes != null && journey.notes!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.blueGrey.shade50),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.sticky_note_2_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    journey.notes!,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Duration', journey.duration, Icons.timer_outlined),
                            _buildStatItem('Distance', '${journey.distanceKm.toStringAsFixed(1)} km', Icons.straighten_rounded),
                            _buildStatItem('Battery Drop', '${journey.startBattery}% → ${journey.endBattery ?? journey.startBattery}%', Icons.battery_charging_full_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Colors.blueGrey.shade50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shared With Circle',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        sharedContacts.isEmpty
                            ? const Text('This journey was not shared with any trusted contacts.', style: TextStyle(color: AppColors.textSecondary))
                            : Column(
                                children: sharedContacts.map((contact) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: Text(
                                        contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(contact.relationship),
                                    trailing: Text(contact.phone, style: const TextStyle(color: AppColors.textSecondary)),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildMockMapCard(String destination) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MockDetailsMapPainter(),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.map_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Recorded Route Simulation',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.sosRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destination Arrived',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            destination,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  String _statusText(JourneyStatus status) {
    switch (status) {
      case JourneyStatus.completed:
        return 'Completed';
      case JourneyStatus.cancelled:
        return 'Cancelled';
      case JourneyStatus.sosTriggered:
        return 'SOS Triggered';
    }
  }
}

class _MockDetailsMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.secondary.withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDotted = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.65);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.25,
      size.width * 0.85,
      size.height * 0.4,
    );

    canvas.drawPath(path, paintLine);

    // Draw some mock background streets/grids
    for (int i = 1; i < 6; i++) {
      canvas.drawLine(
        Offset(0, size.height * 0.18 * i),
        Offset(size.width, size.height * 0.18 * i + 20),
        paintDotted,
      );
      canvas.drawLine(
        Offset(size.width * 0.2 * i, 0),
        Offset(size.width * 0.2 * i - 20, size.height),
        paintDotted,
      );
    }

    // Draw start node
    final paintNode = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.65), 10, paintNode);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.65), 5, Paint()..color = Colors.white);

    // Draw end node
    final paintDestNode = Paint()
      ..color = AppColors.sosRed
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.4), 10, paintDestNode);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.4), 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
