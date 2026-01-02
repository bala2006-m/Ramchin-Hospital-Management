import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/consultation_service.dart';
import '../../../Services/testing&scanning_service.dart';

const Color customGold = Color(0xFFBF955E);
const Color backgroundColor = Color(0xFFFFF7E6);
const Color cardColor = Colors.white;

const TextStyle sectionTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle cardTitleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

const TextStyle cardValueStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  final ConsultationService _consultationService = ConsultationService();
  final TestingScanningService _testingService = TestingScanningService();

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  late Future<void> _dashboardFuture;

  String selectedMode = "today";

  int registered = 0;
  int pending = 0;
  int ongoing = 0;
  int completed = 0;
  int cancel = 0;

  int overallRegistered = 0;
  int overallPending = 0;
  int overallOngoing = 0;
  int overallCompleted = 0;
  int overallCancel = 0;

  int testPending = 0;
  int testOngoing = 0;
  int testCompleted = 0;
  int testCancel = 0;

  int overallTestPending = 0;
  int overallTestOngoing = 0;
  int overallTestCompleted = 0;
  int overallTestCancel = 0;

  bool isRetrying = false;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _dashboardFuture = _loadDashboardData();
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();

    hospitalName = prefs.getString('hospitalName') ?? "Unknown";
    hospitalPlace = prefs.getString('hospitalPlace') ?? "Unknown";
    hospitalPhoto =
        prefs.getString('hospitalPhoto') ??
        "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    setState(() {});
  }

  bool isToday(String? dateString) {
    if (dateString == null || dateString.isEmpty) return false;
    try {
      final formatter = DateFormat('yyyy-MM-dd hh:mm a');
      final date = formatter.parse(dateString);
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadDashboardData() async {
    final consultation = await _consultationService.getAllConsultations();
    final testingAndScanning = await _testingService
        .getAllTestingAndScanningData();

    final todayConsultations = consultation
        .where((c) => isToday(c['createdAt']))
        .toList();
    //print('todayConsultations $todayConsultations');
    final todayTesting = testingAndScanning
        .where((t) => isToday(t['createdAt']))
        .toList();

    _countConsultations(todayConsultations);
    _countTesting(todayTesting);

    _countOverallConsultations(consultation);
    _countOverallTesting(testingAndScanning);
  }

  // TODAY Counters
  void _countConsultations(List<dynamic> data) {
    registered = data.length;

    pending = data
        .where((c) => c['status'].toString().toLowerCase() == 'pending')
        .length;

    ongoing = data.where((c) {
      final status = c['status'].toString().toLowerCase();
      return status == 'ongoing' || status == 'endprocessing';
    }).length;

    completed = data
        .where((c) => c['status'].toString().toLowerCase() == 'completed')
        .length;
    cancel = data
        .where((c) => c['status'].toString().toLowerCase() == 'cancelled')
        .length;
  }

  void _countTesting(List<dynamic> data) {
    testPending = data
        .where(
          (t) =>
              t['status'].toString().toLowerCase() == 'pending' &&
              t['paymentStatus'] == true,
        )
        .length;

    testOngoing = data
        .where(
          (t) =>
              t['status'].toString().toLowerCase() == 'ongoing' ||
              t['status'].toString().toLowerCase() == 'endprocessing',
        )
        .length;
    testCompleted = data
        .where((t) => t['status'].toString().toLowerCase() == 'completed')
        .length;
    testCancel = data
        .where((t) => t['status'].toString().toLowerCase() == 'cancelled')
        .length;
  }

  // OVERALL Counters
  void _countOverallConsultations(List<dynamic> data) {
    overallRegistered = data.length;

    overallPending = data
        .where((c) => c['status'].toString().toLowerCase() == 'pending')
        .length;

    overallOngoing = data.where((c) {
      final status = c['status'].toString().toLowerCase();
      return status == 'ongoing' || status == 'endprocessing';
    }).length;

    overallCompleted = data
        .where((c) => c['status'].toString().toLowerCase() == 'completed')
        .length;

    overallCancel = data
        .where((c) => c['status'].toString().toLowerCase() == 'cancelled')
        .length;
  }

  void _countOverallTesting(List<dynamic> data) {
    overallTestPending = data
        .where(
          (t) =>
              t['status'].toString().toLowerCase() == 'pending' &&
              t['paymentStatus'] == true,
        )
        .length;

    overallTestOngoing = data
        .where(
          (t) =>
              t['status'].toString().toLowerCase() == 'ongoing' ||
              t['status'].toString().toLowerCase() == 'endprocessing',
        )
        .length;

    overallTestCompleted = data
        .where((t) => t['status'].toString().toLowerCase() == 'completed')
        .length;

    overallTestCancel = data
        .where((t) => t['status'].toString().toLowerCase() == 'cancelled')
        .length;
  }

  // ----------------------------------------------------------------------
  // UI SECTION
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<void>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          // ---------------------------------------------------
          // NETWORK ERROR / SERVER ERROR UI
          // ---------------------------------------------------
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.redAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Network Error",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // -------------------------
                  // TRY AGAIN BUTTON WITH LOADING
                  // -------------------------
                  ElevatedButton(
                    onPressed: isRetrying
                        ? null
                        : () async {
                            setState(() => isRetrying = true);

                            try {
                              await _loadDashboardData();
                              setState(() {
                                _dashboardFuture = _loadDashboardData();
                              });
                            } finally {
                              setState(() => isRetrying = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isRetrying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Try Again",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            );
          }

          // ---------------------------------------------------
          // LOADING
          // ---------------------------------------------------
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ---------------------------------------------------
          // SUCCESS UI
          // ---------------------------------------------------
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardFuture = _loadDashboardData();
              });
              await _dashboardFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHospitalCard(),
                  const SizedBox(height: 22),

                  _modeButtons(),
                  const SizedBox(height: 20),

                  _buildSectionTitle(
                    selectedMode == "today"
                        ? "Consultations (Today)"
                        : "Consultations (Overall)",
                  ),

                  const SizedBox(height: 12),

                  _buildGrid([
                    _buildMetricCard(
                      "Registered",
                      selectedMode == "today"
                          ? "$registered"
                          : "$overallRegistered",
                      Icons.person_add_alt_1_rounded,
                    ),

                    _buildMetricCard(
                      "Waiting",

                      selectedMode == "today" ? "$pending" : "$overallPending",
                      Icons.pending_actions_outlined,
                    ),
                    _buildMetricCard(
                      "Consulting",
                      selectedMode == "today" ? "$ongoing" : "$overallOngoing",
                      Icons.timelapse_rounded,
                    ),
                    _buildMetricCard(
                      "Completed",
                      selectedMode == "today"
                          ? "$completed"
                          : "$overallCompleted",
                      Icons.verified_outlined,
                    ),
                    _buildMetricCard(
                      "Cancelled",
                      selectedMode == "today" ? "$cancel" : "$overallCancel",
                      Icons.cancel_outlined,
                    ),
                  ]),

                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    selectedMode == "today"
                        ? "Testing & Scanning (Today)"
                        : "Testing & Scanning (Overall)",
                  ),

                  const SizedBox(height: 12),

                  _buildGrid([
                    _buildMetricCard(
                      "Waiting",

                      selectedMode == "today"
                          ? "$testPending"
                          : "$overallTestPending",
                      Icons.science_outlined,
                    ),
                    _buildMetricCard(
                      "Consulting",

                      selectedMode == "today"
                          ? "$testOngoing"
                          : "$overallTestOngoing",
                      Icons.biotech_rounded,
                    ),
                    _buildMetricCard(
                      "Completed",
                      selectedMode == "today"
                          ? "$testCompleted"
                          : "$overallTestCompleted",
                      Icons.check_circle_outline_rounded,
                    ),
                    _buildMetricCard(
                      "Cancelled",
                      selectedMode == "today"
                          ? "$testCancel"
                          : "$overallTestCancel",
                      Icons.check_circle_outline_rounded,
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- UI Helpers ----------------

  Widget _modeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _modeButton("today", "Today"),
        const SizedBox(width: 10),
        _modeButton("overall", "Overall"),
      ],
    );
  }

  Widget _modeButton(String mode, String label) {
    final bool isActive = selectedMode == mode;

    return GestureDetector(
      onTap: () => setState(() => selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? customGold : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: customGold, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : customGold,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                hospitalPhoto ?? "",
                height: 65,
                width: 65,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.local_hospital,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospitalName ?? "Unknown Hospital",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hospitalPlace ?? "Unknown Place",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(width: 8),
      Text(title, style: sectionTitleStyle),
    ],
  );

  Widget _buildGrid(List<Widget> cards) => GridView.count(
    crossAxisCount: MediaQuery.sizeOf(context).width > 800
        ? 5
        : MediaQuery.sizeOf(context).width > 650
        ? 4
        : MediaQuery.sizeOf(context).width > 500
        ? 3
        : 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.25,
    children: cards,
  );

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 5),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: customGold, size: 28),
              const SizedBox(width: 8),
              Text(
                title,
                style: cardTitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: cardValueStyle),
        ],
      ),
    );
  }
}
