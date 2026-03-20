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

  List<Map<String, dynamic>> attendanceList = [];

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

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
          String checkIn = "";
          String checkOut = "";
          String duration = "";

          if (value is Map<String, dynamic>) {
            status = (value["status"] ?? "--").toString();

            // ✅ GET DATA FROM API
            checkIn = (value["checkin"] ?? "").toString();
            checkOut = (value["checkout"] ?? "").toString();
            duration = (value["duration"] ?? "").toString();

            // ✅ IMPORTANT FIX (HANDLE null STRING)
            if (checkIn == "null") checkIn = "";
            if (checkOut == "null") checkOut = "";
            if (duration == "null") duration = "";
          }

          DateTime date = DateTime(selectedYear, selectedMonth, dayNumber);

          if (date.weekday == DateTime.sunday) {
            status = "S";
          }

          tempList.add({
            "day": dayNumber,
            "status": status,
            "check_in": checkIn,
            "check_out": checkOut,
            "duration": duration,
          });
        });

        tempList.sort((a, b) => a["day"].compareTo(b["day"]));

        setState(() {
          attendanceList = tempList;
        });
      } else {
        setState(() {
          attendanceList = [];
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => attendanceList = []);
    }
  }

  Color getStatusColor(Map record) {
    String status = record["status"];
    String checkIn = record["check_in"];
    String checkOut = record["check_out"];

    int day = record["day"];
    DateTime date = DateTime(selectedYear, selectedMonth, day);

    // ✅ FUTURE DATE → NO COLOR
    if (date.isAfter(DateTime.now())) {
      return Colors.transparent;
    }

    // 🟡 Partial day
    if (checkIn.isNotEmpty && (checkOut.isEmpty || checkOut == "null")) {
      return Colors.yellow.shade600;
    }

    // 🔵 Sunday
    if (status == "S") {
      return Colors.lightBlue.shade200;
    }

    // 🟢 Present
    if (status == "P") {
      return Colors.green.shade400;
    }

    // 🔴 Absent
    if (status == "A") {
      return Colors.red.shade400;
    }

    return Colors.grey.shade300;
  }

  /// ✅ Build calendar with proper alignment
  List<Map<String, dynamic>> buildCalendar() {
    List<Map<String, dynamic>> calendar = [];

    DateTime firstDay =
    DateTime(selectedYear, selectedMonth, 1);

    int startWeekday = firstDay.weekday; // Mon=1

    // Empty boxes before 1st day
    for (int i = 1; i < startWeekday; i++) {
      calendar.add({"day": "", "status": ""});
    }

    calendar.addAll(attendanceList);

    return calendar;
  }

  @override
  Widget build(BuildContext context) {
    final calendarData = buildCalendar();

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Attendance",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Row(
              children: [

                // Month
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
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
                ),

                const SizedBox(width: 10),

                // Year
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
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
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Week header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Mon"), Text("Tue"), Text("Wed"),
                Text("Thu"), Text("Fri"), Text("Sat"), Text("Sun"),
              ],
            ),

            const SizedBox(height: 10),

            // ❌ No Data
            if (attendanceList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No Attendance Data"),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: calendarData.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  var record = calendarData[index];

                  String day = record["day"].toString();
                  String status = record["status"].toString();

                  if (day == "") {
                    return const SizedBox();
                  }

                  DateTime date = DateTime(selectedYear, selectedMonth, int.parse(day));

                  return GestureDetector(
                    onTap: () {
                      showStatusPopup(context, status, date, record);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: getStatusColor(record), // ✅ updated
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getDisplayText(record),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  //
  String _getDisplayText(Map record) {
    int day = record["day"];
    String status = record["status"];

    DateTime date = DateTime(selectedYear, selectedMonth, day);

    // ✅ FUTURE → SHOW DAY NUMBER
    if (date.isAfter(DateTime.now())) {
      return day.toString();
    }

    // ✅ PAST → SHOW STATUS
    return status;
  }
  //
  void showStatusPopup(
      BuildContext context, String status, DateTime date, Map record) {

    String formattedDate =
        "${date.day}-${date.month}-${date.year}";

    String title = "";
    String message = "";

    if (status == "A") {
      title = "Absent";
      message = "You were absent on\n$formattedDate";
    }

    else if (status == "P") {
      title = "Attendance Details";

      String checkIn = (record["check_in"] != null &&
          record["check_in"].toString().isNotEmpty &&
          record["check_in"] != "null")
          ? record["check_in"]
          : "Not Marked";

      String checkOut = (record["check_out"] != null &&
          record["check_out"].toString().isNotEmpty &&
          record["check_out"] != "null")
          ? record["check_out"]
          : "Not Marked";

      String duration = (record["duration"] != null &&
          record["duration"].toString().isNotEmpty &&
          record["duration"] != "null")
          ? record["duration"]
          : "Not Available";

      message =
      "📅 Date: $formattedDate\n\n"
          "🟢 Check-In: $checkIn\n"
          "🔴 Check-Out: $checkOut\n"
          "⏱ Duration: $duration";
    }

    else if (status == "S") {
      title = "Sunday";
      message = "🎉 Holiday on\n$formattedDate";
    }

    else {
      title = "No Data";
      message = "No attendance data available";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String _getMonthName(int month) {
    List<String> months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }
}