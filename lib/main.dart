import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'leaves.dart';
import 'expenses.dart';
import 'welcome.dart';
import 'responsive_layout.dart';
import 'employee_details.dart';
import 'attendance_details.dart';
import 'tasks.dart';
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'attendance_channel',
    'Attendance Notifications',
    channelDescription: 'Check In & Check Out Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails notificationDetails =
  NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
      0, title, body, notificationDetails);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}
// LOGIN PAGE
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String apiUrl = "https://hrm.eltrive.com/api/login";
  bool isLoading = false;
  bool _obscurePassword = true;

  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      if (!mounted) return false;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("No Internet Connection"),
          content: const Text("Please check your internet connection"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );

      return false;
    }
  }

  Future<void> _login() async {
    if (!await checkInternetConnection()) return;

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Missing Details"),
            content: const Text("Please enter username & password"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      String serial = androidInfo.id ?? "unknown";

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": username,
          "password": password,
          "device_serial_number": serial,
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          "fcm_token": "sample_fcm_token_123"
        }),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {

        String empName = data["emp_name"];
        String empId = data["emp_id"];
        String token = data["auth_token"];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(username: empName, empId: empId, authToken: token),
          ),
        );

        //ScaffoldMessenger.of(context)
            //.showSnackBar(SnackBar(content: Text("Welcome $empName")));

      } else {

        String message = data["message"] ?? "Login Failed";

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text("Login Failed"),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F9D58), Color(0xD2FFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            // ✅ SafeScrollColumn — fixes overflow on web/desktop/tablet
            child: SafeScrollColumn(
              centerContent: true,
              padding: EdgeInsets.symmetric(
                horizontal: context.rv(mobile: 28.0, tablet: 60.0, desktop: 0.0),
              ),
              children: [
                // Back button



                const SizedBox(height: 20),

                // Logo — responsive height
                Image.asset(
                  "assets/eltrive_name.png",
                  height: context.rv(mobile: 80.0, tablet: 100.0, desktop: 110.0),
                ),

                const SizedBox(height: 40),

                // ✅ MaxWidthContainer — caps card width on wide screens
                MaxWidthContainer(
                  maxWidth: 480,
                  child: Container(
                    padding: EdgeInsets.all(
                      context.rv(mobile: 25.0, tablet: 32.0, desktop: 36.0),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Login",
                          style: TextStyle(
                            // ✅ context.fontSize — responsive text
                            fontSize: context.fontSize(
                                mobile: 20, tablet: 22, desktop: 24),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 25),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person),
                            labelText: "Username",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            labelText: "Password",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: context.rv(
                              mobile: 50.0, tablet: 54.0, desktop: 56.0),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF149D0F),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: context.rv(
                                    mobile: 16.0, tablet: 17.0, desktop: 18.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }
}
// HOME PAGE
class HomePage extends StatefulWidget {
  final String username;
  final String empId;
  final String authToken;

  const HomePage({
    super.key,
    required this.username,
    required this.empId,
    required this.authToken,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? checkInTime;
  DateTime? checkOutTime;
  String workedDuration = "";
  bool isLoading = false;
  int _selectedIndex = 0;
  late Timer _shiftTimer;
  bool _isShiftRunning = false;
  bool isAllowedToCheckIn = false;
  bool isAllowedToCheckOut = false;
  bool alreadyCheckedInToday = false;
  DateTime _currentTime = DateTime.now();
  late Timer _timer;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<int> yearsList = List.generate(5, (index) => DateTime.now().year - index);

  final String statusApi = "https://hrm.eltrive.com/api/status";
  final String checkinApi = "https://hrm.eltrive.com/api/checkin";

  List<Map<String, String>> attendanceList = [];

  String _getMonthName(int month) {
    List<String> months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Future<void> getEmployeeStatus() async {
    try {
      final response = await http.post(
        Uri.parse(statusApi),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"auth_token": widget.authToken, "emp_id": widget.empId}),
      );
      var data = jsonDecode(response.body);
      if (data["status"] == "success") {
        String currentStatus = data["current_status"] ?? "";
        isAllowedToCheckIn = data["is_allowed_to_check_in"] == "true";
        isAllowedToCheckOut = data["is_allowed_to_check_out"] == "true";
        if (data["last_check_in_time"] != "NA") {
          checkInTime = DateTime.parse(data["last_check_in_time"]);
        } else {
          checkInTime = null;
        }
        if (data["last_check_out_time"] != "NA") {
          checkOutTime = DateTime.parse(data["last_check_out_time"]);
        } else {
          checkOutTime = null;
        }
        if (data["cumulative_working_hours"] != "NA") {
          workedDuration = data["cumulative_working_hours"];
        }
        if (currentStatus == "checked_in" && checkInTime != null) {
          alreadyCheckedInToday = true;
          _isShiftRunning = true;
          try { _shiftTimer.cancel(); } catch (_) {}
          _shiftTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!_isShiftRunning || checkInTime == null) return;
            Duration difference = DateTime.now().difference(checkInTime!);
            setState(() {
              workedDuration =
              "${difference.inHours.toString().padLeft(2, '0')}:"
                  "${(difference.inMinutes % 60).toString().padLeft(2, '0')}:"
                  "${(difference.inSeconds % 60).toString().padLeft(2, '0')}";
            });
          });
        }
        if (currentStatus == "checked_out") {
          _isShiftRunning = false;
          try { _shiftTimer.cancel(); } catch (_) {}
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint("Status API Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await getEmployeeStatus();

    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    if (_isShiftRunning) _shiftTimer.cancel();
    super.dispose();
  }

  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      if (!mounted) return false;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("No Internet Connection"),
          content: const Text("Please check your internet connection"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      return false;
    }
  }

  String formatOnlyTime(DateTime time) =>
      "${time.hour.toString().padLeft(2, '0')}:"
          "${time.minute.toString().padLeft(2, '0')}:"
          "${time.second.toString().padLeft(2, '0')}";

  String formatTimeWithAmPm(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return "${hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}:"
        "${time.second.toString().padLeft(2, '0')} $period";
  }

  String formatFullDate(DateTime date) {
    List<String> weekdays = [
      "Monday", "Tuesday", "Wednesday",
      "Thursday", "Friday", "Saturday", "Sunday"
    ];
    List<String> months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return "${weekdays[date.weekday - 1]}, "
        "${date.day.toString().padLeft(2, '0')} "
        "${months[date.month - 1]} "
        "${date.year}";
  }

  Future<Position?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Location Disabled"),
          content: const Text("Please enable your device location"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"))
          ],
        ),
      );
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Location Permission Denied"),
            content: const Text("Please allow location permission"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"))
            ],
          ),
        );
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Location Permission Permanently Denied"),
          content: const Text(
              "Please enable location permission from App Settings"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"))
          ],
        ),
      );
      return null;
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<String> _getSerial() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? "unknown";
    }
    return "unknown";
  }

  Future<void> checkIn() async {
    if (!await checkInternetConnection()) return;
    setState(() => isLoading = true);
    try {
      Position? position = await _getLocation();
      if (position == null) { setState(() => isLoading = false); return; }
      String serial = await _getSerial();
      checkInTime = DateTime.now();
      checkOutTime = null;
      workedDuration = "00:00:00";
      setState(() {});
      final response = await http.post(
        Uri.parse(checkinApi),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "auth_token": widget.authToken,
          "emp_id": widget.empId,
          "device_serial_number": serial,
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          "shift_id": 1
        }),
      );
      var data = jsonDecode(response.body);
      if (data["status"] == "success") {
        _isShiftRunning = true;
        try { _shiftTimer.cancel(); } catch (_) {}
        _shiftTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!_isShiftRunning || checkInTime == null) return;
          Duration difference = DateTime.now().difference(checkInTime!);
          setState(() {
            workedDuration =
            "${difference.inHours.toString().padLeft(2, '0')}:"
                "${(difference.inMinutes % 60).toString().padLeft(2, '0')}:"
                "${(difference.inSeconds % 60).toString().padLeft(2, '0')}";
          });
        });
        await showNotification(
            "Check In Successful", "Checked in at ${formatOnlyTime(checkInTime!)}");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Checked In Successfully")));
        await getEmployeeStatus();
      } else {
        String message = data["message"] ?? "Check In Failed";
        String previousTime = data["previous_check_in_time"] ?? "";

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text("Check In Alert"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 10),
                if (previousTime.isNotEmpty)
                  Text(
                    "Previous Check-In: $previousTime",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => isLoading = false);
  }


  Future<void> checkOut() async {
    if (!await checkInternetConnection()) return;
    if (checkInTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please Check In First")));
      return;
    }
    setState(() => isLoading = true);
    try {
      Position? position = await _getLocation();
      if (position == null) { setState(() => isLoading = false); return; }
      checkOutTime = DateTime.now();
      String onlyTime = formatOnlyTime(checkOutTime!);
      Duration difference = checkOutTime!.difference(checkInTime!);
      if (_isShiftRunning) { _shiftTimer.cancel(); _isShiftRunning = false; }
      workedDuration =
      "${difference.inHours.toString().padLeft(2, '0')}:"
          "${(difference.inMinutes % 60).toString().padLeft(2, '0')}:"
          "${(difference.inSeconds % 60).toString().padLeft(2, '0')}";
      String serial = await _getSerial();
      final response = await http.post(
        Uri.parse("https://hrm.eltrive.com/api/checkout"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "auth_token": widget.authToken,
          "emp_id": widget.empId,
          "device_serial_number": serial,
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          "shift_id": 1
        }),
      );
      var data = jsonDecode(response.body);
      if (data["status"] == "success") {
        String cumulativeHours =
            data["cumulative_working_hours"] ?? workedDuration;

        await showNotification(
            "Check Out Successful", "Worked Duration: $cumulativeHours");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data["message"] ?? "Checkout successful")));
        await getEmployeeStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data["message"] ?? "Check Out Failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => isLoading = false);
  }

  // ── ATTENDANCE CONTENT ──────────────────────────────────────────────────────
  Widget _attendanceContent() {
    int hour = _currentTime.hour;
    String greeting;
    IconData greetingIcon;
    Color greetingColor;

    if (hour < 12) {
      greeting = "Good Morning";
      greetingIcon = Icons.wb_sunny_rounded;
      greetingColor = const Color(0xFFFF8F00);
    } else if (hour < 17) {
      greeting = "Good Afternoon";
      greetingIcon = Icons.light_mode_rounded;
      greetingColor = const Color(0xFFFF6F00);
    } else {
      greeting = "Good Evening";
      greetingIcon = Icons.nights_stay_rounded;
      greetingColor = const Color(0xFF3949AB);
    }

    return SingleChildScrollView(
      // ✅ context.pagePadding — responsive padding from responsive_layout.dart
      padding: context.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Greeting Card ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.rv(mobile: 18.0, tablet: 22.0, desktop: 24.0),
              vertical:   context.rv(mobile: 16.0, tablet: 18.0, desktop: 20.0),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                      context.rv(mobile: 10.0, tablet: 12.0, desktop: 12.0)),
                  decoration: BoxDecoration(
                    color: greetingColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(greetingIcon,
                      color: greetingColor,
                      // ✅ Responsive.iconSize from responsive_layout.dart
                      size: Responsive.iconSize(context,
                          mobile: 26, tablet: 28, desktop: 30)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          // ✅ context.fontSize from responsive_layout.dart
                          fontSize: context.fontSize(
                              mobile: 13, tablet: 14, desktop: 15),
                          color: greetingColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.username.toUpperCase(),
                        style: TextStyle(
                          fontSize: context.fontSize(
                              mobile: 17, tablet: 19, desktop: 21),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A2E),
                          letterSpacing: 0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Clock Card ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical:   context.rv(mobile: 20.0, tablet: 24.0, desktop: 28.0),
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  formatTimeWithAmPm(_currentTime),
                  style: TextStyle(
                    fontSize: context.rv(mobile: 40.0, tablet: 46.0, desktop: 52.0),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatFullDate(_currentTime),
                  style: TextStyle(
                    fontSize: context.fontSize(mobile: 13, tablet: 14, desktop: 15),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Shift Card ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.rv(mobile: 18.0, tablet: 20.0, desktop: 22.0),
              vertical:   context.rv(mobile: 14.0, tablet: 16.0, desktop: 18.0),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF149D0F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.access_time_rounded,
                      color: Color(0xFF149D0F), size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Current Shift",
                        style: TextStyle(
                            fontSize: context.rv(
                                mobile: 11.0, tablet: 12.0, desktop: 12.0),
                            color: Colors.grey,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text("GEN : 9:15 AM – 6:45 PM",
                        style: TextStyle(
                            fontSize: context.rv(
                                mobile: 15.0, tablet: 16.0, desktop: 16.0),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Check In / Check Out Buttons ─────────────────────────────────
          Row(
            children: [
              // CHECK IN
              Expanded(
                child: GestureDetector(
                  onTap: isLoading || !isAllowedToCheckIn ? null : checkIn,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      vertical: context.rv(
                          mobile: 22.0, tablet: 26.0, desktop: 28.0),
                    ),
                    decoration: BoxDecoration(
                      gradient: isAllowedToCheckIn
                          ? const LinearGradient(
                        colors: [Color(0xFF149D0F), Color(0xFF0F9D58)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : LinearGradient(colors: [
                        Colors.green.shade100,
                        Colors.green.shade100
                      ]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isAllowedToCheckIn
                          ? [
                        BoxShadow(
                          color: const Color(0xFF149D0F).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded,
                            color: isAllowedToCheckIn
                                ? Colors.white
                                : Colors.green.shade300,
                            size: Responsive.iconSize(context,
                                mobile: 28, tablet: 30, desktop: 32)),
                        const SizedBox(height: 8),
                        Text("Check In",
                            style: TextStyle(
                                fontSize: context.rv(
                                    mobile: 15.0, tablet: 16.0, desktop: 17.0),
                                fontWeight: FontWeight.w700,
                                color: isAllowedToCheckIn
                                    ? Colors.white
                                    : Colors.green.shade300,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            checkInTime == null
                                ? "--:--:--"
                                : formatOnlyTime(checkInTime!),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isAllowedToCheckIn
                                    ? Colors.white
                                    : Colors.green.shade300),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // CHECK OUT
              Expanded(
                child: GestureDetector(
                  onTap: isLoading || !isAllowedToCheckOut ? null : checkOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      vertical: context.rv(
                          mobile: 22.0, tablet: 26.0, desktop: 28.0),
                    ),
                    decoration: BoxDecoration(
                      gradient: isAllowedToCheckOut
                          ? const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : LinearGradient(colors: [
                        Colors.red.shade100,
                        Colors.red.shade100
                      ]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isAllowedToCheckOut
                          ? [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: isAllowedToCheckOut
                                ? Colors.white
                                : Colors.red.shade200,
                            size: Responsive.iconSize(context,
                                mobile: 28, tablet: 30, desktop: 32)),
                        const SizedBox(height: 8),
                        Text("Check Out",
                            style: TextStyle(
                                fontSize: context.rv(
                                    mobile: 15.0, tablet: 16.0, desktop: 17.0),
                                fontWeight: FontWeight.w700,
                                color: isAllowedToCheckOut
                                    ? Colors.white
                                    : Colors.red.shade200,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            checkOutTime == null
                                ? "--:--:--"
                                : formatOnlyTime(checkOutTime!),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isAllowedToCheckOut
                                    ? Colors.white
                                    : Colors.red.shade200),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Total Working Time Card ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.rv(mobile: 20.0, tablet: 22.0, desktop: 24.0),
              vertical:   context.rv(mobile: 18.0, tablet: 20.0, desktop: 22.0),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0277BD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer_rounded,
                      color: Color(0xFF0277BD), size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Working Time",
                        style: TextStyle(
                            fontSize: context.rv(
                                mobile: 12.0, tablet: 13.0, desktop: 13.0),
                            color: Colors.grey,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(
                      workedDuration.isEmpty ? "00:00:00" : workedDuration,
                      style: TextStyle(
                        fontSize: context.rv(
                            mobile: 22.0, tablet: 24.0, desktop: 26.0),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0277BD),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

        AttendanceDetails(authToken: widget.authToken),

          const SizedBox(height: 30),

        ],
      ),
    );
  }


  Widget _getTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _attendanceContent();
      case 1:
        return LeavesPage(
            username: widget.username,
            authToken: widget.authToken,
            empId: widget.empId);
      case 2:
        return const ExpensesPage();
      case 3:
        return TasksPage(
          authToken: widget.authToken,
          empId: widget.empId,
        );
      case 4:
        return const Center(child: Text("More Page"));
      default:
        return _attendanceContent();
    }
  }

  void _onTabTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // ✅ ResponsiveScaffold from responsive_layout.dart
        // Mobile  → bottom nav bar
        // Tablet  → icon-only side rail (70px wide)
        // Desktop → labeled side rail (220px wide)
        ResponsiveScaffold(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabTapped,
          primaryColor: const Color(0xFF149D0F),

          appBarLogo: Row(
            children: [

              // Logo
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.asset(
                    "assets/eltrive_name.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Profile Icon (Top Right)
              IconButton(
                tooltip: "My Profile",
                icon: const Icon(
                  Icons.account_circle,
                  size: 32,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeProfilePage(
                        authToken: widget.authToken,
                        empId: widget.empId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),


          // ✅ NavDestination from responsive_layout.dart
          destinations: const [
            NavDestination(
                icon: Icons.home_rounded, label: "Attendance"),
            NavDestination(
                icon: Icons.beach_access_rounded, label: "Leaves"),
            NavDestination(
                icon: Icons.receipt_long_rounded, label: "Expenses"),
            NavDestination(
                icon: Icons.task_alt_rounded, label: "Tasks"),
            NavDestination(
                icon: Icons.more_horiz_rounded, label: "More"),
          ],

          body: _getTabContent(),

          // Profile + Logout in side rail footer (tablet/desktop)

        ),

        // Loading overlay
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}