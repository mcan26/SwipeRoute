import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final bool isOffline;
  const ProfileScreen({super.key, required this.isOffline});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _savedRoutesCount = 0;
  List<String> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStr = prefs.getString('offline_routes') ?? '[]';
    List parsed = [];
    try {
      parsed = json.decode(savedStr) as List;
    } catch (_) {}

    setState(() {
      _savedRoutesCount = parsed.length;
      _badges.clear();
      
      // Basic gamification logic
      if (_savedRoutesCount >= 1) {
        _badges.add('İlk Adım 🎒');
      }
      if (_savedRoutesCount >= 3) {
        _badges.add('Gezgin 🌍');
      }
      if (_savedRoutesCount >= 5) {
        _badges.add('Seyahat Uzmanı 👑');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14141B), Color(0xFF0C0B0E)],
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFFFE3C72),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kullanıcı Profili',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Kaydedilen', 'Rotalar', '$_savedRoutesCount'),
                _buildStatColumn('Kazanılan', 'Rozetler', '${_badges.length}'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Başarı Rozetleri 🏆',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _badges.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz rozet kazanmadınız. Rota oluşturun!',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    itemCount: _badges.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: const Color(0xFFFE3C72).withOpacity(0.1),
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: Text(
                            _badges[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

  Widget _buildStatColumn(String label1, String label2, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFE3C72),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label1,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        Text(
          label2,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}
