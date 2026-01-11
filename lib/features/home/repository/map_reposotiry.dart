import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapRepository {
  Future<List<dynamic>> getAutocomplete(String input) async {
    try {
      final response = await Dio().get(
        "https://api.geoapify.com/v1/geocode/autocomplete",
        queryParameters: {
          "text": input,
          "apiKey": dotenv.env['API_KEY'],
          "format": "json", // FORCE plain JSON with "results" array
          "limit": 5, // optional: limits number of suggestions
        },
        options: Options(responseType: ResponseType.json),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("Raw Response Data: ${response.data}");
          print("Response data type: ${response.data.runtimeType}");
          print("Results: ${response.data["results"]}");
          print("Results length: ${response.data["results"]?.length ?? 0}");
        }

        final results = response.data["results"];
        if (results is List) {
          return List<dynamic>.from(results);
        }
        return [];
      } else {
        if (kDebugMode) print("Error: ${response.statusCode}");
        return [];
      }
    } on DioException catch (e) {
      if (kDebugMode) print("Network Error: ${e.message}");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getRoutes(String waypoints, String mode) async {
    try {
      if (kDebugMode) {
        print("=== Routing API Request ===");
        print("Waypoints: $waypoints");
        print("Mode: $mode");
        print("API Key exists: ${dotenv.env['API_KEY'] != null}");
      }

      final response = await Dio().get(
        "https://api.geoapify.com/v1/routing",
        queryParameters: {
          "waypoints": waypoints,
          "mode": mode,
          "apiKey": dotenv.env['API_KEY'],
        },
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (status) => status! < 500, // Don't throw on 4xx
        ),
      );

      if (kDebugMode) {
        print("Response Status: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("✓ Route Response Success");
          print("Features count: ${response.data["features"]?.length ?? 0}");
        }

        if (response.data["features"] == null ||
            response.data["features"].isEmpty) {
          if (kDebugMode) {
            print("✗ No route found between these points for mode: $mode");
            print("✗ API Message: ${response.data["message"] ?? 'No message'}");
            print(
              "✗ Try a different mode or check if locations are accessible",
            );
          }
          return null;
        }

        return response.data["features"][0];
      } else {
        if (kDebugMode) {
          print("✗ Error Status: ${response.statusCode}");
          print("✗ Error Response: ${response.data}");
        }
        return null;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print("✗ Network Error on Routing: ${e.message}");
        print("✗ Error Type: ${e.type}");
        if (e.response != null) {
          print("✗ Response Data: ${e.response?.data}");
        }
      }
      return null;
    }
  }
}
