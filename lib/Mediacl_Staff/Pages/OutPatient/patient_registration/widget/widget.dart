import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../Pages/NotificationsPage.dart';

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
void onPhoneChanged(String value, void Function(bool) setValidity) {
  String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);
  setValidity(digitsOnly.length == 10);
}

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

void showSnackBar(String msg, context) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

int calculateAge(String dob) {
  final birth = DateTime.parse(dob);
  final today = DateTime.now();
  int age = today.year - birth.year;
  if (today.month < birth.month ||
      (today.month == birth.month && today.day < birth.day)) {
    age--;
  }
  return age;
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

Widget buildHospitalCard({
  required String hospitalName,
  required String hospitalPlace,
  required String hospitalPhoto,
}) {
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
              hospitalPhoto,
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
                  hospitalName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hospitalPlace,
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

Widget buildInput(
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

Widget buildSelectionCard({
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

Widget sectionLabel(String text) => Padding(
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

PreferredSize overviewAppBar(BuildContext context) => PreferredSize(
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

Widget showTestsScans({
  required Map<String, Map<String, dynamic>> savedScans,
  required Map<String, Map<String, dynamic>> savedTests,
}) {
  final num scansTotal = savedScans.values.fold(
    0,
    (s, d) => s + (d['totalAmount'] ?? 0),
  );
  final num testsTotal = savedTests.values.fold(
    0,
    (s, d) => s + (d['totalAmount'] ?? 0),
  );
  final int grandTotal = scansTotal.toInt() + testsTotal.toInt();

  Widget sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget buildItem({
    required String title,
    required Map<String, int> amounts,
    required String description,
    required int totalAmount,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        trailing: Chip(
          label: Text(
            "₹ $totalAmount",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
        ),
        children: [
          ...amounts.entries.map(
            (e) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("• ${e.key}", style: const TextStyle(fontSize: 14)),
                    Text(
                      "₹ ${e.value}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(thickness: 0.5),
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.notes, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                const Text(
                  "Notes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (savedScans.isNotEmpty) ...[
        sectionHeader("Scans", Icons.medical_services),
        ...savedScans.entries.map(
          (e) => buildItem(
            title: e.key,
            amounts: Map<String, int>.from(e.value['amounts'] ?? {}),
            description: e.value['description'] ?? '',
            totalAmount: e.value['totalAmount'] ?? 0,
          ),
        ),
      ],
      if (savedTests.isNotEmpty) ...[
        sectionHeader("Tests", Icons.biotech),
        ...savedTests.entries.map(
          (e) => buildItem(
            title: e.key,
            amounts: Map<String, int>.from(
              e.value['selectedOptionsAmount'] ?? {},
            ),
            description: e.value['description'] ?? '',
            totalAmount: e.value['totalAmount'] ?? 0,
          ),
        ),
      ],
      if (savedScans.isNotEmpty || savedTests.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.blueAccent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Grand Total",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "₹ $grandTotal",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
