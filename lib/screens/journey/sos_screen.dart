import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/journey_model.dart';
import '../../providers/home_provider.dart';
import '../../providers/auth_provider.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  int _countdown = 5;
  Timer? _timer;
  bool _isDispatched = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        _timer = null;
        _dispatchSOS();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _dispatchSOS() {
    setState(() {
      _isDispatched = true;
    });

    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.currentUser?.token ?? '';

    if (homeProvider.hasActiveJourney) {
      // Complete journey in SOS state
      homeProvider.endCurrentJourney(JourneyStatus.sosTriggered, token);
    }
  }

  void _cancelSOSWithPin() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
            SizedBox(width: 12),
            Text('Enter SOS PIN', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Input your safety PIN to deactivate this emergency alert.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'PIN (Default: 4321)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (pinController.text == '4321') {
                Navigator.pop(context); // close dialog
                _timer?.cancel();
                _timer = null;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SOS Alarm cancelled successfully.'),
                    backgroundColor: AppColors.safeGreen,
                  ),
                );
                // Return to home
                context.go('/home');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect PIN. SOS remains active!'),
                    backgroundColor: AppColors.sosRed,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150202), // Very dark red/black
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final colorVal = (_pulseController.value * 0.12) + 0.04;
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.red.withOpacity(colorVal),
                    Colors.transparent,
                  ],
                  radius: 1.2,
                ),
              ),
              child: child,
            );
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isDispatched ? _buildDispatchedState() : _buildCountdownState(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.sosRed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.sosRed.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.emergency_rounded, color: AppColors.sosRed, size: 18),
              SizedBox(width: 8),
              Text(
                'EMERGENCY MODE ACTIVATING',
                style: TextStyle(color: AppColors.sosRed, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 220,
              width: 220,
              child: CircularProgressIndicator(
                value: _countdown / 5.0,
                strokeWidth: 10,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sosRed),
                backgroundColor: Colors.white.withOpacity(0.08),
              ),
            ),
            Container(
              height: 180,
              width: 180,
              decoration: const BoxDecoration(
                color: AppColors.sosRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.sosRed, blurRadius: 28, spreadRadius: 4),
                ],
              ),
              child: Center(
                child: Text(
                  '$_countdown',
                  style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        const Text(
          'Sending Distress Signals',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Distress message will be sent automatically to your circle guardians in $_countdown seconds.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
        const SizedBox(height: 64),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.12),
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          onPressed: _cancelSOSWithPin,
          child: const Text('Cancel Alarm (Enter PIN)', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDispatchedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: const BoxDecoration(
            color: AppColors.sosRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.sosRed, blurRadius: 24, spreadRadius: 2),
            ],
          ),
          child: const Icon(Icons.emergency_share_rounded, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 36),
        const Text(
          'Distress Alerts Dispatched',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your Circle guardians (Mom, Dad, Friend) have been notified with your last known mock location (82% battery, CIT College).',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: const [
              Icon(Icons.spatial_audio_off_rounded, color: AppColors.safeGreen),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Auto audio-recorder is active. Ambient noise is being saved locally.',
                  style: TextStyle(color: AppColors.safeGreen, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 64),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.safeGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: _cancelSOSWithPin,
          child: const Text('Deactivate Distress Mode (PIN)', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
