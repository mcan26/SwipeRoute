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
import '../widgets/route_map_widget.dart';
import '../widgets/budget_chart_widget.dart';

import 'vibe_check_screen.dart';
import 'settings_bottom_sheet.dart';
import 'discovery_hub_screen.dart';
import 'swiper_screen.dart';

// -----------------------------------------------------------------------------
// PERSISTENT MY SAVED ROUTES SCREEN
// -----------------------------------------------------------------------------
class SavedRoutesScreen extends StatefulWidget {
  final bool isOffline;
  const SavedRoutesScreen({super.key, required this.isOffline});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);

    if (widget.isOffline || !isSupabaseInitialized) {
      // SharedPreferences'tan oku
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('offline_routes') ?? '[]';
      List parsed;
      try {
        parsed = json.decode(savedStr) as List;
      } catch (_) {
        parsed = [];
      }
      setState(() {
        _routes = List<Map<String, dynamic>>.from(parsed).reversed.toList();
        _isLoading = false;
      });
    } else {
      // Supabase'den oku
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          final prefs = await SharedPreferences.getInstance();
          final savedStr = prefs.getString('offline_routes') ?? '[]';
          List parsed;
          try {
            parsed = json.decode(savedStr) as List;
          } catch (_) {
            parsed = [];
          }
          setState(() {
            _routes = List<Map<String, dynamic>>.from(parsed).reversed.toList();
            _isLoading = false;
          });
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        final savedStr = prefs.getString('offline_routes') ?? '[]';
        List parsedOffline;
        try {
          parsedOffline = json.decode(savedStr) as List;
        } catch (_) {
          parsedOffline = [];
        }

        final response = await Supabase.instance.client
            .from('saved_routes')
            .select('*')
            .eq('user_id', user.id);

        setState(() {
          final merged = [
            ...List<Map<String, dynamic>>.from(parsedOffline),
            ...List<Map<String, dynamic>>.from(response)
          ];
          _routes = merged.reversed.toList();
          _isLoading = false;
        });
      } catch (e) {
        // Hata durumunda sharedPreferences'a fallback et
        final prefs = await SharedPreferences.getInstance();
        final savedStr = prefs.getString('offline_routes') ?? '[]';
        List parsed;
        try {
          parsed = json.decode(savedStr) as List;
        } catch (_) {
          parsed = [];
        }
        setState(() {
          _routes = List<Map<String, dynamic>>.from(parsed).reversed.toList();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRoute(int index, String? dbId) async {
    if (widget.isOffline || !isSupabaseInitialized || dbId == null) {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('offline_routes') ?? '[]';
      List parsed;
      try {
        parsed = json.decode(savedStr) as List;
      } catch (_) {
        parsed = [];
      }
      if (index >= 0 && index < parsed.length) {
        parsed.removeAt(parsed.length - 1 - index); // Ters sıralı okumuştuk
      }
      await prefs.setString('offline_routes', json.encode(parsed));
      _loadRoutes();
    } else {
      try {
        await Supabase.instance.client
            .from('saved_routes')
            .delete()
            .eq('id', dbId);
        _loadRoutes();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silme işlemi bulutta yapılamadı.')),
        );
      }
    }
  }

  void _openRouteInGoogleMaps(dynamic placesData) async {
    try {
      final List<dynamic> places = placesData is String
          ? json.decode(placesData)
          : placesData as List<dynamic>;
      if (places.isEmpty) return;

      if (places.length == 1) {
        final p = places.first;
        final url = Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=${p['lat']},${p['lng']}",
        );
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }

      final first = places.first;
      final last = places.last;
      final waypointsList = places.sublist(1, places.length - 1);
      final waypointsStr = waypointsList
          .map((p) => "${p['lat']},${p['lng']}")
          .join('|');

      String urlStr =
          "https://www.google.com/maps/dir/?api=1&origin=${first['lat']},${first['lng']}&destination=${last['lat']},${last['lng']}&travelmode=driving";
      if (waypointsStr.isNotEmpty) {
        urlStr += "&waypoints=$waypointsStr";
      }

      final url = Uri.parse(urlStr);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Harita açılamadı: $e');
      }
    } catch (e) {
      debugPrint('Error opening maps: $e');
    }
  }

  void _viewRouteDetails(Map<String, dynamic> route) {
    final String rawNotes = route['route_details'] ?? route['route_notes'] ?? '';
    String displayNotes = rawNotes;
    Map<String, double> budgetData = {};

    final budgetMatch = RegExp(r'<BUDGET_JSON>(.*?)</BUDGET_JSON>', dotAll: true).firstMatch(rawNotes);
    if (budgetMatch != null) {
      try {
        final decoded = json.decode(budgetMatch.group(1)!);
        if (decoded is Map<String, dynamic>) {
          budgetData = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
        }
        displayNotes = displayNotes.replaceAll(budgetMatch.group(0)!, '').trim();
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF16161C),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      route['title'] ?? 'Seyahat Rotası',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFE3C72).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${route['trip_days'] ?? 3} GÜN',
                      style: const TextStyle(
                        color: Color(0xFFFE3C72),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (route['city_id'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Şehir: ${route['city_id']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayNotes,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.white70,
                        ),
                      ),
                      if (budgetData.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        BudgetChartWidget(budgetData: budgetData),
                      ],
                      if (route['places'] != null) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Rota Haritası',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 250,
                            width: double.infinity,
                            child: RouteMapWidget(
                              places: route['places'] is String
                                  ? json.decode(route['places'])
                                  : (route['places'] as List<dynamic>),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _openRouteInGoogleMaps(route['places']),
                            icon: const Icon(Icons.navigation, color: Colors.white),
                            label: const Text(
                              'Haritalar ile Navigasyonu Başlat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F13), Color(0xFF0D0D11)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kayıtlı Rotalarım 🗺️',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _loadRoutes,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Yapay zeka asistanı tarafından hazırlanan seyahat rotalarınız.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFE3C72)),
                  )
                : _routes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 54, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text(
                          'Henüz kaydedilmiş seyahat rotanız yok.',
                          style: TextStyle(color: Colors.white30, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _routes.length,
                    itemBuilder: (context, index) {
                      final route = _routes[index];
                      final dbId = route['id']?.toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C24),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFE3C72).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFFE3C72),
                            ),
                          ),
                          title: Text(
                            route['title'] ?? 'Seyahat Rotası',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${route['trip_days'] ?? 3} Günlük Seyahat Planı',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white38,
                                  size: 16,
                                ),
                                onPressed: () => _viewRouteDetails(route),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => _deleteRoute(index, dbId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TINDER CARD SWIPER SCREEN
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// MAIN SCAFFOLD WITH BOTTOM NAVIGATION BAR
// -----------------------------------------------------------------------------
