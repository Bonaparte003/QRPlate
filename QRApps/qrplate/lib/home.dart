import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'main.dart';

const Color whitey = Colors.white;
const Color bluey = Color.fromARGB(255, 8, 81, 182);

final storage = FlutterSecureStorage();
Future<String?> getAccessToken() async {
  return await storage.read(key: 'access');
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? qrCodeContent;
  String? qrCodeUrl;
  String? email;
  String? studentId;
  String? profilePictureUrl;
  bool isUploadingImage = false;
  XFile? _profileImage;
  String? firstName;
  String? lastName;

  double imageWidth = 1;
  double imageHeight = 1;
  double profileBoxSize = 250.0;
  @override
  void initState() {
    super.initState();
    fetchHomeData();
    _loadProfileImage();
  }

  Future<void> fetchHomeData() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final response = await http.get(
        Uri.parse('https://9865-196-12-151-106.ngrok-free.app/api/home-api/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Home API Response Status Code: ${response.statusCode}');
      print('Home API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Debug print for profile picture URL
        print('Profile Picture URL from API: ${data['profile_picture_url']}');

        setState(() {
          qrCodeContent = data['qr_code'];
          qrCodeUrl = data['qr_code_url'];
          email = data['user_profile']['email'];
          studentId = data['user_profile']['student_id'];
          firstName = data['user_profile']['first_name'];
          lastName = data['user_profile']['last_name'];
          profilePictureUrl = data['profile_picture_url'] != null 
              ? 'https://9865-196-12-151-106.ngrok-free.app${data['profile_picture_url']}'
              : null;
        });

        // Debug print after setting state
        print('Profile Picture URL after setState: $profilePictureUrl');
      } else if (response.statusCode == 401) {
        await refreshAccessToken();
        await fetchHomeData(); // Retry after token refresh
      } else {
        print('Error fetching home data: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Exception in fetchHomeData: $e');
    }
  }

  Future<void> refreshAccessToken() async {
    String? refreshToken = await storage.read(key: 'refresh');

    final response = await http.post(
      Uri.parse('https://9865-196-12-151-106.ngrok-free.app/api/token/refresh/'),
      body: {
        'refresh': refreshToken,
      },
    );

    print('Refresh Token Response Status Code: ${response.statusCode}');
    print('Refresh Token Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String newAccessToken = data['access'];
      await storage.write(key: 'access', value: newAccessToken);
    } else {
      print('Error refreshing access token: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          isUploadingImage = true;
        });

        // Refresh token before uploading
        await refreshAccessToken();
        
        // Get fresh access token
        final accessToken = await getAccessToken();
        if (accessToken == null) {
          throw Exception('No access token available');
        }

        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://9865-196-12-151-106.ngrok-free.app/api/update-profile-picture/'),
        );

        // Add authorization header
        request.headers['Authorization'] = 'Bearer $accessToken';

        // Add the file
        var stream = http.ByteStream(image.openRead());
        var length = await image.length();
        var multipartFile = http.MultipartFile(
          'profile_picture',
          stream,
          length,
          filename: image.path.split('/').last
        );
        request.files.add(multipartFile);

        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        print('Upload response: $responseData'); // Debug print

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(responseData);
          
          // Refresh home data to get updated profile picture
          await fetchHomeData();
          
          setState(() {
            profilePictureUrl = jsonResponse['profile_picture_url'];
            isUploadingImage = false;
          });
        } else if (response.statusCode == 401) {
          // Token expired during upload, retry once
          await refreshAccessToken();
          setState(() {
            isUploadingImage = false;
          });
          // Retry upload
          _pickAndUploadImage();
        } else {
          print('Failed to upload image: ${response.statusCode}');
          print('Response: $responseData');
          setState(() {
            isUploadingImage = false;
          });
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        isUploadingImage = false;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    String? imagePath = await storage.read(key: 'profile_image_path');
    if (imagePath != null) {
      setState(() {
        _profileImage = XFile(imagePath);
      });
    }
  }

  Future<void> _logout() async {
    await storage.deleteAll();
    setState(() {
      qrCodeContent = null;
      qrCodeUrl = null;
    });
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;

          return Stack(
            children: [
              // Background layer
              Positioned.fill(
                child: Column(
                  children: [
                    Container(
                      height: screenHeight * 0.62,
                      decoration: BoxDecoration(
                        color: whitey,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(1000),
                          bottomRight: Radius.circular(1000),
                        ),
                      ),
                    ),
                    Container(
                      height: screenHeight * 0.38,
                      color: bluey,
                    ),
                  ],
                ),
              ),
              // Content
              Positioned(
                top: screenHeight * 0.12,
                left: screenWidth * 0.1,
                right: screenWidth * 0.1,
                child: SizedBox(
                  height: screenHeight * 0.07,
                  width: screenWidth * 0.2,
                  child: Image.asset('assets/alualu.png'),
                ),
              ),
              Positioned(
                  top: screenHeight * 0.35,
                  left: screenWidth * 0.1,
                  right: screenWidth * 0.1,
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: bluey, // Changed from whitey to bluey for blue border
                              width: 4.0, // Slightly thicker border
                            ),
                          ),
                          child: CircleAvatar(
                            radius: profileBoxSize / 2,
                            backgroundColor: Colors.grey[200],
                            child: profilePictureUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      profilePictureUrl!,
                                      width: profileBoxSize,
                                      height: profileBoxSize,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(bluey),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading profile picture: $error');
                                        return Container(
                                          width: profileBoxSize,
                                          height: profileBoxSize,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            size: profileBoxSize * 0.6,
                                            color: Color.fromARGB(255, 200, 200, 200),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    width: profileBoxSize,
                                    height: profileBoxSize,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: profileBoxSize * 0.6,
                                      color: Color.fromARGB(255, 200, 200, 200),
                                    ),
                                  ),
                          ),
                        ),
                        if (isUploadingImage)
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: screenHeight * 0.2,
                left: screenWidth * 0.1,
                right: screenWidth * 0.1,
                child: Column(
                  children: [
                    Text(
                      '${firstName ?? ''} ${lastName ?? ''}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: whitey,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      email ?? 'Loading...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: whitey,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: screenHeight * 0.05,
                left: screenWidth * 0.35,
                right: screenWidth * 0.35,
                child: SizedBox(
                  height: screenHeight * 0.09,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Center(
                            child: Container(
                              width: screenWidth * 0.8,
                              height: screenHeight * 0.43,
                              decoration: BoxDecoration(
                                color: whitey,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    qrCodeContent != null
                                        ? Container(
                                            width: screenWidth * 0.65,
                                            height: screenHeight * 0.4 * 0.8,
                                            child: Image.memory(
                                              base64Decode(qrCodeContent!),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : CircularProgressIndicator(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Image.asset('assets/qr.png'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: whitey,
                      foregroundColor: bluey,
                      shape: CircleBorder(),
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.05,
                left: screenWidth * 0.88,
                right: screenWidth * 0.05,
                child: IconButton(
                  icon: Icon(Icons.logout, color: bluey, size: 30),
                  onPressed: _logout,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}