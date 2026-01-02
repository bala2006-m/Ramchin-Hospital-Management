import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../../../../Pages/NotificationsPage.dart';

String formatDob(String? dob) {
  if (dob == null || dob.isEmpty) return 'N/A';
  try {
    return DateFormat('dd-MM-yyyy').format(DateTime.parse(dob));
  } catch (_) {
    return dob;
  }
}

String calculateAge(String? dob) {
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

PreferredSize buildAppbar({required BuildContext context}) {
  return PreferredSize(
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
                " CT-Scan",
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
                    MaterialPageRoute(builder: (_) => const NotificationPage()),
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
  );
}

// 🧍 PATIENT CARD
Widget buildPatientCard({
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
  required VoidCallback togglePatientExpand,
  required Animation<double> patientExpandAnimation,
  required bool isPatientExpanded,
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: togglePatientExpand,
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
                      isPatientExpanded ? "Hide" : "View All",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      isPatientExpanded ? Icons.expand_less : Icons.expand_more,
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
        const SizedBox(height: 2),
        Divider(color: Colors.grey.shade300),
        infoRow("Patient ID", id),
        infoRow("Cell No", phone),
        infoRow("Address", address),
        // Expandable Section
        SizeTransition(
          sizeFactor: patientExpandAnimation,
          axisAlignment: -1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 30, color: Colors.grey),
              sectionHeader("Patient Information"),
              const SizedBox(height: 8),
              infoRow("DOB", dob),
              infoRow("Age", age),
              infoRow("Gender", gender),
              infoRow("Blood Type", bloodGroup),
              infoRow("Created At", createdAt),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget sectionHeader(String text) {
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

Widget infoRow(String label, String value) {
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
