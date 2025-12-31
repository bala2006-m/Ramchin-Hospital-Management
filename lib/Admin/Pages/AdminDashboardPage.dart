import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health_icons/health_icons.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Mediacl_Staff/Pages/Doctor/pages/DrOpDashboard/DrInPatientQueuePage.dart';
import '../../Mediacl_Staff/Pages/Doctor/pages/DrOpDashboard/DrOutPatientQueuePage.dart';
import '../../Mediacl_Staff/Pages/Medical/MedicalQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Page/GynPage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/patient_registration/PatientRegistrationPage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/AbdomenQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/CtScanQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/DopplerQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/ECHOQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/EcgQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/EegQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/FeesQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/GynQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/InjectionQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/LabQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/MriScanQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/OpQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/OpstetricsQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/PetScanQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/SymptomsQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/UltersoundQueuePage.dart';
import '../../Mediacl_Staff/Pages/OutPatient/Queue/X-RayQueuePage.dart';
import '../../Services/admin_service.dart';
import 'Accounts/AccountsDrawerPage.dart';
import 'Accounts/ExpensePage.dart';
import 'Accounts/FinancePage.dart';
import 'Accounts/IncomeExpensePage.dart';

class AdminOpDashboardPage extends StatefulWidget {
  const AdminOpDashboardPage({super.key});

  @override
  State<AdminOpDashboardPage> createState() => _AdminOpDashboardPageState();
}

class _AdminOpDashboardPageState extends State<AdminOpDashboardPage> {
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  String currentDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
  List<int> doctorPermissionIds = [];
  bool accessDoctorRole = false;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _loadDrOpData();
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('hospitalName');
    final place = prefs.getString('hospitalPlace');
    final photo = prefs.getString('hospitalPhoto');

    setState(() {
      hospitalName = name ?? "Unknown Hospital";
      hospitalPlace = place ?? "Unknown Place";
      hospitalPhoto =
          photo ??
          "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    });
  }

  Future<void> _loadDrOpData() async {
    final profile = await AdminService().getProfile();
    final List<dynamic> perms = profile?['permissions'] ?? [];
    //final bool accessDoctorRole = profile?['accessDoctorRole'] ?? false;

    //if (accessDoctorRole == true)
    setState(() {
      doctorPermissionIds = perms.map<int>((e) => e as int).toList();
    });

    print("Cashier Permissions Loaded: $doctorPermissionIds");
  }
  // Future<void> _loadDrOpData() async {
  //   final profile = await AdminService().getProfile();
  //   final List<dynamic> perms = profile?['permissions'] ?? [];
  //   final bool hasDoctorAccess = profile?['accessDoctorRole'] ?? false;
  //
  //   setState(() {
  //     accessDoctorRole = hasDoctorAccess;
  //
  //     if (hasDoctorAccess) {
  //       doctorPermissionIds = perms.map<int>((e) => e as int).toList();
  //     } else {
  //       doctorPermissionIds.clear();
  //     }
  //   });
  //
  //   print("Cashier Permissions Loaded: $doctorPermissionIds");
  //   print("Doctor Access: $accessDoctorRole");
  // }

  Future<void> _onRefresh() async {
    await _loadHospitalInfo();
    await _loadDrOpData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let gradient show through
      body: Container(
        height: double.infinity,
        width: double.infinity,
        // 🌈 Full-screen gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF7E6), Color(0xFFFFF7E6)],

            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          // 👇 Single scroll for the whole screen
          child: RefreshIndicator(
            color: const Color(0xFFBF955E), // optional (gold color)
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                //     child: SingleChildScrollView(
                // physics: const BouncingScrollPhysics(),
                // padding: const EdgeInsets.all(16.0),
                // child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHospitalCard(),
                  const SizedBox(height: 16),

                  // 📅 Date Tag
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFBF955E),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        currentDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  if (doctorPermissionIds.contains(6) ||
                      doctorPermissionIds.contains(8)) ...[
                    //const SizedBox(height: 25),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      color: Colors.white.withValues(alpha: 0.95),
                      elevation: 8,
                      shadowColor: Colors.black26,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 30,
                          horizontal: 20,
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Text(
                                'DOCTOR DESK',
                                style: TextStyle(
                                  color: Color(0xFF886638),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            if (!doctorPermissionIds.contains(6) &&
                                !doctorPermissionIds.contains(8))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.red.shade300,
                                    width: 1.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "You don't have permission",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (doctorPermissionIds.contains(6) ||
                                doctorPermissionIds.contains(8))
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (doctorPermissionIds.contains(6))
                                    _buildActionItem(
                                      Icons.person,
                                      "Outpatient",
                                      () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DrOutPatientQueuePage(
                                                  role: 'doctor',
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  if (doctorPermissionIds.contains(8))
                                    _buildActionItem(
                                      Icons.person,
                                      "InPatient",
                                      () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const DrInPatientQueuePage(),
                                          ),
                                        );
                                      },
                                    ),
                                  // _buildActionItem(
                                  //   Icons.report,
                                  //   "Failed Payments",
                                  //   () {},
                                  // ),
                                ],
                              ),
                            const SizedBox(height: 25),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 25),
                  // 📋 Action Section Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    color: Colors.white.withValues(alpha: 0.95),
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              'PRELIMINARY DESK',
                              style: TextStyle(
                                color: Color(0xFF886638),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(
                                Icons.person_add,
                                "Register",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PatientRegistrationPage(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionItem(Icons.healing, "Vitals", () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SymptomsQueuePage(),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(Icons.queue, "Queue", () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OutpatientQueuePage(),
                                  ),
                                );
                              }),
                              _buildActionItem(Icons.vaccines, "Injection", () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const InjectionQueuePage(),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    color: Colors.white.withValues(alpha: 0.95),
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              'CASHIER DESK',
                              style: TextStyle(
                                color: Color(0xFF886638),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(
                                Icons.currency_rupee,
                                "Payment",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FeesQueuePage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    color: Colors.white.withValues(alpha: 0.95),
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              'ACCOUNTS',
                              style: TextStyle(
                                color: Color(0xFF886638),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(Icons.money, "Income", () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AccountIncomePage(),
                                  ),
                                );
                              }),
                              _buildActionItem(Icons.healing, "Expense", () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AccountExpensePage(),
                                  ),
                                );
                              }),
                              _buildActionItem(
                                Icons.drive_folder_upload_rounded,
                                "Drawing",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AccountDrawerPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(Icons.bar_chart, "Finance", () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FinancePage(),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📋 Action Section Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    color: Colors.white.withValues(alpha: 0.95),
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              'SCANNING',
                              style: TextStyle(
                                color: Color(0xFF886638),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(
                                HealthIcons.xrayFilled,
                                "X-Ray",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const XRayQueuePage(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionItem(
                                FontAwesomeIcons.brain, // MRI best match
                                "MRI-Scan",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MriScanQueuePage(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionItem(
                                FontAwesomeIcons.bone,
                                "CT-Scan",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CtScanQueuePage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(
                                HealthIcons.ecmoFilled, // ECG
                                "ECG",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EcgQueuePage(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionItem(
                                HealthIcons
                                    .radiologyFilled, // PET Scan close match
                                "PET-Scan",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PetScanQueuePage(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionItem(
                                FontAwesomeIcons.brain, // EEG (brain waves)
                                "EEG",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EegQueuePage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(
                                HealthIcons.xrayFilled,
                                "ABDOMEN",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AbdomenQueuePage(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionItem(
                                FontAwesomeIcons.brain, // MRI best match
                                "GYN",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const GynQueuePage(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionItem(
                                FontAwesomeIcons.bone,
                                "DOPPLER",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DopplerQueuePage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(
                                HealthIcons
                                    .ultrasoundScannerFilled, // Ultrasound
                                "OBSTETRICS",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ObstetricsQueuePage(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionItem(
                                HealthIcons
                                    .ultrasoundScannerFilled, // Ultrasound
                                "ECHO",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EchoQueuePage(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionItem(
                                HealthIcons
                                    .ultrasoundScannerFilled, // Ultrasound
                                "HF UltraSound",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const UltrasoundQueuePage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          //   children: [
                          //     _buildActionItem(
                          //       HealthIcons
                          //           .ultrasoundScannerFilled, // Ultrasound
                          //       "OBSTETRICS",
                          //       () {
                          //         Navigator.push(
                          //           context,
                          //           MaterialPageRoute(
                          //             builder: (_) =>
                          //                 const UltersoundQueuePage(),
                          //           ),
                          //         );
                          //       },
                          //     ),
                          //     // _buildActionItem(
                          //     //   HealthIcons
                          //     //       .ultrasoundScannerFilled, // Ultrasound
                          //     //   "HF UltraSound",
                          //     //   () {
                          //     //     Navigator.push(
                          //     //       context,
                          //     //       MaterialPageRoute(
                          //     //         builder: (_) =>
                          //     //             const UltersoundQueuePage(),
                          //     //       ),
                          //     //     );
                          //     //   },
                          //     // ),
                          //     // _buildActionItem(
                          //     //   HealthIcons
                          //     //       .ultrasoundScannerFilled, // Ultrasound
                          //     //   "UltraSound",
                          //     //   () {
                          //     //     Navigator.push(
                          //     //       context,
                          //     //       MaterialPageRoute(
                          //     //         builder: (_) =>
                          //     //             const UltersoundQueuePage(),
                          //     //       ),
                          //     //     );
                          //     //   },
                          //     // ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    color: Colors.white.withValues(alpha: 0.95),
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              'TESTING',
                              style: TextStyle(
                                color: Color(0xFF886638),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(
                                Icons.science_rounded,
                                "Lab",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LabQueuePage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    color: Colors.white.withValues(alpha: 0.95),
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              'Medical Desk',
                              style: TextStyle(
                                color: Color(0xFF886638),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(
                                Icons.medical_services,
                                "Medical",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MedicalQueuePage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFEDBA77),
            Color(0xFFC59A62),
            // Color(0xFFEDBA77),
          ], //customGold.withValues(alpha:0.8)
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

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 70,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),

              // ★ FULL COLOR GRADIENT BACKGROUND
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFCECCF), // soft gold top
                  const Color(0xFFF6D8A8), // deeper gold bottom
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

              // ★ Clean gold border
              border: Border.all(color: const Color(0xFFBF955E), width: 1.4),

              // ★ Smooth depth shadow
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: Center(
              child: Icon(
                icon,
                color: const Color(0xFF8B6C3A), // deep gold icon color
                size: 34,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
