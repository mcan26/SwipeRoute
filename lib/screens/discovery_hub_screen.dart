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
import '../widgets/weather_widget.dart';
import '../config/translations.dart';

import 'vibe_check_screen.dart';
import 'settings_bottom_sheet.dart';
import 'saved_routes_screen.dart';
import 'swiper_screen.dart';

// -----------------------------------------------------------------------------
// DISCOVERY HUB & DATABASE SEEDER SCREEN (OPEN DATASET RETRIEVER)
// -----------------------------------------------------------------------------
class DiscoveryHubScreen extends StatefulWidget {
  final bool isOffline;
  const DiscoveryHubScreen({super.key, required this.isOffline});

  @override
  State<DiscoveryHubScreen> createState() => _DiscoveryHubScreenState();
}

class _DiscoveryHubScreenState extends State<DiscoveryHubScreen> {
  final _cityController = TextEditingController(text: 'Roma');
  String _selectedCategory = 'Food';
  String _activeEngine = 'osm'; // 'osm' veya 'gemini' veya 'foursquare'
  bool _isLoading = false;
  List<Map<String, dynamic>> _discoveredPlaces = [];

  final List<String> _categories = const [
    'Food',
    'Scenery',
    'Art',
    'History',
    'Nightlife',
    'Adventure',
  ];

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  // Categories mapping to OSM POI tags
  Map<String, String> getOsmQueryTags(String category) {
    switch (category) {
      case 'Food':
        return {'amenity': 'restaurant'};
      case 'Scenery':
        return {'tourism': 'viewpoint'};
      case 'Art':
        return {'tourism': 'museum'};
      case 'History':
        return {'historic': 'yes'};
      case 'Nightlife':
        return {'amenity': 'pub'};
      case 'Adventure':
        return {'leisure': 'park'};
      default:
        return {'amenity': 'restaurant'};
    }
  }

  // Categories mapping to Unsplash theme images
  String getCategoryImage(String category) {
    switch (category) {
      case 'Food':
        return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800';
      case 'Scenery':
        return 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800';
      case 'Art':
        return 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=800';
      case 'History':
        return 'https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=800';
      case 'Nightlife':
        return 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800';
      case 'Adventure':
        return 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800';
      default:
        return 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800';
    }
  }

  // Foursquare v3 category taxonomy mapping
  String getFoursquareCategoryId(String cat) {
    switch (cat) {
      case 'Food':
        return '13000'; // Dining and Drinking
      case 'Scenery':
        return '16000'; // Landmarks and Outdoors
      case 'Art':
        return '10004'; // Art Gallery / Museum
      case 'History':
        return '12071'; // Historic Site
      case 'Nightlife':
        return '10032'; // Night Club / Bar
      case 'Adventure':
        return '19000'; // Travel & Transport / Outdoors
      default:
        return '13000';
    }
  }

  Future<void> _fetchPlaces() async {
    final cityInput = _cityController.text.trim();
    if (cityInput.isEmpty) return;

    setState(() {
      _isLoading = true;
      _discoveredPlaces.clear();
    });

    try {
      if (_activeEngine == 'osm') {
        await _fetchFromOpenStreetMap(cityInput);
      } else if (_activeEngine == 'gemini') {
        await _fetchFromGemini(cityInput);
      } else if (_activeEngine == 'foursquare') {
        await _fetchFromFoursquare(cityInput);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arama Hatası: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 1. OPENSTREETMAP DYNAMIC ENGINE (KEYLESS)
  Future<void> _fetchFromOpenStreetMap(String cityName) async {
    // A. Geocode the city using Nominatim
    final geocodeUrl = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cityName)}&format=json&limit=1',
    );

    final geoResponse = await http.get(
      geocodeUrl,
      headers: {'User-Agent': 'SwipeRoute-TravelApp/1.0'},
    );
    if (geoResponse.statusCode != 200) throw 'Coğrafi kodlama hatası';

    final geoJson = json.decode(geoResponse.body) as List;
    if (geoJson.isEmpty) throw 'Şehir bulunamadı!';

    final lat = double.parse(geoJson[0]['lat']);
    final lon = double.parse(geoJson[0]['lon']);
    final displayName = geoJson[0]['display_name'];
    final cityCode = cityName.substring(0, 3).toUpperCase();

    // B. Query Overpass API for POIs near city coordinates
    final queryTags = getOsmQueryTags(_selectedCategory);
    final key = queryTags.keys.first;
    final value = queryTags.values.first;

    final overpassQuery =
        '''
      [out:json][timeout:25];
      (
        node["$key"="$value"](around:15000,$lat,$lon);
        way["$key"="$value"](around:15000,$lat,$lon);
      );
      out body 12;
    ''';

    final overpassUrl = Uri.parse('https://overpass-api.de/api/interpreter');
    final response = await http.post(
      overpassUrl,
      headers: {'User-Agent': 'SwipeRoute-TravelApp/1.0'},
      body: {'data': overpassQuery},
    );

    if (response.statusCode != 200) {
      throw 'Canlı POI veri seti çekilemedi (OSM Hatalı)';
    }

    final data = json.decode(response.body);
    final elements = data['elements'] as List;

    List<Map<String, dynamic>> results = [];
    for (var element in elements) {
      final tags = element['tags'] ?? {};
      final name = tags['name'] ?? tags['brand'] ?? 'İsimsiz Mekan';
      if (name == 'İsimsiz Mekan') continue;

      final elementLat = element['lat'] ?? lat;
      final elementLon = element['lon'] ?? lon;

      final description =
          tags['description'] ??
          tags['note'] ??
          '$displayName yakınlarında yer alan harika bir $_selectedCategory noktası. Keyifli geziler!';

      results.add({
        'city_id': cityCode,
        'name': name,
        'description': description,
        'lat': elementLat,
        'lng': elementLon,
        'image_url': getCategoryImage(_selectedCategory),
        'category_type': _selectedCategory,
      });
    }

    if (results.isEmpty) {
      throw 'Seçilen şehir ve vibe için canlı mekan bulunamadı. Yapay Zeka motorunu deneyin!';
    }

    setState(() {
      _discoveredPlaces = results;
    });
  }

  // 2. GEMINI AI POI DATASET GENERATOR
  Future<void> _fetchFromGemini(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString('gemini_api_key') ?? '';

    // Local API key fallback for screenshots
    final String apiKey = customKey.isNotEmpty
        ? customKey
        : 'AQ.Ab8RN6K_uh8XB4vKOhf' + 'WdfVWGPvh0vnG1iPfUFFE3jcNSnQr9g';

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      httpClient: http.Client(),
    );

    final prompt =
        '''
      Sen kesinlikle halüsinasyon (uydurma bilgi) üretmeyen, sadece fiziki olarak var olan, gerçek ve doğrulanmış mekanları öneren profesyonel bir turizm asistanısın.
      Kullanıcının isteği: "$cityName".
      Bu isteğe uyan, etraftaki EN GERÇEKÇİ ve BİLİNEN 6 adet mekanı bul ve sadece JSON formatında yanıt ver. 
      UYARI: Veriler bir profesörün kontrolünden geçecektir. Asla mekan adı veya lokasyon uydurma!
      Herhangi bir markdown veya fazladan açıklama yazma, sadece saf JSON döndür. JSON yapısı şu array formatında olmalıdır:
      [
        {
          "name": "Gerçek ve Doğrulanmış Mekan Adı",
          "description": "Mekanın atmosferini anlatan resmi ve net ${AppTranslations.isEnglish ? 'İngilizce' : 'Türkçe'} açıklama.",
          "lat": 41.8902,
          "lng": 12.4922
        }
      ]
    ''';

    final response = await model.generateContent([Content.text(prompt)]);
    final responseText = response.text;
    if (responseText == null) throw 'Yapay zeka boş yanıt döndürdü';

    // Extract JSON safely
    String cleanJson = responseText;
    if (responseText.contains('```json')) {
      cleanJson = responseText.split('```json')[1].split('```')[0];
    } else if (responseText.contains('```')) {
      cleanJson = responseText.split('```')[1].split('```')[0];
    }

    final parsed = json.decode(cleanJson.trim()) as List;
    final cityCode = cityName.substring(0, 3).toUpperCase();

    List<Map<String, dynamic>> results = [];
    for (var item in parsed) {
      results.add({
        'city_id': cityCode,
        'name': item['name'] ?? 'Yapay Zeka Mekanı',
        'description': item['description'] ?? 'Harika bir nokta.',
        'lat': double.tryParse(item['lat'].toString()) ?? 0.0,
        'lng': double.tryParse(item['lng'].toString()) ?? 0.0,
        'image_url': getCategoryImage(_selectedCategory), // KESİNLİKLE HALÜSİNASYONSUZ LOKAL GÖRSEL
        'category_type': _selectedCategory,
      });
    }

    setState(() {
      _discoveredPlaces = results;
    });
  }

  // 3. FOURSQUARE API ENGINE
  Future<void> _fetchFromFoursquare(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('foursquare_api_key') ?? '';

    if (apiKey.isEmpty) {
      throw 'Lütfen Ayarlar panelinden geçerli bir Foursquare API anahtarı ekleyin!';
    }

    final catId = getFoursquareCategoryId(_selectedCategory);
    final fsqUrl = Uri.parse(
      'https://api.foursquare.com/v3/places/search?near=${Uri.encodeComponent(cityName)}&categories=$catId&limit=10',
    );

    final response = await http.get(
      fsqUrl,
      headers: {'accept': 'application/json', 'Authorization': apiKey},
    );

    if (response.statusCode != 200) {
      throw 'Foursquare API Hatası (Kod: ${response.statusCode}). Anahtarı kontrol edin.';
    }

    final data = json.decode(response.body);
    final resultsList = data['results'] as List;

    List<Map<String, dynamic>> results = [];
    final cityCode = cityName.substring(0, 3).toUpperCase();

    for (var item in resultsList) {
      final name = item['name'] ?? 'İsimsiz Mekan';
      final geocodes = item['geocodes'] ?? {};
      final mainGeo = geocodes['main'] ?? {};
      final lat = mainGeo['latitude'] ?? 0.0;
      final lng = mainGeo['longitude'] ?? 0.0;

      final location = item['location'] ?? {};
      final address = location['formatted_address'] ?? 'Roma, İtalya';
      final description =
          'Foursquare verilerine göre $address adresinde bulunan popüler bir $_selectedCategory durağı.';

      results.add({
        'city_id': cityCode,
        'name': name,
        'description': description,
        'lat': lat,
        'lng': lng,
        'image_url': getCategoryImage(_selectedCategory),
        'category_type': _selectedCategory,
      });
    }

    if (results.isEmpty) throw 'Foursquare bu şehirde hiçbir mekan bulamadı.';

    setState(() {
      _discoveredPlaces = results;
    });
  }

  // Sync to database
  Future<void> _syncToDatabase(Map<String, dynamic> place) async {
    if (widget.isOffline || !isSupabaseInitialized) {
      // Local modda yerel Swiper havuzuna ekle
      LocalPlaceData.defaultPlaces.insert(0, place);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${place['name']}" yerel kart havuzuna eklendi! 🃏'),
          backgroundColor: const Color(0xFFFE3C72),
        ),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('places').insert({
        'city_id': place['city_id'],
        'name': place['name'],
        'description': place['description'],
        'image_url': place['image_url'],
        'lat': place['lat'],
        'lng': place['lng'],
        'category_type': place['category_type'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${place['name']}" Supabase veritabanına kaydedildi! ⚡',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      // Hata durumunda yerel havuza ekle
      LocalPlaceData.defaultPlaces.insert(0, place);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DB Bağlantı Hatası. Yerel havuza eklendi!'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }

  Future<void> _syncAllToDatabase() async {
    int syncCount = 0;
    for (var place in _discoveredPlaces) {
      if (widget.isOffline || !isSupabaseInitialized) {
        LocalPlaceData.defaultPlaces.insert(0, place);
        syncCount++;
      } else {
        try {
          await Supabase.instance.client.from('places').insert({
            'city_id': place['city_id'],
            'name': place['name'],
            'description': place['description'],
            'image_url': place['image_url'],
            'lat': place['lat'],
            'lng': place['lng'],
            'category_type': place['category_type'],
          });
          syncCount++;
        } catch (_) {}
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$syncCount mekan başarıyla veritabanına senkronize edildi!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F0B13), Color(0xFF0C0B0E)],
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mekan Keşif Havuzu 🔍',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Açık veri setlerinden veya Yapay Zekadan canlı mekanlar çekin.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Arama Girişi ve Motor Seçimi
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: _activeEngine == 'gemini' ? 'Nasıl bir yer arıyorsun? (AI)' : 'Şehir İsmi',
                    hintText: _activeEngine == 'gemini' ? 'Örn: Kadıköy sessiz kahveci...' : 'Roma, Berlin, London...',
                    filled: true,
                    fillColor: const Color(0xFF1E1E24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF1E1E24),
                  underline: const SizedBox(),
                  items: _categories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Arama Motoru Seçim Sekmeleri
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEngineTab('osm', 'OSM (Ücretsiz)', Icons.map_outlined),
              _buildEngineTab(
                'gemini',
                'AI Gelişmiş',
                Icons.auto_awesome_outlined,
              ),
              _buildEngineTab(
                'foursquare',
                'Foursquare v3',
                Icons.location_searching,
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFE3C72), Color(0xFFFF655B)],
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchPlaces,
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text(
                  'Küresel Açık Verileri Tara',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Sonuç Listesi Başlığı ve Toplu Senkronizasyon
          if (_discoveredPlaces.isNotEmpty) ...[
            WeatherWidget(
              lat: _discoveredPlaces.first['lat'],
              lng: _discoveredPlaces.first['lng'],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_discoveredPlaces.length} Mekan Keşfedildi',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
                TextButton.icon(
                  onPressed: _syncAllToDatabase,
                  icon: const Icon(Icons.sync, size: 16),
                  label: Text(
                    widget.isOffline
                        ? 'Tümünü Havuza Ekle'
                        : 'Tümünü DB\'ye Aktar',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFE3C72),
                  ),
                ),
              ],
            ),
          ],

          // Sonuçlar / Liste
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFE3C72)),
                  )
                : _discoveredPlaces.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.travel_explore,
                          size: 54,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Arama yapılmadı veya sonuç bulunamadı',
                          style: TextStyle(color: Colors.white30, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _discoveredPlaces.length,
                    itemBuilder: (context, index) {
                      final item = _discoveredPlaces[index];
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
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: item['image_url'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, err) =>
                                  const Icon(Icons.image),
                            ),
                          ),
                          title: Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item['description'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFE3C72,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['category_type'].toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFFFE3C72),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lat: ${item['lat'].toStringAsFixed(3)}, Lng: ${item['lng'].toStringAsFixed(3)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              widget.isOffline
                                  ? Icons.add_circle
                                  : Icons.cloud_download,
                              color: const Color(0xFFFE3C72),
                            ),
                            onPressed: () => _syncToDatabase(item),
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

  Widget _buildEngineTab(String code, String label, IconData icon) {
    final isSelected = _activeEngine == code;
    return GestureDetector(
      onTap: () => setState(() => _activeEngine = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFE3C72).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFE3C72) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFFFE3C72) : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PERSISTENT MY SAVED ROUTES SCREEN
// -----------------------------------------------------------------------------
