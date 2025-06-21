import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class ScanPage extends StatefulWidget {
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('No cameras available');
        return;
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null) return;

    try {
      final XFile photo = await _controller!.takePicture();
      print('Picture taken: ${photo.path}');
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isCameraInitialized || _controller == null) return;

    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        print('Image selected from gallery: ${image.path}');
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: _isCameraInitialized
                ? CameraPreview(_controller!)
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7F55FF),
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              color: const Color.fromARGB(233, 43, 42, 42).withOpacity(0.45),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Scan Receipt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 40), 
                ],
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align the receipt within the frame',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
          // Scan frame
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            child: Center(
              child: CustomPaint(
                size: Size(320, 450),
                painter: ScanFramePainter(),
              ),
            ),
          ),
          // Bottom buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Flash icon
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  child: IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ),
                // Shutter icon
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFF7F55FF),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white, size: 32),
                    onPressed: _takePicture,
                  ),
                ),
                // Gallery icon
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.photo_library, color: Color(0xFF7F55FF), size: 26),
                    onPressed: _pickImageFromGallery,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    double cornerLength = 40;
    double radius = 18;

    // top left
    final path1 = Path();
    path1.moveTo(0, radius);
    path1.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius), clockwise: true);
    path1.lineTo(cornerLength, 0);
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, radius);
    path2.lineTo(0, cornerLength);
    canvas.drawPath(path2, paint);

    // top right
    final path3 = Path();
    path3.moveTo(size.width - radius, 0);
    path3.arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius), clockwise: true);
    path3.lineTo(size.width, cornerLength);
    canvas.drawPath(path3, paint);

    final path4 = Path();
    path4.moveTo(size.width - cornerLength, 0);
    path4.lineTo(size.width - radius, 0);
    canvas.drawPath(path4, paint);

    // bottom left
    final path5 = Path();
    path5.moveTo(0, size.height - radius);
    path5.arcToPoint(Offset(radius, size.height), radius: Radius.circular(radius), clockwise: false);
    path5.lineTo(cornerLength, size.height);
    canvas.drawPath(path5, paint);

    final path6 = Path();
    path6.moveTo(0, size.height - radius);
    path6.lineTo(0, size.height - cornerLength);
    canvas.drawPath(path6, paint);

    // bottom right
    final path7 = Path();
    path7.moveTo(size.width - radius, size.height);
    path7.arcToPoint(Offset(size.width, size.height - radius), radius: Radius.circular(radius), clockwise: false);
    path7.lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(path7, paint);

    final path8 = Path();
    path8.moveTo(size.width - cornerLength, size.height);
    path8.lineTo(size.width - radius, size.height);
    canvas.drawPath(path8, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 