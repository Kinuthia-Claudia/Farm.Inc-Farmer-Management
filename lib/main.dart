import 'package:farmerapplication/firebase_options.dart';
import 'package:farmerapplication/screens/activity_screen.dart';
import 'package:farmerapplication/screens/profile.dart';
import 'package:farmerapplication/screens/routes_location_screen.dart';
import 'package:farmerapplication/screens/view_farmers_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:farmerapplication/screens/add_farmer_screen.dart';
import 'package:farmerapplication/screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
 await Future.delayed(Duration(seconds: 2));
runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

 @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  
      initialRoute: '/login',
      routes: {
        '/login': (context) => const Loginscreen(),
        '/signup': (context) => const Registerscreen(),
         '/home': (context) => const HomeScreen(),
         '/addfarmer': (context) => const FarmersDetails(),
         '/routesandLocation': (context) => const RoutesAndLocations(),
         '/viewfarmers':(context) =>const ViewFarmersPage(),
          '/activity':(context) =>const ActivityScreen(),
           '/profile':(context) =>const UserProfileScreen(),
       
      },
    );
  }
}

