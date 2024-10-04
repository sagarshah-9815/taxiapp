import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class MapService {
  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/driving/';

  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final response = await http.get(Uri.parse(
        '$_baseUrl${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> coordinates =
          data['routes'][0]['geometry']['coordinates'];
      return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
    } else {
      throw Exception('Failed to load route');
    }
  }

  static double calculateFare(double distanceInMeters) {
    // Base fare: 50 NPR
    // Per kilometer rate: 20 NPR
    // Minimum fare: 100 NPR
    double fareInNPR = 50 + (distanceInMeters / 1000) * 20;
    return fareInNPR < 100 ? 100 : fareInNPR;
  }

  static List<LatLng> dijkstra(List<LatLng> graph, LatLng start, LatLng end) {
    final Distance distanceCalculator =
        Distance(); // Use Distance class for calculating distances

    Map<LatLng, double> distances = {};
    Map<LatLng, LatLng?> previousNodes = {};
    List<LatLng> unvisited = List.from(graph);

    for (var node in graph) {
      distances[node] = node == start ? 0 : double.infinity;
      previousNodes[node] = null;
    }

    while (unvisited.isNotEmpty) {
      LatLng current =
          unvisited.reduce((a, b) => distances[a]! < distances[b]! ? a : b);

      if (current == end) break;

      unvisited.remove(current);

      for (var neighbor in graph.where((node) => unvisited.contains(node))) {
        double alt =
            distances[current]! + distanceCalculator(current, neighbor);
        if (alt < distances[neighbor]!) {
          distances[neighbor] = alt;
          previousNodes[neighbor] = current;
        }
      }
    }

    List<LatLng> path = [];
    LatLng? current = end;
    while (current != null) {
      path.add(current);
      current = previousNodes[current];
    }
    return path.reversed.toList();
  }
}
