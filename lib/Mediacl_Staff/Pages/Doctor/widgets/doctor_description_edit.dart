import 'package:flutter/material.dart';

class EditTestScanTab extends StatefulWidget {
  final List<dynamic> items;
  final void Function(List<dynamic>) onChanged;

  const EditTestScanTab({
    super.key,
    required this.items,
    required this.onChanged,
  });

  @override
  State<EditTestScanTab> createState() => _EditTestScanTabState();
}

class _EditTestScanTabState extends State<EditTestScanTab> {
  late List<dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = List.from(widget.items);
  }

  void _removeItem(int index) {
    if (_data.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least one Test or Scan must remain")),
      );
      return;
    }

    setState(() {
      _data.removeAt(index);
    });

    widget.onChanged(_data);
  }

  @override
  Widget build(BuildContext context) {
    if (_data.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _data.length,
      itemBuilder: (context, index) {
        final item = _data[index];
        final type = (item['type'] ?? '').toString().toUpperCase();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: Icon(
              type.contains('SCAN') ? Icons.document_scanner : Icons.science,
              color: Colors.blueAccent,
            ),
            title: Text(
              item['title']?.toString() ?? type,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(type),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ✏️ EDIT
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () {
                    // navigate to edit page if needed
                  },
                ),

                /// 🗑 DELETE
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
