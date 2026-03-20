import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TasksPage extends StatefulWidget {
  final String authToken;
  final String empId;

  const TasksPage({
    super.key,
    required this.authToken,
    required this.empId,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  // ── Design tokens ─────────────────────────────────────────────────────────
  static const _green       = Color(0xFF149D0F);
  static const _blue        = Color(0xFF0277BD);
  static const _red         = Color(0xFFE53935);
  static const _amber       = Color(0xFFFFA000);
  static const _darkText    = Color(0xFF1A1A2E);
  static const _borderColor = Color(0xFFEEEEEE);
  static const _cardBg      = Color(0xFFF9FAFB);

  // ── State ─────────────────────────────────────────────────────────────────
  bool   _isLoading    = true;
  bool   _hasError     = false;
  String _errorMessage = "";
  List<Map<String, dynamic>> _tasks    = [];
  int    _totalTasks   = 0;
  String _selectedFilter = "All";

  final List<String> _filters = ["All", "Active", "Completed", "Pending"];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  // ── API CALL (logic unchanged) ─────────────────────────────────────────────
  Future<void> fetchTasks() async {
    setState(() {
      _isLoading    = true;
      _hasError     = false;
      _errorMessage = "";
    });

    try {
      final response = await http.post(
        Uri.parse("https://hrm.eltrive.com/api/tasks"),
        headers: {
          "Content-Type":  "application/json",
          "Authorization": "Bearer ${widget.authToken}",
        },
        body: jsonEncode({"emp_id": widget.empId}),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        final List<dynamic> raw = data["tasks"] ?? [];
        setState(() {
          _totalTasks = data["total_tasks"] ?? 0;
          _tasks      = raw.map((t) => Map<String, dynamic>.from(t)).toList();
          _isLoading  = false;
        });
      } else {
        setState(() {
          _hasError     = true;
          _errorMessage = data["message"] ?? "Failed to load tasks";
          _isLoading    = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError     = true;
        _errorMessage = "Network error: $e";
        _isLoading    = false;
      });
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredTasks {
    if (_selectedFilter == "All") return _tasks;
    return _tasks
        .where((t) =>
    (t["status"] ?? "").toString().toLowerCase() ==
        _selectedFilter.toLowerCase())
        .toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":    return _green;
      case "completed": return _blue;
      case "pending":   return _amber;
      default:          return Colors.grey;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case "active":    return const Color(0xFFE8F5E9);
      case "completed": return const Color(0xFFE3F2FD);
      case "pending":   return const Color(0xFFFFF8E1);
      default:          return Colors.grey.shade100;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case "active":    return Icons.play_circle_rounded;
      case "completed": return Icons.check_circle_rounded;
      case "pending":   return Icons.pause_circle_rounded;
      default:          return Icons.circle_outlined;
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty || date == "0000-00-00") return "No due date";
    try {
      final d = DateTime.parse(date);
      const months = ["Jan","Feb","Mar","Apr","May","Jun",
        "Jul","Aug","Sep","Oct","Nov","Dec"];
      return "${d.day.toString().padLeft(2,'0')} ${months[d.month - 1]} ${d.year}";
    } catch (_) {
      return "No due date";
    }
  }

  bool _isOverdue(String? date) {
    if (date == null || date.isEmpty || date == "0000-00-00") return false;
    try {
      final d = DateTime.parse(date);
      return d.isBefore(DateTime.now()) && d.year > 1;
    } catch (_) {
      return false;
    }
  }

  String _formatCreatedAt(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return "";
    try {
      final d = DateTime.parse(createdAt);
      const months = ["Jan","Feb","Mar","Apr","May","Jun",
        "Jul","Aug","Sep","Oct","Nov","Dec"];
      return "${d.day.toString().padLeft(2,'0')} ${months[d.month - 1]} ${d.year}";
    } catch (_) {
      return createdAt;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _green,
      onRefresh: fetchTasks,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),

            if (_isLoading) _buildLoadingState(),
            if (!_isLoading && _hasError) _buildErrorState(),

            if (!_isLoading && !_hasError) ...[
              _buildSummaryRow(),
              const SizedBox(height: 16),
              _buildFilterRow(),
              const SizedBox(height: 16),

              if (_filteredTasks.isEmpty)
                _buildEmptyState()
              else
                ..._filteredTasks
                    .map((task) => _buildProjectNameCard(task))
                    .toList(),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18, right: -18,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -24, right: 50,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.task_alt_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "MY TASKS",
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white70, letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isLoading
                          ? "Loading..."
                          : "$_totalTasks Task${_totalTasks == 1 ? '' : 's'} Assigned",
                      style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: fetchTasks,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SUMMARY ROW ───────────────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    int active    = _tasks.where((t) => (t["status"] ?? "").toLowerCase() == "active").length;
    int completed = _tasks.where((t) => (t["status"] ?? "").toLowerCase() == "completed").length;
    int pending   = _tasks.where((t) => (t["status"] ?? "").toLowerCase() == "pending").length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: "Total",     value: _totalTasks, color: _darkText),
          _vDivider(),
          _SummaryItem(label: "Active",    value: active,      color: _green),
          _vDivider(),
          _SummaryItem(label: "Completed", value: completed,   color: _blue),
          _vDivider(),
          _SummaryItem(label: "Pending",   value: pending,     color: _amber),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: _borderColor);

  // ── FILTER CHIPS ──────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final bool selected = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _green : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _green : _borderColor,
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: _green.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
                    : [],
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── PROJECT NAME CARD (tap → full detail popup) ───────────────────────────
  Widget _buildProjectNameCard(Map<String, dynamic> task) {
    final String status      = (task["status"] ?? "active").toString();
    final String projectName = (task["project_name"] ?? "Unnamed Project").toString();
    final String taskName    = (task["task_name"] ?? "").toString();
    final String dueDate     = (task["due_date"] ?? "").toString();
    final String taskId      = (task["task_id"] ?? "").toString();
    final List<dynamic> subprojects = task["subprojects"] ?? [];
    final bool overdue =
        _isOverdue(dueDate) && status.toLowerCase() != "completed";

    return GestureDetector(
      onTap: () => _showTaskDetail(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: overdue
                ? _red.withOpacity(0.30)
                : _statusColor(status).withOpacity(0.20),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _statusBg(status),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _statusIcon(status),
                color: _statusColor(status),
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // Project name + task name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project name — primary
                  Text(
                    projectName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 3),
                  // Task name — secondary
                  Text(
                    taskName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  // Subproject count pill
                  if (subprojects.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border:
                        Border.all(color: _blue.withOpacity(0.2)),
                      ),
                      child: Text(
                        "${subprojects.length} subproject${subprojects.length == 1 ? '' : 's'}",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _blue.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right: status badge + overdue/id + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                if (overdue)
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 11, color: _red),
                      const SizedBox(width: 3),
                      Text(
                        "Overdue",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _red,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    "#$taskId",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: Colors.grey.shade300),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── TASK DETAIL BOTTOM SHEET ──────────────────────────────────────────────
  void _showTaskDetail(Map<String, dynamic> task) {
    final String status      = (task["status"] ?? "active").toString();
    final String taskName    = (task["task_name"] ?? "Untitled Task").toString();
    final String projectName = (task["project_name"] ?? "").toString();
    final String description = (task["description"] ?? "").toString();
    final String dueDate     = (task["due_date"] ?? "").toString();
    final String deadline    = (task["deadline"] ?? "").toString();
    final String createdAt   = (task["created_at"] ?? "").toString();
    final String taskId      = (task["task_id"] ?? "").toString();
    final List<dynamic> subprojects = task["subprojects"] ?? [];
    final List<dynamic> subTasks    = task["sub_tasks"] ?? [];
    final bool overdue =
        _isOverdue(dueDate) && status.toLowerCase() != "completed";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // ── Popup header ───────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusColor(status),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _statusColor(status).withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -12, right: -12,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project name row
                      Row(
                        children: [
                          Icon(_statusIcon(status),
                              color: Colors.white, size: 16),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              projectName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "#$taskId",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Task name
                      Text(
                        taskName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Status + overdue badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (overdue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.warning_amber_rounded,
                                      size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    "OVERDUE",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Scrollable detail content ──────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Detail tiles
                    _DetailTile(
                        icon: Icons.folder_rounded,
                        color: _blue,
                        label: "Project",
                        value: projectName),
                    const SizedBox(height: 10),
                    _DetailTile(
                        icon: Icons.task_alt_rounded,
                        color: _statusColor(status),
                        label: "Task",
                        value: taskName),
                    const SizedBox(height: 10),
                    _DetailTile(
                        icon: Icons.flag_rounded,
                        color: _statusColor(status),
                        label: "Status",
                        value: status.toUpperCase()),
                    const SizedBox(height: 10),
                    _DetailTile(
                        icon: Icons.calendar_today_rounded,
                        color: overdue ? _red : Colors.grey,
                        label: "Due Date",
                        value: _formatDate(dueDate)),
                    if (deadline.isNotEmpty && deadline != "null") ...[
                      const SizedBox(height: 10),
                      _DetailTile(
                          icon: Icons.event_busy_rounded,
                          color: _amber,
                          label: "Deadline",
                          value: deadline),
                    ],
                    const SizedBox(height: 10),
                    _DetailTile(
                        icon: Icons.access_time_rounded,
                        color: Colors.grey,
                        label: "Created On",
                        value: _formatCreatedAt(createdAt)),

                    // Description
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const _SectionLabel(label: "DESCRIPTION"),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],

                    // Subprojects
                    if (subprojects.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const _SectionLabel(label: "SUBPROJECTS"),
                      const SizedBox(height: 8),
                      ...subprojects.asMap().entries.map(
                            (e) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _blue.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                  color: _blue.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "${e.key + 1}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _blue,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _blue.withOpacity(0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Sub-tasks
                    if (subTasks.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const _SectionLabel(label: "SUB-TASKS"),
                      const SizedBox(height: 8),
                      ...subTasks.map(
                            (st) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.subdirectory_arrow_right_rounded,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  st.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _darkText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOADING STATE ─────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        4,
            (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(
                color: _green, strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }

  // ── ERROR STATE ───────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: _red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: _red.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: fetchTasks,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.checklist_rounded,
              size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            _selectedFilter == "All"
                ? "No tasks assigned"
                : "No $_selectedFilter tasks",
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
}

// ═════════════════════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _SummaryItem extends StatelessWidget {
  final String label;
  final int    value;
  final Color  color;
  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;
  const _DetailTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}