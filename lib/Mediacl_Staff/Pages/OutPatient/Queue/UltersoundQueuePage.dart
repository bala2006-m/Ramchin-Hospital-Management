import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/testing&scanning_service.dart';
import '../Page/UlterSoundPage.dart';

class UltrasoundQueuePage extends StatefulWidget {
  const UltrasoundQueuePage({super.key});

  @override
  State<UltrasoundQueuePage> createState() => _UltrasoundQueuePageState();
}

class _UltrasoundQueuePageState extends State<UltrasoundQueuePage> {
  late Future<List<dynamic>> futureCtScanQueue;
  final Color primaryColor = const Color(0xFFBF955E);
  int _currentIndex = 0; // Bottom tab index

  @override
  void initState() {
    super.initState();

    futureCtScanQueue = TestingScanningService().getAllTestingAndScanning(
      'HF ULTRA SOUND',
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dob);
      return DateFormat('dd-MM-yyyy').format(date);
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

  Color _genderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Colors.lightBlue.shade400;
      case 'female':
        return Colors.pink.shade300;
      default:
        return Colors.orange.shade400;
    }
  }

  IconData _genderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.transgender;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    "Ultrasound Queue",

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
                ],
              ),
            ),
          ),
        ),
      ),

      body: FutureBuilder<List<dynamic>>(
        future: futureCtScanQueue,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Lottie.asset(
                'assets/Lottie/error404.json',
                width: 280,
                height: 280,
                fit: BoxFit.contain,
              ),
            );
          }

          final records = snapshot.data ?? [];

          // Separate pending and completed records
          List<dynamic> pendingRecords = records
              .where((r) => r['queueStatus']?.toString() == 'PENDING')
              .toList();
          List<dynamic> completedRecords = records
              .where((r) => r['queueStatus']?.toString() == 'COMPLETED')
              .toList();
          List<List<dynamic>> tabRecords = [pendingRecords, completedRecords];

          return Column(
            children: [
              // Waiting Patients Card
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor, width: 2),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),

                child: Center(
                  child: Text(
                    "Waiting Patients ( ${records.length} )",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              // Queue List
              Expanded(child: _buildQueueList(tabRecords[_currentIndex])),
            ],
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: "Pending",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Scanned",
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(List<dynamic> records) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/Lottie/NoData.json',
              width: 250,
              height: 250,
              repeat: true,
            ),
            const SizedBox(height: 16),
            const Text(
              "No Ultrasound patients in this tab",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final patient = record['Patient'] ?? {};
        final createdAt = record['createdAt'];
        final title = record['title'] ?? record['type'];
        final gender = patient['gender'] ?? 'other';
        final color = _genderColor(gender);
        final tokenNo =
            (patient['tokenNo'] == null ||
                patient['tokenNo'] == 0 ||
                patient['tokenNo'] == 'N/A')
            ? '-'
            : patient['tokenNo'].toString();
        final queueStatus = record['queueStatus'];
        final mode = (queueStatus == 'PENDING') ? 1 : 2;

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UltrasoundPage(record: record, mode: mode),
              ),
            );
            if (result == true) {
              setState(() {
                futureCtScanQueue = TestingScanningService()
                    .getAllTestingAndScanning('HF ULTRA SOUND');
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Gender + Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_genderIcon(gender), size: 28, color: color),
                      const SizedBox(width: 8),
                      Text(
                        patient['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Divider(
                    color: Colors.grey.shade400,
                    thickness: 1.4,
                    endIndent: 25,
                    indent: 25,
                  ),
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
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (queueStatus == 'COMPLETED') ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _infoText("ID", patient['id'].toString()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _infoText("DOB", _formatDob(patient['dob'])),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _infoText("Age", _calculateAge(patient['dob'])),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _infoText("Created", _formatDate(createdAt)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoText(String label, String value) {
    return RichText(
      text: TextSpan(
        text: '$label : ',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Colors.black87,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
