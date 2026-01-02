// Future<void> _checkUserExists(String userId) async {
//   setState(() => isCheckingUser = true);
//
//   try {
//     final exists = await patientService.checkUserIdExists(userId);
//     lastCheckedUserId = userId;
//
//     if (exists == true) {
//       final patients = await patientService.getPatientById(userId);
//
//       if (patients.isNotEmpty) {
//         setState(() {
//           familyPatients = patients;
//           isExistingUser = true;
//           isAddingNewChild = false;
//         });
//
//         _showSnackBar('Family members found');
//       } else {
//         setState(() {
//           familyPatients = [];
//           isExistingUser = false;
//           isAddingNewChild = true;
//         });
//
//         _showSnackBar('New patient registration');
//       }
//
//       print('✅ Patient fetched: $fetched');
//
//       // ✅ Check if the patient already has ongoing consultation(s)
//       final consultations = fetched['Consultation'] as List<dynamic>? ?? [];
//       final hasOngoing = consultations.any((c) {
//         final status = c['status']?.toString().toUpperCase() ?? '';
//         return status != 'COMPLETED';
//       });
//
//       if (hasOngoing) {
//         // 🚫 Patient already has an active consultation
//         setState(() {
//           isExistingUser = true;
//           existingPatient = fetched;
//         });
//
//         _showSnackBar(
//           'Your consultation is already ongoing. Please complete it before creating a new one.',
//         );
//         return; // Stop here — don’t populate form further or allow submit
//       }
//
//       // ✅ No active consultations — safe to continue
//       setState(() {
//         isExistingUser = true;
//         existingPatient = fetched;
//
//         _ignorePhoneListener = true; // 🚫 stop triggering listener
//         phoneController.text = '+91 ${fetched['user_Id']}';
//         _ignorePhoneListener = false; // ✅ re-enable it
//
//         fullNameController.text = fetched['name'] ?? '';
//         AddressController.text =
//             fetched['address']?['Address'] ?? fetched['address'] ?? '';
//         dobController.text = fetched['dob'] != null
//             ? DateFormat(
//                 'yyyy-MM-dd',
//               ).format(DateTime.parse(fetched['dob']).toLocal())
//             : '';
//         selectedGender = fetched['gender'];
//         selectedBloodType = fetched['bldGrp'];
//         emailController.text = fetched['email']?['personal'] ?? '';
//         guardianEmailController.text = fetched['email']?['guardian'] ?? '';
//
//         // Compute age
//         if (fetched['dob'] != null) {
//           final dob = DateTime.parse(fetched['dob']);
//           final today = DateTime.now();
//           final age =
//               today.year -
//               dob.year -
//               ((today.month < dob.month ||
//                       (today.month == dob.month && today.day < dob.day))
//                   ? 1
//                   : 0);
//           ageController.text = age.toString();
//         }
//       });
//
//       _showSnackBar('Existing patient found.');
//     } else {
//       // 🆕 New patient registration
//       setState(() {
//         isExistingUser = false;
//         existingPatient = null;
//
//         fullNameController.clear();
//         AddressController.clear();
//         dobController.clear();
//         emailController.clear();
//         guardianEmailController.clear();
//         ageController.clear();
//         selectedGender = null;
//         selectedBloodType = null;
//
//         _ignorePhoneListener = true;
//         phoneController.text = '+91 $userId';
//         _ignorePhoneListener = false;
//       });
//
//       _showSnackBar('New patient registration.');
//     }
//   } catch (e) {
//     print('❌ Error fetching patient: $e');
//     _showSnackBar('Error: $e');
//   } finally {
//     if (mounted) setState(() => isCheckingUser = false);
//   }
// }

// Future<void> _checkUserExists(String userId) async {
//   setState(() {
//     isCheckingUser = true;
//
//     // 🔹 CLEAR OLD DATA IMMEDIATELY
//     familyPatients = [];
//     existingPatient = null;
//     isExistingUser = false;
//     isAddingNewChild = false;
//   });
//
//   try {
//     // 🔹 Try fetching patient
//     final Map<String, dynamic>? patient = await patientService.getPatientById(
//       userId,
//     );
//
//     // 🔹 If API returns null / empty → new patient
//     if (patient == null || patient.isEmpty) {
//       _prepareNewPatient(userId);
//       return;
//     }
//
//     // 🔹 Convert single patient → list (temporary solution)
//     final List<Map<String, dynamic>> patients = [patient];
//
//     lastCheckedUserId = userId;
//
//     setState(() {
//       familyPatients = patients;
//       isExistingUser = true;
//       isAddingNewChild = false;
//     });
//
//     _showSnackBar('Patient found. Select patient or add new.');
//   } catch (e) {
//     // 🔹 IMPORTANT: treat error as NEW PATIENT
//     print('ℹ️ No patient found for this number');
//
//     _prepareNewPatient(userId);
//   } finally {
//     if (mounted) {
//       setState(() => isCheckingUser = false);
//     }
//   }
// }

// Future<void> _fetchDoctors() async {
//   setState(() => isLoadingDoctors = true);
//   try {
//     final docs = await doctorService.getDoctors();
//     setState(() {
//       allDoctors = docs;
//       filteredDoctors = List.from(docs); // show all by default
//       showDoctorSection = true; // always show doctor list
//     });
//   } catch (e) {
//     _showSnackBar('Error loading doctors: $e');
//   } finally {
//     setState(() => isLoadingDoctors = false);
//   }
// }

// =======
//       if (exists == true) {
//         final fetched = await patientService.getPatientById(userId);
//         print('✅ Patient fetched: $fetched');

//         // ✅ Check if the patient already has ongoing consultation(s)
//         final consultations = fetched['Consultation'] as List<dynamic>? ?? [];
//         final hasOngoing = consultations.any((c) {
//           final status = c['status']?.toString().toUpperCase() ?? '';
//           return status != 'COMPLETED';
//         });

//         if (hasOngoing) {
//           // 🚫 Patient already has an active consultation
//           setState(() {
//             isExistingUser = true;
//             existingPatient = fetched;
//           });

//           _showSnackBar(
//             'Your consultation is already ongoing. Please complete it before creating a new one.',
//           );
//           return; // Stop here — don’t populate form further or allow submit
//         }

//         // ✅ No active consultations — safe to continue
//         setState(() {
//           isExistingUser = true;
//           existingPatient = fetched;

//           _ignorePhoneListener = true; // 🚫 stop triggering listener
//           phoneController.text = '+91 ${fetched['user_Id']}';
//           _ignorePhoneListener = false; // ✅ re-enable it

//           fullNameController.text = fetched['name'] ?? '';
//           AddressController.text =
//               fetched['address']?['Address'] ?? fetched['address'] ?? '';
//           dobController.text = fetched['dob'] != null
//               ? DateFormat(
//                   'yyyy-MM-dd',
//                 ).format(DateTime.parse(fetched['dob']).toLocal())
//               : '';
//           selectedGender = fetched['gender'];
//           selectedBloodType = fetched['bldGrp'];
//           emailController.text = fetched['email']?['personal'] ?? '';
//           guardianEmailController.text = fetched['email']?['guardian'] ?? '';

//           // Compute age
//           if (fetched['dob'] != null) {
//             final dob = DateTime.parse(fetched['dob']);
//             final today = DateTime.now();
//             final age =
//                 today.year -
//                 dob.year -
//                 ((today.month < dob.month ||
//                         (today.month == dob.month && today.day < dob.day))
//                     ? 1
//                     : 0);
//             ageController.text = age.toString();
//           }
//         });

//         _showSnackBar('Existing patient found.');
//       } else {
//         // 🆕 New patient registration
//         setState(() {
//           isExistingUser = false;
//           existingPatient = null;

//           fullNameController.clear();
//           AddressController.clear();
//           dobController.clear();
//           emailController.clear();
//           guardianEmailController.clear();
//           ageController.clear();
//           selectedGender = null;
//           selectedBloodType = null;

//           _ignorePhoneListener = true;
//           phoneController.text = '+91 $userId';
//           _ignorePhoneListener = false;
//         });

//         _showSnackBar('New patient registration.');
// >>>>>>> 3f063fbf1fae91f45feca0bca76a410ab6083f20
// Widget _buildInput(
//   String label,
//   TextEditingController controller, {
//   int maxLines = 1,
//   String? hint,
//   String? errorText,
//   TextInputType keyboardType = TextInputType.text,
//   void Function(String)? onChanged,
//   List<TextInputFormatter>? inputFormatters,
//   Widget? suffix, // 👈 added this line
// }) {
//   return SizedBox(
//     width: 320,
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 6),
//         TextField(
//           cursorColor: customGold,
//           controller: controller,
//           maxLines: maxLines,
//           keyboardType: keyboardType,
//           onChanged: onChanged,
//           inputFormatters: inputFormatters,
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: Colors.grey[50],
//             hintText: hint,
//             hintStyle: TextStyle(color: Colors.grey[400]),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 13,
//             ),
//             suffixIcon:
//                 suffix, // 👈 this allows us to show the loader or icon
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(
//                 color: errorText != null ? Colors.red : Colors.grey.shade300,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(
//                 color: errorText != null ? Colors.red : customGold,
//                 width: 1.5,
//               ),
//             ),
//             errorText: errorText,
//             errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
//           ),
//           style: const TextStyle(fontSize: 15),
//         ),
//       ],
//     ),
//   );
// }
