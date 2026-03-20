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
  // ── Design tokens ─────────────────────────────────────────────────────────
  static const _green       = Color(0xFF149D0F);
  static const _blue        = Color(0xFF0277BD);
  static const _red         = Color(0xFFE53935);
  static const _amber       = Color(0xFFFFA000);
  static const _darkText    = Color(0xFF1A1A2E);
  static const _borderColor = Color(0xFFEEEEEE);
  static const _cardBg      = Color(0xFFF9FAFB);

  int selectedMonth = DateTime.now().month;
  int selectedYear  = DateTime.now().year;

  List<Map<String, dynamic>> attendanceList = [];

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  // ── FETCH ATTENDANCE (logic unchanged) ────────────────────────────────────
  Future<void> fetchAttendance() async {
    try {
      final response = await http.post(
        Uri.parse("https://hrm.eltrive.com/api/attendance"),
        headers: {
          "Content-Type":  "application/json",
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

          String status   = "--";
          String checkIn  = "";
          String checkOut = "";
          String duration = "";

          if (value is Map<String, dynamic>) {
            status   = (value["status"]   ?? "--").toString();
            checkIn  = (value["checkin"]  ?? "").toString();
            checkOut = (value["checkout"] ?? "").toString();
            duration = (value["duration"] ?? "").toString();

            if (checkIn  == "null") checkIn  = "";
            if (checkOut == "null") checkOut = "";
            if (duration == "null") duration = "";
          }

          DateTime date = DateTime(selectedYear, selectedMonth, dayNumber);
          if (date.weekday == DateTime.sunday) status = "S";

          tempList.add({
            "day":       dayNumber,
            "status":    status,
            "check_in":  checkIn,
            "check_out": checkOut,
            "duration":  duration,
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

  // ── ARROW NAVIGATION ──────────────────────────────────────────────────────
  void _previousMonth() {
    setState(() {
      if (selectedMonth == 1) {
        selectedMonth = 12;
        selectedYear--;
      } else {
        selectedMonth--;
      }
    });
    fetchAttendance();
  }

  void _nextMonth() {
    // Do not allow going beyond current month
    final now = DateTime.now();
    if (selectedYear == now.year && selectedMonth == now.month) return;
    setState(() {
      if (selectedMonth == 12) {
        selectedMonth = 1;
        selectedYear++;
      } else {
        selectedMonth++;
      }
    });
    fetchAttendance();
  }

  bool get _isCurrentMonth =>
      selectedYear == DateTime.now().year &&
          selectedMonth == DateTime.now().month;

  // ── STATUS COLOR HELPERS (logic unchanged) ────────────────────────────────
  Color getStatusColor(Map record) {
    String status   = record["status"];
    String checkIn  = record["check_in"];
    String checkOut = record["check_out"];
    int    day      = record["day"];
    DateTime date   = DateTime(selectedYear, selectedMonth, day);

    if (date.isAfter(DateTime.now()))                                   return Colors.grey.shade100;
    if (checkIn.isNotEmpty && (checkOut.isEmpty || checkOut == "null")) return _amber;
    if (status == "S")                                                   return _blue;
    if (status == "P")                                                   return _green;
    if (status == "A")                                                   return _red;
    return Colors.grey.shade300;
  }

  Color getStatusTextColor(Map record) {
    String status   = record["status"];
    String checkIn  = record["check_in"];
    String checkOut = record["check_out"];
    int    day      = record["day"];
    DateTime date   = DateTime(selectedYear, selectedMonth, day);

    if (date.isAfter(DateTime.now()))                                   return Colors.grey.shade500;
    if (checkIn.isNotEmpty && (checkOut.isEmpty || checkOut == "null")) return Colors.white;
    if (status == "S")                                                   return Colors.white;
    if (status == "P")                                                   return Colors.white;
    if (status == "A")                                                   return Colors.white;
    return Colors.grey.shade600;
  }

  Color getStatusBorderColor(Map record) {
    String status   = record["status"];
    String checkIn  = record["check_in"];
    String checkOut = record["check_out"];
    int    day      = record["day"];
    DateTime date   = DateTime(selectedYear, selectedMonth, day);

    if (date.isAfter(DateTime.now()))                                   return Colors.grey.shade200;
    if (checkIn.isNotEmpty && (checkOut.isEmpty || checkOut == "null")) return _amber;
    if (status == "S")                                                   return _blue;
    if (status == "P")                                                   return _green;
    if (status == "A")                                                   return _red;
    return Colors.grey.shade300;
  }

  List<Map<String, dynamic>> buildCalendar() {
    List<Map<String, dynamic>> calendar = [];
    DateTime firstDay = DateTime(selectedYear, selectedMonth, 1);
    int startWeekday  = firstDay.weekday;
    for (int i = 1; i < startWeekday; i++) {
      calendar.add({"day": "", "status": ""});
    }
    calendar.addAll(attendanceList);
    return calendar;
  }

  String _getDisplayText(Map record) {
    int    day    = record["day"];
    String status = record["status"];
    DateTime date = DateTime(selectedYear, selectedMonth, day);
    if (date.isAfter(DateTime.now())) return day.toString();
    return status;
  }

  Map<String, int> _getSummary() {
    int present = 0, absent = 0, partial = 0, sunday = 0;
    for (var r in attendanceList) {
      DateTime date = DateTime(selectedYear, selectedMonth, r["day"] as int);
      if (date.isAfter(DateTime.now())) continue;
      final s  = r["status"].toString();
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

  String _getMonthName(int month) {
    const months = ["January","February","March","April","May","June",
      "July","August","September","October","November","December"];
    return months[month - 1];
  }

  String _getShortMonthName(int month) {
    const months = ["Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"];
    return months[month - 1];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── INDIVIDUAL CELL POPUP ────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════
  void _showCellPopup(Map<String, dynamic> record) {
    final int    day      = record["day"] is int ? record["day"] : int.parse(record["day"].toString());
    final String status   = record["status"].toString();
    final String checkIn  = record["check_in"].toString();
    final String checkOut = record["check_out"].toString();
    final String duration = record["duration"].toString();
    final DateTime date   = DateTime(selectedYear, selectedMonth, day);

    Color    headerColor;
    IconData headerIcon;
    String   statusLabel;
    final bool isHalfDay = checkIn.isNotEmpty && (checkOut.isEmpty || checkOut == "null");

    if (isHalfDay) {
      headerColor = _amber;
      headerIcon  = Icons.schedule_rounded;
      statusLabel = "Half Day";
    } else if (status == "P") {
      headerColor = _green;
      headerIcon  = Icons.check_circle_rounded;
      statusLabel = "Present";
    } else if (status == "A") {
      headerColor = _red;
      headerIcon  = Icons.cancel_rounded;
      statusLabel = "Absent";
    } else if (status == "S") {
      headerColor = _blue;
      headerIcon  = Icons.celebration_rounded;
      statusLabel = "Holiday";
    } else {
      headerColor = Colors.grey.shade400;
      headerIcon  = Icons.info_outline_rounded;
      statusLabel = "No Data";
    }

    const weekdays = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"];
    final fullDate = "${weekdays[date.weekday - 1]}, "
        "${day.toString().padLeft(2,'0')} "
        "${_getMonthName(selectedMonth)} "
        "$selectedYear";

    final displayCI = (checkIn.isNotEmpty  && checkIn  != "null") ? checkIn  : "—";
    final displayCO = (checkOut.isNotEmpty && checkOut != "null") ? checkOut : "—";
    final displayDr = (duration.isNotEmpty && duration != "null") ? duration : "—";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: headerColor,
                boxShadow: [BoxShadow(color: headerColor.withOpacity(0.30), blurRadius: 10, offset: const Offset(0,4))],
              ),
              child: Stack(children: [
                Positioned(top: -16, right: -16,
                    child: Container(width: 80, height: 80,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.10)))),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(12)),
                    child: Icon(headerIcon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(statusLabel,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(fullDate,
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85))),
                  ])),
                ]),
              ]),
            ),
            // Rows
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Column(children: [
                _PopupRow(icon: Icons.calendar_today_rounded, color: headerColor,
                    label: "Date",
                    value: "${day.toString().padLeft(2,'0')}-${selectedMonth.toString().padLeft(2,'0')}-$selectedYear"),
                const SizedBox(height: 10),
                _PopupRow(icon: Icons.flag_rounded, color: headerColor,
                    label: "Status", value: statusLabel, valueColor: headerColor),
                const SizedBox(height: 10),
                _PopupRow(icon: Icons.login_rounded, color: _green,
                    label: "Check-In", value: displayCI,
                    valueColor: displayCI != "—" ? _green : null),
                const SizedBox(height: 10),
                _PopupRow(icon: Icons.logout_rounded, color: _red,
                    label: "Check-Out", value: displayCO,
                    valueColor: displayCO != "—" ? _red : null),
                const SizedBox(height: 10),
                _PopupRow(icon: Icons.timer_rounded, color: _blue,
                    label: "Duration", value: displayDr,
                    valueColor: displayDr != "—" ? _blue : null),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: headerColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                    ),
                    child: const Text("Close",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── MONTHLY TABLE POPUP — tap anywhere on calendar card ──────────────────
  // ═══════════════════════════════════════════════════════════════════════════
  void _showMonthlyTablePopup() {
    final List<Map<String, dynamic>> records = attendanceList.where((r) {
      final date = DateTime(selectedYear, selectedMonth, r["day"] as int);
      return !date.isAfter(DateTime.now());
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: const BoxDecoration(color: _green),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("MONTHLY REPORT",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1.0)),
                  const SizedBox(height: 2),
                  Text("${_getMonthName(selectedMonth)} $selectedYear",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ])),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),

            // ── Table ─────────────────────────────────────────────────────
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.62,
              ),
              child: records.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.event_busy_rounded, size: 44, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No data available",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ]),
              )
                  : SingleChildScrollView(
                child: Column(children: [

                  // Table column headers
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.07),
                      border: Border(bottom: BorderSide(color: _green.withOpacity(0.15))),
                    ),
                    child: Row(children: const [
                      _TH(label: "Date",     flex: 3),
                      _TH(label: "Status",   flex: 3),
                      _TH(label: "In",       flex: 3),
                      _TH(label: "Out",      flex: 3),
                      _TH(label: "Hours",    flex: 3),
                    ]),
                  ),

                  // Table data rows
                  ...records.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final r   = entry.value;
                    final int    d  = r["day"] as int;
                    final String s  = r["status"].toString();
                    final String ci = r["check_in"].toString();
                    final String co = r["check_out"].toString();
                    final String dr = r["duration"].toString();
                    final bool isHalfDay = ci.isNotEmpty && (co.isEmpty || co == "null");

                    Color  badgeColor;
                    String badgeLabel;
                    if (isHalfDay)     { badgeColor = _amber; badgeLabel = "Half"; }
                    else if (s == "P") { badgeColor = _green; badgeLabel = "P"; }
                    else if (s == "A") { badgeColor = _red;   badgeLabel = "A"; }
                    else if (s == "S") { badgeColor = _blue;  badgeLabel = "Sun"; }
                    else               { badgeColor = Colors.grey.shade400; badgeLabel = "—"; }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: idx.isEven ? Colors.white : _cardBg,
                        border: Border(
                          bottom: BorderSide(color: _borderColor, width: 1),
                        ),
                      ),
                      child: Row(children: [
                        // Date
                        Expanded(flex: 3, child: Text(
                          "${d.toString().padLeft(2,'0')}/${selectedMonth.toString().padLeft(2,'0')}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _darkText),
                        )),
                        // Status badge
                        Expanded(flex: 3, child: Center(child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badgeLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                        ))),
                        // Check-In
                        Expanded(flex: 3, child: Text(
                          (ci.isNotEmpty && ci != "null") ? ci : "—",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: (ci.isNotEmpty && ci != "null") ? _green : Colors.grey.shade400,
                          ),
                        )),
                        // Check-Out
                        Expanded(flex: 3, child: Text(
                          (co.isNotEmpty && co != "null") ? co : "—",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: (co.isNotEmpty && co != "null") ? _red : Colors.grey.shade400,
                          ),
                        )),
                        // Duration
                        Expanded(flex: 3, child: Text(
                          (dr.isNotEmpty && dr != "null") ? dr : "—",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: (dr.isNotEmpty && dr != "null") ? _blue : Colors.grey.shade400,
                          ),
                        )),
                      ]),
                    );
                  }),
                ]),
              ),
            ),

            // ── Close button ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  child: const Text("Close",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final calendarData = buildCalendar();
    final summary      = _getSummary();

    return GestureDetector(
      onTap: _showMonthlyTablePopup, // ✅ CLICK ANYWHERE → TABLE
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0,4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildHeader(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSummaryRow(summary),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMonthNavigator(),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildWeekHeader(),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: attendanceList.isEmpty
                  ? _buildEmptyState()
                  : _buildGrid(calendarData),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: _buildLegend(),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,

              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER (tap → monthly table) ──────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Text("Attendance",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        const Spacer(),
        Text(
          "${_getShortMonthName(selectedMonth)} $selectedYear",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _SummaryPill(label: "Present",  value: s["P"]!, color: _green),
        _vDiv(),
        _SummaryPill(label: "Absent",   value: s["A"]!, color: _red),
        _vDiv(),
        _SummaryPill(label: "Half Day", value: s["H"]!, color: _amber),
        _vDiv(),
        _SummaryPill(label: "Holiday",  value: s["S"]!, color: _blue),
      ]),
    );
  }

  Widget _vDiv() => Container(width: 1, height: 30, color: _borderColor);

  // ── ARROW MONTH NAVIGATOR (replaces dropdowns) ────────────────────────────
  Widget _buildMonthNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        // ◀ LEFT ARROW
        GestureDetector(
          onTap: _previousMonth,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left_rounded, color: _green),
          ),
        ),

        // 📅 MONTH BOX
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          child: Text(
            _getMonthName(selectedMonth),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _darkText,
            ),
          ),
        ),

        // 📆 YEAR BOX
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          child: Text(
            selectedYear.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _darkText,
            ),
          ),
        ),

        // ▶ RIGHT ARROW
        GestureDetector(
          onTap: _isCurrentMonth ? null : _nextMonth,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isCurrentMonth
                  ? Colors.grey.shade100
                  : _green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: _isCurrentMonth ? Colors.grey.shade300 : _green,
            ),
          ),
        ),
      ],
    );
  }

  // ── WEEK HEADER ───────────────────────────────────────────────────────────
  Widget _buildWeekHeader() {
    const days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) => Expanded(
        child: Center(
          child: Text(d,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: d == "Sun" ? _blue : Colors.grey.shade600,
                letterSpacing: 0.3,
              )),
        ),
      )).toList(),
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
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemBuilder: (context, index) {
        var record = calendarData[index];
        String day = record["day"].toString();

        if (day == "") return const SizedBox();

        DateTime date    = DateTime(selectedYear, selectedMonth, int.parse(day));
        bool isToday     = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day   == DateTime.now().day;
        bool isFuture    = date.isAfter(DateTime.now());

        final bgColor  = getStatusColor(record);
        final txtColor = getStatusTextColor(record);
        final brdColor = isToday ? Colors.white : getStatusBorderColor(record);

        return GestureDetector(
          onTap: isFuture
              ? null
              : () {
            _showCellPopup(Map<String, dynamic>.from(record));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: brdColor, width: isToday ? 2.5 : 1.0),
              boxShadow: isToday
                  ? [BoxShadow(color: _green.withOpacity(0.35), blurRadius: 6, offset: const Offset(0,2))]
                  : [],
            ),
            child: Center(
              child: Text(
                _getDisplayText(record),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: isFuture ? Colors.grey.shade400 : txtColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── LEGEND ────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Wrap(spacing: 12, runSpacing: 6, children: [
      _LegendDot(color: _green, label: "Present"),
      _LegendDot(color: _red,   label: "Absent"),
      _LegendDot(color: _amber, label: "Half Day"),
      _LegendDot(color: _blue,  label: "Holiday"),
    ]);
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(children: [
        Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text("No Attendance Data",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TABLE HEADER CELL
// ═════════════════════════════════════════════════════════════════════════════
class _TH extends StatelessWidget {
  final String label;
  final int    flex;
  const _TH({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: Color(0xFF149D0F), letterSpacing: 0.3,
          )),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  POPUP ROW
// ═════════════════════════════════════════════════════════════════════════════
class _PopupRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _PopupRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        const Spacer(),
        Text(value,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1A1A2E),
            )),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═════════════════════════════════════════════════════════════════════════════
class _SummaryPill extends StatelessWidget {
  final String label; final int value; final Color color;
  const _SummaryPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value.toString(),
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 2),
    Text(label,
        style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
  ]);
}

class _LegendDot extends StatelessWidget {
  final Color color; final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
    ]);
  }
}