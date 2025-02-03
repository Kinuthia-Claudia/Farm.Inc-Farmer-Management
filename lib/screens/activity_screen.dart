import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Color.fromARGB(255, 10, 224, 2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('farmers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final farmers = snapshot.data!.docs;

          final totalFarmers = farmers.length;
          final totalCattles = farmers.fold<int>(0, (sum, farmer) {
            final data = farmer.data() as Map<String, dynamic>;
            return sum + (data['numberOfCattles'] as int? ?? 0);
          });
          final farmersWithMilking = farmers.where((farmer) {
            final data = farmer.data() as Map<String, dynamic>;
            return (data['numberOfTimesMilking'] as int? ?? 0) > 0;
          }).length;
          final averageCattles =
              totalFarmers > 0 ? totalCattles / totalFarmers : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildStatCard('Total Farmers', totalFarmers.toString(),
                          Icons.person, Colors.blue),
                      _buildStatCard('Total Cattles', totalCattles.toString(),
                          Icons.pets, Colors.brown),
                      _buildStatCard(
                          'Farmers with Milking',
                          farmersWithMilking.toString(),
                          Icons.local_drink,
                          Colors.teal),
                      _buildStatCard(
                          'Avg Cattles/Farmer',
                          averageCattles.toStringAsFixed(2),
                          Icons.bar_chart,
                          Colors.deepPurple),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      shadowColor: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}