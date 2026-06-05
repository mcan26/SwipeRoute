import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteMapWidget extends StatelessWidget {
  final List<dynamic> places;
  
  const RouteMapWidget({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Center(child: Text('Haritada gösterilecek mekan yok.'));
    }

    final validPlaces = places.where((p) => p['lat'] != null && p['lng'] != null).toList();
    if (validPlaces.isEmpty) {
      return const Center(child: Text('Konum bilgisi bulunamadı.'));
    }

    double sumLat = 0;
    double sumLng = 0;
    List<Marker> markers = [];
    List<LatLng> points = [];

    for (int i = 0; i < validPlaces.length; i++) {
      final p = validPlaces[i];
      final lat = (p['lat'] as num).toDouble();
      final lng = (p['lng'] as num).toDouble();
      final point = LatLng(lat, lng);
      
      sumLat += lat;
      sumLng += lng;
      points.add(point);
      
      markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFE3C72),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final centerLat = sumLat / validPlaces.length;
    final centerLng = sumLng / validPlaces.length;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.swiperoute.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              color: const Color(0xFFFE3C72),
              strokeWidth: 4.0,
            ),
          ],
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
