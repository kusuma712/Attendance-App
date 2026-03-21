import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EXPENSE ITEM MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ExpenseItem {
  TextEditingController billRefController     = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController amountController      = TextEditingController();
  DateTime? billDate;
  String  fileName = "";
  String? filePath;
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPENSES PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ExpensesPage extends StatefulWidget {
  final String token;

  const ExpensesPage({super.key, required this.token});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  // ── Design tokens ─────────────────────────────────────────────────────────
  static const _green       = Color(0xFF149D0F);
  static const _red         = Color(0xFFE53935);
  static const _amber       = Color(0xFFFFA000);
  static const _darkText    = Color(0xFF1A1A2E);
  static const _borderColor = Color(0xFFEEEEEE);
  static const _cardBg      = Color(0xFFF9FAFB);

  // ── State ─────────────────────────────────────────────────────────────────
  String? _selectedExpenseType;
  String? _selectedProjectType;
  String  _selectedGST     = "yes";
  String? _selectedCompany;          // ✅ new

  List<dynamic> expenseTypes = [];
  List<dynamic> projectTypes = [];
  List<dynamic> fuelTypes    = [];
  List<dynamic> companies    = [];   // ✅ new — loaded from masterdata

  List<ExpenseItem> _expenseItems = [ExpenseItem()];

  bool _isSubmitting = false;

  // ── Fuel fields ───────────────────────────────────────────────────────────
  String? _selectedFuelType;
  final TextEditingController startKmController         = TextEditingController();
  final TextEditingController endKmController           = TextEditingController();
  final TextEditingController fuelAmountController      = TextEditingController();
  final TextEditingController fuelDescriptionController = TextEditingController();
  DateTime? fuelBillDate;
  String? _travelAuthorizedBy;
  String  fuelFileName = "";
  String? fuelFilePath;

  final List<String> travelAuthList = [
    "Gopisetty Rajesh",
    "Vardhineedi Adi Seshu",
    "HR",
  ];

  @override
  void initState() {
    super.initState();
    _travelAuthorizedBy = travelAuthList.first;
    fetchMasterData();
  }

  @override
  void dispose() {
    startKmController.dispose();
    endKmController.dispose();
    fuelAmountController.dispose();
    fuelDescriptionController.dispose();
    super.dispose();
  }

  // ── IS FUEL SELECTED ──────────────────────────────────────────────────────
  bool get isFuelSelected {
    if (_selectedExpenseType == null) return false;
    final selected = expenseTypes.firstWhere(
          (e) => e["id"].toString() == _selectedExpenseType.toString(),
      orElse: () => <String, dynamic>{},
    );
    return (selected["name"]?.toString().toLowerCase().contains("fuel")) ?? false;
  }

  // ── FETCH MASTER DATA ─────────────────────────────────────────────────────
  Future<void> fetchMasterData() async {
    try {
      final res = await http.post(
        Uri.parse("https://hrm.eltrive.com/api/masterdata"),
        headers: {
          "Content-Type":  "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );
      final data = jsonDecode(res.body);
      if (data["status"] == "success") {
        setState(() {
          expenseTypes = data["data"]["expenses_types"] ?? [];
          projectTypes = data["data"]["project_types"]  ?? [];
          fuelTypes    = data["data"]["fuel_types"]      ?? [];
          companies    = data["data"]["companies"]        ?? []; // ✅ load companies
        });
      }
    } catch (e) {
      debugPrint("MasterData error: $e");
    }
  }

  // ── FILE HELPERS ──────────────────────────────────────────────────────────
  Future<String> _fileToBase64(String path) async {
    final bytes = await File(path).readAsBytes();
    return base64Encode(bytes);
  }

  String _getFileExt(String path) {
    final parts = path.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : "jpg";
  }

  // ── SUBMIT EXPENSE ────────────────────────────────────────────────────────
  Future<void> _submitExpense() async {

    // ── Validation ────────────────────────────────────────────────────────
    if (_selectedExpenseType == null) {
      _showAlertPopup(title: "Missing Field", message: "Please select an Expense Type.", isSuccess: false);
      return;
    }
    if (_selectedProjectType == null) {
      _showAlertPopup(title: "Missing Field", message: "Please select a Project Type.", isSuccess: false);
      return;
    }

    // ✅ Company required only when GST = yes and not fuel
    if (!isFuelSelected && _selectedGST == "yes" && _selectedCompany == null) {
      _showAlertPopup(title: "Missing Field", message: "Please select a Company.", isSuccess: false);
      return;
    }

    if (isFuelSelected) {
      if (_selectedFuelType == null) {
        _showAlertPopup(title: "Missing Field", message: "Please select a Fuel Type.", isSuccess: false);
        return;
      }
      if (startKmController.text.trim().isEmpty) {
        _showAlertPopup(title: "Missing Field", message: "Please enter Start KM.", isSuccess: false);
        return;
      }
      if (endKmController.text.trim().isEmpty) {
        _showAlertPopup(title: "Missing Field", message: "Please enter End KM.", isSuccess: false);
        return;
      }
      if (fuelBillDate == null) {
        _showAlertPopup(title: "Missing Field", message: "Please select Bill Date.", isSuccess: false);
        return;
      }
      if (fuelAmountController.text.trim().isEmpty) {
        _showAlertPopup(title: "Missing Field", message: "Please enter Amount.", isSuccess: false);
        return;
      }
    } else {
      for (int i = 0; i < _expenseItems.length; i++) {
        final item = _expenseItems[i];
        if (item.billRefController.text.trim().isEmpty) {
          _showAlertPopup(title: "Missing Field", message: "Please enter Bill Number for item ${i + 1}.", isSuccess: false);
          return;
        }
        if (item.amountController.text.trim().isEmpty) {
          _showAlertPopup(title: "Missing Field", message: "Please enter Amount for item ${i + 1}.", isSuccess: false);
          return;
        }
        if (item.billDate == null) {
          _showAlertPopup(title: "Missing Field", message: "Please select Bill Date for item ${i + 1}.", isSuccess: false);
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      Map<String, dynamic> body;

      if (isFuelSelected) {
        // ── FUEL EXPENSE ────────────────────────────────────────────────
        String base64Str = " ";
        String extStr    = "jpg";
        if (fuelFilePath != null && File(fuelFilePath!).existsSync()) {
          base64Str = await _fileToBase64(fuelFilePath!);
          extStr    = _getFileExt(fuelFilePath!);
        }

        body = {
          "auth_token":       widget.token,
          "expenses_type_id": int.tryParse(_selectedExpenseType ?? "0") ?? 0,
          "project_type_id":  int.tryParse(_selectedProjectType ?? "0") ?? 0,
          "gst_applicable":   "no",
          "fuel_type_id":     int.tryParse(_selectedFuelType ?? "0") ?? 0,
          "details": [
            {
              "bill_date":        _formatDate(fuelBillDate!),
              "billnumber1":      fuelDescriptionController.text.trim(),
              "amount":           double.tryParse(fuelAmountController.text.trim()) ?? 0.0,
              "started_km":       int.tryParse(startKmController.text.trim()) ?? 0,
              "ended_km":         int.tryParse(endKmController.text.trim()) ?? 0,
              "authorized_by":    _travelAuthorizedBy ?? "",
              "bill_file_base64": base64Str,
              "bill_file_ext":    extStr,
            }
          ],
        };

      } else {
        // ── GENERAL EXPENSE ──────────────────────────────────────────────
        List<Map<String, dynamic>> details = [];

        for (final item in _expenseItems) {
          String base64Str = " ";
          String extStr    = "jpg";
          if (item.filePath != null && File(item.filePath!).existsSync()) {
            base64Str = await _fileToBase64(item.filePath!);
            extStr    = _getFileExt(item.filePath!);
          }

          details.add({
            "bill_number":      item.billRefController.text.trim(),
            "billnumber1":      item.descriptionController.text.trim(),
            "bill_date":        _formatDate(item.billDate!),
            "amount":           double.tryParse(item.amountController.text.trim()) ?? 0.0,
            "bill_file_base64": base64Str,
            "bill_file_ext":    extStr,
          });
        }

        body = {
          "auth_token":       widget.token,
          "expenses_type_id": int.tryParse(_selectedExpenseType ?? "0") ?? 0,
          "project_type_id":  int.tryParse(_selectedProjectType ?? "0") ?? 0,
          "gst_applicable":   _selectedGST,
          // ✅ send company_id only when GST = yes
          "company_id":       _selectedGST == "yes"
              ? (_selectedCompany ?? "1")
              : "1",
          "details": details,
        };
      }

      debugPrint("Expense body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse("https://hrm.eltrive.com/api/expense"),
        headers: {
          "Content-Type":  "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(body),
      );

      final rawBody = response.body;
      debugPrint("Expense response [${response.statusCode}]: $rawBody");

      setState(() => _isSubmitting = false);

      String statusValue  = "error";
      String messageValue = rawBody.isNotEmpty ? rawBody : "No response from server";

      try {
        final cleaned = rawBody.trim().replaceAll('\uFEFF', '');
        final decoded = jsonDecode(cleaned);
        if (decoded is Map) {
          statusValue  = decoded["status"]?.toString()  ?? "error";
          messageValue = decoded["message"]?.toString() ?? "No message";
        }
      } catch (_) {}

      if (statusValue == "success") {
        _showAlertPopup(title: "Expense Submitted!", message: messageValue, isSuccess: true);
        _resetForm();
      } else {
        _showAlertPopup(title: "Submission Failed", message: messageValue, isSuccess: false);
      }

    } catch (e) {
      setState(() => _isSubmitting = false);
      _showAlertPopup(title: "Network Error", message: e.toString(), isSuccess: false);
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";

  String _displayDate(DateTime? d) {
    if (d == null) return "Select Date";
    const months = ["Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"];
    return "${d.day.toString().padLeft(2,'0')} ${months[d.month-1]} ${d.year}";
  }

  void _resetForm() {
    setState(() {
      _selectedExpenseType = null;
      _selectedProjectType = null;
      _selectedGST         = "yes";
      _selectedCompany     = null;   // ✅ reset
      _selectedFuelType    = null;
      _expenseItems        = [ExpenseItem()];
      startKmController.clear();
      endKmController.clear();
      fuelAmountController.clear();
      fuelDescriptionController.clear();
      fuelBillDate         = null;
      fuelFileName         = "";
      fuelFilePath         = null;
      _travelAuthorizedBy  = travelAuthList.first;
    });
  }

  // ── FILE PICKER ───────────────────────────────────────────────────────────
  void _showFilePicker({required Function(String path, String name) onPicked}) {
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
          const Text("Attach File",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkText)),
          const SizedBox(height: 4),
          Text("Choose a source", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 18),
          _FileSourceTile(
            icon: Icons.camera_alt_rounded, color: const Color(0xFF0277BD),
            label: "Take Photo", subtitle: "Use device camera",
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final XFile? img = await ImagePicker().pickImage(
                    source: ImageSource.camera, imageQuality: 80);
                if (img != null) onPicked(img.path, img.name);
              } catch (e) {
                _showAlertPopup(title: "Camera Error", message: e.toString(), isSuccess: false);
              }
            },
          ),
          const SizedBox(height: 10),
          _FileSourceTile(
            icon: Icons.photo_library_rounded, color: _amber,
            label: "Choose from Gallery", subtitle: "Pick from your photos",
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final XFile? img = await ImagePicker().pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (img != null) onPicked(img.path, img.name);
              } catch (e) {
                _showAlertPopup(title: "Gallery Error", message: e.toString(), isSuccess: false);
              }
            },
          ),
          const SizedBox(height: 10),
          _FileSourceTile(
            icon: Icons.attach_file_rounded, color: _green,
            label: "Browse Files", subtitle: "PDF, DOC, XLS and more",
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final result = await FilePicker.platform.pickFiles(
                    type: FileType.any, allowMultiple: false);
                if (result != null && result.files.single.path != null) {
                  onPicked(result.files.single.path!, result.files.single.name);
                }
              } catch (e) {
                _showAlertPopup(title: "File Error", message: e.toString(), isSuccess: false);
              }
            },
          ),
        ]),
      ),
    );
  }

  // ── ALERT POPUP ───────────────────────────────────────────────────────────
  void _showAlertPopup({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    final color = isSuccess ? _green : _red;
    final icon  = isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.10), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkText)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text("OK",
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Expense",
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: Colors.black, letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              isFuelSelected ? "Fuel Expense" : "General Expense",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _green),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Expense Details card ─────────────────────────────────────────
            _SectionCard(
              title: "Expense Details",
              child: Column(children: [

                // Expense Type
                _buildDynamicDropdown(
                  value: _selectedExpenseType,
                  hint: "Expense Type *",
                  items: expenseTypes,
                  onChanged: (val) => setState(() {
                    _selectedExpenseType = val;
                    // reset company when switching type
                    _selectedCompany = null;
                  }),
                ),
                const SizedBox(height: 14),

                // Project Type
                _buildDynamicDropdown(
                  value: _selectedProjectType,
                  hint: "Project Type *",
                  items: projectTypes,
                  onChanged: (val) => setState(() => _selectedProjectType = val),
                ),

                // GST + Company (only for general expense)
                if (!isFuelSelected) ...[
                  const SizedBox(height: 14),
                  _buildStaticDropdown(
                    label: "GST Applicable",
                    value: _selectedGST,
                    items: const ["yes", "no"],
                    onChanged: (val) => setState(() {
                      _selectedGST     = val;
                      _selectedCompany = null; // reset when GST changes
                    }),
                  ),

                  // ✅ Company dropdown — only visible when GST = yes
                  if (_selectedGST == "yes") ...[
                    const SizedBox(height: 14),
                    // Animated appearance
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _buildCompanyDropdown(),
                    ),
                  ],
                ],
              ]),
            ),

            // ── General expense bill items ────────────────────────────────────
            if (!isFuelSelected) ...[
              ..._expenseItems.asMap().entries.map((entry) {
                final idx  = entry.key;
                final item = entry.value;
                return _SectionCard(
                  title: _expenseItems.length > 1
                      ? "Bill Item ${idx + 1}"
                      : "Bill Information",
                  trailing: _expenseItems.length > 1
                      ? GestureDetector(
                    onTap: () => setState(() => _expenseItems.removeAt(idx)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, color: _red, size: 16),
                    ),
                  )
                      : null,
                  child: Column(children: [
                    _StyledTextField(
                      controller: item.billRefController,
                      label: "Bill Number *",
                      icon: Icons.receipt_rounded,
                    ),
                    const SizedBox(height: 12),
                    _StyledTextField(
                      controller: item.descriptionController,
                      label: "Description",
                      icon: Icons.notes_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _StyledTextField(
                      controller: item.amountController,
                      label: "Amount *",
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _DatePickerTile(
                      label: "Bill Date *",
                      value: _displayDate(item.billDate),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: item.billDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(primary: _green),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setState(() => item.billDate = picked);
                      },
                    ),
                    const SizedBox(height: 12),
                    _FileTile(
                      fileName: item.fileName,
                      onTap: () => _showFilePicker(onPicked: (path, name) {
                        setState(() { item.filePath = path; item.fileName = name; });
                      }),
                      onRemove: item.fileName.isNotEmpty
                          ? () => setState(() { item.filePath = null; item.fileName = ""; })
                          : null,
                    ),
                  ]),
                );
              }),

              // Add more items
              GestureDetector(
                onTap: () => setState(() => _expenseItems.add(ExpenseItem())),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _green.withOpacity(0.30)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_circle_outline_rounded, size: 18, color: _green.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text("Add Another Bill Item",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: _green.withOpacity(0.85))),
                  ]),
                ),
              ),
            ],

            // ── Fuel expense ──────────────────────────────────────────────────
            if (isFuelSelected) ...[
              _SectionCard(
                title: "Fuel Details",
                child: Column(children: [
                  _buildDynamicDropdown(
                    value: _selectedFuelType,
                    hint: "Fuel Type *",
                    items: fuelTypes,
                    onChanged: (val) => setState(() => _selectedFuelType = val),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _StyledTextField(
                      controller: startKmController,
                      label: "Start KM *",
                      icon: Icons.speed_rounded,
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StyledTextField(
                      controller: endKmController,
                      label: "End KM *",
                      icon: Icons.speed_rounded,
                      keyboardType: TextInputType.number,
                    )),
                  ]),
                  const SizedBox(height: 12),
                  _StyledTextField(
                    controller: fuelDescriptionController,
                    label: "Description",
                    icon: Icons.notes_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _DatePickerTile(
                    label: "Bill Date *",
                    value: _displayDate(fuelBillDate),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fuelBillDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(primary: _green),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => fuelBillDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  _StyledTextField(
                    controller: fuelAmountController,
                    label: "Amount *",
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildStaticDropdown(
                    label: "Authorized By",
                    value: _travelAuthorizedBy ?? travelAuthList.first,
                    items: travelAuthList,
                    onChanged: (val) => setState(() => _travelAuthorizedBy = val),
                  ),
                  const SizedBox(height: 12),
                  _FileTile(
                    fileName: fuelFileName,
                    onTap: () => _showFilePicker(onPicked: (path, name) {
                      setState(() { fuelFilePath = path; fuelFileName = name; });
                    }),
                    onRemove: fuelFileName.isNotEmpty
                        ? () => setState(() { fuelFilePath = null; fuelFileName = ""; })
                        : null,
                  ),
                ]),
              ),
            ],

            // ── Submit ────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: _green.withOpacity(0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text("Submit Expense",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── COMPANY DROPDOWN ──────────────────────────────────────────────────────
  // ✅ uses company_name field from API (not "name")
  Widget _buildCompanyDropdown() {
    return DropdownButtonFormField<String>(
      key: const ValueKey("company_dropdown"),
      value: _selectedCompany,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Select Company *",
        prefixIcon: Icon(Icons.business_rounded, size: 18, color: Colors.grey.shade500),
        filled: true,
        fillColor: _cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
      ),
      selectedItemBuilder: (context) => companies.map<Widget>((c) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            c["company_name"]?.toString() ?? "",
            overflow: TextOverflow.ellipsis, maxLines: 1,
            style: const TextStyle(fontSize: 14, color: _darkText),
          ),
        );
      }).toList(),
      items: companies.map<DropdownMenuItem<String>>((c) {
        return DropdownMenuItem(
          value: c["id"]?.toString(),
          child: Text(c["company_name"]?.toString() ?? "",
              overflow: TextOverflow.ellipsis, maxLines: 1),
        );
      }).toList(),
      onChanged: (val) { if (val != null) setState(() => _selectedCompany = val); },
    );
  }

  // ── DROPDOWN BUILDERS ─────────────────────────────────────────────────────
  Widget _buildDynamicDropdown({
    required String? value,
    required String hint,
    required List<dynamic> items,
    required Function(String) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: hint,
        filled: true,
        fillColor: _cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
      ),
      selectedItemBuilder: (context) => items.map<Widget>((item) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(item["name"]?.toString() ?? "",
              overflow: TextOverflow.ellipsis, maxLines: 1,
              style: const TextStyle(fontSize: 14, color: _darkText)),
        );
      }).toList(),
      items: items.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem(
          value: item["id"]?.toString(),
          child: Text(item["name"]?.toString() ?? "",
              overflow: TextOverflow.ellipsis, maxLines: 1),
        );
      }).toList(),
      onChanged: (val) { if (val != null) onChanged(val); },
    );
  }

  Widget _buildStaticDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
      ),
      items: items.map((e) => DropdownMenuItem(
        value: e,
        child: Text(e, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (val) { if (val != null) onChanged(val); },
    );
  }
} // ✅ END OF _ExpensesPageState

// ═════════════════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String  title;
  final Widget  child;
  final Widget? trailing;
  static const _borderColor = Color(0xFFEEEEEE);
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(children: [
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: Colors.black, letterSpacing: 0.2))),
            if (trailing != null) trailing!,
          ]),
        ),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ]),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String        label;
  final IconData      icon;
  final int           maxLines;
  final TextInputType keyboardType;
  static const _green       = Color(0xFF149D0F);
  static const _borderColor = Color(0xFFEEEEEE);
  static const _cardBg      = Color(0xFFF9FAFB);
  const _StyledTextField({
    required this.controller, required this.label, required this.icon,
    this.maxLines = 1, this.keyboardType = TextInputType.text,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, maxLines: maxLines, keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade500),
        filled: true, fillColor: _cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  static const _green       = Color(0xFF149D0F);
  static const _borderColor = Color(0xFFEEEEEE);
  static const _cardBg      = Color(0xFFF9FAFB);
  static const _darkText    = Color(0xFF1A1A2E);
  const _DatePickerTile({required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final bool has = value != "Select Date";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: has ? _green.withOpacity(0.40) : _borderColor, width: has ? 1.5 : 1.0),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _green.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.calendar_today_rounded, color: _green, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: has ? _darkText : Colors.grey.shade400)),
          ])),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
        ]),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final String fileName;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  static const _green       = Color(0xFF149D0F);
  static const _borderColor = Color(0xFFEEEEEE);
  static const _cardBg      = Color(0xFFF9FAFB);
  static const _darkText    = Color(0xFF1A1A2E);
  const _FileTile({required this.fileName, required this.onTap, this.onRemove});
  @override
  Widget build(BuildContext context) {
    final bool has = fileName.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: has ? _green.withOpacity(0.05) : _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: has ? _green.withOpacity(0.40) : _borderColor, width: has ? 1.5 : 1.0),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: has ? _green.withOpacity(0.12) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(has ? Icons.check_circle_outline_rounded : Icons.attach_file_rounded,
                color: has ? _green : Colors.grey.shade500, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(
            has ? fileName : "Attach File or Photo (Optional)",
            style: TextStyle(fontSize: 13,
                fontWeight: has ? FontWeight.w600 : FontWeight.w400,
                color: has ? _darkText : Colors.grey.shade500),
            overflow: TextOverflow.ellipsis,
          )),
          if (has && onRemove != null)
            GestureDetector(onTap: onRemove,
                child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400))
          else
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
        ]),
      ),
    );
  }
}

class _FileSourceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, subtitle;
  final VoidCallback onTap;
  const _FileSourceTile({
    required this.icon, required this.color,
    required this.label, required this.subtitle, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
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
}