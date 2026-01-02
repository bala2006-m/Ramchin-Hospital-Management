import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class TestingScanningService {
  /// Create a Testing/Scanning record
  Future<void> createTestingScanning(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/testing_and_scanning_patient/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create testing/scanning: ${response.body}');
    }
  }

  Future<String> getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  Future<List<dynamic>> getAllTestingAndScanning(String type) async {
    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse(
          '$baseUrl/testing_and_scanning_patient/all/$hospitalId/$type',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          return decoded['data'] as List<dynamic>;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to fetch ECG queue: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching ECG queue: $e');
    }
  }

  Future<List<dynamic>> getAllTestingAndScanningData() async {
    try {
      final hospitalId = await getHospitalId();

      final response = await http.get(
        Uri.parse('$baseUrl/testing_and_scanning_patient/all/$hospitalId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          return decoded['data'] as List<dynamic>;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to fetch ECG queue: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching ECG queue: $e');
    }
  }

  Future<List<dynamic>> getAllEditTestingAndScanning() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hospitalId = await getHospitalId();
      final doctorId = prefs.getString('assistantDoctorId');

      final response = await http.get(
        Uri.parse(
          '$baseUrl/testing_and_scanning_patient/all/pendingPaymentStatus/$hospitalId/$doctorId',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        print('decoded ${decoded['data']}');

        if (decoded['status'] == 'success' && decoded['data'] != null) {
          // Filter only paymentStatus == false
          final unpaidRecords = (decoded['data'] as List<dynamic>)
              .where((item) => item['paymentStatus'] == false)
              .toList();

          return unpaidRecords;
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Failed to fetch testing/scanning queue: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching testing/scanning queue: $e');
    }
  }

  Future<Map<String, dynamic>> updateTestAndScan(int id) async {
    try {
      final response = await http.patch(
        Uri.parse(
          "$baseUrl/testing_and_scanning_patient/update-payment-status/$id",
        ),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "failed",
          "message": "Server returned ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "failed", "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateTesting(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse(
          "$baseUrl/testing_and_scanning_patient/updateByIdTesting/$id",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "failed",
          "message": "Server returned ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "failed", "message": e.toString()};
    }
  }

  // Future<Map<String, dynamic>> updateScanning(
  //   int id,
  //   Map<String, String> fields,
  //   List<File> images,
  // ) async {
  //   try {
  //     var uri = Uri.parse(
  //       "$baseUrl/testing_and_scanning_patient/updateByIdScanning/$id",
  //     );
  //
  //     var request = http.MultipartRequest("PATCH", uri);
  //
  //     // Add normal fields
  //     fields.forEach((key, value) {
  //       request.fields[key] = value;
  //     });
  //
  //     // Attach images (if any)
  //     for (int i = 0; i < images.length; i++) {
  //       var imageFile = await http.MultipartFile.fromPath(
  //         'files', // MUST MATCH your NestJS interceptor name
  //         images[i].path,
  //       );
  //       request.files.add(imageFile);
  //     }
  //
  //     var response = await request.send();
  //     var responseBody = await response.stream.bytesToString();
  //
  //
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       return jsonDecode(responseBody);
  //     } else {
  //       return {
  //         "status": "failed",
  //         "message": "Server returned ${response.statusCode}",
  //       };
  //     }
  //   } catch (e) {
  //     return {"status": "failed", "message": e.toString()};
  //   }
  // }
  Future<Map<String, dynamic>> updateScanning(
    int id,
    Map<String, dynamic> fields, // <-- CHANGE HERE
    List<File> images,
  ) async {
    try {
      var uri = Uri.parse(
        "$baseUrl/testing_and_scanning_patient/updateByIdScanning/$id",
      );

      var request = http.MultipartRequest("PATCH", uri);

      // Convert ALL values to string (multipart requires string fields)
      fields.forEach((key, value) {
        request.fields[key] = value is String ? value : jsonEncode(value);
      });

      // Attach images
      for (int i = 0; i < images.length; i++) {
        var imageFile = await http.MultipartFile.fromPath(
          'files',
          images[i].path,
        );
        request.files.add(imageFile);
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        return {
          "status": "failed",
          "message": "Server returned ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "failed", "message": e.toString()};
    }
  }

  /// DELETE (PRISMA DELETE)
  Future<Map<String, dynamic>> deleteTesting(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/testing_and_scanning_patient/deleteById/$id"),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "failed",
          "message": "Server returned ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "failed", "message": e.toString()};
    }
  }

  // Future<Map<String, dynamic>> updateScanning(
  //   int id,
  //   Map<String, dynamic> fields,
  //   List<File> images,
  // ) async {
  //
  //
  //   try {
  //     var uri = Uri.parse(
  //       "$baseUrl/testing_and_scanning_patient/updateByIdScanning/$id",
  //     );
  //
  //     var request = http.MultipartRequest("PATCH", uri);
  //
  //     // Convert ALL values to string (multipart requires string fields)
  //     fields.forEach((key, value) {
  //       request.fields[key] = value is String ? value : jsonEncode(value);
  //     });
  //
  //     // Attach images
  //     for (int i = 0; i < images.length; i++) {
  //       var imageFile = await http.MultipartFile.fromPath(
  //         'files',
  //         images[i].path,
  //       );
  //       request.files.add(imageFile);
  //     }
  //
  //     var response = await request.send();
  //     var responseBody = await response.stream.bytesToString();
  //
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       return jsonDecode(responseBody);
  //     } else {
  //       return {
  //         "status": "failed",
  //         "message": "Server returned ${response.statusCode}",
  //       };
  //     }
  //   } catch (e) {
  //     return {"status": "failed", "message": e.toString()};
  //   }
  // }
}
