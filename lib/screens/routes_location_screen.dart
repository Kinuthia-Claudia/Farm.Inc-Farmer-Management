import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoutesAndLocations extends StatefulWidget {
  const RoutesAndLocations({super.key});

  @override
  RoutesAndLocationsState createState() => RoutesAndLocationsState();
}

class RoutesAndLocationsState extends State<RoutesAndLocations> {
  bool showMapView = false;
  String searchQuery = '';
  final LatLng _defaultLocation = const LatLng(0.0, 36.0);
  late Stream<QuerySnapshot> _farmersStream;
  String? selectedFarmerId;

  @override
  void initState() {
    super.initState();
    _farmersStream = FirebaseFirestore.instance
        .collection('farmers')
        .where('location.coordinates', isNotEqualTo: null)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterFarmers(QuerySnapshot snapshot, String query) {
    return snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['fullName']?.toString().toLowerCase() ?? '';
      final location = data['location.address']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase()) || location.contains(query.toLowerCase());
    }).toList();
  }

  LatLng _parseCoordinates(Map<String, dynamic> locationData) {
    try {
      final coords = locationData['coordinates'] as Map<String, dynamic>;
      final lat = coords['lat'] as num;
      final lon = coords['lon'] as num;
      return LatLng(lat.toDouble(), lon.toDouble());
    } catch (e) {
      print("Error parsing coordinates: $e");
      return _defaultLocation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Routes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildViewToggle('List View', false),
              _buildViewToggle('Map View', true),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search farmers...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _farmersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filtered = _filterFarmers(snapshot.data!, searchQuery);
                return showMapView
                    ? _buildMapView(filtered)
                    : _buildListView(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(String text, bool isMapView) {
    return ElevatedButton(
      onPressed: () => setState(() {
        showMapView = isMapView;
        selectedFarmerId = null;
      }),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: showMapView == isMapView ? Colors.green : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(text),
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot> farmers) {
    return ListView.builder(
      itemCount: farmers.length,
      itemBuilder: (context, index) {
        final data = farmers[index].data() as Map<String, dynamic>;
        final location = data['location'] as Map<String, dynamic>?;
        final address = location?['address'] ?? 'Unknown';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: const Icon(Icons.person, size: 40),
            title: Text(data['fullName'] ?? 'Unknown Farmer'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location: $address'),
                Text('Cattle: ${data['numberOfCattles'] ?? '0'}'),
               
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                selectedFarmerId = farmers[index].id;
                showMapView = true;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildMapView(List<QueryDocumentSnapshot> farmers) {
    final selectedFarmer = selectedFarmerId != null
        ? farmers.firstWhere((doc) => doc.id == selectedFarmerId)
        : null;

    for (final doc in farmers) {
      final data = doc.data() as Map<String, dynamic>;
      final coords = _parseCoordinates(data['location']);
      print("Farmer: ${data['fullName']}, Coordinates: $coords");
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: selectedFarmer != null
            ? _parseCoordinates((selectedFarmer.data() as Map<String, dynamic>)['location'])
            : _defaultLocation,
        initialZoom: selectedFarmer != null ? 15.0 : 10.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: (selectedFarmer != null ? [selectedFarmer] : farmers)
              .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final coords = _parseCoordinates(data['location']);
            return Marker(
              point: coords,
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () => _showFarmerPopup(context, data),
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showFarmerPopup(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['fullName'] ?? 'Farmer Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location: ${data['location.address']}'),
              Text('National ID: ${data['nationalId']}'),
              Text('Cattle Count: ${data['numberOfCattles'] ?? '0'}'),
              if (data['imageUrl'] != null) Image.network(data['imageUrl'], height: 100),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}