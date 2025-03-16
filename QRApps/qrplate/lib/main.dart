import 'home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const Color whitey = Colors.white;
const Color blacky = Colors.black;
const Color bluey = Color.fromARGB(255, 8, 81, 182);

void main() async {
  // Lock the orientation to portrait mode
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

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
      home: HomePageLayout(),
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
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Home()),
                );
              },
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: bluey,
                foregroundColor: whitey,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
            ],
          ),
        );
      },
    );
  }
}