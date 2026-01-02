// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
//
// import '../../../../Pages/NotificationsPage.dart';
// import '../../../../utils/utils.dart';
//
// class ScanningPage extends StatefulWidget {
//   final Map<String, dynamic> consultation;
//
//   const ScanningPage({super.key, required this.consultation});
//
//   @override
//   State<ScanningPage> createState() => _ScanningPageState();
// }
//
// class _ScanningPageState extends State<ScanningPage> {
//   final Color primaryColor = const Color(0xFFBF955E);
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//
//   bool _isSubmitting = false;
//   String? _dateTime;
//   int _expandedIndex = -1; // one card expanded at a time
//
//   final Map<String, Map<String, dynamic>> savedScans = {};
//   final Map<String, bool> showAllMap =
//       {}; // Tracks which scan shows all options
//
//   final List<Map<String, dynamic>> scans = [
//     {'name': 'X-Ray', 'icon': FontAwesomeIcons.xRay},
//     {'name': 'CT-Scan', 'icon': FontAwesomeIcons.brain},
//     {'name': 'MRI-Scan', 'icon': FontAwesomeIcons.diagnoses},
//     {'name': 'Ultrasound', 'icon': FontAwesomeIcons.waveSquare},
//     {'name': 'ECG', 'icon': FontAwesomeIcons.heartPulse},
//     {'name': 'EEG', 'icon': FontAwesomeIcons.brain},
//     {'name': 'PET Scan', 'icon': FontAwesomeIcons.radiation},
//   ];
//
//   final Map<String, Map<String, dynamic>> scanPricing = {
//     'CT-Scan': {
//       'base': 500,
//       'options': [
//         {'name': 'Brain', 'price': 300, 'icon': FontAwesomeIcons.brain},
//         {'name': 'Chest', 'price': 200, 'icon': FontAwesomeIcons.lungs},
//         {'name': 'Abdomen', 'price': 300, 'icon': FontAwesomeIcons.storeSlash},
//         {'name': 'Pelvis', 'price': 100, 'icon': FontAwesomeIcons.barsProgress},
//         {'name': 'Spine', 'price': 400, 'icon': FontAwesomeIcons.spinner},
//         {'name': 'Neck', 'price': 250, 'icon': FontAwesomeIcons.neos},
//         {
//           'name': 'Extremities',
//           'price': 200,
//           'icon': FontAwesomeIcons.personWalking,
//         },
//       ],
//     },
//     'X-Ray': {
//       'base': 300,
//       'options': [
//         {
//           'name': 'Skull (AP / Lateral View)',
//           'price': 150,
//           'icon': FontAwesomeIcons.skull,
//         },
//         {
//           'name': 'Chest (PA / Lateral View)',
//           'price': 120,
//           'icon': FontAwesomeIcons.lungs,
//         },
//         {
//           'name': 'Abdomen (AP View)',
//           'price': 100,
//           'icon': FontAwesomeIcons.storeSlash,
//         },
//         {'name': 'Pelvis', 'price': 100, 'icon': FontAwesomeIcons.barsProgress},
//         {
//           'name': 'Cervical Spine (AP / Lateral)',
//           'price': 150,
//           'icon': FontAwesomeIcons.spinner,
//         },
//         {
//           'name': 'Thoracic Spine (AP / Lateral)',
//           'price': 150,
//           'icon': FontAwesomeIcons.spinner,
//         },
//         {
//           'name': 'Lumbar Spine (AP / Lateral)',
//           'price': 150,
//           'icon': FontAwesomeIcons.spinner,
//         },
//         {
//           'name': 'Shoulder Joint',
//           'price': 100,
//           'icon': FontAwesomeIcons.handsHolding,
//         },
//         {
//           'name': 'Elbow Joint',
//           'price': 100,
//           'icon': FontAwesomeIcons.handPointRight,
//         },
//         {
//           'name': 'Wrist Joint',
//           'price': 100,
//           'icon': FontAwesomeIcons.handPointUp,
//         },
//         {'name': 'Hand', 'price': 100, 'icon': FontAwesomeIcons.hand},
//         {
//           'name': 'Hip Joint',
//           'price': 120,
//           'icon': FontAwesomeIcons.personWalking,
//         },
//         {
//           'name': 'Knee Joint',
//           'price': 120,
//           'icon': FontAwesomeIcons.personRunning,
//         },
//         {
//           'name': 'Ankle Joint',
//           'price': 100,
//           'icon': FontAwesomeIcons.childReaching,
//         },
//         {'name': 'Foot', 'price': 100, 'icon': FontAwesomeIcons.child},
//         {'name': 'Ribs', 'price': 150, 'icon': FontAwesomeIcons.bone},
//         {
//           'name': 'Sinuses (Waters / Caldwell View)',
//           'price': 150,
//           'icon': FontAwesomeIcons.faceSmile,
//         },
//         {
//           'name': 'Cervical Soft Tissue',
//           'price': 120,
//           'icon': FontAwesomeIcons.neos,
//         },
//       ],
//     },
//     'MRI-Scan': {
//       'base': 700,
//       'options': [
//         {'name': 'Brain', 'price': 400, 'icon': FontAwesomeIcons.brain},
//         {
//           'name': 'Spine (Cervical/Thoracic/Lumbar)',
//           'price': 350,
//           'icon': FontAwesomeIcons.spinner,
//         },
//         {
//           'name': 'Joints (Knee/Shoulder/Ankle)',
//           'price': 300,
//           'icon': FontAwesomeIcons.hands,
//         },
//         {'name': 'Abdomen', 'price': 200, 'icon': FontAwesomeIcons.storeSlash},
//         {'name': 'Pelvis', 'price': 200, 'icon': FontAwesomeIcons.barsProgress},
//       ],
//     },
//     'EEG': {
//       'base': 300,
//       'options': [
//         {
//           'name': 'Brain Activity (Standard)',
//           'price': 200,
//           'icon': FontAwesomeIcons.brain,
//         },
//         {'name': 'Sleep EEG', 'price': 100, 'icon': FontAwesomeIcons.bed},
//         {
//           'name': 'Ambulatory EEG',
//           'price': 200,
//           'icon': FontAwesomeIcons.personWalking,
//         },
//       ],
//     },
//     'PET Scan': {
//       'base': 1000,
//       'options': [
//         {'name': 'Whole Body', 'price': 800, 'icon': FontAwesomeIcons.person},
//         {'name': 'Brain', 'price': 600, 'icon': FontAwesomeIcons.brain},
//         {'name': 'Lungs', 'price': 500, 'icon': FontAwesomeIcons.lungs},
//         {'name': 'Abdomen', 'price': 400, 'icon': FontAwesomeIcons.storeSlash},
//         {
//           'name': 'Bone Metastasis',
//           'price': 700,
//           'icon': FontAwesomeIcons.bone,
//         },
//       ],
//     },
//     'ECG': {
//       'base': 200,
//       'options': [
//         {
//           'name': 'Resting ECG (12-Lead)',
//           'price': 100,
//           'icon': FontAwesomeIcons.heart,
//         },
//         {
//           'name': 'Single Lead ECG',
//           'price': 80,
//           'icon': FontAwesomeIcons.heartbeat,
//         },
//         {
//           'name': '3-Lead ECG',
//           'price': 100,
//           'icon': FontAwesomeIcons.heartPulse,
//         },
//         {
//           'name': '5-Lead ECG',
//           'price': 120,
//           'icon': FontAwesomeIcons.waveSquare,
//         },
//         {
//           'name': '15-Lead ECG',
//           'price': 150,
//           'icon': FontAwesomeIcons.heartCircleBolt,
//         },
//         {
//           'name': 'Treadmill Test (TMT)',
//           'price': 250,
//           'icon': FontAwesomeIcons.personRunning,
//         },
//         {
//           'name': 'Stress ECG (Exercise / Pharmacologic)',
//           'price': 250,
//           'icon': FontAwesomeIcons.personWalking,
//         },
//         {
//           'name': 'Holter Monitoring (24 hr)',
//           'price': 300,
//           'icon': FontAwesomeIcons.clock,
//         },
//         {
//           'name': 'Holter Monitoring (48 hr)',
//           'price': 400,
//           'icon': FontAwesomeIcons.clockRotateLeft,
//         },
//         {
//           'name': 'Holter Monitoring (72 hr)',
//           'price': 500,
//           'icon': FontAwesomeIcons.clockRotateLeft,
//         },
//         {
//           'name': 'Event Recorder ECG',
//           'price': 350,
//           'icon': FontAwesomeIcons.recordVinyl,
//         },
//         {
//           'name': 'Ambulatory ECG (AECG)',
//           'price': 300,
//           'icon': FontAwesomeIcons.personWalking,
//         },
//         {
//           'name': 'Patch ECG (Wearable)',
//           'price': 350,
//           'icon': FontAwesomeIcons.bandAid,
//         },
//         {
//           'name': 'Signal-Averaged ECG (SAECG)',
//           'price': 400,
//           'icon': FontAwesomeIcons.waveSquare,
//         },
//         {
//           'name': 'High-Resolution ECG',
//           'price': 400,
//           'icon': FontAwesomeIcons.eye,
//         },
//         {
//           'name': 'Vectorcardiography (VCG)',
//           'price': 350,
//           'icon': FontAwesomeIcons.vectorSquare,
//         },
//         {
//           'name': 'Telemetry ECG Monitoring',
//           'price': 250,
//           'icon': FontAwesomeIcons.radio,
//         },
//       ],
//     },
//     'Ultrasound': {
//       'base': 400,
//       'options': [
//         {
//           'name': 'Abdominal Ultrasound',
//           'price': 200,
//           'icon': FontAwesomeIcons.bowlFood,
//         },
//         {
//           'name': 'Pelvic Ultrasound',
//           'price': 180,
//           'icon': FontAwesomeIcons.paw,
//         },
//         {
//           'name': 'Whole Abdomen (Abdomen + Pelvis)',
//           'price': 300,
//           'icon': FontAwesomeIcons.bowlRice,
//         },
//         {
//           'name': 'Obstetric Ultrasound (Single Pregnancy)',
//           'price': 250,
//           'icon': FontAwesomeIcons.baby,
//         },
//         {
//           'name': 'Obstetric Ultrasound (Twin Pregnancy)',
//           'price': 300,
//           'icon': FontAwesomeIcons.babyCarriage,
//         },
//         {
//           'name': 'Follicular Study',
//           'price': 180,
//           'icon': FontAwesomeIcons.seedling,
//         },
//         {
//           'name': 'Transvaginal Ultrasound (TVS)',
//           'price': 200,
//           'icon': FontAwesomeIcons.venus,
//         },
//         {
//           'name': 'Thyroid Ultrasound',
//           'price': 150,
//           'icon': FontAwesomeIcons.ankh,
//         },
//         {
//           'name': 'Breast Ultrasound',
//           'price': 180,
//           'icon': FontAwesomeIcons.personBreastfeeding,
//         },
//         {
//           'name': 'Scrotal / Testicular Ultrasound',
//           'price': 180,
//           'icon': FontAwesomeIcons.square,
//         },
//         {
//           'name': 'Soft Tissue Ultrasound',
//           'price': 150,
//           'icon': FontAwesomeIcons.solidSquare,
//         },
//         {
//           'name': 'Neck Ultrasound',
//           'price': 160,
//           'icon': FontAwesomeIcons.person,
//         },
//         {
//           'name': 'Musculoskeletal Ultrasound (MSK)',
//           'price': 250,
//           'icon': FontAwesomeIcons.personHiking,
//         },
//         {
//           'name': 'Venous Doppler (Limbs)',
//           'price': 250,
//           'icon': FontAwesomeIcons.personWalking,
//         },
//         {
//           'name': 'Carotid Doppler (Neck Vessels)',
//           'price': 300,
//           'icon': FontAwesomeIcons.personRunning,
//         },
//         {
//           'name': 'Arterial Doppler (Limbs)',
//           'price': 250,
//           'icon': FontAwesomeIcons.person,
//         },
//         {
//           'name': 'Renal (Kidney) Ultrasound',
//           'price': 150,
//           'icon': FontAwesomeIcons.kickstarter,
//         },
//         {
//           'name': 'Liver Elastography',
//           'price': 350,
//           'icon': FontAwesomeIcons.lungs,
//         },
//         {
//           'name': 'Prostate Ultrasound (Transrectal)',
//           'price': 200,
//           'icon': FontAwesomeIcons.person,
//         },
//         {
//           'name': 'Guided Procedure (Biopsy / Aspiration)',
//           'price': 300,
//           'icon': FontAwesomeIcons.syringe,
//         },
//       ],
//     },
//   };
//
//   @override
//   void initState() {
//     super.initState();
//     _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
//   }
//
//   int _calculateTotalAmount(String scanName, Set<String> selectedOptions) {
//     final scan = scanPricing[scanName];
//     if (scan == null) return 0;
//     final base = scan['base'] ?? 0;
//     final options = scan['options'] as List<dynamic>;
//     int total = base;
//     for (var optName in selectedOptions) {
//       for (var option in options) {
//         if (option['name'] == optName) {
//           total += option['price'] as int? ?? 0;
//           break;
//         }
//       }
//     }
//     return total;
//   }
//
//   Future<void> _submitAllScans() async {
//     if (savedScans.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("No scans to submit."),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isSubmitting = true);
//
//     try {
//       final doctorId = await secureStorage.read(key: 'userId') ?? '';
//       final hospitalId = widget.consultation['hospital_Id'];
//       final patientId = widget.consultation['patient_Id'];
//
//       for (var entry in savedScans.entries) {
//         final scanName = entry.key;
//         final scanData = entry.value;
//
//         final data = {
//           "hospital_Id": hospitalId,
//           "patient_Id": patientId,
//           "doctor_Id": doctorId,
//           "staff_Id": [],
//           "title": scanData['description'],
//           "type": scanName,
//           "scheduleDate": DateTime.now().toIso8601String(),
//           "status": "PENDING",
//           "paymentStatus": false,
//           "result": '',
//           "amount": scanData['totalAmount'],
//           "selectedOptions": scanData['options'].toList(),
//           "createdAt": _dateTime.toString(),
//         };
//
//         await http.post(
//           Uri.parse('$baseUrl/testing_and_scanning_patient/create'),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode(data),
//         );
//       }
//       Navigator.pop(context, 'scan_test');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('All scans submitted successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error submitting scans: $e'),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     } finally {
//       setState(() => _isSubmitting = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(100),
//         child: Container(
//           height: 100,
//           decoration: BoxDecoration(
//             color: primaryColor,
//             borderRadius: const BorderRadius.only(
//               bottomLeft: Radius.circular(12),
//               bottomRight: Radius.circular(12),
//             ),
//           ),
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const Text(
//                     "View Scanning",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     icon: const Icon(Icons.notifications, color: Colors.white),
//                     onPressed: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const NotificationPage(),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: _isSubmitting
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//               itemCount: scans.length,
//               itemBuilder: (context, index) {
//                 final scan = scans[index];
//                 return _buildScanCard(scan, index);
//               },
//             ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(12),
//         child: ElevatedButton.icon(
//           onPressed: _isSubmitting ? null : _submitAllScans,
//           icon: const Icon(Icons.cloud_upload),
//           label: const Text("Submit All"),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: primaryColor,
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(vertical: 14),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildScanCard(Map<String, dynamic> scan, int index) {
//     final scanName = scan['name'] as String;
//     final icon = scan['icon'] as IconData;
//     final isExpanded = _expandedIndex == index;
//     final options = (scanPricing[scanName]?['options'] as List<dynamic>?) ?? [];
//
//     final selectedOptions =
//         (savedScans[scanName]?['options'] ?? <String>{}) as Set<String>;
//
//     final descController = TextEditingController(
//       text: savedScans[scanName]?['description'] ?? '',
//     );
//
//     final bool showAll = showAllMap[scanName] ?? false;
//     final List<dynamic> displayedOptions = showAll
//         ? options
//         : options.take(6).toList();
//
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ExpansionTile(
//         key: ValueKey('exp_$index'),
//         leading: Icon(icon, color: primaryColor, size: 28),
//         title: Center(
//           child: Text(
//             scanName,
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//         ),
//         initiallyExpanded: isExpanded,
//         onExpansionChanged: (expanded) {
//           setState(() {
//             _expandedIndex = expanded ? index : -1;
//           });
//         },
//         children: [
//           Divider(
//             thickness: 1.5,
//             color: primaryColor,
//             indent: 30,
//             endIndent: 30,
//           ),
//           Padding(
//             padding: const EdgeInsets.all(5),
//             child: Column(
//               children: [
//                 if (options.isEmpty)
//                   const Text(
//                     'No specific options available.',
//                     style: TextStyle(color: Colors.grey),
//                   )
//                 else
//                   ...displayedOptions.map((opt) {
//                     final String name = opt['name'];
//                     final int price = opt['price'];
//                     final IconData optIcon = opt['icon'];
//
//                     final selected = selectedOptions.contains(name);
//
//                     return CheckboxListTile(
//                       activeColor: primaryColor,
//                       value: selected,
//                       title: Text(
//                         name,
//                         style: const TextStyle(color: Colors.black),
//                       ),
//                       secondary: Icon(optIcon, color: primaryColor, size: 20),
//                       controlAffinity: ListTileControlAffinity.trailing,
//                       onChanged: (v) {
//                         setState(() {
//                           final mutable = Set<String>.from(selectedOptions);
//                           if (v == true) {
//                             mutable.add(name);
//                           } else {
//                             mutable.remove(name);
//                           }
//                           savedScans[scanName] = {
//                             'options': mutable,
//                             'description':
//                                 savedScans[scanName]?['description'] ?? '',
//                             'totalAmount': _calculateTotalAmount(
//                               scanName,
//                               mutable,
//                             ),
//                           };
//                         });
//                       },
//                     );
//                   }).toList(),
//                 if (options.length > 6)
//                   TextButton(
//                     onPressed: () {
//                       setState(() {
//                         showAllMap[scanName] = !(showAllMap[scanName] ?? false);
//                       });
//                     },
//                     child: Text(
//                       showAll ? 'Show Less' : 'Show All',
//                       style: TextStyle(color: primaryColor),
//                     ),
//                   ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: descController,
//                   maxLines: 3,
//                   decoration: InputDecoration(
//                     hintText: "Enter findings or notes...",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey.shade50,
//                   ),
//                   onChanged: (val) {
//                     savedScans[scanName] = {
//                       'options': selectedOptions,
//                       'description': val,
//                       'totalAmount': _calculateTotalAmount(
//                         scanName,
//                         selectedOptions,
//                       ),
//                     };
//                   },
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/Scan_Test_Get-Service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/socket_service.dart';
import '../../../../utils/utils.dart';

class ScanningPage extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final String role;

  const ScanningPage({
    super.key,
    required this.consultation,
    required this.role,
  });

  @override
  State<ScanningPage> createState() => _ScanningPageState();
}

class _ScanningPageState extends State<ScanningPage> {
  final Color primaryColor = const Color(0xFFBF955E);
  final socketService = SocketService();

  bool _isSubmitting = false;
  bool _isLoading = true;
  int _expandedIndex = -1;
  bool scanningTesting = false;
  late String _dateTime;
  final Map<String, TextEditingController> _descControllers = {};

  final Map<String, Map<String, dynamic>> savedScans = {};
  final Map<String, bool> showAllMap = {};
  List<Map<String, dynamic>> scans = []; // fetched from backend

  final ScanTestGetService _testScanService = ScanTestGetService();

  @override
  void initState() {
    super.initState();
    _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    _loadScan();
  }

  /// 🔹 Fetch scans from backend
  Future<void> _loadScan() async {
    try {
      final fetchedTests = await _testScanService.fetchTests('SCAN');
      setState(() {
        scans = fetchedTests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to fetch scans: $e')));
      }
    }
  }

  int _calculateTotalAmount(
    Map<String, dynamic> scan,
    Set<String> selectedOptions,
  ) {
    int total = 0;
    for (var optName in selectedOptions) {
      for (var option in scan['options']) {
        if (option['optionName'] == optName) {
          total += option['price'] as int;
          break;
        }
      }
    }
    return total;
  }

  Future<void> _submitAllScans() async {
    if (savedScans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No scans selected!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = widget.role == 'doctor'
          ? prefs.getString('userId') ?? ''
          : prefs.getString('assistantDoctorId') ?? '';
      final hospitalId = widget.consultation['hospital_Id'];
      final patientId = widget.consultation['patient_Id'];
      final consultationId = widget.consultation['id'];

      for (var entry in savedScans.entries) {
        final scanName = entry.key;
        final scanData = entry.value;

        // 🔥 SKIP IF options list is empty
        if (scanData['options'] == null || scanData['options'].isEmpty) {
          continue; // Skip this scan
        }

        final payload = {
          "hospital_Id": hospitalId,
          "patient_Id": patientId,
          "doctor_Id": doctorId,
          "consultation_Id": consultationId,
          "staff_Id": [],
          "title": scanName,
          "type": scanName,
          "reason": scanData['description'],
          "scheduleDate": DateTime.now().toIso8601String(),
          "status": "PENDING",
          "paymentStatus": false,
          "result": '',
          "amount": scanData['totalAmount'],
          "selectedOptions": scanData['options'].toList(),
          "selectedOptionAmounts": scanData['selectedOptionsAmount'],
          "createdAt": _dateTime,
        };

        await http.post(
          Uri.parse('$baseUrl/testing_and_scanning_patient/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }
      setState(() {
        scanningTesting = true;
      });
      final consultation = await ConsultationService().updateConsultation(
        consultationId,
        {
          'status': 'ONGOING',
          'scanningTesting': scanningTesting,
          // 'medicineTonic': medicineTonicInjection,
          // 'Injection': injection,
          'queueStatus': 'COMPLETED',
          'updatedAt': _dateTime.toString(),
        },
      );
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Scan submitted!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting scans: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
      setState(() => scanningTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : scans.isEmpty
          ? const Center(
              child: Text(
                "No scans found.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      for (int index = 0; index < scans.length; index++)
                        _buildScanCard(scans[index], index),
                    ],
                  ),

                  SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitAllScans,
        icon: const Icon(Icons.cloud_upload),
        label: const Text("Submit Scans"),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "View Scanning",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationPage()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan, int index) {
    final scanName = scan['title'] as String;
    final options = (scan['options'] ?? []) as List<dynamic>;
    final isExpanded = _expandedIndex == index;
    final selectedOptions =
        (savedScans[scanName]?['options'] ?? <String>{}) as Set<String>;
    // final descController = TextEditingController(
    //   text: savedScans[scanName]?['description'] ?? '',
    // );
    final descController = _descControllers.putIfAbsent(
      scanName,
      () => TextEditingController(
        text: savedScans[scanName]?['description'] ?? '',
      ),
    );

    final bool showAll = showAllMap[scanName] ?? false;
    final displayedOptions = showAll ? options : options.take(5).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: ValueKey('exp_$index'),
        leading: Icon(FontAwesomeIcons.vials, color: primaryColor),
        title: Center(
          child: Text(
            scanName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) =>
            setState(() => _expandedIndex = expanded ? index : -1),
        children: [
          Divider(
            thickness: 1.5,
            color: primaryColor.withValues(alpha: 0.6),
            indent: 30,
            endIndent: 30,
          ),
          ...displayedOptions.map((opt) {
            //final name = opt['name'];
            final String name = opt['optionName'] ?? '';
            final price = opt['price'];
            final selected = selectedOptions.contains(name);

            return CheckboxListTile(
              value: selected,
              activeColor: primaryColor,
              title: Text('$name ( ₹ $price )', style: TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.trailing,
              // onChanged: (v) {
              //   setState(() {
              //     final mutable = Set<String>.from(selectedOptions);
              //     if (v == true) {
              //       mutable.add(name);
              //     } else {
              //       mutable.remove(name);
              //     }
              //     savedScans[scanName] = {
              //       'options': mutable,
              //       'description': savedScans[scanName]?['description'] ?? '',
              //       'totalAmount': _calculateTotalAmount(scan, mutable),
              //     };
              //   });
              // },
              onChanged: (v) {
                setState(() {
                  // Always initialize safely
                  final Map<String, int> optionAmountMap =
                      savedScans[scanName]?['selectedOptionsAmount'] != null
                      ? Map<String, int>.from(
                          savedScans[scanName]!['selectedOptionsAmount'],
                        )
                      : <String, int>{};

                  if (v == true) {
                    optionAmountMap[name] = price;
                  } else {
                    optionAmountMap.remove(name);
                  }

                  if (optionAmountMap.isEmpty) {
                    savedScans.remove(scanName);
                  } else {
                    savedScans[scanName] = {
                      'options': optionAmountMap.keys.toSet(),
                      'selectedOptionsAmount': optionAmountMap,
                      'description': savedScans[scanName]?['description'] ?? '',
                      'totalAmount': optionAmountMap.values.fold<int>(
                        0,
                        (a, b) => a + b,
                      ),
                    };
                  }
                });
              },
            );
          }),
          if (options.length > 5)
            TextButton(
              onPressed: () => setState(() => showAllMap[scanName] = !showAll),
              child: Text(
                showAll ? 'Show Less' : 'Show All',
                style: TextStyle(color: primaryColor),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter findings or notes...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              // onChanged: (val) {
              //   savedScans[scanName] = {
              //     'options': selectedOptions,
              //     'description': val,
              //     'totalAmount': _calculateTotalAmount(scan, selectedOptions),
              //   };
              // },
              onChanged: (val) {
                setState(() {
                  final existing = savedScans[scanName] ?? {};

                  savedScans[scanName] = {
                    'options': existing['options'] ?? selectedOptions,
                    'selectedOptionsAmount':
                        existing['selectedOptionsAmount'] ?? <String, int>{},
                    'description': val,
                    'totalAmount':
                        existing['totalAmount'] ??
                        _calculateTotalAmount(scan, selectedOptions),
                  };
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
