import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsis;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'config/supabase_config.dart';
import 'config/translations.dart';
import 'models/local_places.dart';

import 'screens/auth_screen.dart';
import 'screens/vibe_check_screen.dart';
import 'screens/settings_bottom_sheet.dart';
import 'screens/discovery_hub_screen.dart';
import 'screens/saved_routes_screen.dart';
import 'screens/swiper_screen.dart';
import 'screens/main_container_screen.dart';
// Global Supabase initialized state checker
bool isSupabaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase'i güvenli şekilde başlat
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    isSupabaseInitialized = true;
  } catch (e) {
    debugPrint('Supabase başlatılamadı: $e');
    isSupabaseInitialized = false;
  }

  // Load Language Preference
  final prefs = await SharedPreferences.getInstance();
  AppTranslations.isEnglish = prefs.getBool('is_english') ?? false;

  runApp(const SwipeRouteApp());
}

class SwipeRouteApp extends StatelessWidget {
  const SwipeRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwipeRoute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        primaryColor: const Color(0xFFFF5A5F),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF5A5F),
          secondary: Color(0xFF00A699),
          surface: Colors.white,
          error: Color(0xFFE1306C),
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Eğer Supabase başlatılamadıysa (örneğin internet yok veya URL geçersizse),
    // kullanıcıyı doğrudan Çevrimdışı/Yerel Modda ana ekrana yönlendir.
    if (!isSupabaseInitialized) {
      return const MainContainerScreen(isOfflineOnly: true);
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFE3C72)),
            ),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;
        if (session != null) {
          return const MainContainerScreen(isOfflineOnly: false);
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}

class MainScaffoldScreen extends StatefulWidget {
  final String cityCode;
  final List<String> selectedCategories;
  final bool isOffline;
  final int tripDays;

  const MainScaffoldScreen({
    super.key,
    required this.cityCode,
    required this.selectedCategories,
    required this.isOffline,
    required this.tripDays,
  });

  @override
  State<MainScaffoldScreen> createState() => _MainScaffoldScreenState();
}

class _MainScaffoldScreenState extends State<MainScaffoldScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      SwiperScreen(
        cityCode: widget.cityCode,
        selectedCategories: widget.selectedCategories,
        isOffline: widget.isOffline,
        tripDays: widget.tripDays,
      ),
      SavedRoutesScreen(isOffline: widget.isOffline),
      Container(
        color: const Color(0xFFF7F9FC),
        child: const Center(
          child: Text(
            'Profil Çok Yakında!',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      extendBody:
          true, // Allows body to extend behind the translucent bottom bar
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: const Color(0xFFFF5A5F).withOpacity(0.15),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(
                        color: Color(0xFFFF5A5F),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      );
                    }
                    return const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    );
                  }),
                ),
                child: NavigationBar(
                  height: 65,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentIndex = idx);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined, color: Colors.black54),
                      selectedIcon: Icon(
                        Icons.explore_rounded,
                        color: Color(0xFFFF5A5F),
                      ),
                      label: 'Keşfet',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined, color: Colors.black54),
                      selectedIcon: Icon(
                        Icons.map_rounded,
                        color: Color(0xFFFF5A5F),
                      ),
                      label: 'Rotam',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline, color: Colors.black54),
                      selectedIcon: Icon(
                        Icons.person_rounded,
                        color: Color(0xFFFF5A5F),
                      ),
                      label: 'Profil',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

