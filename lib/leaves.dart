import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LeavesPage extends StatefulWidget {

  final String username;
  final String authToken;
  final String empId;

  const LeavesPage({
    super.key,
    required this.username,
    required this.authToken,
    required this.empId,
  });

  @override
  State<LeavesPage> createState() => _LeavesPageState();
}

class _LeavesPageState extends State<LeavesPage> {

  DateTime? _fromDate;
  DateTime? _toDate;

  String _selectedLeaveType = "Casual Leave";

  final TextEditingController _reasonController = TextEditingController();

  bool isLoading = false;

  final String leaveApi =
      "https://hrm.eltrive.com/api/leaveapply";

  int getLeaveTypeId() {

    switch (_selectedLeaveType) {

      case "Casual Leave":
        return 1;

      case "Comp Off Leave":
        return 2;

      case "Earned Leave":
        return 3;

      default:
        return 1;
    }
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
  }

  Future<void> applyLeave() async {

    if (_fromDate == null ||
        _toDate == null ||
        _reasonController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final response = await http.post(
        Uri.parse(leaveApi),
        headers: {
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "auth_token": widget.authToken,
          "emp_id": widget.empId,
          "leave_type_id": getLeaveTypeId(),
          "from_date": formatDate(_fromDate!),
          "to_date": formatDate(_toDate!),
          "reason": _reasonController.text
        }),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );

        setState(() {
          _fromDate = null;
          _toDate = null;
          _reasonController.clear();
          _selectedLeaveType = "Casual Leave";
        });

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Leave failed")),
        );

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

    }

    setState(() {
      isLoading = false;
    });
  }

  Widget _buildDateBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text),
          const Icon(Icons.calendar_today),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [

        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 40),

              const Text(
                "Apply Leave",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Hello, ${widget.username}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              const Text("From Date",
                  style: TextStyle(fontWeight: FontWeight.w600)),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: () async {

                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _fromDate ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );

                  if (picked != null) {
                    setState(() {
                      _fromDate = picked;
                    });
                  }
                },
                child: _buildDateBox(
                  _fromDate == null
                      ? "Select From Date"
                      : "${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}",
                ),
              ),

              const SizedBox(height: 20),

              const Text("To Date",
                  style: TextStyle(fontWeight: FontWeight.w600)),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: () async {

                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _toDate ?? _fromDate ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );

                  if (picked != null) {
                    setState(() {
                      _toDate = picked;
                    });
                  }
                },
                child: _buildDateBox(
                  _toDate == null
                      ? "Select To Date"
                      : "${_toDate!.day}/${_toDate!.month}/${_toDate!.year}",
                ),
              ),

              const SizedBox(height: 20),

              const Text("Leave Type",
                  style: TextStyle(fontWeight: FontWeight.w600)),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLeaveType,
                    isExpanded: true,
                    items: const [

                      DropdownMenuItem(
                        value: "Casual Leave",
                        child: Text("Casual Leave"),
                      ),

                      DropdownMenuItem(
                        value: "Comp Off Leave",
                        child: Text("Comp Off Leave"),
                      ),

                      DropdownMenuItem(
                        value: "Earned Leave",
                        child: Text("Earned Leave"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLeaveType = value!;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text("Reason",
                  style: TextStyle(fontWeight: FontWeight.w600)),

              const SizedBox(height: 8),

              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter reason for leave",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: isLoading ? null : applyLeave,

                  child: const Text(
                    "Submit",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
      ],
    );
  }
}