import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home.dart';

const Color whitey = Colors.white;
const Color blacky = Colors.black;
const Color bluey = Color.fromARGB(255, 8, 81, 182);

void main() async {
  // Lock the orientation to portrait mode
  WidgetsFlutterBinding.ensureInitialized();
  
  final storage = FlutterSecureStorage();
  String? accessToken;
  
  try {
    // Try to read the access token
    accessToken = await storage.read(key: 'access');
  } catch (e) {
    // If there's an error, delete all data and reinitialize
    await storage.deleteAll();
    print('Secure storage reset due to error: $e');
  }

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(MyApp(accessToken: accessToken));
}

class MyApp extends StatelessWidget {
  final String? accessToken;

  const MyApp({super.key, this.accessToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: bluey,
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: bluey),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: bluey,
        ),
      ),
      home: accessToken != null ? Home() : const HomePageLayout(),
    );
  }
}

class HomePageLayout extends StatefulWidget {
  const HomePageLayout({super.key});

  @override
  _HomePageLayoutState createState() => _HomePageLayoutState();
}

class _HomePageLayoutState extends State<HomePageLayout> {
  bool isLogin = true;
  bool isOtpVerification = false;
  final storage = FlutterSecureStorage();

  void toggleView() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  void showOtpVerification() {
    setState(() {
      isOtpVerification = true;
    });
  }

  void showLogin() {
    setState(() {
      isOtpVerification = false;
      isLogin = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (isOtpVerification) {
      showLogin();
      return false;
    }
    if (!isLogin) {
      toggleView();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isOtpVerification
                      ? OtpVerification(showLogin: showLogin)
                      : isLogin
                          ? Login(toggleView: toggleView, showOtpVerification: showOtpVerification)
                          : SignUp(toggleView: toggleView),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.65,
              left: 0,
              right: 0,
              child: Image.asset('assets/cartoon.png'),
            ),
          ],
        ),
      ),
    );
  }
}

class Login extends StatefulWidget {
  final VoidCallback toggleView;
  final VoidCallback showOtpVerification;

  const Login({required this.toggleView, required this.showOtpVerification, Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool isLoading = false;

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://e6d5-105-179-8-146.ngrok-free.app/api/login/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': emailController.text,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final sessionId = responseData['sessionId']; // Adjust key based on API response

      await storage.write(key: 'email', value: emailController.text);
      await storage.write(key: 'sessionId', value: sessionId);

      print('Login successful: $responseData');
      widget.showOtpVerification();
    } else {
      print('Login failed: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset('assets/alualu.png', height: 40),
            Container(
              width: constraints.maxWidth * 1,
              color: Colors.white,
            ),
            Container(
              width: constraints.maxWidth * 0.7,
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  hintText: 'Enter Student Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
            ),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bluey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 30),
                    ),
                    child: const Text('Login', style: TextStyle(color: whitey)),
                  ),
            RichText(
              text: TextSpan(
                text: "Don't have an Account? ",
                style: TextStyle(color: blacky),
                children: [
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(
                      color: bluey,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = widget.toggleView,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class OtpVerification extends StatefulWidget {
  final VoidCallback showLogin;

  const OtpVerification({required this.showLogin, Key? key}) : super(key: key);

  @override
  _OtpVerificationState createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  final storage = FlutterSecureStorage();
  bool isLoading = false;

  void handleOtpInput(String value) {
    if (value.length > 6) {
      value = value.substring(0, 6);
    }

    for (int i = 0; i < value.length; i++) {
      otpControllers[i].text = value[i];
    }
  }

  Future<void> verifyOtp() async {
    setState(() {
      isLoading = true;
    });

    final otp = otpControllers.map((controller) => controller.text).join();
    final email = await storage.read(key: 'email');
    final response = await http.post(
      Uri.parse('https://e6d5-105-179-8-146.ngrok-free.app/api/verify-otp/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'sessionid=${await storage.read(key: "sessionId")}',
      },
      body: jsonEncode(<String, String>{
        'otp': otp,
        'email': email ?? '',
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      print('Verification successful');
      final responseBody = jsonDecode(response.body);
      var tokens = responseBody['tokens'];
      var user = responseBody['user'];
      if (tokens != null) {
        await storage.write(key: 'access', value: tokens['access']);
        await storage.write(key: 'refresh', value: tokens['refresh']);
      }
      print(await storage.read(key: 'access'));
      print(await storage.read(key: 'refresh'));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    } else {
      print('Failed to verify');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.showLogin();
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image.asset('assets/alualu.png', height: 40),
              Container(
                width: constraints.maxWidth * 1,
                color: Colors.white,
              ),
              Container(
                width: constraints.maxWidth * 0.7,
                child: TextField(
                  onChanged: handleOtpInput,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter OTP',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
              ),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bluey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 30),
                      ),
                      child: const Text('Verify', style: TextStyle(color: whitey)),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class SignUp extends StatefulWidget {
  final VoidCallback toggleView;

  const SignUp({required this.toggleView, Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool isLoading = false;

  Future<void> signUp() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://e6d5-105-179-8-146.ngrok-free.app/api/signup/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': emailController.text,
        'first_name': firstNameController.text,
        'last_name': lastNameController.text,
        'phone': phoneNumberController.text,
        'student_id': studentIdController.text,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 201) {
      print('Signup successful: ${response.body}');
      widget.toggleView();
    } else {
      print('Signup failed: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/alualu.png', height: 40),
              const SizedBox(height: 10),
              Container(
                width: constraints.maxWidth *
                    1, // Set the width to 70% of the container's widt
              ),
              const SizedBox(height: 10),
              Container(
                  width: constraints.maxWidth * 0.7,
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Student Email',
                      labelStyle:
                          TextStyle(fontSize: 14), // Make the label smaller
                      border: UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: bluey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                    ),
                  )),
              Container(
                width: constraints.maxWidth * 0.7,
                child: TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    labelStyle:
                        TextStyle(fontSize: 14), // Make the label smaller
                    border: UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: bluey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: constraints.maxWidth * 0.7,
                child: TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    labelStyle:
                        TextStyle(fontSize: 14), // Make the label smaller
                    border: UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: bluey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: constraints.maxWidth * 0.7,
                child: TextField(
                  controller: phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle:
                        TextStyle(fontSize: 14), // Make the label smaller
                    border: UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: bluey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: constraints.maxWidth * 0.7,
                child: TextField(
                  controller: studentIdController,
                  decoration: InputDecoration(
                    labelText: 'Student ID',
                    labelStyle:
                        TextStyle(fontSize: 14), // Make the label smaller
                    border: UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: bluey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bluey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 30),
                      ),
                      child: const Text('Sign Up', style: TextStyle(color: whitey)),
                    ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }
}