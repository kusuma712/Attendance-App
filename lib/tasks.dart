import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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
  static const _green       = Color(0xFF149D0F);
  static const _blue        = Color(0xFF0277BD);
  static const _red         = Color(0xFFE53935);
  static const _amber       = Color(0xFFFFA000);
  static const _darkText    = Color(0xFF1A1A2E);
  static const _borderColor = Color(0xFFEEEEEE);
  static const _cardBg      = Color(0xFFF9FAFB);

  bool   _isLoading    = true;
  bool   _hasError     = false;
  String _errorMessage = "";
  List<Map<String, dynamic>> _tasks = [];
  int    _totalTasks   = 0;
  String _selectedFilter = "All";

  final List<String> _filters = ["All", "Active", "Completed", "Pending"];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  // ── FETCH TASKS ────────────────────────────────────────────────────────────
  Future<void> fetchTasks() async {
    setState(() { _isLoading = true; _hasError = false; _errorMessage = ""; });
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
          _totalTasks = (data["total_tasks"] is int)
              ? data["total_tasks"]
              : int.tryParse(data["total_tasks"].toString()) ?? 0;
          _tasks = raw.map((t) {
            final map = Map<String, dynamic>.from(t as Map);
            map["subprojects"] = _toStringList(map["subprojects"]);
            map["sub_tasks"]   = _toStringList(map["sub_tasks"]);
            return map;
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError     = true;
          _errorMessage = data["message"]?.toString() ?? "Failed to load tasks";
          _isLoading    = false;
        });
      }
    } catch (e) {
      setState(() { _hasError = true; _errorMessage = "Network error: $e"; _isLoading = false; });
    }
  }

  List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  List<Map<String, dynamic>> get _filteredTasks {
    if (_selectedFilter == "All") return _tasks;
    return _tasks.where((t) =>
    (t["status"] ?? "").toString().toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case "active":    return _green;
      case "completed": return _blue;
      case "pending":   return _amber;
      default:          return Colors.grey;
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case "active":    return const Color(0xFFE8F5E9);
      case "completed": return const Color(0xFFE3F2FD);
      case "pending":   return const Color(0xFFFFF8E1);
      default:          return Colors.grey.shade100;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
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
      const m = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
      return "${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}";
    } catch (_) { return "No due date"; }
  }

  bool _isOverdue(String? date) {
    if (date == null || date.isEmpty || date == "0000-00-00") return false;
    try {
      final d = DateTime.parse(date);
      return d.isBefore(DateTime.now()) && d.year > 1;
    } catch (_) { return false; }
  }

  String _formatCreatedAt(String? v) {
    if (v == null || v.isEmpty) return "";
    try {
      final d = DateTime.parse(v);
      const m = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
      return "${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}";
    } catch (_) { return v; }
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
    _buildProjectListCard(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _green.withOpacity(0.30), blurRadius: 16, offset: const Offset(0,6))],
      ),
      child: Stack(children: [
        Positioned(top: -18, right: -18,
            child: Container(width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("MY TASKS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1.2)),
            const SizedBox(height: 3),
            Text(_isLoading ? "Loading..." : "$_totalTasks Task${_totalTasks == 1 ? '' : 's'} Assigned",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          ])),
          GestureDetector(
            onTap: fetchTasks,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSummaryRow() {
    int active    = _tasks.where((t) => (t["status"] ?? "").toLowerCase() == "active").length;
    int completed = _tasks.where((t) => (t["status"] ?? "").toLowerCase() == "completed").length;
    int pending   = _tasks.where((t) => (t["status"] ?? "").toLowerCase() == "pending").length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _SummaryItem(label: "Total",     value: _totalTasks, color: _darkText),
        _vDivider(),
        _SummaryItem(label: "Active",    value: active,      color: _green),
        _vDivider(),
        _SummaryItem(label: "Completed", value: completed,   color: _blue),
        _vDivider(),
        _SummaryItem(label: "Pending",   value: pending,     color: _amber),
      ]),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 32, color: _borderColor);

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final bool sel = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _green : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _green : _borderColor, width: 1.5),
                boxShadow: sel ? [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 8, offset: const Offset(0,3))] : [],
              ),
              child: Text(f, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey.shade600)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProjectListCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: _filteredTasks.map((task) {
          final String status      = (task["status"] ?? "active").toString();
          final String projectName = (task["project_name"] ?? "Unnamed Project").toString();
          final String taskName    = (task["task_name"] ?? "").toString();
          final String dueDate     = (task["due_date"] ?? "").toString();
          final String taskId      = (task["task_id"] ?? "").toString();
          final bool overdue = _isOverdue(dueDate) && status.toLowerCase() != "completed";

          return GestureDetector(
            onTap: () => _showTaskDetail(task), // ✅ SAME LOGIC
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _darkText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          taskName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 👉 RIGHT SIDE ARROW
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── TASK DETAIL ───────────────────────────────────────────────────────────
  void _showTaskDetail(Map<String, dynamic> task) {
    final String status      = (task["status"] ?? "active").toString();
    final String taskName    = (task["task_name"] ?? "Untitled Task").toString();
    final String projectName = (task["project_name"] ?? "").toString();
    final String description = (task["description"] ?? "").toString();
    final String dueDate     = (task["due_date"] ?? "").toString();
    final String deadline    = (task["deadline"] ?? "").toString();
    final String createdAt   = (task["created_at"] ?? "").toString();
    final String taskId      = (task["task_id"] ?? "").toString();
    final List<String> subprojects = task["subprojects"] is List ? List<String>.from(task["subprojects"]) : [];
    final List<String> subTasks    = task["sub_tasks"] is List ? List<String>.from(task["sub_tasks"]) : [];
    final bool overdue = _isOverdue(dueDate) && status.toLowerCase() != "completed";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [

            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // PROJECT NAME
                    Text(
                      projectName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // TASK NAME
                    Text(
                      taskName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _darkText,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // DETAILS SIMPLE TEXT
                    Text("Status: ${status.toUpperCase()}"),
                    const SizedBox(height: 6),
                    Text("Task ID: #$taskId"),
                    const SizedBox(height: 6),
                    Text("Due Date: ${_formatDate(dueDate)}"),
                    const SizedBox(height: 6),
                    Text("Created On: ${_formatCreatedAt(createdAt)}"),

                    if (deadline.isNotEmpty && deadline != "null") ...[
                      const SizedBox(height: 6),
                      Text("Deadline: $deadline"),
                    ],

                    if (overdue) ...[
                      const SizedBox(height: 6),
                      Text(
                        "Overdue",
                        style: TextStyle(
                          color: _red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    // DESCRIPTION
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(description),
                    ],

                    // SUBPROJECTS
                    if (subprojects.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        "Subprojects",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      ...subprojects.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text("• $e"),
                      )),
                    ],

                    // SUBTASKS
                    if (subTasks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        "Sub Tasks",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      ...subTasks.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text("• $e"),
                      )),
                    ],

                    const SizedBox(height: 30),

                    // SUBMIT BUTTON (UNCHANGED LOGIC)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showReportForm(taskId, projectName, taskName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Submit Task Report",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
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

  // ── TASK REPORT FORM ──────────────────────────────────────────────────────
  void _showReportForm(String taskId, String projectName, String taskName) {
    final TextEditingController descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    File? selectedFile;
    String? selectedFileName;
    bool isSubmitting = false;

    String fmtDate(DateTime d) =>
        "${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";
    String fmtTime(TimeOfDay t) =>
        "${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setFormState) {

          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(primary: _green, onPrimary: Colors.white),
                ),
                child: child!,
              ),
            );
            if (picked != null) setFormState(() => selectedDate = picked);
          }

          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: selectedTime,
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(primary: _green, onPrimary: Colors.white),
                ),
                child: child!,
              ),
            );
            if (picked != null) setFormState(() => selectedTime = picked);
          }

          Future<void> pickFromCamera() async {
            try {
              final XFile? img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
              if (img != null) setFormState(() { selectedFile = File(img.path); selectedFileName = img.name; });
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Camera error: $e"), backgroundColor: _red));
            }
          }

          Future<void> pickFromGallery() async {
            try {
              final XFile? img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
              if (img != null) setFormState(() { selectedFile = File(img.path); selectedFileName = img.name; });
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gallery error: $e"), backgroundColor: _red));
            }
          }

          Future<void> pickAnyFile() async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
              if (result != null && result.files.single.path != null) {
                setFormState(() { selectedFile = File(result.files.single.path!); selectedFileName = result.files.single.name; });
              }
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File error: $e"), backgroundColor: _red));
            }
          }

          void showFilePicker() {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 16),
                  const Text("Attach File", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkText)),
                  const SizedBox(height: 4),
                  Text("Choose a source", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 18),
                  _FileSourceTile(icon: Icons.camera_alt_rounded, color: _blue, label: "Take Photo", subtitle: "Use device camera",
                      onTap: () { Navigator.pop(ctx); pickFromCamera(); }),
                  const SizedBox(height: 10),
                  _FileSourceTile(icon: Icons.photo_library_rounded, color: _amber, label: "Choose from Gallery", subtitle: "Pick from your photos",
                      onTap: () { Navigator.pop(ctx); pickFromGallery(); }),
                  const SizedBox(height: 10),
                  _FileSourceTile(icon: Icons.attach_file_rounded, color: _green, label: "Browse Files", subtitle: "PDF, DOC, XLS and more",
                      onTap: () { Navigator.pop(ctx); pickAnyFile(); }),
                ]),
              ),
            );
          }

          // ── SUBMIT ───────────────────────────────────────────────────────
          Future<void> submitReport() async {

            // ── Validation popup ─────────────────────────────────────────
            if (descController.text.trim().isEmpty) {
              await showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: _amber.withOpacity(0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber_rounded, color: _amber, size: 40),
                      ),
                      const SizedBox(height: 14),
                      const Text("Description Required",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkText)),
                      const SizedBox(height: 8),
                      Text("Please enter a description before submitting.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _amber,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("OK", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ]),
                  ),
                ),
              );
              return;
            }

            setFormState(() => isSubmitting = true);

            try {
              var request = http.MultipartRequest(
                "POST",
                Uri.parse("https://hrm.eltrive.com/api/taskreport"),
              );

              request.headers["Authorization"] = "Bearer ${widget.authToken}";
              request.fields["task_id"]     = taskId.toString();
              request.fields["report_date"] = fmtDate(selectedDate);
              request.fields["report_time"] = fmtTime(selectedTime);
              request.fields["description"] = descController.text.trim();

              if (selectedFile != null && await selectedFile!.exists()) {
                request.files.add(await http.MultipartFile.fromPath("file", selectedFile!.path));
              }

              final streamed = await request.send();
              final rawBody  = await streamed.stream.bytesToString(); // ✅ read raw string first

              debugPrint("TaskReport RAW response: $rawBody");       // ✅ print to debug console

              setFormState(() => isSubmitting = false);

              // ✅ Safe parse — handles HTML, empty, or malformed responses
              String statusValue  = "error";
              String messageValue = rawBody.isNotEmpty ? rawBody : "No response from server";

              try {
                // strip BOM or whitespace that breaks jsonDecode
                final cleaned = rawBody.trim().replaceAll('\uFEFF', '');
                final decoded = jsonDecode(cleaned);
                if (decoded is Map) {
                  statusValue  = decoded["status"]?.toString()  ?? "error";
                  messageValue = decoded["message"]?.toString() ?? "No message";
                }
              } catch (_) {
                // response was not JSON — messageValue already has rawBody
                statusValue = "error";
              }

              if (statusValue == "success") {
                if (context.mounted) Navigator.pop(context); // close form
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: _green.withOpacity(0.10), shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle_rounded, color: _green, size: 48),
                          ),
                          const SizedBox(height: 16),
                          const Text("Report Submitted!",
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _darkText)),
                          const SizedBox(height: 8),
                          Text(messageValue, textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                }
              } else {
                // ✅ Show error popup instead of just a snackbar
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: _red.withOpacity(0.10), shape: BoxShape.circle),
                            child: const Icon(Icons.error_outline_rounded, color: _red, size: 40),
                          ),
                          const SizedBox(height: 14),
                          const Text("Submission Failed",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkText)),
                          const SizedBox(height: 8),
                          Text(messageValue, textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                }
              }
            } catch (e) {
              setFormState(() => isSubmitting = false);
              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: _red.withOpacity(0.10), shape: BoxShape.circle),
                          child: const Icon(Icons.wifi_off_rounded, color: _red, size: 40),
                        ),
                        const SizedBox(height: 14),
                        const Text("Network Error",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkText)),
                        const SizedBox(height: 8),
                        Text(e.toString(), textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              }
            }
          }

          // ── FORM UI ──────────────────────────────────────────────────────
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // Date
                      const _SectionLabel(label: "REPORT DATE"),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderColor)),
                          child: Row(children: [
                            Container(padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(color: _green.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.calendar_today_rounded, color: _green, size: 16)),
                            const SizedBox(width: 12),
                            Text(fmtDate(selectedDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkText)),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Time
                      const _SectionLabel(label: "REPORT TIME"),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: pickTime,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderColor)),
                          child: Row(children: [
                            Container(padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(color: _blue.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.access_time_rounded, color: _blue, size: 16)),
                            const SizedBox(width: 12),
                            Text(fmtTime(selectedTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkText)),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Description
                      const _SectionLabel(label: "DESCRIPTION *"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: "Describe the work completed...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          filled: true, fillColor: _cardBg,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Attachment
                      const _SectionLabel(label: "ATTACHMENT (OPTIONAL)"),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: showFilePicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: selectedFile != null ? _green.withOpacity(0.05) : _cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedFile != null ? _green.withOpacity(0.40) : _borderColor,
                              width: selectedFile != null ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: selectedFile != null ? _green.withOpacity(0.12) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                selectedFile != null ? Icons.check_circle_outline_rounded : Icons.attach_file_rounded,
                                color: selectedFile != null ? _green : Colors.grey.shade500, size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(
                              selectedFileName ?? "Tap to attach a file or photo",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selectedFile != null ? FontWeight.w600 : FontWeight.w400,
                                color: selectedFile != null ? _darkText : Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )),
                            if (selectedFile != null)
                              GestureDetector(
                                onTap: () => setFormState(() { selectedFile = null; selectedFileName = null; }),
                                child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400),
                              )
                            else
                              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            disabledBackgroundColor: _green.withOpacity(0.6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text("Submit Report",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade600)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }


  Widget _buildLoadingState() {
    return Column(children: List.generate(4, (i) => Container(
      margin: const EdgeInsets.only(bottom: 12), height: 72,
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
      child: const Center(child: CircularProgressIndicator(color: _green, strokeWidth: 2.5)),
    )));
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(color: _red.withOpacity(0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: _red.withOpacity(0.2))),
      child: Column(children: [
        Icon(Icons.error_outline_rounded, size: 48, color: _red.withOpacity(0.6)),
        const SizedBox(height: 12),
        Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: fetchTasks,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text("Retry"),
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(Icons.checklist_rounded, size: 52, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(_selectedFilter == "All" ? "No tasks assigned" : "No $_selectedFilter tasks",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _SummaryItem extends StatelessWidget {
  final String label; final int value; final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
  ]);
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: 1.0));
}

class _DetailTile extends StatelessWidget {
  final IconData icon; final Color color; final String label; final String value;
  const _DetailTile({required this.icon, required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color)),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      const Spacer(),
      Flexible(child: Text(value, textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
    ]),
  );
}

class _FileSourceTile extends StatelessWidget {
  final IconData icon; final Color color; final String label; final String subtitle; final VoidCallback onTap;
  const _FileSourceTile({required this.icon, required this.color, required this.label, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ])),
        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
      ]),
    ),
  );
}