import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _locationTracking = true;

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
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
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.blueGrey.shade50),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                        title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Toggle night theme appearance'),
                        value: _darkMode,
                        onChanged: (val) {
                          setState(() => _darkMode = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Theme: ${val ? 'Dark' : 'Light'} (UI simulation)')),
                          );
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
                        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Trigger circle alerts and countdowns'),
                        value: _notifications,
                        onChanged: (val) {
                          setState(() => _notifications = val);
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                        title: const Text('Location Services', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Share mock coordinates during journeys'),
                        value: _locationTracking,
                        onChanged: (val) {
                          setState(() => _locationTracking = val);
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
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.blueGrey.shade50),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Legal & Safety Guidelines',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                        title: const Text('About SafeCircle', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showInfoDialog(
                          'About SafeCircle',
                          'SafeCircle is a premium Journey Safety & Emergency Assistance system.\n\nBuilt for hackathon demonstrations, the app allows users to configure a trusted circle, start simulated safety journeys, trigger mock fake phone calls, and dispatch immediate SOS notifications.\n\nAll services run on mock configurations without storing details in external databases.',
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary),
                        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showInfoDialog(
                          'Privacy Policy',
                          'Your location, contact list, and safety history are stored locally on your device via SharedPreferences. No backend processes are connected, ensuring absolute frontend-only privacy for this demo application.\n\nWhen real integrations are complete, your details will be encrypted end-to-end.',
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.gavel_outlined, color: AppColors.textSecondary),
                        title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showInfoDialog(
                          'Terms of Service',
                          'SafeCircle is provided "as is" for display and safety exercise purposes only.\n\nIn active emergency situations, always contact national emergency numbers (e.g. 911 or 112) directly. SafeCircle mock notifications do not contact real police departments or dispatch rescue services during this demo phase.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'SafeCircle Version 1.0.0 (Demo Build)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
