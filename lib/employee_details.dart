import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

//////////////////////////////////////////////////////////
// EMPLOYEE DETAILS MODEL
//////////////////////////////////////////////////////////

class EmployeeDetails {
  final String name;
  final String employeeId;
  final String designation;
  final String department;
  final String email;
  final String contact;
  final String doj;
  final String insuredId;
  final String photo;

  EmployeeDetails({
    required this.name,
    required this.employeeId,
    required this.designation,
    required this.department,
    required this.email,
    required this.contact,
    required this.doj,
    required this.insuredId,
    required this.photo,
  });

  factory EmployeeDetails.fromJson(Map<String, dynamic> json) {
    return EmployeeDetails(
      name: json["name"] ?? "",
      employeeId: json["employee_id"] ?? "",
      designation: json["designation"] ?? "",
      department: json["department"] ?? "",
      email: json["email"] ?? "",
      contact: json["contact_number"] ?? "",
      doj: json["doj"] ?? "",
      insuredId: json["insured_id"] ?? "",
      photo: json["photo"] ?? "",
    );
  }
}

//////////////////////////////////////////////////////////
// EMPLOYEE PROFILE PAGE
//////////////////////////////////////////////////////////

class EmployeeProfilePage extends StatefulWidget {
  final String authToken;
  final String empId;

  const EmployeeProfilePage({
    super.key,
    required this.authToken,
    required this.empId,
  });

  @override
  State<EmployeeProfilePage> createState() =>
      _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  EmployeeDetails? employee;
  bool isLoading = true;

  final String api = "https://hrm.eltrive.com/api/employee-details";

  @override
  void initState() {
    super.initState();
    fetchEmployee();
  }

  Future<void> fetchEmployee() async {
    try {
      final response = await http.post(
        Uri.parse(api),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "auth_token": widget.authToken,
          "emp_id": widget.empId
        }),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        setState(() {
          employee =
              EmployeeDetails.fromJson(data["employee_details"]);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget buildRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Expanded(
            flex: 5,
            child: Text(value,
                style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Profile"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                employee!.name,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              buildRow(context, "Employee ID", employee!.employeeId),
              buildRow(context, "Designation", employee!.designation),
              buildRow(context, "Department", employee!.department),
              buildRow(context, "Email", employee!.email),
              buildRow(context, "Contact", employee!.contact),
              buildRow(context, "Date Of Joining", employee!.doj),
              buildRow(context, "Insured ID", employee!.insuredId),
            ],
          ),
        ),
      ),
    );
  }
}