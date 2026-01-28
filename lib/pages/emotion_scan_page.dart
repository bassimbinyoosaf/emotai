import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui; // for ImageFilter
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart'; // Theme switching via Provider

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// ML Kit (capture-time only)
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// Your app's theme notifier (used on other pages)
import '../theme/app_theme.dart';

// Floating glitter particles for background flair
class GlitterParticle extends StatefulWidget {
  final double size;
  final Color color;
  final double initialX;
  final double initialY;

  const GlitterParticle({
    Key? key,
    required this.size,
    required this.color,
    required this.initialX,
    required this.initialY,
  }) : super(key: key);

  @override
  State<GlitterParticle> createState() => _GlitterParticleState();
}

class _GlitterParticleState extends State<GlitterParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.8).chain(CurveTween(curve: Curves.linear)),
        weight: 33.3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 0.0).chain(CurveTween(curve: Curves.linear)),
        weight: 33.3,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 33.4,
      ),
    ]).animate(_controller);

    _translateY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -30.0).chain(CurveTween(curve: Curves.linear)),
        weight: 66.7,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 33.3,
      ),
    ]).animate(_controller);

    Future.delayed(
      Duration(milliseconds: (math.Random().nextDouble() * 2000).toInt()),
      () {
        if (mounted) _controller.repeat();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.initialX,
          top: widget.initialY + _translateY.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class EmotionScanPage extends StatefulWidget {
  const EmotionScanPage({super.key});

  @override
  State<EmotionScanPage> createState() => _EmotionScanPageState();
}

class _EmotionScanPageState extends State<EmotionScanPage>
    with SingleTickerProviderStateMixin {
  // Single source of truth for inner frame geometry
  static const double _framePadding = 10.0;
  static const double _frameRadius = 18.0;
  static const double _frameStroke = 1.2;

  CameraController? _controller;
  XFile? _capturedImage;
  String _emotion = "No emotion detected";

  // Firebase Realtime Database reference
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Interests selection (using composite keys "Category|Interest")
  final List<String> _selectedInterests = <String>[];

  // Interest catalog
  final Map<String, List<String>> _interestCatalog = {
    'Music': [
      'Pop', 'Rock', 'Classical', 'Jazz', 'Hip Hop', 'EDM', 'Country', 'R&B', 'Folk', 'Blues', 'Metal', 'Indie'
    ],
    'Art': [
      'Painting', 'Drawing', 'Sculpture', 'Photography', 'Digital Art', 'Calligraphy', 'Street Art', 'Ceramics', 'Illustration'
    ],
    'Singing': [
      'Choir', 'Solo', 'Karaoke', 'A Cappella', 'Musical Theatre', 'R&B Vocals', 'Classical Vocals'
    ],
    'Dancing': [
      'Hip Hop', 'Contemporary', 'Ballet', 'Salsa', 'Tango', 'Ballroom', 'Folk Dance', 'Breakdance', 'K-Pop'
    ],
    'Sports': [
      'Football', 'Basketball', 'Hockey', 'Cricket', 'Tennis', 'Baseball', 'Rugby', 'Volleyball', 'Badminton',
      'Golf', 'Swimming', 'Athletics', 'Cycling', 'Table Tennis', 'MMA', 'Boxing', 'Wrestling', 'Skateboarding',
      'Surfing', 'Skiing', 'Snowboarding', 'Esports', 'Formula 1', 'Motorsport', 'Handball', 'Lacrosse',
      'Field Hockey', 'Ice Hockey', 'Water Polo', 'Gymnastics', 'Snooker', 'Darts', 'Squash', 'Polo', 'Curling'
    ],
  };

  late final FaceDetector _faceDetector;
  bool? _photoFaceDetected;

  // Low light monitoring
  bool _isLowLight = false;
  DateTime _lastLightCheck = DateTime.fromMillisecondsSinceEpoch(0);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  bool _pressingCapture = false;

  // Gate flag: resolve in background; null = unknown, true = require selection, false = show scanner
  bool? _requireInterestSelection;

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();

    // Resolve interest gate in background (no UI flicker to interest page)
    _decideInterestGate();

    // Initialize camera
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() {}); // trigger rebuild
      await _startLightMonitoring();
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  // Centralized SnackBar
  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Check if user has at least one interest saved (value == true)
  Future<bool> _userHasInterests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("Interest gate: no user -> show interest page");
        return false; // lead to interest page
      }

      final snap = await _dbRef.child("users").child(user.uid).child("interests").get();
      if (!snap.exists) return false;

      final val = snap.value;
      if (val is Map) {
        final map = Map<String, dynamic>.from(val as Map);
        final anyTrue = map.values.any((v) => v == true);
        return anyTrue;
      }
      return false;
    } catch (e) {
      debugPrint("Interest gate check failed: $e");
      return false; // on error, lead to interest page
    }
  }

  // Background decision: resolve gate without briefly rendering the interest page
  Future<void> _decideInterestGate() async {
    final has = await _userHasInterests();
    if (!mounted) return;
    setState(() {
      _requireInterestSelection = !has;
    });
  }

  Future<void> _startLightMonitoring() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isStreamingImages) return;

    try {
      await _controller!.startImageStream((CameraImage img) {
        final now = DateTime.now();
        if (now.difference(_lastLightCheck).inMilliseconds < 400) return;
        _lastLightCheck = now;

        if (img.planes.isNotEmpty) {
          final bytes = img.planes[0].bytes;
          const step = 24;
          int sum = 0;
          int count = 0;
          for (int i = 0; i < bytes.length; i += step) {
            sum += bytes[i];
            count++;
            if (count >= 4000 ~/ step) break;
          }
          final avgLuma = count == 0 ? 255.0 : sum / count;
          final lowLight = avgLuma < 45.0;
          if (lowLight != _isLowLight && mounted) {
            setState(() => _isLowLight = lowLight);
          }
        }
      });
    } catch (e) {
      debugPrint("startImageStream error: $e");
    }
  }

  Future<void> _stopLightMonitoring() async {
    if (_controller == null) return;
    if (_controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
    }
  }

  Future<void> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_controller!.value.isStreamingImages) {
        await _stopLightMonitoring();
      }

      final image = await _controller!.takePicture();

      // Face check: if no face, then set emotion to "No emotion detected"
      bool photoHasFace;
      try {
        final faces = await _face_detector_process(image.path);
        photoHasFace = faces > 0;
      } catch (_) {
        photoHasFace = true;
      }

      final emotionText = photoHasFace ? scanEmotion() : "No emotion detected";

      setState(() {
        _capturedImage = image;
        _emotion = emotionText;
        _photoFaceDetected = photoHasFace;
      });

      await _startLightMonitoring();
    } catch (e) {
      debugPrint("Capture error: $e");
    }
  }

  // Helper: run ML Kit
  Future<int> _face_detector_process(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final faces = await _faceDetector.processImage(inputImage);
    return faces.length;
  }

  // Human-readable user label
  String _buildUserLabel(User user) {
    return user.displayName ??
        user.email ??
        user.phoneNumber ??
        user.providerData.firstOrNull?.uid ??
        user.uid;
  }

  // Save interests and a readable profile, then proceed to main UI
  Future<bool> saveUserInterests(List<String> selectedInterests) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ User not logged in. Interests not saved.");
      _showSnack('You must be signed in to save interests.');
      return false;
    }

    try {
      final Map<String, bool> interestsMap = {
        for (var interestId in selectedInterests) interestId: true,
      };

      final profileMap = <String, dynamic>{
        "uid": user.uid,
        "username": _buildUserLabel(user),
        if (user.email != null) "email": user.email,
        if (user.photoURL != null) "photoURL": user.photoURL,
        "lastUpdated": ServerValue.timestamp,
      };

      await _dbRef.child("users").child(user.uid).update({
        "profile": profileMap,
        "interests": interestsMap,
      });

      _showSnack('Saved for ${_buildUserLabel(user)} • ${selectedInterests.length} interests');

      // Flip to main UI
      if (mounted) {
        setState(() {
          _requireInterestSelection = false;
        });
      }
      return true;
    } catch (e) {
      debugPrint('Save interests error: $e');
      _showSnack("Save failed: $e");
      return false;
    }
  }

  Future<void> _shareCapture() async {
    if (_capturedImage == null) {
      _showSnack('Capture a photo first to share.');
      return;
    }
    try {
      final shareText = _photoFaceDetected == false
          ? 'Emotion: No emotion detected'
          : 'Emotion: $_emotion';

      await Share.shareXFiles(
        [XFile(_capturedImage!.path)],
        text: shareText,
        subject: 'Emotion Scan',
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (!mounted) return;
      _showSnack('Unable to share right now.');
    }
  }

  String scanEmotion() {
    final emotions = [
      "Happy 😊",
      "Calm 🙂",
      "Sad 😔",
      "Neutral 😐",
      "Excited 😄",
      "Surprised 😮",
    ];
    emotions.shuffle();
    return emotions.first;
  }

  // Theme toggle using the same Provider pattern as other pages
  void _toggleTheme() {
    try {
      context.read<ThemeNotifier>().toggleTheme();
    } catch (e) {
      debugPrint("Theme toggle error: $e");
      if (!mounted) return;
      _showSnack('Unable to toggle theme on this page.');
    }
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home_al');
    }
  }

  @override
  void dispose() {
    _stopLightMonitoring();
    _faceDetector.close();
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Camera card with glass layer + consistent inner frame
  Widget _buildCameraCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Glass backdrop
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFFFFFFFF).withOpacity(0.08), const Color(0xFFFFFFFF).withOpacity(0.03)]
                        : [const Color(0xFF2C3E50).withOpacity(0.10), const Color(0xFF2C3E50).withOpacity(0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.18 : 0.14),
                    width: 1.2,
                  ),
                ),
              ),
            ),

            // Inner frame area
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(_framePadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_frameRadius),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _CameraPreviewCover(controller: _controller),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(isDark ? 0.14 : 0.10),
                              ],
                              center: Alignment.center,
                              radius: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Stroke on top using same geometry
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(_framePadding),
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RoundedFramePainter(
                      radius: _frameRadius,
                      stroke: _frameStroke,
                      color: Colors.white.withOpacity(isDark ? 0.28 : 0.22),
                    ),
                  ),
                ),
              ),
            ),

            // Top hint pills
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLowLight)
                    _HintPill(
                      color: Colors.amber,
                      icon: Icons.light_mode,
                      text: "Low light detected. Try a brighter spot.",
                      textColor: Colors.black87,
                    ),
                  const SizedBox(height: 8),
                  _HintPill(
                    color: isDark ? const Color(0xFF1E293B) : Colors.black87,
                    icon: Icons.center_focus_strong,
                    text: "Center your face inside the frame",
                    textColor: Colors.white,
                    opacity: isDark ? 0.55 : 0.50,
                  ),
                ],
              ),
            ),

            // Capture button
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _pressingCapture = true),
                  onTapCancel: () => setState(() => _pressingCapture = false),
                  onTapUp: (_) => setState(() => _pressingCapture = false),
                  onTap: captureImage,
                  child: AnimatedScale(
                    scale: _pressingCapture ? 0.92 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF8B7FFF), const Color(0xFFB4A7FF)]
                              : [const Color(0xFF0A7EA4), const Color(0xFF3DA5C8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? const Color(0xFF8B7FFF) : const Color(0xFF0A7EA4))
                                .withOpacity(0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.30),
                          width: 1.6,
                        ),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // After-capture card
  Widget _buildAfterCaptureCard(BuildContext context, bool isDark, BoxConstraints cons) {
    final theme = Theme.of(context);

    final maxH = cons.maxHeight;
    final imageH = math.max(100.0, math.min(150.0, maxH * 0.45));

    // Responsive extra gap that scales with available height and safe area
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final extraGap = math.max(
      16.0,
      math.min(32.0, (cons.maxHeight * 0.06) + (safeBottom * 0.15)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFFFFFFFF).withOpacity(0.14), const Color(0xFFFFFFFF).withOpacity(0.06)]
                        : [const Color(0xFF2C3E50).withOpacity(0.12), const Color(0xFF2C3E50).withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.20 : 0.16),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    if (_capturedImage != null)
                      Padding(
                        padding: const EdgeInsets.all(_framePadding),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(_frameRadius),
                              child: SizedBox(
                                height: imageH - (_framePadding * 2),
                                width: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: Image.file(
                                    File(_capturedImage!.path),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _RoundedFramePainter(
                                    radius: _frameRadius,
                                    stroke: _frameStroke,
                                    color: Colors.white.withOpacity(isDark ? 0.28 : 0.22),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Column(
                        children: [
                          Text(
                            "Detected Emotion",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isDark ? Colors.white70 : const Color(0xFF687076),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _EmotionChip(text: _emotion, isDark: isDark),

                          // Optional face warning
                          if (_photoFaceDetected == false) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.tag_faces_outlined, size: 16, color: Colors.orange),
                                SizedBox(width: 6),
                                Text(
                                  "No face recognized in the photo. Try retaking.",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Extra safe space to move action buttons down a bit more
                          SizedBox(height: extraGap),

                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 12, // slightly larger run spacing for better touch targets
                            children: [
                              _ActionPill(
                                label: "Retake",
                                icon: Icons.refresh,
                                isDark: isDark,
                                onTap: () {
                                  setState(() {
                                    _capturedImage = null;
                                    _emotion = "No emotion detected";
                                    _photoFaceDetected = null;
                                  });
                                },
                              ),
                              _ActionPill(
                                label: "Share",
                                icon: Icons.share_outlined,
                                isDark: isDark,
                                onTap: _shareCapture,
                              ),
                            ],
                          ),
                        ],
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

  // Interest selection section (FilterChip-based)
  Widget _buildInterestSection(String category, List<String> items, bool isDark) {
    final headerColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final subColor = isDark ? Colors.white70 : const Color(0xFF2C3E50).withOpacity(0.75);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: headerColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((interest) {
              final id = '$category|$interest';
              final selected = _selectedInterests.contains(id);

              return FilterChip(
                label: Text(
                  interest,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF2C3E50)),
                  ),
                ),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    if (selected) {
                      _selectedInterests.remove(id);
                    } else {
                      _selectedInterests.add(id);
                    }
                  });
                },
                selectedColor: isDark ? const Color(0xFF8B7FFF) : const Color(0xFF0A7EA4),
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.85),
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: (selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF2C3E50)))
                        .withOpacity(0.25),
                    width: 1,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            "Tap to select your preferences",
            style: TextStyle(
              fontSize: 11,
              color: subColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Interest selection page (only shown when interests are NOT saved; otherwise never interferes)
  Widget _buildInterestSelectionGate(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? Colors.white : const Color(0xFF2C3E50);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C3E64)]
                : const [Color(0xFFa8edea), Color(0xFFfed6e3), Color(0xFFa6c1ee), Color(0xFFfbc2eb)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    _HeaderIcon(icon: Icons.arrow_back, onTap: _goBack, isDark: isDark),
                    const Spacer(),
                    _HeaderIcon(
                      icon: isDark ? Icons.wb_sunny : Icons.nightlight_round,
                      onTap: _toggleTheme,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Your Interests",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: headerColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Choose topics and sports you care about to personalize your experience.",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF2C3E50).withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sections
                      ..._interestCatalog.entries.map(
                        (e) => _buildInterestSection(e.key, e.value, isDark),
                      ),

                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 18,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2C3E50)),
                          const SizedBox(width: 6),
                          Text(
                            "Selected: ${_selectedInterests.length}",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2C3E50),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedInterests.clear();
                              });
                            },
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text("Clear"),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white70
                                  : const Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_outlined),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            backgroundColor:
                                isDark ? const Color(0xFF8B7FFF) : const Color(0xFF0A7EA4),
                          ),
                          onPressed: () async {
                            if (_selectedInterests.isEmpty) {
                              _showSnack("Please select at least one interest.");
                              return;
                            }
                            final ok = await saveUserInterests(_selectedInterests);
                            if (ok) {
                              // Gate flips to scanner automatically after saving
                            }
                          },
                          label: const Text(
                            "Save & Continue",
                            style: TextStyle(fontWeight: FontWeight.w800),
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
      ),
    );
  }

  // Build decides which page to show based on the interest gate; NO interest-page flicker
  @override
  Widget build(BuildContext context) {
    // Only show interest selection AFTER the background check resolves to true.
    if (_requireInterestSelection == true) {
      return _buildInterestSelectionGate(context);
    }

    // Main Emotion Scanner UI
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;
    final gap = isCompact ? 8.0 : 12.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C3E64)]
                : const [Color(0xFFa8edea), Color(0xFFfed6e3), Color(0xFFa6c1ee), Color(0xFFfbc2eb)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background particles
            ...List.generate(18, (i) {
              final particleSize = 4.0 + math.Random().nextDouble() * 6;
              final x = math.Random().nextDouble() * size.width;
              final y = math.Random().nextDouble() * size.height * 0.7;
              final colorsArr = isDark
                  ? [const Color(0xFF8CC8FF).withOpacity(0.6), const Color(0xFFB496FF).withOpacity(0.55)]
                  : [const Color(0xFFFFFFFF).withOpacity(0.9), const Color(0xFFF0F0FF).withOpacity(0.85)];
              final color = colorsArr[math.Random().nextInt(colorsArr.length)];
              return GlitterParticle(
                key: ValueKey(i),
                size: particleSize,
                color: color,
                initialX: x,
                initialY: y,
              );
            }),

            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (_, __) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _HeaderIcon(
                              icon: Icons.arrow_back,
                              onTap: _goBack,
                              isDark: isDark,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  children: [
                                    Text(
                                      'Emotion Scanner',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF2C3E50),
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Real-time detection',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFFFFFFFF).withOpacity(0.85)
                                            : const Color(0xFF2C3E50).withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _HeaderIcon(
                              icon: isDark ? Icons.wb_sunny : Icons.nightlight_round,
                              onTap: _toggleTheme,
                              isDark: isDark,
                            ),
                          ],
                        ),

                        SizedBox(height: gap),

                        // Content
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildCameraCard(context, isDark),
                              ),
                              SizedBox(height: gap),
                              Expanded(
                                flex: 4,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: _capturedImage == null
                                      ? Container(
                                          key: const ValueKey('placeholder'),
                                          width: double.infinity,
                                          margin: const EdgeInsets.symmetric(horizontal: 12),
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.75),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(isDark ? 0.22 : 0.18),
                                              width: 1.2,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "Your result will appear here after capture",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white70 : const Color(0xFF2C3E50).withOpacity(0.7),
                                            ),
                                          ),
                                        )
                                      : LayoutBuilder(
                                          builder: (c2, c2Cons) =>
                                              _buildAfterCaptureCard(context, isDark, c2Cons),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

/* ===== Helper widgets ===== */

// Fills the given size (the inner frame) while preserving preview aspect via BoxFit.cover.
class _CameraPreviewCover extends StatelessWidget {
  final CameraController? controller;
  const _CameraPreviewCover({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isReady = controller?.value.isInitialized == true;
    if (!isReady) {
      return Container(color: Theme.of(context).colorScheme.surface);
    }

    final previewSize = controller!.value.previewSize;
    final naturalW = (previewSize?.height ?? 1080).toDouble();
    final naturalH = (previewSize?.width ?? 720).toDouble();

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: naturalW,
        height: naturalH,
        child: CameraPreview(controller!),
      ),
    );
  }
}

// Precise stroke painter matching the clip RRect.
class _RoundedFramePainter extends CustomPainter {
  final double radius;
  final double stroke;
  final Color color;

  _RoundedFramePainter({
    required this.radius,
    required this.stroke,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(rrect, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoundedFramePainter old) {
    return old.radius != radius || old.stroke != stroke || old.color != color;
  }
}

class _HintPill extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final Color? textColor;
  final double opacity;

  const _HintPill({
    Key? key,
    required this.color,
    required this.icon,
    required this.text,
    this.textColor,
    this.opacity = 0.95,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final onColor = textColor ?? Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: onColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: onColor,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  final String text;
  final bool isDark;
  const _EmotionChip({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = isDark
        ? [const Color(0xFF8B7FFF), const Color(0xFFB4A7FF)]
        : [const Color(0xFF0A7EA4), const Color(0xFF3DA5C8)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final bool dimmed;
  final VoidCallback onTap;

  const _ActionPill({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final fg = dimmed ? baseColor.withOpacity(0.7) : baseColor;
    final bg =
        isDark ? Colors.white.withOpacity(dimmed ? 0.05 : 0.08) : Colors.white.withOpacity(dimmed ? 0.5 : 0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.20),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w800, color: fg, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _HeaderIcon({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFFFFFFFF).withOpacity(0.3), const Color(0xFFFFFFFF).withOpacity(0.1)]
                : [const Color(0xFF2C3E50).withOpacity(0.2), const Color(0xFF2C3E50).withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
        ),
        child: Icon(icon, size: 22, color: isDark ? Colors.white : const Color(0xFF2C3E50)),
      ),
    );
  }
}

extension FirstOrNullList<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}