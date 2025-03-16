import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'main.dart';

const Color whitey = Colors.white;
const Color bluey = Color.fromARGB(255, 8, 81, 182);
const double profileBoxSize = 120.0;

final storage = FlutterSecureStorage();


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  XFile? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
      await storage.write(key: 'profile_image_path', value: image.path);
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
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: profileBoxSize / 2,
                    backgroundColor: bluey,
                    child: CircleAvatar(
                      radius: (profileBoxSize / 2) - 5,
                      backgroundImage: _profileImage != null
                          ? FileImage(File(_profileImage!.path))
                          : null,
                      child: _profileImage == null
                          ? Icon(
                              Icons.person,
                              size: profileBoxSize / 2,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: screenHeight * 0.2,
                left: screenWidth * 0.1,
                right: screenWidth * 0.1,
                child: Column(
                  children: [
                    FutureBuilder(
                      future: storage.read(key: 'first_name'),
                      builder: (context, firstNameSnapshot) {
                        if (firstNameSnapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (firstNameSnapshot.hasError) {
                          return Text('Error: ${firstNameSnapshot.error}');
                        } else {
                          return FutureBuilder(
                            future: storage.read(key: 'last_name'),
                            builder: (context, lastNameSnapshot) {
                              if (lastNameSnapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (lastNameSnapshot.hasError) {
                                return Text('Error: ${lastNameSnapshot.error}');
                              } else {
                                return Text(
                                  '${firstNameSnapshot.data} ${lastNameSnapshot.data}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: whitey,
                                  ),
                                );
                              }
                            },
                          );
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    FutureBuilder(
                      future: storage.read(key: 'email1'),
                      builder: (context, emailSnapshot) {
                        if (emailSnapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (emailSnapshot.hasError) {
                          return Text('Error: ${emailSnapshot.error}');
                        } else {
                          return Text(
                            '${emailSnapshot.data}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: whitey,
                            ),
                          );
                        }
                      },
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
                                    CircularProgressIndicator(),
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