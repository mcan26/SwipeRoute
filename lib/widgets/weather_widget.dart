import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherWidget extends StatefulWidget {
  final double lat;
  final double lng;
  
  const WeatherWidget({super.key, required this.lat, required this.lng});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  bool _isLoading = true;
  String _temperature = '';
  String _weatherDescription = '';
  IconData _weatherIcon = Icons.wb_cloudy;
  Color _weatherColor = Colors.white70;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${widget.lat}&longitude=${widget.lng}&current_weather=true');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final temp = current['temperature'];
        final code = current['weathercode'];

        _setWeatherInfo(temp, code);
      }
    } catch (e) {
      debugPrint('Hava durumu alınamadı: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setWeatherInfo(double temp, int code) {
    _temperature = '${temp.toStringAsFixed(1)}°C';
    
    // WMO Weather interpretation codes
    if (code == 0) {
      _weatherDescription = 'Açık, Güneşli';
      _weatherIcon = Icons.wb_sunny;
      _weatherColor = Colors.amber;
    } else if (code == 1 || code == 2 || code == 3) {
      _weatherDescription = 'Parçalı Bulutlu';
      _weatherIcon = Icons.cloud;
      _weatherColor = Colors.grey;
    } else if (code >= 51 && code <= 67) {
      _weatherDescription = 'Yağmurlu';
      _weatherIcon = Icons.beach_access;
      _weatherColor = Colors.blueAccent;
    } else if (code >= 71 && code <= 77) {
      _weatherDescription = 'Karlı';
      _weatherIcon = Icons.ac_unit;
      _weatherColor = Colors.lightBlueAccent;
    } else if (code >= 95) {
      _weatherDescription = 'Fırtınalı';
      _weatherIcon = Icons.flash_on;
      _weatherColor = Colors.deepPurpleAccent;
    } else {
      _weatherDescription = 'Sisli / Kapalı';
      _weatherIcon = Icons.cloud_queue;
      _weatherColor = Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
      );
    }

    if (_temperature.isEmpty) {
      return const SizedBox.shrink(); // Hatada bir şey gösterme
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _weatherColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _weatherColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_weatherIcon, color: _weatherColor, size: 16),
          const SizedBox(width: 6),
          Text(
            '$_temperature - $_weatherDescription',
            style: TextStyle(
              color: _weatherColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
