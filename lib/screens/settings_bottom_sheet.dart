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
import '../config/translations.dart';

import 'vibe_check_screen.dart';
import 'discovery_hub_screen.dart';
import 'saved_routes_screen.dart';
import 'swiper_screen.dart';

// -----------------------------------------------------------------------------
// SETTINGS BOTTOM SHEET
// -----------------------------------------------------------------------------
class SettingsBottomSheet extends StatefulWidget {
  final bool isOffline;
  final ValueChanged<bool> onOfflineToggled;

  const SettingsBottomSheet({
    super.key,
    required this.isOffline,
    required this.onOfflineToggled,
  });

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  final _geminiKeyController = TextEditingController();
  final _foursquareKeyController = TextEditingController();
  late bool _localMode;
  late bool _isEnglish;

  @override
  void initState() {
    super.initState();
    _localMode = widget.isOffline;
    _isEnglish = AppTranslations.isEnglish;
    _loadKeys();
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    _foursquareKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _geminiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _foursquareKeyController.text =
          prefs.getString('foursquare_api_key') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _geminiKeyController.text.trim());
    await prefs.setString(
      'foursquare_api_key',
      _foursquareKeyController.text.trim(),
    );
    await prefs.setBool('is_english', _isEnglish);
    AppTranslations.isEnglish = _isEnglish;

    widget.onOfflineToggled(_localMode);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayarlar başarıyla kaydedildi! ⚙️'),
          backgroundColor: Color(0xFFFE3C72),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16161C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Uygulama Ayarları ⚙️',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'API anahtarlarınızı girin ve veritabanı modunu yönetin.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Veritabanı Modu Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Çevrimdışı / Yerel Mod',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Mekan verilerini lokal havuzdan okur',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  Switch(
                    value: _localMode,
                    activeThumbColor: const Color(0xFFFE3C72),
                    onChanged: (val) {
                      if (!isSupabaseInitialized && !val) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Supabase sunucusuna ulaşılamıyor. Bulut moduna geçilemez.',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      setState(() => _localMode = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Dil Seçeneği
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.t('settings_lang'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        AppTranslations.t('settings_lang_desc'),
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isEnglish,
                    activeThumbColor: const Color(0xFFFE3C72),
                    onChanged: (val) {
                      setState(() => _isEnglish = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gemini API Key Input
            const Text(
              'Gemini API Anahtarı (Yapay Zeka Rotaları İçin)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _geminiKeyController,
              decoration: _inputDecoration('AIzaSy...', Icons.auto_awesome),
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Foursquare API Key Input
            const Text(
              'Foursquare API Anahtarı (Keşif Havuzu İçin)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _foursquareKeyController,
              decoration: _inputDecoration('fsq3...', Icons.location_searching),
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFE3C72), Color(0xFFFF655B)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Değişiklikleri Kaydet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.white30, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFE3C72), width: 1.5),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DISCOVERY HUB & DATABASE SEEDER SCREEN (OPEN DATASET RETRIEVER)
// -----------------------------------------------------------------------------
