import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AttendanceDetails extends StatefulWidget {
  final String authToken;

  const AttendanceDetails({super.key, required this.authToken});

  @override
  State<AttendanceDetails> createState() => _AttendanceDetailsState();
}

class _AttendanceDetailsState extends State<AttendanceDetails> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<int> yearsList =
  List.generate(5, (index) => DateTime.now().year - index);

  List<Map<String, String>> attendanceList = [];

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  // ✅ API CALL
  Future<void> fetchAttendance() async {
    try {
      final response = await http.post(
        Uri.parse("https://hrm.eltrive.com/api/attendance"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.authToken}"
        },
        body: jsonEncode({
          "month": selectedMonth,
          "year": selectedYear
        }),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success" && data["days"] != null) {
        Map<String, dynamic> days = data["days"];
        List<Map<String, dynamic>> tempList = [];

        days.forEach((key, value) {
          int dayNumber = int.parse(key.replaceAll("day", ""));

          String status = "--";
          String checkIn = "--";
          String checkOut = "--";
          String duration = "--";

          if (value is Map<String, dynamic>) {
            status = (value["status"] ?? "--").toString();
            checkIn = value["checkin"]?.toString() ?? "--";
            checkOut = value["checkout"]?.toString() ?? "--";
            duration = value["duration"]?.toString() ?? "--";
          }

          tempList.add({
            "day": dayNumber,
            "date": "$dayNumber ${_getMonthName(selectedMonth)} $selectedYear",
            "checkin": checkIn,
            "checkout": checkOut,
            "duration": duration,
            "status": status,
          });
        });

        tempList.sort((a, b) => a["day"].compareTo(b["day"]));

        setState(() {
          attendanceList = tempList.map((item) {
            return {
              "date": item["date"].toString(),
              "checkin": item["checkin"].toString(),
              "checkout": item["checkout"].toString(),
              "duration": item["duration"].toString(),
              "status": item["status"].toString(),
            };
          }).toList();
        });
      } else {
        setState(() => attendanceList = []);
      }
    } catch (e) {
      debugPrint("Attendance Error: $e");
      setState(() => attendanceList = []);
    }
  }

  String _getMonthName(int month) {
    List<String> months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  // ✅ TABLE CELL
  Widget _tableCell(String text, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isStatus ? FontWeight.bold : FontWeight.normal,
          color: isStatus
              ? text == "P"
              ? Colors.green
              : text == "A"
              ? Colors.red
              : text == "L"
              ? Colors.orange
              : Colors.grey
              : Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🔹 HEADER + FILTER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Attendance",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  DropdownButton<int>(
                    value: selectedMonth,
                    underline: const SizedBox(),
                    items: List.generate(12, (index) {
                      int month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(_getMonthName(month)),
                      );
                    }),
                    onChanged: (value) async {
                      setState(() => selectedMonth = value!);
                      await fetchAttendance();
                    },
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: selectedYear,
                    underline: const SizedBox(),
                    items: yearsList.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() => selectedYear = value!);
                      await fetchAttendance();
                    },
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 15),

          attendanceList.isEmpty
              ? const Center(child: Text("No Data"))
              : SizedBox(
            height: 350,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(130),
                    1: FixedColumnWidth(110),
                    2: FixedColumnWidth(110),
                    3: FixedColumnWidth(110),
                    4: FixedColumnWidth(90),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F5E9),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Date",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Check In",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Check Out",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Duration",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Status",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    ...attendanceList.map((record) {
                      return TableRow(
                        children: [
                          _tableCell(record["date"]!),
                          _tableCell(record["checkin"]!),
                          _tableCell(record["checkout"]!),
                          _tableCell(record["duration"]!),
                          _tableCell(record["status"]!, isStatus: true),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}