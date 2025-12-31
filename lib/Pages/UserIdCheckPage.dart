import 'package:flutter/material.dart';

import '../Mediacl_Staff/Pages/OutPatient/patient_registration/PatientRegistrationPage.dart';
import '../Services/patient_service.dart';
import 'DrawerPages/ReceptionDeskPage.dart';

const Color customGold = Color(0xFFBF955E);
const Color backgroundColor = Color(0xFFF9F7F2);

class UserIdCheckPage extends StatefulWidget {
  const UserIdCheckPage({super.key});

  @override
  State<UserIdCheckPage> createState() => _UserIdCheckPageState();
}

class _UserIdCheckPageState extends State<UserIdCheckPage> {
  final TextEditingController _userIdController = TextEditingController();
  bool _isChecking = false;

  // Initialize PatientService with your API URL
  final PatientService patientService =
      PatientService(); // Replace with your API URL

  void _onCheckPressed() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter User ID')));
      return;
    }

    setState(() => _isChecking = true);

    try {
      // ✅ Check if user exists via backend
      final bool registered = await patientService.checkUserIdExists(userId);

      // Navigate based on existence
      final nextPage = registered
          ? ReceptionDeskPage(UserId: userId)
          : PatientRegistrationPage();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking User ID: $e')));
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAF3E0), Color(0xFFFFE8A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 80, color: customGold),
                  const SizedBox(height: 16),
                  const Text(
                    "Check User ID",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _userIdController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Enter your User ID',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _onCheckPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isChecking
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              'Check',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
}
