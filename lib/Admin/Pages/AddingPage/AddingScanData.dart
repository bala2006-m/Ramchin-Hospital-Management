import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Pages/NotificationsPage.dart';
import '../../../Services/Scan_Test_Get-Service.dart';

const primaryBlue = Color(0xFF1565C0);
const secondaryBlue = Color(0xFF2196F3);
const lightBlue = Color(0xFFE3F2FD);
const tealGreen = Color(0xFF00897B);
const softGrey = Color(0xFFF5F7FA);

class AddScanPage extends StatefulWidget {
  const AddScanPage({Key? key}) : super(key: key);

  @override
  State<AddScanPage> createState() => _AddScanPageState();
}

class _AddScanPageState extends State<AddScanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  int? editingId;
  bool isLoading = false;
  String? _dateTime;
  SharedPreferences? _prefs;

  List<Map<String, dynamic>> selectedOptions = [];
  List<dynamic> scanTestList = [];
  List<dynamic> optionList = [];
  String? selectedOptionName;
  String? selectedOption;
  int? selectedOptionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    fetchScanTests();
    fetchAllOptionName();
    _updateTime();
    // Listen to tab changes to rebuild FAB visibility
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // triggers rebuild
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  /// ---------------- FETCH All  ----------------

  Future<void> fetchAllOptionName() async {
    setState(() => isLoading = true);
    optionList = await ScanTestGetService().getAllUnitReference('SCAN');

    setState(() => isLoading = false);
  }

  List<String> get testTitleSuggestions {
    return optionList.map((e) => e['optionTitle'].toString()).toSet().toList();
  }

  // List<Map<String, dynamic>> get filteredOptions {
  //   return optionList
  //       .where((e) => e['testTitle'] == _titleController.text)
  //       .map<Map<String, dynamic>>(
  //         (e) => {"name": e['name'], "price": e['price']},
  //       )
  //       .toList();
  // }

  List<Map<String, dynamic>> get filteredOptionList {
    if (_titleController.text.isEmpty) return [];

    return optionList
        .where((e) => e['optionTitle'] == _titleController.text)
        .map<Map<String, dynamic>>(
          (e) => {"id": e['id'], "name": e['optionName']},
        )
        .toList();
  }

  /// ---------------- FETCH ----------------
  Future<void> fetchScanTests() async {
    setState(() => isLoading = true);
    scanTestList = await ScanTestGetService().fetchTestAndScan('SCAN');
    setState(() => isLoading = false);
  }

  /// ---------------- SAVE ----------------
  Future<void> saveScanTest() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final prefs = await SharedPreferences.getInstance(); // ✅ FIX

    if (!_formKey.currentState!.validate()) return;
    if (selectedOptions.isEmpty) {
      snack("Add at least one Scan option");
      return;
    }

    final hospitalId = prefs.getString('hospitalId') ?? '';
    setState(() => isLoading = true);

    final testData = {
      "hospital_Id": int.parse(hospitalId),
      "title": _titleController.text,
      "type": "SCAN",
      "options": selectedOptions,
      "amount": calculateTotal(),
      "createdAt": _dateTime.toString(),
      "updatedAt": '',
    };

    if (editingId == null) {
      await ScanTestGetService().createTestScan([testData]);
    } else {
      await ScanTestGetService().updateScanTest(editingId!, testData);
    }
    setState(() => isLoading = false);

    clearForm();
    fetchScanTests();
    _tabController.animateTo(1);
  }

  /// ---------------- DELETE ----------------
  Future<void> deleteScanTest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Scan"),
        content: const Text("Are you sure you want to delete this Scan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);

      await ScanTestGetService().deleteScanTest(id);
      setState(() => isLoading = false);

      fetchScanTests();
    }
  }

  /// ---------------- EDIT ----------------
  // void editScanTest(dynamic item) {
  //   setState(() {
  //     editingId = item['id'];
  //     _titleController.text = item['title'];
  //     _amountController.text = item['amount'].toString();
  //     selectedOptions = parseOptions(item['options']);
  //     _tabController.animateTo(0);
  //   });
  // }
  void editScanTest(dynamic item) {
    setState(() {
      editingId = item['id'];
      _titleController.text = item['title'];
      selectedOptions = parseOptions(item['options']);
      selectedOption = null; // ✅ reset once here
      _tabController.animateTo(0);
    });
  }

  /// ---------------- UTIL ----------------
  // List<Map<String, dynamic>> parseOptions(dynamic options) {
  //   if (options == null) return [];
  //   if (options is String) {
  //     return List<Map<String, dynamic>>.from(jsonDecode(options));
  //   }
  //   if (options is List) return List<Map<String, dynamic>>.from(options);
  //   return [];
  // }
  List<Map<String, dynamic>> parseOptions(dynamic options) {
    if (options == null) return [];

    final List list = options is String ? jsonDecode(options) : options as List;

    return list.map<Map<String, dynamic>>((e) {
      return {
        "id": e['id'], // ✅ KEEP ID
        "name": e['name'] ?? e['optionName'] ?? "",
        "price": e['price'] ?? 0,
      };
    }).toList();
  }

  void clearForm() {
    editingId = null;
    _titleController.clear();
    _amountController.clear();
    selectedOptions.clear();
  }

  double calculateTotal() {
    double total = 0;
    for (var opt in selectedOptions) {
      total += double.tryParse(opt['price'].toString()) ?? 0;
    }
    _amountController.text = total.toStringAsFixed(2);
    return total;
  }

  void snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ---------------- OPTION DIALOG ----------------
  void addOptionDialog({Map<String, dynamic>? editOption}) {
    //selectedOption = null;
    selectedOption = editOption?['name'];
    final nameCtrl = TextEditingController(text: editOption?['name'] ?? '');
    final priceCtrl = TextEditingController(
      text: editOption?['price']?.toString() ?? '',
    );
    // bool get isOptionFormValid {
    //   return selectedOption != null &&
    //       selectedOption!.isNotEmpty &&
    //       priceCtrl.text.isNotEmpty &&
    //       double.tryParse(priceCtrl.text) != null;
    // }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                editOption == null ? "Add Test Option" : "Edit Test Option",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 20),

              // Name Field
              // TextField(
              //   controller: nameCtrl,
              //   decoration: InputDecoration(
              //     labelText: "Option Name",
              //     prefixIcon: const Icon(Icons.medical_services_outlined),
              //     filled: true,
              //     fillColor: Colors.grey.shade100,
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(16),
              //       borderSide: BorderSide.none,
              //     ),
              //   ),
              // ),
              DropdownButtonFormField<String>(
                value:
                    filteredOptionList.any((e) => e['name'] == selectedOption)
                    ? selectedOption
                    : null,

                isExpanded: true, // ✅ IMPORTANT (prevents overflow)

                decoration: InputDecoration(
                  labelText: "Option Name",
                  prefixIcon: const Icon(Icons.science_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),

                items: filteredOptionList.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['name'],
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                onChanged: (value) {
                  final opt = filteredOptionList.firstWhere(
                    (e) => e['name'] == value,
                  );

                  setState(() {
                    selectedOption = value;
                    selectedOptionId = opt['id']; // ✅ SAVE ID
                    nameCtrl.text = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Price Field
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Price",
                  prefixIcon: const Icon(Icons.currency_rupee),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (editOption != null) {
                        editOption['id'] ??=
                            selectedOptionId; // ✅ keep or set ID

                        editOption['name'] = nameCtrl.text;
                        editOption['price'] = double.parse(priceCtrl.text);
                      } else {
                        selectedOptions.add({
                          "id": selectedOptionId, // ✅ VERY IMPORTANT
                          "name": nameCtrl.text,
                          "price": double.parse(priceCtrl.text),
                        });
                      }
                      calculateTotal();
                      setState(() {});
                      Navigator.pop(context);
                    },
                    // onPressed: isOptionFormValid
                    //     ? () {
                    //         if (editOption != null) {
                    //           editOption['name'] = nameCtrl.text;
                    //           editOption['price'] = double.parse(
                    //             priceCtrl.text,
                    //           );
                    //         } else {
                    //           selectedOptions.add({
                    //             "name": nameCtrl.text,
                    //             "price": double.parse(priceCtrl.text),
                    //           });
                    //         }
                    //         calculateTotal();
                    //         setState(() {});
                    //         Navigator.pop(context);
                    //       }
                    //     : null, // ✅ DISABLED
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void cancelEditMode() {
    setState(() {
      editingId = null;
      _titleController.clear();
      _amountController.clear();
      selectedOptions.clear();
    });

    snack("Edit cancelled");
  }

  /// ---------------- ADD TAB ----------------
  Widget addTab() {
    return Form(
      key: _formKey,
      child: Container(
        color: softGrey,
        child: Column(
          children: [
            /// ================= EDIT MODE BANNER =================
            if (editingId != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrangeAccent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_note, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text(
                      "Editing Scan  ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: cancelEditMode,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.cancel,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                children: [
                  /// ================= HEADER =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: primaryBlue.withValues(alpha: 0.2),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.local_hospital,
                                  color: primaryBlue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Scan Details",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Enter Scan title and options",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  /// ================= SCAN INFO CARD =================
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    shadowColor: primaryBlue.withValues(alpha: 0.15),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFE3F2FD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Scan Title Input
                          // TextFormField(
                          //   controller: _titleController,
                          //   decoration: InputDecoration(
                          //     labelText: "Test Title",
                          //     prefixIcon: const Icon(
                          //       Icons.medical_services_outlined,
                          //     ),
                          //     filled: true,
                          //     fillColor: Colors.white,
                          //     border: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(16),
                          //       borderSide: BorderSide.none,
                          //     ),
                          //   ),
                          //   validator: (v) =>
                          //       v == null || v.isEmpty ? "Required" : null,
                          // ),
                          Autocomplete<String>(
                            optionsBuilder: (TextEditingValue value) {
                              if (value.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return testTitleSuggestions.where(
                                (title) => title.toLowerCase().contains(
                                  value.text.toLowerCase(),
                                ),
                              );
                            },
                            // onSelected: (selection) {
                            //   _titleController.text = selection;
                            //
                            //   // Clear previous options when title changes
                            //   selectedOptions.clear();
                            //   setState(() {});
                            // },
                            onSelected: (selection) {
                              _titleController.text = selection;

                              selectedOptions.clear();
                              selectedOption = null; // ✅ VERY IMPORTANT
                              setState(() {});
                            },

                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmit) {
                                  controller.text = _titleController.text;

                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      labelText: "Scan Title",
                                      prefixIcon: const Icon(
                                        Icons.medical_services_outlined,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? "Required"
                                        : null,
                                  );
                                },
                          ),

                          const SizedBox(height: 8),

                          // Total Amount Box
                          // Container(
                          //   padding: const EdgeInsets.symmetric(
                          //     horizontal: 16,
                          //     vertical: 14,
                          //   ),
                          //   decoration: BoxDecoration(
                          //     color: primaryBlue.withValues(alpha:0.1),
                          //     borderRadius: BorderRadius.circular(16),
                          //     boxShadow: [
                          //       BoxShadow(
                          //         color: primaryBlue.withValues(alpha:0.05),
                          //         blurRadius: 8,
                          //         offset: const Offset(0, 4),
                          //       ),
                          //     ],
                          //   ),
                          //   child: Row(
                          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //     children: [
                          //       const Text(
                          //         "Total Amount",
                          //         style: TextStyle(
                          //           fontWeight: FontWeight.w600,
                          //           fontSize: 16,
                          //           color: Colors.black87,
                          //         ),
                          //       ),
                          //       Text(
                          //         "₹ ${_amountController.text}",
                          //         style: const TextStyle(
                          //           fontWeight: FontWeight.bold,
                          //           fontSize: 18,
                          //           color: primaryBlue,
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          ElevatedButton.icon(
                            //onPressed: addOptionDialog,
                            onPressed: _titleController.text.isEmpty
                                ? null
                                : addOptionDialog,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: tealGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              "Add Options",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ================= OPTIONS HEADER =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Scan Options",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      // ElevatedButton.icon(
                      //   onPressed: addOptionDialog,
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: tealGreen,
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //   ),
                      //   icon: const Icon(Icons.add, color: Colors.white),
                      //   label: const Text(
                      //     "Add Option",
                      //     style: TextStyle(color: Colors.white),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /// ================= OPTIONS LIST =================
                  if (selectedOptions.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.science_outlined,
                              size: 36,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "No Scan options added yet",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...selectedOptions.map(
                      (opt) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryBlue,
                            child: const Icon(
                              Icons.science,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            //opt['name'],
                            opt['name'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("₹ ${opt['price'] ?? 0}"),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: secondaryBlue,
                                ),
                                onPressed: () =>
                                    addOptionDialog(editOption: opt),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  selectedOptions.remove(opt);
                                  calculateTotal();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            /// ================= SAVE BUTTON =================
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black12.withValues(alpha:0.08),
            //         blurRadius: 12,
            //       ),
            //     ],
            //   ),
            //   child: SizedBox(
            //     width: double.infinity,
            //     height: 56,
            //     child: ElevatedButton(
            //       onPressed: saveScanTest,
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: primaryBlue,
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(20),
            //         ),
            //       ),
            //       child: Text(
            //         editingId == null ? "SAVE SCAN" : "UPDATE SCAN",
            //         style: const TextStyle(
            //           fontSize: 17,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// ---------------- MODIFY TAB ----------------
  Widget modifyTab() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (scanTestList.isEmpty) {
      return const Center(child: Text("No Tests Available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      itemCount: scanTestList.length,
      itemBuilder: (_, i) {
        final item = scanTestList[i];
        final options = parseOptions(item['options']);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shadowColor: primaryBlue.withValues(alpha: 0.5),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: CircleAvatar(
              backgroundColor: primaryBlue.withValues(alpha: 0.2),
              child: const Icon(Icons.science_outlined, color: primaryBlue),
            ),
            title: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              "${options.length} option(s)", //₹${item['amount']} •
              style: const TextStyle(color: Colors.black54),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Ink(
                  decoration: const ShapeDecoration(
                    color: Colors.blue,
                    shape: CircleBorder(),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 24),
                    onPressed: () => editScanTest(item),
                  ),
                ),
                const SizedBox(width: 8),
                Ink(
                  decoration: const ShapeDecoration(
                    color: Colors.red,
                    shape: CircleBorder(),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => deleteScanTest(item['id']),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFBF955E);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: const BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
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
                    "Scan Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              //onPressed: isLoading ? null : saveScanTest,
              onPressed:
                  (isLoading ||
                      _titleController.text.isEmpty ||
                      selectedOptions.isEmpty)
                  ? null
                  : saveScanTest,

              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              icon: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                isLoading
                    ? "PLEASE WAIT..."
                    : editingId == null
                    ? "SAVE Scan"
                    : "UPDATE Scan",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      bottomNavigationBar: Material(
        elevation: 8,
        color: Colors.white,
        child: SizedBox(
          height: 56,
          child: TabBar(
            controller: _tabController,
            indicatorColor: gold,
            indicatorWeight: 3,
            labelColor: gold,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.add_circle_outline, size: 20), text: "ADD"),
              Tab(icon: Icon(Icons.edit_note_outlined, size: 20), text: "Home"),
            ],
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [addTab(), modifyTab()],
      ),
    );
  }
}
