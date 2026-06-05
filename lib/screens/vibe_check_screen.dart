import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../main.dart'; // For globals
import '../config/supabase_config.dart';
import '../models/local_places.dart';

import 'settings_bottom_sheet.dart';
import 'discovery_hub_screen.dart';
import 'saved_routes_screen.dart';
import 'swiper_screen.dart';

// -----------------------------------------------------------------------------
// MAIN CONTAINER SCREEN (WITH BOTTOM NAV BAR)
// -----------------------------------------------------------------------------
class VibeCheckScreen extends StatefulWidget {
  final bool isOffline;
  const VibeCheckScreen({super.key, required this.isOffline});

  @override
  State<VibeCheckScreen> createState() => _VibeCheckScreenState();
}

class _VibeCheckScreenState extends State<VibeCheckScreen> {
  final List<Map<String, dynamic>> categories = const [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.orangeAccent},
    {'name': 'Scenery', 'icon': Icons.landscape, 'color': Colors.greenAccent},
    {'name': 'Art', 'icon': Icons.palette, 'color': Colors.purpleAccent},
    {
      'name': 'History',
      'icon': Icons.account_balance,
      'color': Color(0xFFE57373),
    },
    {'name': 'Nightlife', 'icon': Icons.nightlife, 'color': Colors.pinkAccent},
    {'name': 'Adventure', 'icon': Icons.explore, 'color': Colors.redAccent},
  ];

  final Set<String> _selectedCategories = {};
  double _selectedDays = 3;
  String _selectedCity = 'IST';

  final List<Map<String, String>> _cities = const [
    {'code': 'IST', 'name': 'İstanbul'},
    {'code': 'PAR', 'name': 'Paris'},
    {'code': 'LON', 'name': 'Londra'},
    {'code': 'TYO', 'name': 'Tokyo'},
    {'code': 'NYC', 'name': 'New York'},
    {'code': 'ROM', 'name': 'Roma'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Light Theme
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rotanı Seç 🗺️',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hangi şehirde ne tür mekanlar arıyorsun?',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Şehir Seçin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _cities.map((city) {
                    final isSel = _selectedCity == city['code'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCity = city['code']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFFF5A5F)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              if (isSel)
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF5A5F,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              else
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                            border: Border.all(
                              color: isSel
                                  ? Colors.transparent
                                  : Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            city['name']!,
                            style: TextStyle(
                              color: isSel ? Colors.white : Colors.black87,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Kategoriler (Vibe)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 12.0,
                    children: categories.map((category) {
                      final isSelected = _selectedCategories.contains(
                        category['name'],
                      );
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCategories.remove(category['name']);
                            } else {
                              _selectedCategories.add(category['name']);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (category['color'] as Color).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? category['color']!
                                  : Colors.grey[200]!,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category['icon'],
                                size: 16,
                                color: isSelected
                                    ? category['color']
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category['name'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Kaç günlük bir seyahat? (${_selectedDays.toInt()} Gün)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFFF5A5F),
                    inactiveTrackColor: Colors.grey[200],
                    thumbColor: const Color(0xFFFF5A5F),
                    overlayColor: const Color(0xFFFF5A5F).withOpacity(0.1),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _selectedDays,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${_selectedDays.toInt()} Gün',
                    onChanged: (value) => setState(() => _selectedDays = value),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _selectedCategories.isEmpty
                      ? Colors.grey[300]
                      : const Color(0xFFFF5A5F),
                  boxShadow: _selectedCategories.isEmpty
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFFFF5A5F).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: ElevatedButton(
                  onPressed: _selectedCategories.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainScaffoldScreen(
                                selectedCategories: _selectedCategories
                                    .toList(),
                                tripDays: _selectedDays.toInt(),
                                cityCode: _selectedCity,
                                isOffline: widget.isOffline,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _selectedCategories.isEmpty
                        ? 'Lütfen Kategori Seçin'
                        : 'Mekanları Kaydırmaya Başla',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedCategories.isEmpty
                          ? Colors.black38
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SETTINGS BOTTOM SHEET
// -----------------------------------------------------------------------------
