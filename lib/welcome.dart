import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';
import 'responsive_layout.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double bottomPad = context.bottomPadding;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0FFF4), Color(0xFFE0F7FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // ✅ Column → SafeArea + SingleChildScrollView
        // This prevents RenderFlex overflow on web/desktop/tablet
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              // Ensures content fills the full screen height on tall screens
              // but scrolls on short screens — no overflow either way
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height
                    - MediaQuery.of(context).padding.top
                    - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [

                    // ── Header ──────────────────────────────────────────
                    _Header(),

                    // ── Main content — fills remaining space ────────────
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          // ✅ Responsive horizontal padding
                          horizontal: context.rv(
                            mobile: context.screenWidth * 0.08,
                            tablet: context.screenWidth * 0.15,
                            desktop: 0.0,
                          ),
                        ),
                        // ✅ MaxWidthContainer caps width on desktop
                        child: MaxWidthContainer(
                          maxWidth: 540,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              SizedBox(height: context.rv(
                                  mobile: 24.0, tablet: 32.0, desktop: 40.0)),

                              // ── Logo box ───────────────────────────────
                              Container(
                                // ✅ Fixed size on wide screens, relative on mobile
                                width: context.rv(
                                  mobile: context.screenWidth * 0.38,
                                  tablet: 200.0,
                                  desktop: 220.0,
                                ),
                                height: context.rv(
                                  mobile: context.screenWidth * 0.38,
                                  tablet: 200.0,
                                  desktop: 220.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    context.rv(
                                        mobile: context.screenWidth * 0.06,
                                        tablet: 24.0,
                                        desktop: 28.0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF149D0F)
                                          .withOpacity(0.18),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(
                                  context.rv(
                                      mobile: context.screenWidth * 0.04,
                                      tablet: 24.0,
                                      desktop: 28.0),
                                ),
                                child: Image.asset(
                                  "assets/welcome.png",
                                  fit: BoxFit.contain,
                                ),
                              ),

                              SizedBox(height: context.rv(
                                  mobile: context.screenHeight * 0.038,
                                  tablet: 28.0,
                                  desktop: 32.0)),

                              // ── "Welcome Back" ─────────────────────────
                              Text(
                                "Welcome Back",
                                style: TextStyle(
                                  // ✅ context.fontSize from responsive_layout.dart
                                  fontSize: context.fontSize(
                                      mobile: context.screenWidth * 0.048,
                                      tablet: 20,
                                      desktop: 22),
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF37474F),
                                ),
                              ),

                              SizedBox(height: context.rv(
                                  mobile: context.screenHeight * 0.01,
                                  tablet: 8.0,
                                  desktop: 10.0)),

                              // ── "ELTRIVE" gradient text ─────────────────
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFF149D0F),
                                        Color(0xFF0277BD)
                                      ],
                                    ).createShader(bounds),
                                child: Text(
                                  "ELTRIVE",
                                  style: TextStyle(
                                    fontSize: context.rv(
                                        mobile: context.screenWidth * 0.115,
                                        tablet: 64.0,
                                        desktop: 72.0),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              SizedBox(height: context.rv(
                                  mobile: context.screenHeight * 0.06,
                                  tablet: 40.0,
                                  desktop: 48.0)),

                              // ── LOGIN button ───────────────────────────
                              SizedBox(
                                width: context.rv(
                                  mobile: context.screenWidth * 0.72,
                                  tablet: 320.0,
                                  desktop: 360.0,
                                ),
                                height: context.rv(
                                  mobile: context.screenHeight * 0.068,
                                  tablet: 54.0,
                                  desktop: 58.0,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const LoginPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF149D0F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    "LOGIN",
                                    style: TextStyle(
                                      fontSize: context.rv(
                                          mobile: 16.0,
                                          tablet: 17.0,
                                          desktop: 18.0),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: context.rv(
                                  mobile: 24.0, tablet: 32.0, desktop: 40.0)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Footer ──────────────────────────────────────────
                    _Footer(bottomPad: bottomPad),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── HEADER ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: context.rv(mobile: 16.0, tablet: 20.0, desktop: 24.0),
      ),
      child: Center(
        child: Image.asset(
          "assets/eltrive_name.png",
          // ✅ Responsive logo height
          height: context.rv(mobile: 36.0, tablet: 44.0, desktop: 48.0),
        ),
      ),
    );
  }
}

// ── FOOTER ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.bottomPad});
  final double bottomPad;

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://www.eltrive.com');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPad + 12,
        top: 8,
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Visit us at ",
              style: TextStyle(
                color: Colors.grey,
                fontSize: context.rv(mobile: 13.0, tablet: 14.0, desktop: 14.0),
              ),
            ),
            TextSpan(
              text: "www.eltrive.com",
              style: TextStyle(
                color: const Color(0xFF149D0F),
                decoration: TextDecoration.underline,
                fontSize: context.rv(mobile: 13.0, tablet: 14.0, desktop: 14.0),
              ),
              recognizer: TapGestureRecognizer()..onTap = _launchUrl,
            ),
          ],
        ),
      ),
    );
  }
}