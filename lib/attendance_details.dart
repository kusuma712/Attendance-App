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

  // ── Design tokens ────────────────────────────────────────────────────────
  static const _green = Color(0xFF149D0F);
  static const _blue = Color(0xFF0277BD);
  static const _red = Color(0xFFE53935);
  static const _amber = Color(0xFFFFA000);
  static const _cardBg = Color(0xFFF9FAFB);
  static const _borderColor = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  // ── ALL LOGIC UNCHANGED ──────────────────────────────────────────────────
  Future<void> fetchAttendance() async {
    try {
      final response = await http.post(
        Uri.parse("https://hrm.eltrive.com/api/attendance"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.authToken}"
        },
        body: jsonEncode({"month": selectedMonth, "year": selectedYear}),
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
            checkIn = (value["checkin"] ?? "").toString();
            checkOut = (value["checkout"] ?? "").toString();
            duration = (value["duration"] ?? "").toString();

            if (checkIn == "null") checkIn = "";
            if (checkOut == "null") checkOut = "";
            if (duration == "null") duration = "";
          }

          DateTime date = DateTime(selectedYear, selectedMonth, dayNumber);
          if (date.weekday == DateTime.sunday) status = "S";

          tempList.add({
            "day": dayNumber,
            "status": status,
            "check_in": checkIn,
            "check_out": checkOut,
            "duration": duration,
          });
        });

        tempList.sort((a, b) => a["day"].compareTo(b["day"]));
        setState(() => attendanceList = tempList);
      } else {
        setState(() => attendanceList = []);
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

    if (date.isAfter(DateTime.now())) return Colors.transparent;
    if (checkIn.isNotEmpty && (checkOut.isEmpty || checkOut == "null")) {
      return _amber.withOpacity(0.18);
    }
    if (status == "S") return const Color(0xFFE3F2FD);
    if (status == "P") return const Color(0xFFE8F5E9);
    if (status == "A") return const Color(0xFFFFEBEE);
    return Colors.grey.shade100;
  }

  Color getStatusTextColor(Map record) {
    String status = record["status"];
    String checkIn = record["check_in"];
    String checkOut = record["check_out"];
    int day = record["day"];
    DateTime date = DateTime(selectedYear, selectedMonth, day);

    if (date.isAfter(DateTime.now())) return Colors.grey.shade400;
    if (checkIn.isNotEmpty && (checkOut.isEmpty || checkOut == "null")) {
      return _amber;
    }
    if (status == "S") return _blue;
    if (status == "P") return _green;
    if (status == "A") return _red;
    return Colors.grey.shade500;
  }

  Color getStatusBorderColor(Map record) {
    String status = record["status"];
    String checkIn = record["check_in"];
    String checkOut = record["check_out"];
    int day = record["day"];
    DateTime date = DateTime(selectedYear, selectedMonth, day);

    if (date.isAfter(DateTime.now())) return Colors.grey.shade200;
    if (checkIn.isNotEmpty && (checkOut.isEmpty || checkOut == "null")) {
      return _amber.withOpacity(0.4);
    }
    if (status == "S") return _blue.withOpacity(0.25);
    if (status == "P") return _green.withOpacity(0.3);
    if (status == "A") return _red.withOpacity(0.3);
    return Colors.grey.shade200;
  }

  List<Map<String, dynamic>> buildCalendar() {
    List<Map<String, dynamic>> calendar = [];
    DateTime firstDay = DateTime(selectedYear, selectedMonth, 1);
    int startWeekday = firstDay.weekday;
    for (int i = 1; i < startWeekday; i++) {
      calendar.add({"day": "", "status": ""});
    }
    calendar.addAll(attendanceList);
    return calendar;
  }

  String _getDisplayText(Map record) {
    int day = record["day"];
    String status = record["status"];
    DateTime date = DateTime(selectedYear, selectedMonth, day);
    if (date.isAfter(DateTime.now())) return day.toString();
    return status;
  }

  // ── Summary counts ───────────────────────────────────────────────────────
  Map<String, int> _getSummary() {
    int present = 0, absent = 0, partial = 0, sunday = 0;
    for (var r in attendanceList) {
      DateTime date =
      DateTime(selectedYear, selectedMonth, r["day"] as int);
      if (date.isAfter(DateTime.now())) continue;
      final s = r["status"].toString();
      final ci = r["check_in"].toString();
      final co = r["check_out"].toString();
      if (ci.isNotEmpty && (co.isEmpty || co == "null")) {
        partial++;
      } else if (s == "P") {
        present++;
      } else if (s == "A") {
        absent++;
      } else if (s == "S") {
        sunday++;
      }
    }
    return {"P": present, "A": absent, "H": partial, "S": sunday};
  }

  @override
  Widget build(BuildContext context) {
    final calendarData = buildCalendar();
    final summary = _getSummary();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _buildHeader(),

          // ── Summary Pills ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSummaryRow(summary),
          ),

          const SizedBox(height: 16),

          // ── Month / Year selector ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterRow(),
          ),

          const SizedBox(height: 16),

          // ── Week day header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildWeekHeader(),
          ),

          const SizedBox(height: 10),

          // ── Calendar Grid ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: attendanceList.isEmpty
                ? _buildEmptyState()
                : _buildGrid(calendarData),
          ),

          // ── Legend ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            "Attendance",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${_getMonthName(selectedMonth)} $selectedYear",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SUMMARY ROW ───────────────────────────────────────────────────────────
  Widget _buildSummaryRow(Map<String, int> s) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryPill(label: "Present", value: s["P"]!, color: _green),
          _verticalDivider(),
          _SummaryPill(label: "Absent", value: s["A"]!, color: _red),
          _verticalDivider(),
          _SummaryPill(label: "Half Day", value: s["H"]!, color: _amber),
          _verticalDivider(),
          _SummaryPill(label: "Holiday", value: s["S"]!, color: _blue),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
    width: 1,
    height: 30,
    color: _borderColor,
  );

  // ── FILTER ROW ────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _StyledDropdown<int>(
            value: selectedMonth,
            icon: Icons.calendar_today_rounded,
            items: List.generate(12, (i) {
              int m = i + 1;
              return DropdownMenuItem(value: m, child: Text(_getMonthName(m)));
            }),
            onChanged: (value) async {
              setState(() => selectedMonth = value!);
              await fetchAttendance();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StyledDropdown<int>(
            value: selectedYear,
            icon: Icons.date_range_rounded,
            items: yearsList
                .map((y) =>
                DropdownMenuItem(value: y, child: Text(y.toString())))
                .toList(),
            onChanged: (value) async {
              setState(() => selectedYear = value!);
              await fetchAttendance();
            },
          ),
        ),
      ],
    );
  }

  // ── WEEK HEADER ───────────────────────────────────────────────────────────
  Widget _buildWeekHeader() {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map(
            (d) => Expanded(
          child: Center(
            child: Text(
              d,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: d == "Sun" ? _blue : Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  // ── GRID ──────────────────────────────────────────────────────────────────
  Widget _buildGrid(List<Map<String, dynamic>> calendarData) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: calendarData.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        var record = calendarData[index];
        String day = record["day"].toString();
        String status = record["status"].toString();

        if (day == "") return const SizedBox();

        DateTime date =
        DateTime(selectedYear, selectedMonth, int.parse(day));
        bool isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        return GestureDetector(
          onTap: () => showStatusPopup(context, status, date, record),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: getStatusColor(record),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isToday
                    ? _green
                    : getStatusBorderColor(record),
                width: isToday ? 2.0 : 1.0,
              ),
              boxShadow: isToday
                  ? [
                BoxShadow(
                  color: _green.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
                  : [],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDisplayText(record),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: getStatusTextColor(record),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── LEGEND ────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _LegendDot(color: _green, label: "Present"),
        _LegendDot(color: _red, label: "Absent"),
        _LegendDot(color: _amber, label: "Half Day"),
        _LegendDot(color: _blue, label: "Holiday"),
      ],
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            "No Attendance Data",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── POPUP (UNCHANGED LOGIC) ───────────────────────────────────────────────
  void showStatusPopup(
      BuildContext context, String status, DateTime date, Map record) {
    String formattedDate = "${date.day}-${date.month}-${date.year}";
    String title = "";
    Widget content;

    if (status == "A") {
      title = "Absent";
      content = _PopupContent(
        icon: Icons.cancel_rounded,
        iconColor: _red,
        lines: ["You were absent on", formattedDate],
      );
    } else if (status == "P") {
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
      content = _AttendancePopupContent(
        date: formattedDate,
        checkIn: checkIn,
        checkOut: checkOut,
        duration: duration,
      );
    } else if (status == "S") {
      title = "Holiday";
      content = _PopupContent(
        icon: Icons.celebration_rounded,
        iconColor: _blue,
        lines: ["Holiday on", formattedDate],
      );
    } else {
      title = "No Data";
      content = _PopupContent(
        icon: Icons.info_outline_rounded,
        iconColor: Colors.grey,
        lines: ["No attendance data available"],
      );
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog header bar
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: const BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: content,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Close",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _SummaryPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final List<String> lines;

  const _PopupContent(
      {required this.icon, required this.iconColor, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(height: 14),
        ...lines.map(
              (l) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttendancePopupContent extends StatelessWidget {
  final String date;
  final String checkIn;
  final String checkOut;
  final String duration;

  const _AttendancePopupContent({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(
            icon: Icons.calendar_today_rounded,
            color: Colors.grey,
            label: "Date",
            value: date),
        const SizedBox(height: 10),
        _DetailRow(
            icon: Icons.login_rounded,
            color: const Color(0xFF149D0F),
            label: "Check-In",
            value: checkIn),
        const SizedBox(height: 10),
        _DetailRow(
            icon: Icons.logout_rounded,
            color: const Color(0xFFE53935),
            label: "Check-Out",
            value: checkOut),
        const SizedBox(height: 10),
        _DetailRow(
            icon: Icons.timer_rounded,
            color: const Color(0xFF0277BD),
            label: "Duration",
            value: duration),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon,
        required this.color,
        required this.label,
        required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}