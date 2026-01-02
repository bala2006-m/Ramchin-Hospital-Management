import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

enum DateFilter { day, month, year, periodical }

typedef ReportFilterCallback =
    void Function({
      required DateFilter reportType,
      required DateTime selectedDate,
      DateTime? fromDate,
      DateTime? toDate,
    });

class ReportFilterWidget extends StatefulWidget {
  final ReportFilterCallback onApply;

  const ReportFilterWidget({super.key, required this.onApply});

  @override
  State<ReportFilterWidget> createState() => _ReportFilterWidgetState();
}

class _ReportFilterWidgetState extends State<ReportFilterWidget> {
  DateFilter _dateFilter = DateFilter.day;
  DateTime _selectedDate = DateTime.now();
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(2),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------------- FIRST ROW: DAY / MONTH / YEAR ----------------
            Row(
              children: [DateFilter.day, DateFilter.month, DateFilter.year].map(
                (filter) {
                  final isSelected = _dateFilter == filter;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _onFilterTap(filter),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              filter.name.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),

            const SizedBox(height: 16),

            // ---------------- PERIODICAL ROW ----------------
            Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: _dateFilter == DateFilter.periodical
                          ? Colors.blue
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() => _dateFilter = DateFilter.periodical);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            "PERIODICAL",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _dateFilter == DateFilter.periodical
                                  ? Colors.white
                                  : Colors
                                        .black87, // ✅ Use _dateFilter check here
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ---------------- SINGLE DATE PICKER ----------------
            if (_dateFilter != DateFilter.periodical)
              _dateSelectorBox(
                label: _dateLabel(),
                date: _selectedDate,
                onTap: _pickSingleDate,
              ),

            // ---------------- PERIODICAL PICKER ----------------
            if (_dateFilter == DateFilter.periodical) _periodicalPicker(),
          ],
        ),
      ),
    );
  }

  // ---------------- FILTER LOGIC ----------------
  Future<void> _onFilterTap(DateFilter filter) async {
    setState(() => _dateFilter = filter);

    if (filter != DateFilter.periodical) {
      await _pickSingleDate();
      widget.onApply(reportType: filter, selectedDate: _selectedDate);
    }
  }

  Future<void> _pickSingleDate() async {
    if (_dateFilter == DateFilter.day) {
      final d = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (d != null) {
        setState(() => _selectedDate = d);
        widget.onApply(reportType: DateFilter.day, selectedDate: _selectedDate);
      }
    } else if (_dateFilter == DateFilter.month) {
      final m = await showMonthPicker(
        context: context,
        initialDate: _selectedDate,
      );
      if (m != null) {
        setState(() => _selectedDate = DateTime(m.year, m.month));
        widget.onApply(
          reportType: DateFilter.month,
          selectedDate: _selectedDate,
        );
      }
    } else if (_dateFilter == DateFilter.year) {
      final y = await showDialog<int>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Select Year"),
          content: SizedBox(
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              selectedDate: _selectedDate,
              onChanged: (d) => Navigator.pop(context, d.year),
            ),
          ),
        ),
      );
      if (y != null) {
        setState(() => _selectedDate = DateTime(y));
        widget.onApply(
          reportType: DateFilter.year,
          selectedDate: _selectedDate,
        );
      }
    }
  }

  // ---------------- PERIODICAL PICKER ----------------
  Widget _periodicalPicker() {
    return Row(
      children: [
        Expanded(
          child: _dateSelectorBox(
            label: "From",
            date: _fromDate,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _fromDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (d != null) {
                setState(() => _fromDate = d);
                if (_toDate != null) _applyPeriodical();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _dateSelectorBox(
            label: "To",
            date: _toDate,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _toDate ?? DateTime.now(),
                firstDate: _fromDate ?? DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (d != null) {
                setState(() => _toDate = d);
                if (_fromDate != null) _applyPeriodical();
              }
            },
          ),
        ),
      ],
    );
  }

  void _applyPeriodical() {
    widget.onApply(
      reportType: DateFilter.periodical,
      selectedDate: DateTime.now(),
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  // ---------------- UI HELPERS ----------------
  Widget _dateSelectorBox({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              date == null ? label : DateFormat("dd MMM yyyy").format(date),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel() {
    switch (_dateFilter) {
      case DateFilter.day:
        return "Select Day";
      case DateFilter.month:
        return "Select Month";
      case DateFilter.year:
        return "Select Year";
      default:
        return "";
    }
  }
}
