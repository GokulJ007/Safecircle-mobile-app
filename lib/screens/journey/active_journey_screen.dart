import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/journey_model.dart';
import '../../providers/home_provider.dart';

class ActiveJourneyScreen extends StatefulWidget {
  const ActiveJourneyScreen({super.key});

  @override
  State<ActiveJourneyScreen> createState() => _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends State<ActiveJourneyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showSmartCheckInDialog(HomeProvider provider) {
    // We defer the dialog display using Future.microtask to avoid triggering
    // setState during build.
    Future.microtask(() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: AppColors.surface,
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.warningOrange, size: 28),
              SizedBox(width: 12),
              Text("You're running late.", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text("Everything okay? SafeCircle has detected your delay. Let your circle know you are safe or trigger emergency help."),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.sosRed),
                foregroundColor: AppColors.sosRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                provider.dismissSmartCheckIn();
                // Push immediately to SOS
                context.push('/sos');
              },
              child: const Text('Need Help'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safeGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                provider.dismissSmartCheckIn();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Marked safe. Your circle has been updated."),
                    backgroundColor: AppColors.safeGreen,
                  ),
                );
              },
              child: const Text("I'm Safe"),
            ),
          ],
        ),
      );
    });
  }

  void _showEndJourneyConfirmation(HomeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: AppColors.surface,
        title: const Text('Arrived Safely?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will complete the journey, stop live coordinate sharing, and log this trip in your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safeGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // close confirm dialog
              provider.endCurrentJourney(JourneyStatus.completed);
              _showSummaryDialog();
            },
            child: const Text('Yes, I am Safe'),
          ),
        ],
      ),
    );
  }

  void _showSummaryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: AppColors.surface,
        title: Column(
          children: const [
            Icon(Icons.verified_rounded, color: AppColors.safeGreen, size: 54),
            SizedBox(height: 12),
            Text('Journey Completed!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your trusted circle has been notified of your safe arrival. Safe tracking session has ended.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(context); // close summary dialog
                context.go('/home'); // return to home shell
              },
              child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    // If check-in is pending, show dialog
    if (homeProvider.showSmartCheckIn) {
      _showSmartCheckInDialog(homeProvider);
    }

    final durationText = homeProvider.formattedDuration;
    final destination = homeProvider.activeDestination.isNotEmpty
        ? homeProvider.activeDestination
        : 'CIT College';
    final eta = homeProvider.activeEta.isNotEmpty ? homeProvider.activeEta : '5:45 PM';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking Session', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // forces user to use action buttons
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFF4F8FF), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Stack(
                    children: [
                      // Styled Custom Map Placeholder
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withOpacity(0.24),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _LiveJourneyMapPainter(
                                  progressRatio: (homeProvider.journeySecondsElapsed % 120) / 120.0,
                                  pulseValue: _pulseController.value,
                                ),
                                child: Container(),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 8,
                                    width: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.safeGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Mock GPS Active',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.battery_std_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${homeProvider.activeBattery}%',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Stats Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Card(
                  elevation: 0,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: Colors.blueGrey.shade50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.navigation_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    destination,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Expected Arrival: $eta',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLiveStat('Elapsed', durationText, Icons.timer_outlined),
                            _buildLiveStat('Guardians', '${homeProvider.activeSharedContactIds.length}', Icons.shield_outlined),
                            _buildLiveStat('Dist. Left', '1.4 km', Icons.directions_walk_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Emergency Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.call_rounded),
                        label: const Text('Fake Call'),
                        onPressed: () => context.push('/fake-call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warningOrange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text("I'm Safe"),
                        onPressed: () => _showEndJourneyConfirmation(homeProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.safeGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.emergency_rounded),
                        label: const Text('SOS'),
                        onPressed: () => context.push('/sos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sosRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
  }

  Widget _buildLiveStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _LiveJourneyMapPainter extends CustomPainter {
  final double progressRatio; // 0.0 to 1.0
  final double pulseValue; // 0.0 to 1.0

  _LiveJourneyMapPainter({
    required this.progressRatio,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint grid background
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.5;

    for (int i = 1; i < 7; i++) {
      canvas.drawLine(
        Offset(0, size.height * 0.15 * i),
        Offset(size.width, size.height * 0.15 * i + 10),
        paintGrid,
      );
      canvas.drawLine(
        Offset(size.width * 0.16 * i, 0),
        Offset(size.width * 0.16 * i - 10, size.height),
        paintGrid,
      );
    }

    // Paint quadratic path for tracking
    final paintPath = Paint()
      ..color = AppColors.secondary.withOpacity(0.8)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startPoint = Offset(size.width * 0.2, size.height * 0.7);
    final controlPoint = Offset(size.width * 0.5, size.height * 0.2);
    final endPoint = Offset(size.width * 0.8, size.height * 0.45);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    canvas.drawPath(path, paintPath);

    // Calculate current coordinates of moving marker using Bézier calculation
    final t = progressRatio;
    final currentX = (1 - t) * (1 - t) * startPoint.dx + 2 * (1 - t) * t * controlPoint.dx + t * t * endPoint.dx;
    final currentY = (1 - t) * (1 - t) * startPoint.dy + 2 * (1 - t) * t * controlPoint.dy + t * t * endPoint.dy;
    final currentPos = Offset(currentX, currentY);

    // Draw Start Circle
    final paintStart = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPoint, 8, paintStart);
    canvas.drawCircle(startPoint, 4, Paint()..color = Colors.white);

    // Draw End Circle
    final paintEnd = Paint()
      ..color = AppColors.sosRed
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, 8, paintEnd);
    canvas.drawCircle(endPoint, 4, Paint()..color = Colors.white);

    // Draw Pulsing Circle around the Current Position marker
    final pulsePaint = Paint()
      ..color = AppColors.secondary.withOpacity(1.0 - pulseValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(currentPos, 14 + pulseValue * 16, pulsePaint);

    // Draw Marker Current Position
    final paintMarker = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(currentPos, 9, paintMarker);
    canvas.drawCircle(currentPos, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _LiveJourneyMapPainter oldDelegate) {
    return oldDelegate.progressRatio != progressRatio || oldDelegate.pulseValue != pulseValue;
  }
}
