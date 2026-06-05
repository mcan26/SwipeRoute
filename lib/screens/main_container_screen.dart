import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // for screens
import 'auth_screen.dart';
import 'vibe_check_screen.dart';
import 'discovery_hub_screen.dart';
import 'saved_routes_screen.dart';
import 'settings_bottom_sheet.dart';
import 'profile_screen.dart';
import '../config/translations.dart';

class MainContainerScreen extends StatefulWidget {
  final bool isOfflineOnly;
  const MainContainerScreen({super.key, this.isOfflineOnly = false});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _isOffline = widget.isOfflineOnly;
    _screens = [
      VibeCheckScreen(isOffline: _isOffline),
      DiscoveryHubScreen(isOffline: _isOffline),
      SavedRoutesScreen(isOffline: _isOffline),
      ProfileScreen(isOffline: _isOffline),
    ];
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsBottomSheet(
        isOffline: _isOffline,
        onOfflineToggled: (val) {
          setState(() {
            _isOffline = val;
            _screens = [
              VibeCheckScreen(isOffline: _isOffline),
              DiscoveryHubScreen(isOffline: _isOffline),
              SavedRoutesScreen(isOffline: _isOffline),
              ProfileScreen(isOffline: _isOffline),
            ];
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.explore, color: Color(0xFFFE3C72)),
            const SizedBox(width: 8),
            const Text(
              'SwipeRoute',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isOffline
                    ? Colors.orangeAccent.withOpacity(0.15)
                    : Colors.greenAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOffline ? Colors.orangeAccent : Colors.greenAccent,
                  width: 1,
                ),
              ),
              child: Text(
                _isOffline ? 'YEREL' : 'BULUT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _isOffline ? Colors.orangeAccent : Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: _openSettings,
          ),
          if (!_isOffline && isSupabaseInitialized)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white54),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                }
              },
            ),
          if (_isOffline && isSupabaseInitialized)
            IconButton(
              icon: const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _isOffline = false;
                  _screens = [
                    VibeCheckScreen(isOffline: _isOffline),
                    DiscoveryHubScreen(isOffline: _isOffline),
                    SavedRoutesScreen(isOffline: _isOffline),
                    ProfileScreen(isOffline: _isOffline),
                  ];
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bulut moduna geçildi! ☁️')),
                );
              },
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121218),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF121218),
          selectedItemColor: const Color(0xFFFE3C72),
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.swipe_outlined),
              activeIcon: const Icon(Icons.style),
              label: AppTranslations.t('tab_vibe'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_location_alt_outlined),
              activeIcon: const Icon(Icons.add_location_alt),
              label: AppTranslations.t('tab_discovery'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              activeIcon: const Icon(Icons.map),
              label: AppTranslations.t('tab_routes'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: AppTranslations.t('tab_profile'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// VIBE CHECK / SWIPE SCREEN (MAIN APPLICATION FLOW)
// -----------------------------------------------------------------------------
