import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/socket_service.dart';
import '../../../../Services/testing&scanning_service.dart';
import '../Report/ScanReportPage.dart';

class AbdomenPage extends StatefulWidget {
  final Map<String, dynamic> record;
  final int mode;
  // final Function(bool) onRefresh;

  const AbdomenPage({super.key, required this.record, required this.mode});

  @override
  State<AbdomenPage> createState() => _AbdomenPageState();
}

class _AbdomenPageState extends State<AbdomenPage>
    with SingleTickerProviderStateMixin {
  final socketService = SocketService();
  final Color primaryColor = const Color(0xFFBF955E);
  bool _isPatientExpanded = false;
  bool _isLoading = false; // <-- Add this to your State class
  String? _dateTime;
  // File? _pickedImage;
  final List<File> _pickedImages = [];
  Map<String, TextEditingController> noteControllers = {};
  bool isCompleted = false;
  String? logo;
  late Map<String, dynamic> currentRecord;

  late final AnimationController _patientController;
  late final Animation<double> _patientExpandAnimation;

  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateTime();
    currentRecord = Map<String, dynamic>.from(widget.record);
    _patientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _patientExpandAnimation = CurvedAnimation(
      parent: _patientController,
      curve: Curves.easeInOut,
    );
    _loadHospitalLogo();
  }

  @override
  void dispose() {
    _patientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadHospitalLogo() async {
    final prefs = await SharedPreferences.getInstance();
    logo = prefs.getString('hospitalPhoto');
    setState(() {});
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  void _togglePatientExpand() {
    setState(() {
      _isPatientExpanded = !_isPatientExpanded;
      _isPatientExpanded
          ? _patientController.forward()
          : _patientController.reverse();
    });
  }

  // void _toggleXrayExpand() {
  //   setState(() {
  //     _isXrayExpanded = !_isXrayExpanded;
  //   });
  // }

  String _formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(dob));
    } catch (_) {
      return dob;
    }
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return "$age yrs";
    } catch (_) {
      return 'N/A';
    }
  }

  Map<String, String> resultMap = {};

  void _handleSubmit() async {
    noteControllers.forEach((key, controller) {
      resultMap[key] = controller.text.trim();
    });
    bool hasEmpty = resultMap.values.any((v) => v.isEmpty);
    // if (_pickedImages.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text("At least one image is required."),
    //       backgroundColor: Colors.redAccent,
    //     ),
    //   );
    //   return;
    // }
    if (hasEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all ABDOMEN values."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description before submitting.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true); // <-- Start loading

    try {
      final id = widget.record['id'];
      final prefs = await SharedPreferences.getInstance();

      final staffId = prefs.getString('userId');
      // final patient = widget.record['Patient'] ?? {};
      // final consultationList = patient['Consultation'] ?? [];

      // 🧾 Update Testing and Scanning record
      await TestingScanningService().updateScanning(id, {
        'result': description,
        // 'status': 'COMPLETED',
        'updatedAt': _dateTime.toString(),
        'staff_Id': staffId.toString(),
        'selectedOptionResults': resultMap,
      }, _pickedImages);
      // widget.onRefresh(true);
      // // 🧾 Update Consultation record
      // if (consultationId != null) {
      //   await ConsultationService().updateConsultation(consultationId, {
      //     'status': 'ENDPROCESSING',
      //     'scanningTesting': false,
      //     'updatedAt': _dateTime.toString(),
      //   });
      // }
      await TestingScanningService().updateTesting(id, {
        'queueStatus': 'COMPLETED',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ABDOMEN marked as Completed ✅'),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pop(context, true);
      }

      // await widget.onRefresh(true);
      // ✅ Update the current record
      // xrayRefreshNotifier.value = true;

      setState(() {
        isCompleted = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false); // <-- Stop loading
    }
  }

  void handelSubmitReport() async {
    try {
      setState(() => _isLoading = true);
      final consultationId = (widget.record.isNotEmpty)
          ? widget.record['consulateId']
          : null;

      final id = widget.record['id'];
      // 🧾 Update Testing and Scanning record
      await TestingScanningService().updateTesting(id, {'status': 'COMPLETED'});

      // 🧾 Update Consultation record
      if (consultationId != null) {
        await ConsultationService().updateConsultation(consultationId, {
          'status': 'ENDPROCESSING',
          'scanningTesting': false,
          'updatedAt': _dateTime.toString(),
        });
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ABDOMEN Report Submitted ✅'),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e Error: failed to submit ABDOMEN Report'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final patient = record['Patient'] ?? {};
    // final phone = patient['phone']?['mobile'] ?? 'N/A';
    String phone;

    final phoneData = patient['phone'];

    if (phoneData == null) {
      phone = 'N/A';
    } else if (phoneData is String) {
      phone = phoneData;
    } else if (phoneData is Map) {
      phone = phoneData['mobile'] ?? 'N/A';
    } else if (phoneData is List &&
        phoneData.isNotEmpty &&
        phoneData[0] is Map) {
      phone = phoneData[0]['mobile'] ?? 'N/A';
    } else {
      phone = 'N/A';
    }

    final patientId = patient['id'].toString();
    final address = patient['address']?['Address'] ?? 'N/A';
    // final doctorName = ((record['Hospital']?['Admins'] as List?) ?? [])
    //     .cast<Map<String, dynamic>>()
    //     .firstWhere(
    //       (a) =>
    //           a['user_Id'].toString() ==
    //           ((record['doctor_Id'] as List?)?.first?.toString() ?? ''),
    //       orElse: () => {'name': 'N/A'},
    //     )['name']
    //     .toString();
    // final doctorId = record['doctor_Id'] != null
    //     ? (record['doctor_Id'] as List).join(", ")
    //     : 'N/A';
    // final hospitalAdmins = record['Hospital']?['Admins'];
    // List<Map<String, dynamic>> adminList = [];
    //
    // if (hospitalAdmins is List) {
    //   // only cast if it's really a List
    //   adminList = hospitalAdmins.whereType<Map<String, dynamic>>().toList();
    // }

    final doctorIdList = patient['doctor']?['id'] ?? '-';
    String doctorId = '';

    if (doctorIdList is List && doctorIdList.isNotEmpty) {
      doctorId = doctorIdList.first.toString();
    } else if (doctorIdList is String) {
      doctorId = doctorIdList;
    }

    // final doctor = adminList.firstWhere(
    //   (a) => a['user_Id'].toString() == doctorId,
    //   orElse: () => {'name': 'N/A'},
    // );

    final doctorName = patient['doctor']?['name'] ?? '-';

    final createdAt = record['createdAt'] ?? '-';
    final title = record['title'] ?? '-';
    final reason = record['reason'] ?? '-';
    final dob = _formatDob(patient['dob']);
    final age = _calculateAge(patient['dob']);
    final gender = patient['gender'] ?? '-';
    final bloodGroup = patient['bldGrp'] ?? '-';
    final tokenNo = (patient['tokenNo'] == null || patient['tokenNo'] == 0)
        ? '-'
        : patient['tokenNo'].toString();

    // 🩻 Selected X-Ray Options
    final selectedOptions = List<String>.from(record['selectedOptions'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
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
                    " ABDOMEN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () {
                      int count = 0;
                      Navigator.popUntil(context, (route) => count++ >= 2);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: widget.mode == 2
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Scan report card
                  ScanReportCard(scanData: record, hospitalLogo: logo, mode: 2),
                  const SizedBox(height: 20),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPatientCard(
                    name: patient['name'] ?? 'Unknown',
                    id: patientId,
                    phone: phone,
                    tokenNo: tokenNo,
                    address: address,
                    dob: dob,
                    age: age,
                    gender: gender,
                    bloodGroup: bloodGroup,
                    createdAt: createdAt,
                  ),
                  const SizedBox(height: 20),
                  _buildMedicalCard(
                    title: title,
                    doctorName: doctorName,
                    reason: reason,
                    doctorId: doctorId,
                    selectedOptions: selectedOptions,
                  ),
                  const SizedBox(height: 30),

                  // 📝 Description Input Box
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          cursorColor: primaryColor,
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "Enter ABDOMEN report or notes...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : _handleSubmit, // Disable when loading
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              _isLoading ? "Submitting..." : "Submit",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: widget.mode == 2
          ? FloatingActionButton.extended(
              onPressed: handelSubmitReport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text(
                "Submit Report",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              elevation: 5,
            )
          : null, // No FAB in non-completed state

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // 🧍 PATIENT CARD
  Widget _buildPatientCard({
    required String name,
    required String id,
    required String phone,
    required String tokenNo,
    required String address,
    required String dob,
    required String age,
    required String gender,
    required String bloodGroup,
    required String createdAt,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _togglePatientExpand,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isPatientExpanded ? "Hide" : "View All",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        _isPatientExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            //crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Token No: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                tokenNo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2), Divider(color: Colors.grey.shade300),
          _infoRow("Patient ID", id),
          _infoRow("Cell No", phone),
          _infoRow("Address", address),
          // Expandable Section
          SizeTransition(
            sizeFactor: _patientExpandAnimation,
            axisAlignment: -1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 30, color: Colors.grey),
                _sectionHeader("Patient Information"),
                const SizedBox(height: 8),
                _infoRow("DOB", dob),
                _infoRow("Age", age),
                _infoRow("Gender", gender),
                _infoRow("Blood Type", bloodGroup),
                _infoRow("Created At", createdAt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏥 MEDICAL CARD
  Widget _buildMedicalCard({
    required String title,
    required String doctorName,
    required String reason,
    required String doctorId,
    required List<String> selectedOptions,
  }) {
    final testDetails = widget.record['testDetails'] ?? [];

    // Collect selected X-ray options
    final List<Map<String, dynamic>> selectedOptions = [];

    for (var test in testDetails) {
      if (test['options'] != null) {
        for (var opt in test['options']) {
          if (opt['selectedOption'] != "N/A") {
            selectedOptions.add(opt);
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title.isEmpty ? "Medical Information" : title,
              style: TextStyle(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Divider(height: 25, color: Colors.grey),

          _infoRow("Doctor Name", doctorName),
          _infoRow("Doctor ID", doctorId),

          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Doctor Description ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBF955E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 30, color: Colors.grey),
          _sectionHeader("Selected ABDOMEN Options"),
          const SizedBox(height: 10),

          if (selectedOptions.isEmpty)
            const Text(
              "No ABDOMEN Options Selected",
              style: TextStyle(color: Colors.grey),
            ),

          ...selectedOptions.map((opt) {
            final String optionName = opt['selectedOption'];

            // Create controller once
            noteControllers.putIfAbsent(
              optionName,
              () => TextEditingController(),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      optionName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TextField(
                  cursorColor: primaryColor,
                  controller: noteControllers[optionName],
                  decoration: InputDecoration(
                    hintText: "Enter $optionName value...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            );
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickMultiImage();

                    if (picked.isNotEmpty) {
                      if (_pickedImages.length + picked.length > 6) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Maximum 6 images allowed!"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                        return;
                      }

                      setState(() {
                        _pickedImages.addAll(
                          picked.map((img) => File(img.path)).toList(),
                        );
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${picked.length} image(s) added"),
                            backgroundColor: primaryColor,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.attach_file, color: Colors.white),
                  label: const Text(
                    "Gallery ",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // 👈 Rounded Border
                    ),
                  ),
                ),
              ),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                    );

                    if (picked != null) {
                      if (_pickedImages.length + 1 > 6) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Maximum 6 images allowed!"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                        return;
                      }

                      setState(() {
                        _pickedImages.add(File(picked.path));
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("1 image added from Camera"),
                            backgroundColor: primaryColor,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    "Camera",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // 👈 Rounded Border
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_pickedImages.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _pickedImages.map((file) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            file,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          ),
                        ),

                        // ❌ Remove button
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _pickedImages.remove(file);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label :",
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
