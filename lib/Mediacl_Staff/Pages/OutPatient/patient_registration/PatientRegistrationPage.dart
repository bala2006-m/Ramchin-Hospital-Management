import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../../../Services/Doctor/doctor_service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/fees_Service.dart';
import '../../../../Services/patient_service.dart';
import '../../../../Services/payment_service.dart';
import '../../../../Widgets/AgeDobField.dart';
import '../../../../Pages/NotificationsPage.dart';

const Color customGold = Color(0xFFBF955E);
const Color backgroundColor = Color(0xFFF9F7F2);

const List<String> genders = ['Male', 'Female', 'Other'];
const List<String> bloodTypes = [
  'O+',
  'A+',
  'B+',
  'O-',
  'A-',
  'AB+',
  'B-',
  'AB-',
  'Rhnull',
];

const List<String> currentProblemSuggestions = [
  'Fever with chills and body pain',
  'Abdominal pain with vomiting',
  'Cough and difficulty in breathing',
  'Chest pain and dizziness',
  'Headache and weakness',
  'High blood sugar',
  'Hypertension',
  'Acute injury/fracture',
  'Urinary infection symptoms',
  'Rashes on skin',
];

class IndianPhoneNumberFormatter extends TextInputFormatter {
  static const String prefix = '+91 ';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);
    if (digitsOnly.length > 10) digitsOnly = digitsOnly.substring(0, 10);

    final formatted = digitsOnly.isEmpty ? '' : '$prefix$digitsOnly';

    int cursorPosition = formatted.length;
    if (cursorPosition < prefix.length) cursorPosition = prefix.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

class PatientRegistrationPage extends StatefulWidget {
  const PatientRegistrationPage({super.key});
  @override
  State<PatientRegistrationPage> createState() =>
      _PatientRegistrationPageState();
}

class _PatientRegistrationPageState extends State<PatientRegistrationPage> {
  final PatientService patientService = PatientService();
  final doctorService = DoctorService();
  final consultationService = ConsultationService();
  final paymentService = PaymentService();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController AccompanierNameController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController guardianEmailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emergencyController = TextEditingController();
  final TextEditingController AddressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController doctorIdController = TextEditingController();
  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController ComplaintController = TextEditingController();
  final TextEditingController DataTimeController = TextEditingController();
  final TextEditingController currentProblemController =
      TextEditingController();
  final TextEditingController medicalHistoryController =
      TextEditingController();

  bool isSugarTestChecked = false;
  bool isEmergency = false;

  final TextEditingController sugarTestController = TextEditingController();

  String? _dateTime;
  String? selectedGender;
  String? selectedBloodType;
  bool showGuardianEmail = false;
  String? medicalHistoryChoice; // 'Yes' or 'No'
  bool isSubmitting = false;
  bool formValidated = false;
  bool phoneValid = true;
  bool emergencyValid = true;
  bool isLoadingDoctors = false;
  bool showDoctorSection = false;
  bool _ignorePhoneListener = false;
  List<Map<String, dynamic>> allDoctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  Map<String, dynamic>? selectedDoctor;
  List<String> filteredProblemSuggestions = [];
  List<Map<String, dynamic>> familyPatients = [];
  int? selectedPatientId; // auto-increment id
  bool isAddingNewChild = false;

  // New fields for checking/existing user
  bool isExistingUser = false;
  String? lastCheckedUserId;
  bool isCheckingUser = false;
  Map<String, dynamic>? existingPatient;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  void _showSnackBar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _fetchDoctors();
    currentProblemController.addListener(_filterCurrentProblemSuggestions);
    phoneController.addListener(_onPhoneControllerChanged);
    _updateTime();
    Timer.periodic(const Duration(seconds: 60), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    currentProblemController.removeListener(_filterCurrentProblemSuggestions);
    phoneController.removeListener(_onPhoneControllerChanged);
    super.dispose();
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

  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  void _filterCurrentProblemSuggestions() {
    String input = currentProblemController.text.toLowerCase();
    if (input.isEmpty) {
      setState(() => filteredProblemSuggestions = []);
      return;
    }
    final filtered = currentProblemSuggestions
        .where((suggestion) => suggestion.toLowerCase().startsWith(input))
        .toList();
    setState(() => filteredProblemSuggestions = filtered);
  }

  void _onPhoneChanged(String value, void Function(bool) setValidity) {
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);
    setValidity(digitsOnly.length == 10);
  }

  void _onPhoneControllerChanged() {
    if (_ignorePhoneListener) return; // 🚫 skip when updating programmatically

    final raw = phoneController.text;
    String digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);

    // Trigger API check when exactly 10 digits entered
    if (digitsOnly.length == 10) {
      final userId = digitsOnly;
      if (lastCheckedUserId != userId && !isCheckingUser) {
        _checkUserExists(userId);
      }
    } else {
      // Reset if user edits to <10 digits
      if (isExistingUser || existingPatient != null) {
        setState(() {
          isExistingUser = false;
          existingPatient = null;
          lastCheckedUserId = null;
          // Optional: clear other fields too
        });
      }
      setState(() => phoneValid = digitsOnly.length == 10);
    }
  }

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
  Future<void> _checkUserExists(String userId) async {
    setState(() {
      isCheckingUser = true;

      // 🔹 CLEAR OLD DATA IMMEDIATELY
      familyPatients = [];
      existingPatient = null;
      isExistingUser = false;
      isAddingNewChild = false;
    });

    try {
      // 🔹 Fetch patients list
      final List<Map<String, dynamic>> patients = await patientService
          .getPatientsByUserId(userId);

      if (patients.isEmpty) {
        _prepareNewPatient(userId);
        return;
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
      }

      if (patients.isEmpty) {
        _prepareNewPatient(userId);
        return;
      }

      lastCheckedUserId = userId;
      setState(() {
        familyPatients = patients;
        isExistingUser = true;
        isAddingNewChild = false;
      });

      _showSnackBar('Patients found. Select a patient or add new.');
    } catch (e) {
      print('ℹ️ No patient found for this number');
      _prepareNewPatient(userId);
    } finally {
      if (mounted) setState(() => isCheckingUser = false);
    }
  }

  void _selectExistingPatient(Map<String, dynamic> patient) {
    final consultations = patient['Consultation'] as List<dynamic>? ?? [];

    final hasOngoing = consultations.any((c) {
      final status = c['status']?.toString().toUpperCase() ?? '';
      return status != 'COMPLETED';
    });

    if (hasOngoing) {
      _showSnackBar('This patient already has an ongoing consultation.');
      return;
    }

    setState(() {
      existingPatient = patient;
      selectedPatientId = patient['id'];
      isAddingNewChild = false;

      fullNameController.text = patient['name'] ?? '';
      AddressController.text = patient['address']?['Address'] ?? '';
      dobController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(patient['dob']));
      selectedGender = patient['gender'];
      selectedBloodType = patient['bldGrp'];
      emailController.text = patient['email']?['personal'] ?? '';
      guardianEmailController.text = patient['email']?['guardian'] ?? '';
      ageController.text = _calculateAge(patient['dob']).toString();
    });
  }

  int _calculateAge(String dob) {
    final birth = DateTime.parse(dob);
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age;
  }

  void _prepareNewPatient(String userId) {
    setState(() {
      familyPatients = [];
      existingPatient = null;
      isExistingUser = false;
      isAddingNewChild = true;

      fullNameController.clear();
      AddressController.clear();
      dobController.clear();
      emailController.clear();
      guardianEmailController.clear();
      ageController.clear();
      selectedGender = null;
      selectedBloodType = null;

      _ignorePhoneListener = true;
      phoneController.text = '+91 $userId';
      _ignorePhoneListener = false;
    });

    _showSnackBar('New patient registration');
  }

  /// Fetch doctors from API

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

  Future<void> _fetchDoctors() async {
    setState(() => isLoadingDoctors = true);
    try {
      final docs = await doctorService.getDoctors();
      print('doctor $docs');
      // 🔹 Filter Active doctors only
      final activeDoctors = docs
          .where((doc) => doc['status'] == 'ACTIVE')
          .toList();

      setState(() {
        allDoctors = activeDoctors;
        filteredDoctors = List.from(activeDoctors);
        showDoctorSection = true;
      });
    } catch (e) {
      _showSnackBar('Error loading doctors: $e');
    } finally {
      setState(() => isLoadingDoctors = false);
    }
  }

  // Unified submit - behaves differently for new vs existing user
  void _submitPatient() async {
    setState(() {
      formValidated = true;

      String phoneDigits = phoneController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      if (phoneDigits.startsWith('91')) phoneDigits = phoneDigits.substring(2);
      phoneValid = phoneDigits.length == 10;
    });

    List<String> missingFields = [];
    if (fullNameController.text.trim().isEmpty) missingFields.add("Full Name");
    if (dobController.text.trim().isEmpty) missingFields.add("Date of Birth");
    if (!phoneValid) missingFields.add("Phone Number (must be 10 digits)");
    if (AddressController.text.trim().isEmpty) missingFields.add("Address");
    // if (ComplaintController.text.trim().isEmpty) {
    //   missingFields.add("Current Problem");
    // }
    if (selectedGender == null) missingFields.add("Gender");
    if (doctorIdController.text.isEmpty) {
      missingFields.add("Select Doctor");
    }

    if (missingFields.isNotEmpty) {
      String msg =
          "Please fill/complete the following required fields:\n• ${missingFields.join("\n• ")}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();

    setState(() => isSubmitting = true);
    try {
      // normalize phone to userId
      final cleanedMobile = phoneController.text.trim().replaceAll(
        RegExp(r'^\+?91[\s-]*'),
        '',
      );
      final userId = cleanedMobile;

      // Build patient data object
      DateTime dob =
          DateTime.tryParse(dobController.text) ?? DateTime(1990, 1, 1);

      if (selectedGender.toString().toLowerCase() == 'male') {
        fullNameController.text = 'MR. ${fullNameController.text.trim()}';
        setState(() {});
      }
      if (selectedGender.toString().toLowerCase() == 'female') {
        fullNameController.text = 'MS. ${fullNameController.text.trim()}';
        setState(() {});
      }

      final patientData = {
        "name": fullNameController.text,
        "ac_name": AccompanierNameController.text.trim(),
        "staff_Id": prefs.getString('userId'),
        "phone": {
          "mobile": phoneController.text.trim(),
          "emergency": emergencyController.text.trim(),
        },
        "email": {
          "personal": emailController.text.trim(),
          "guardian": guardianEmailController.text.trim(),
        },
        "address": {"Address": AddressController.text.trim()},
        "dob":
            '${(DateTime.parse(DateFormat('yyyy-MM-dd').format(dob))).toLocal().toIso8601String()}Z',
        "gender": selectedGender,
        "bldGrp": selectedBloodType,
        "currentProblem": currentProblemController.text.trim(),
        "createdAt": _dateTime.toString(),
        "tempCreatedAt": DateTime.now().toUtc().toIso8601String(),
      };

      // If existing user => update patient if changed, then create consultation
      if (isExistingUser) {
        // ✅ Step 1: Check existing consultations for ongoing ones
        final consultations =
            existingPatient?['Consultation'] as List<dynamic>? ?? [];

        final hasOngoing = consultations.any((c) {
          final status = c['status']?.toString().toUpperCase() ?? '';

          // not completed or endprocessed means it's still active
          return status != 'COMPLETED'; // && status != 'ENDPROCESSING'
        });

        if (hasOngoing) {
          _showSnackBar(
            'Your consultation is already ongoing. Please complete it before creating a new one.',
          );
          setState(() => isSubmitting = false);
          return; // 🚫 stop here — do NOT create new consultation
        }

        // ✅ Step 2: Proceed normally if no ongoing consultations exist
        try {
          await patientService.updatePatient(
            selectedPatientId.toString(),
            patientData,
          );
        } catch (e) {
          _showSnackBar('Failed to update patient: $e');
        }

        final hospitalId = await doctorService.getHospitalId();

        final result = await consultationService.createConsultation({
          "hospital_Id": hospitalId,
          "patient_Id": selectedPatientId,
          "doctor_Id": doctorIdController.text,
          "name": doctorNameController.text,
          "purpose": ComplaintController.text,
          "emergency": isEmergency,
          "sugarTest": isSugarTestChecked,
          "sugerTestQueue": isSugarTestChecked,
          "temperature": 0,
          "createdAt": _dateTime.toString(),
        });

        if (result['status'] == 'failed') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'])));
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New Appointment created')),
        );
        Navigator.pop(context, true);
      } else {
        // New user: create patient then create consultation
        final results = await patientService.createPatient(patientData);
        print('result $results');
        if (results['status'] == 'failed') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(results['message'])));
          return;
        }
        print('work');
        final PatientId = await results['data']['patient']['id'];
        //
        print('PatientId $PatientId');
        print('selectedPatientId $selectedPatientId');
        final hospitalId = await doctorService.getHospitalId();
        final result = await consultationService.createConsultation({
          "hospital_Id": hospitalId,
          "patient_Id": PatientId,
          "doctor_Id": doctorIdController.text,
          "name": doctorNameController.text,
          "purpose": ComplaintController.text,
          "emergency": isEmergency,
          "sugarTest": isSugarTestChecked,
          "sugerTestQueue": isSugarTestChecked,
          "temperature": 0,
          "createdAt": _dateTime.toString(),
        });

        if (result['status'] == 'failed') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'])));
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient registered and created Appointment')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Register Failed, set Register fees')),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _overviewAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHospitalCard(),
                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(2, 6),
                      ),
                    ],
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isEmergency
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isEmergency
                                ? Colors.red.shade400
                                : Colors.grey.shade300,
                            width: 1.2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              isEmergency = !isEmergency;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: Colors.red.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Emergency Case",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                              Switch(
                                value: isEmergency,
                                activeColor: Colors.red,
                                onChanged: (value) {
                                  setState(() {
                                    isEmergency = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      _buildInput(
                        "Cell No *",
                        phoneController,
                        hint: "+911234567890",
                        errorText: formValidatedErrorText(
                          formValidated: formValidated,
                          valid: phoneValid,
                          errMsg: 'Enter valid 10 digit number',
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (val) => _onPhoneChanged(
                          val,
                          (valid) => setState(() => phoneValid = valid),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          IndianPhoneNumberFormatter(),
                        ],
                        suffix: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: phoneController.text.isEmpty
                              ? const SizedBox.shrink(
                                  key: ValueKey('empty'),
                                ) // 👈 no icon when empty
                              : isCheckingUser
                              ? const SizedBox(
                                  key: ValueKey('loader'),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : (phoneValid
                                    ? Icon(
                                        isExistingUser
                                            ? Icons
                                                  .person // existing patient found
                                            : Icons
                                                  .check_circle, // new number valid
                                        color: isExistingUser
                                            ? Colors.orange
                                            : Colors.green,
                                        key: ValueKey('valid'),
                                      )
                                    : const SizedBox.shrink(
                                        key: ValueKey('no-valid'),
                                      )),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (familyPatients.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.lightBlue.shade50, Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.lightBlue.shade100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Header
                              Row(
                                children: [
                                  Icon(
                                    Icons.family_restroom,
                                    color: Colors.lightBlue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Family Members",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.lightBlue.shade700,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // 🔹 Family List
                              ...familyPatients.map((p) {
                                final bool isSelected =
                                    existingPatient != null &&
                                    existingPatient!['id'] == p['id'];

                                final String gender = (p['gender'] ?? '')
                                    .toString();
                                final int age = _calculateAge(p['dob']);

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.lightBlue.shade50
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.lightBlue.shade300
                                          : Colors.grey.shade200,
                                      width: isSelected ? 1.4 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.lightBlue.shade100
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _selectExistingPatient(p),
                                    child: Row(
                                      children: [
                                        // 🔹 Avatar
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              Colors.lightBlue.shade200,
                                          child: Text(
                                            (p['name'] ?? 'U')
                                                .toString()
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        // 🔹 Name + Meta
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p['name'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 8,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .orange
                                                          .shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "$age yrs",
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  if (gender.isNotEmpty)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            gender
                                                                    .toLowerCase() ==
                                                                'male'
                                                            ? Colors
                                                                  .blue
                                                                  .shade100
                                                            : Colors
                                                                  .pink
                                                                  .shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        gender,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 🔹 Selected Icon
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.lightBlue.shade600,
                                            size: 26,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 16),

                              // 🔹 Add New Patient Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.person_add_alt_1,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  label: const Text(
                                    "Add New Patient",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: lastCheckedUserId == null
                                      ? null
                                      : () => _prepareNewPatient(
                                          lastCheckedUserId!,
                                        ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: Colors.lightBlue.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      _buildInput(
                        "Name *",
                        fullNameController,
                        hint: "Enter full name",
                        inputFormatters: [UpperCaseTextFormatter()],
                      ),
                      AgeDobField(
                        dobController: dobController,
                        ageController: ageController,
                      ),
                      _sectionLabel("Gender *"),
                      Container(
                        width: 320,
                        margin: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: genders
                              .map(
                                (e) => _buildSelectionCard(
                                  label: e,
                                  selected: selectedGender == e,
                                  onTap: () =>
                                      setState(() => selectedGender = e),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      _sectionLabel("Blood Type ( optional )"),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: bloodTypes.map((type) {
                            final selected = selectedBloodType == type;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedBloodType = type),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected ? customGold : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? customGold
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    if (selected)
                                      const BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                  ],
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      _buildInput(
                        "Address *",
                        AddressController,
                        maxLines: 3,
                        hint: "Street address",
                        inputFormatters: [UpperCaseTextFormatter()],
                      ),
                      _buildInput(
                        "Chief Complaint (Optional)",
                        ComplaintController,
                        hint: "Enter complaint",
                        inputFormatters: [UpperCaseTextFormatter()],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSugarTestChecked
                              ? primaryColor.withValues(alpha: 0.08)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSugarTestChecked
                                ? primaryColor
                                : Colors.grey.shade300,
                            width: 1.2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              isSugarTestChecked = !isSugarTestChecked;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.opacity,
                                color: primaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Sugar Test",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              Switch(
                                value: isSugarTestChecked,
                                activeColor: primaryColor,
                                onChanged: (value) {
                                  setState(() {
                                    isSugarTestChecked = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      _sectionLabel(
                        isExistingUser
                            ? "Create Appointment"
                            : "Available Doctors *",
                      ),
                      if (showDoctorSection) ...[_buildDoctorList()],

                      // 🔹 Blood Type Section
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submitPatient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                    child: isSubmitting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            isExistingUser
                                ? "Create Appointment"
                                : "Register Patient",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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

  String? formValidatedErrorText({
    required bool formValidated,
    required bool valid,
    required String errMsg,
  }) {
    if (!formValidated) return null;
    return valid ? null : errMsg;
  }

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

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            cursorColor: customGold,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: customGold.withValues(alpha: 0.7)),
              suffixIcon: suffix,
              filled: true,
              fillColor: customGold.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.red : customGold,
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.red : customGold,
                  width: 1.5,
                ),
              ),
              errorText: errorText,
              errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    if (isLoadingDoctors) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredDoctors.isEmpty) {
      return const Text(
        'No available doctors for this complaint',
        style: TextStyle(color: customGold),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // if inside a scroll view
      itemCount: filteredDoctors.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // ✅ 3 cards per row
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2, // adjust card height
      ),
      itemBuilder: (_, i) {
        final doc = filteredDoctors[i];
        final isSelected =
            selectedDoctor != null && selectedDoctor!['id'] == doc['id'];

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedDoctor = doc;
              doctorIdController.text = doc['id'].toString();
              doctorNameController.text = doc['name'];
              departmentController.text = doc['department'];
            });
          },
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isSelected
                  ? customGold.withValues(alpha: 0.25)
                  : Colors.white,
              border: Border.all(
                color: customGold,
                width: isSelected ? 2 : 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: customGold.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  doc['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  doc['department'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: customGold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionCard({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? customGold : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? customGold : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            if (selected)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 2),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
        fontSize: 18,
        letterSpacing: 0.1,
      ),
    ),
  );

  PreferredSize _overviewAppBar(BuildContext context) => PreferredSize(
    preferredSize: const Size.fromHeight(100),
    child: Container(
      height: 100,
      decoration: const BoxDecoration(
        color: customGold,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Patient Registration',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
