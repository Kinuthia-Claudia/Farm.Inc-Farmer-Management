import 'package:farmerapplication/auth/auth_service.dart';
import 'package:farmerapplication/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmerapplication/screens/profile.dart';
import 'package:farmerapplication/screens/activity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Default index for Home
  int _farmerCount = 0;

  final List<Widget> _pages = [
    const UserProfileScreen(), // Profile Page
    const ActivityScreen(), // Activity Page
  ];

  @override
  void initState() {
    super.initState();
    _fetchFarmerCount(); // Fetch farmer count from Firestore
  }

  // Fetch the number of farmers from Firestore
  Future<void> _fetchFarmerCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('farmers').get();
    setState(() {
      _farmerCount = snapshot.size; // Update farmer count
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _pages[0], // Profile Page
          _homeContent(), // Home Page Content (Instead of including HomeScreen again)
          _pages[1], // Activity Page
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Activity',
          ),
        ],
      ),
    );
  }

  Widget _homeContent() {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(
          left: 24,
          right: 24,
          top: MediaQuery.of(context).padding.top + 10,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 6),
            _insights(),
            const SizedBox(height: 6),
            _actionButtons(context),
          ],
        ),
      ),
    );
  }

  _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello!',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              'Here are some insights ',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 30),
               onPressed: () {
                       
    _fetchFarmerCount(); 
  
                
              },
            ),
            
            IconButton(
              icon: const Icon(Icons.logout, size: 30),
               onPressed: () async{
                 await AuthService().logout();
                 
   
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => Loginscreen()),);
                
              },
            ),
          ],
        ),
      ],
    );
  }

 Widget _insights() {
  return Row(
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: _buildInsightCard(_farmerCount.toString(), 'Newly Added Farmers'),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: _buildInsightCard('0%', 'of Farmers are Active'),
        ),
      ),
    ],
  );
}

Widget _buildInsightCard(String number, String label) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Calculate responsive font size based on screen width
      double fontSize = constraints.maxWidth * 0.1; // Adjust this factor as needed
      if (fontSize > 32) fontSize = 32; // Set a maximum font size

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  _actionButtons(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: double.infinity,
          child: Text(
            'Quick Actions',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 27,
              color: Colors.black,
            ),
          ),
        ),
        _buildActionButton('assets/addfarmer.png', 'Add Farmer', () {
          Navigator.pushNamed(context, '/addfarmer');
        }),
        _buildActionButton('assets/viewdetails.png', 'View Details', () {
          Navigator.pushNamed(context, '/viewfarmers');
        }),
        _buildActionButton('assets/location.png', 'Location', () {
          Navigator.pushNamed(context, '/routesandLocation');
        }),
      ],
    );
  }

  Widget _buildActionButton(String imagePath, String label, Function onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
          backgroundColor: const Color.fromARGB(255, 240, 239, 239),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        onPressed: () => onPressed(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  imagePath,
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
