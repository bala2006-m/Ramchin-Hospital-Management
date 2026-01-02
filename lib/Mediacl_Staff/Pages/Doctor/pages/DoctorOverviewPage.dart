import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Services/consultation_service.dart';

const Color customGold = Color(0xFFBF955E);
const Color backgroundColor = Color(0xFFFFF7E6);
const Color cardColor = Colors.white;

const TextStyle cardTitleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle cardValueStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

class DrOverviewPage extends StatefulWidget {
  const DrOverviewPage({super.key});

  @override
  State<DrOverviewPage> createState() => _DrOverviewPageState();
}

class _DrOverviewPageState extends State<DrOverviewPage> {
  final ConsultationService _consultationService = ConsultationService();
  late Future<void> _dashboardFuture;

  String? doctorId;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  int pending = 0, ongoing = 0, completed = 0, cancel = 0, reg = 0;
  int tPending = 0, tOngoing = 0, tCompleted = 0, tCancel = 0, treg = 0;

  bool showToday = false;
  bool isRetrying = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  // ───────────────────── LOAD DATA ─────────────────────
  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    doctorId = prefs.getString('userId');

    hospitalName = prefs.getString('hospitalName') ?? "Unknown";
    hospitalPlace = prefs.getString('hospitalPlace') ?? "Unknown";
    hospitalPhoto =
        prefs.getString('hospitalPhoto') ??
        "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";

    final consultations = await _consultationService.getAllConsultations();

    final myConsultations = consultations
        .where((c) => c['doctor_Id'].toString() == doctorId)
        .toList();

    _countOverall(myConsultations);
    _countToday(myConsultations);
  }

  void _countOverall(List<dynamic> list) {
    pending = list.where((c) => c['status'].toLowerCase() == 'pending').length;
    ongoing = list
        .where(
          (c) =>
              ['ongoing', 'endprocessing'].contains(c['status'].toLowerCase()),
        )
        .length;
    completed = list
        .where((c) => c['status'].toLowerCase() == 'completed')
        .length;
    cancel = list.where((c) => c['status'].toLowerCase() == 'cancelled').length;
    reg = list.length;
  }

  void _countToday(List<dynamic> list) {
    final now = DateTime.now();

    final today = list.where((c) {
      if (c['createdAt'] == null) return false;

      DateTime? d;
      try {
        d = DateFormat('yyyy-MM-dd hh:mm a').parse(c['createdAt']);
      } catch (_) {
        return false;
      }

      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();

    tPending = today
        .where((c) => c['status'].toLowerCase() == 'pending')
        .length;
    tOngoing = today
        .where(
          (c) =>
              ['ongoing', 'endprocessing'].contains(c['status'].toLowerCase()),
        )
        .length;
    tCompleted = today
        .where((c) => c['status'].toLowerCase() == 'completed')
        .length;
    tCancel = today
        .where((c) => c['status'].toLowerCase() == 'cancelled')
        .length;
    treg = today.length;
  }

  // ───────────────────── UI ─────────────────────
  @override
  Widget build(BuildContext context) {
    print(hospitalPhoto);
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) return _buildErrorUI();

          return RefreshIndicator(
            onRefresh: () async {
              await _loadDashboardData();
              setState(() {});
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHospitalCard(),
                  const SizedBox(height: 20),

                  // ✅ RESPONSIVE FILTER BUTTONS
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      _filterButton("Today", showToday, () {
                        setState(() => showToday = true);
                      }),
                      _filterButton("Overall", !showToday, () {
                        setState(() => showToday = false);
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Assigned Patients Summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // ✅ RESPONSIVE GRID
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      int columns = width >= 1200
                          ? 5
                          : width >= 900
                          ? 4
                          : width >= 600
                          ? 3
                          : 2;

                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: [
                          _buildMetricCard(
                            "Registered",
                            "${showToday ? treg : reg}",
                            Icons.app_registration,
                          ),
                          _buildMetricCard(
                            "Waiting",
                            "${showToday ? tPending : pending}",
                            Icons.pending_actions,
                          ),
                          _buildMetricCard(
                            "Consulting",
                            "${showToday ? tOngoing : ongoing}",
                            Icons.timelapse,
                          ),
                          _buildMetricCard(
                            "Completed",
                            "${showToday ? tCompleted : completed}",
                            Icons.verified_outlined,
                          ),
                          _buildMetricCard(
                            "Canceled",
                            "${showToday ? tCancel : cancel}",
                            Icons.cancel_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────── ERROR UI ─────────────────────
  Widget _buildErrorUI() {
    return const Center(child: Text("Network Error"));
  }

  // ───────────────────── HOSPITAL CARD ─────────────────────
  Widget _buildHospitalCard() {
    final photoUrl = hospitalPhoto;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: photoUrl == null || photoUrl.isEmpty
                ? _buildPlaceholderAvatar()
                : Image.network(
                    photoUrl,
                    height: 65,
                    width: 65,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderAvatar(),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  hospitalPlace ?? "",
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      height: 65,
      width: 65,
      decoration: const BoxDecoration(
        color: Colors.white24,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.local_hospital, color: Colors.white),
    );
  }

  // ───────────────────── FILTER BUTTON ─────────────────────
  Widget _filterButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: active ? customGold : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: customGold),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : customGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min, // ⭐ IMPORTANT
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: customGold),
              const SizedBox(width: 10),
              Text(
                title,
                style: cardTitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: cardValueStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
