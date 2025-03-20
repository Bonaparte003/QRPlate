import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';

const Color whitey = Colors.white;
const Color bluey = Color.fromARGB(255, 8, 81, 182);

final storage = FlutterSecureStorage();

Future<String?> getAccessToken() async {
  return await storage.read(key: 'access');
}

Future<void> refreshAccessToken() async {
  String? refreshToken = await storage.read(key: 'refresh');

  final response = await http.post(
    Uri.parse('https://609d-105-179-6-194.ngrok-free.app/token/refresh/'),
    body: {
      'refresh': refreshToken,
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    String newAccessToken = data['access'];
    await storage.write(key: 'access', value: newAccessToken);
  } else {
    print('Error refreshing access token: ${response.statusCode}');
    print('Response body: ${response.body}');
  }
}

class QRScannerApp extends StatelessWidget {
  const QRScannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Plate Admin',
      theme: ThemeData(
        primaryColor: bluey,
        scaffoldBackgroundColor: whitey,
        appBarTheme: const AppBarTheme(
          backgroundColor: whitey,
          elevation: 0,
          iconTheme: IconThemeData(color: whitey),
          titleTextStyle: TextStyle(
            color: whitey,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: bluey,
            foregroundColor: whitey,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
      home: const QRScannerHomePage(),
    );
  }
}

class QRScannerHomePage extends StatefulWidget {
  const QRScannerHomePage({Key? key}) : super(key: key);

  @override
  _QRScannerHomePageState createState() => _QRScannerHomePageState();
}

class _QRScannerHomePageState extends State<QRScannerHomePage> with SingleTickerProviderStateMixin {
  MobileScannerController? controller;
  bool _showOverlay = false;
  IconData _iconData = Icons.hourglass_empty;
  Color _iconColor = Colors.white;
  bool _isScanning = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller?.dispose();
    super.dispose();
  }

  void _showIconOverlay() {
    setState(() {
      _showOverlay = true;
      _isScanning = false;
      controller?.stop();
      controller = null;
    });
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showOverlay = false);
      }
    });
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        controller = MobileScannerController();
        controller?.start();
        _animationController.repeat(reverse: true);
      } else {
        controller?.stop();
        controller = null;
        _animationController.stop();
      }
    });
  }

  Future<void> postQRCode(String qrCodeId) async {
    if (!_isScanning) return;

    setState(() => _isScanning = false);
    final url = Uri.parse('https://609d-105-179-6-194.ngrok-free.app/api/scan/$qrCodeId/');
    
    try {
      final accessToken = await getAccessToken();
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode == 201) {
        setState(() {
          _iconData = Icons.check_circle;
          _iconColor = Colors.green;
        });
      } else if (response.statusCode == 200) {
        setState(() {
          _iconData = Icons.warning;
          _iconColor = Colors.yellow;
        });
      } else if (response.statusCode == 401) {
        await refreshAccessToken();
        await postQRCode(qrCodeId);
      } else if (response.statusCode == 400) {
        final responseBody = json.decode(response.body);
        setState(() {
          _iconData = responseBody['error'] == 'Invalid QR code ID.'
              ? Icons.cancel
              : Icons.sentiment_very_dissatisfied;
          _iconColor = Colors.red;
        });
      } else {
        setState(() {
          _iconData = Icons.error;
          _iconColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _iconData = Icons.error;
        _iconColor = Colors.red;
      });
    } finally {
      _showIconOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student QR Scanner'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (_isScanning && controller != null)
            Stack(
              children: [
                MobileScanner(
                  controller: controller!,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && _isScanning) {
                      final qrCode = barcodes.first.rawValue;
                      if (qrCode != null) {
                        final uri = Uri.parse(qrCode);
                        final qrCodeId = uri.pathSegments.last;
                        postQRCode(qrCodeId);
                      }
                    }
                  },
                ),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: MediaQuery.of(context).size.height * 0.3 + (_animation.value * MediaQuery.of(context).size.height * 0.4),
                      child: Container(
                        height: 2,
                        color: bluey.withOpacity(0.8),
                        child: Container(
                          height: 2,
                          width: 50,
                          color: whitey,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          else if (!_showOverlay)
            Column(
                children: [
                // ALU Logo at the very top
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/alualu.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Expanded space for center content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // QR Code Icon in the middle with bigger size
                        Icon(
                          Icons.qr_code_scanner,
                          size: 180,
                          color: bluey,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Attend User',
                          style: TextStyle(
                            color: bluey,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Scan Button at bottom with more padding
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: ElevatedButton.icon(
                    onPressed: _toggleScanning,
                    icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
                    label: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isScanning ? Colors.red : bluey,
                      foregroundColor: whitey,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      elevation: 2,
                      ),
                    ),
                  ),
                ],
            ),
          if (_showOverlay)
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: whitey,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: bluey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  _iconData,
                  color: _iconColor,
                  size: 150,
              ),
            ),
          ),
        ],
      ),
    );
  }
}