import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

enum CallState { setup, countdown, ringing, active }

class _FakeCallScreenState extends State<FakeCallScreen> with SingleTickerProviderStateMixin {
  CallState _callState = CallState.setup;
  String _selectedCaller = 'Mom';
  int _selectedDelaySeconds = 5;

  int _timerRemaining = 0;
  Timer? _delayTimer;

  int _callSeconds = 0;
  Timer? _activeCallTimer;

  late final AnimationController _ringController;

  final List<String> _callers = ['Mom', 'Dad', 'Friend (Gokul)', 'Boss'];
  final List<int> _delays = [5, 10, 30];

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _activeCallTimer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _callState = CallState.countdown;
      _timerRemaining = _selectedDelaySeconds;
    });

    _delayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerRemaining > 1) {
        setState(() {
          _timerRemaining--;
        });
      } else {
        _delayTimer?.cancel();
        _delayTimer = null;
        _startRinging();
      }
    });
  }

  void _startRinging() {
    setState(() {
      _callState = CallState.ringing;
    });
    _ringController.repeat(reverse: true);
  }

  void _acceptCall() {
    _ringController.stop();
    setState(() {
      _callState = CallState.active;
      _callSeconds = 0;
    });

    _activeCallTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callSeconds++;
      });
    });
  }

  void _declineOrEndCall() {
    _delayTimer?.cancel();
    _activeCallTimer?.cancel();
    _ringController.stop();
    
    // Go back
    context.pop();
  }

  String _formatActiveTime() {
    final minutes = _callSeconds ~/ 60;
    final seconds = _callSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    switch (_callState) {
      case CallState.setup:
        return _buildSetupUI();
      case CallState.countdown:
        return _buildCountdownUI();
      case CallState.ringing:
        return _buildRingingUI();
      case CallState.active:
        return _buildActiveCallUI();
    }
  }

  Widget _buildSetupUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Fake Call', style: TextStyle(fontWeight: FontWeight.bold)),
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
            colors: [Color(0xFFF9FBFF), Color(0xFFF4F8FF), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: Colors.blueGrey.shade50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose Caller Identity',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCaller,
                          decoration: InputDecoration(
                            labelText: 'Simulated Caller',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          items: _callers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCaller = val);
                            }
                          },
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
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: Colors.blueGrey.shade50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trigger Delay Duration',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: _delays.map((delay) {
                            final isSelected = _selectedDelaySeconds == delay;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  selected: isSelected,
                                  label: Text('$delay Sec'),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedDelaySeconds = delay);
                                    }
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: AppColors.primary.withOpacity(0.12),
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Activate Fake Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _startCountdown,
                ),
                const SizedBox(height: 12),
                const Text(
                  'SafeCircle will trigger a realistic full-screen dialer UI after the countdown to help you deflect unsafe interactions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownUI() {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.ring_volume_rounded, size: 64, color: Colors.white70),
              const SizedBox(height: 24),
              const Text(
                'Fake Call Scheduled',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ringing from $_selectedCaller in',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              Text(
                '$_timerRemaining',
                style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 48),
              OutlinedButton(
                onPressed: _declineOrEndCall,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Cancel Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRingingUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), // Phone App Dark Style
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),
            Text(
              _selectedCaller,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.3 + (_ringController.value * 0.7),
                  child: const Text(
                    'SafeCircle incoming check-in...',
                    style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 0.5),
                  ),
                );
              },
            ),
            const Spacer(),
            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 48.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Container(
                        height: 74,
                        width: 74,
                        decoration: const BoxDecoration(
                          color: AppColors.sosRed,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                          onPressed: _declineOrEndCall,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Decline', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        height: 74,
                        width: 74,
                        decoration: const BoxDecoration(
                          color: AppColors.safeGreen,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.call_rounded, color: Colors.white, size: 32),
                          onPressed: _acceptCall,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Accept', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCallUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),
            Text(
              _selectedCaller,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              _formatActiveTime(),
              style: const TextStyle(color: Colors.white70, fontSize: 18, fontFamily: 'monospace'),
            ),
            const Spacer(),
            // Mock Voice Wave Widget
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(10, (index) {
                  final listHeight = [24.0, 48.0, 72.0, 36.0, 60.0, 80.0, 42.0, 64.0, 30.0, 52.0];
                  return Container(
                    width: 6,
                    height: listHeight[(_callSeconds + index) % 10],
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
            const Spacer(),
            // Grid of buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 1.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCallOptionButton(Icons.mic_off_rounded, 'mute'),
                  _buildCallOptionButton(Icons.dialpad_rounded, 'keypad'),
                  _buildCallOptionButton(Icons.volume_up_rounded, 'speaker'),
                  _buildCallOptionButton(Icons.add_rounded, 'add call'),
                  _buildCallOptionButton(Icons.video_call_rounded, 'video'),
                  _buildCallOptionButton(Icons.person_search_rounded, 'contacts'),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Decline Button
            Container(
              height: 74,
              width: 74,
              decoration: const BoxDecoration(
                color: AppColors.sosRed,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                onPressed: _declineOrEndCall,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCallOptionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
