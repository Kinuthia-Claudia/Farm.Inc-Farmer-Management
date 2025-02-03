import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ViewFarmersPage extends StatefulWidget {
  const ViewFarmersPage({super.key});

  @override
  _ViewFarmersPageState createState() => _ViewFarmersPageState();
}

class _ViewFarmersPageState extends State<ViewFarmersPage> {
  String searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Farmers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search farmers...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('farmers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final farmers = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['fullName'].toString().toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      );
                }).toList();

                return ListView.builder(
                  itemCount: farmers.length,
                  itemBuilder: (context, index) {
                    final farmer = farmers[index];
                    final data = farmer.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text(data['fullName']),
                        subtitle: Text('System ID: ${data['systemId']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditFarmerPage(farmerDoc: farmer),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EditFarmerPage extends StatefulWidget {
  final DocumentSnapshot farmerDoc;

  const EditFarmerPage({Key? key, required this.farmerDoc}) : super(key: key);

  @override
  _EditFarmerPageState createState() => _EditFarmerPageState();
}

class _EditFarmerPageState extends State<EditFarmerPage> {
  late TextEditingController _systemIdController;
  late TextEditingController _nationalIdController;
  late TextEditingController _fullNameController;
  late TextEditingController _telController;
  late TextEditingController _farmNameController;
  late TextEditingController _locationAddressController;
  late TextEditingController _dairyBreedController;
  late TextEditingController _numberOfCattlesController;
  late TextEditingController _numberOfTimesMilkingController;

  List<Map<String, dynamic>> _locationSuggestions = [];
  Map<String, double>? _selectedCoordinates;

  File? _selectedImage;
  Uint8List? _imageBytes;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();
  late DocumentReference farmerRef;
  bool showFarmInsights = false;

  @override
  void initState() {
    super.initState();
    farmerRef = widget.farmerDoc.reference;
    final data = widget.farmerDoc.data() as Map<String, dynamic>;

    _systemIdController = TextEditingController(text: data['systemId'] ?? '');
    _nationalIdController = TextEditingController(text: data['nationalId'] ?? '');
    _fullNameController = TextEditingController(text: data['fullName'] ?? '');
    _telController = TextEditingController(text: data['tel'] ?? '');
    _farmNameController = TextEditingController(text: data['farmName'] ?? '');
    _locationAddressController = TextEditingController(text: data['locationAddress'] ?? '');
    _dairyBreedController = TextEditingController(text: data['dairyBreed'] ?? '');
    _numberOfCattlesController = TextEditingController(text: (data['numberOfCattles'] ?? 0).toString());
    _numberOfTimesMilkingController = TextEditingController(text: (data['numberOfTimesMilking'] ?? 0).toString());

    // Load image from database if it exists
    if (data['imageBase64'] != null && data['imageBase64'].isNotEmpty) {
      _imageBase64 = data['imageBase64'];
      _imageBytes = base64Decode(_imageBase64!);
    }

    // Load existing coordinates
    _selectedCoordinates = {
      'lat': data['lat'] ?? 0.0,
      'lon': data['lon'] ?? 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showFarmInsights = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: showFarmInsights ? Colors.grey : Colors.green,
                ),
                child: const Text('Personal Details'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showFarmInsights = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: showFarmInsights ? Colors.green : Colors.grey,
                ),
                child: const Text('Farm Insights'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: showFarmInsights ? _buildFarmInsights() : _buildPersonalDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_a_photo, size: 40),
                        Text('Add Photo'),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _systemIdController,
            decoration: const InputDecoration(labelText: 'System ID'),
          ),
          TextField(
            controller: _nationalIdController,
            decoration: const InputDecoration(labelText: 'National ID'),
          ),
          TextField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          TextField(
            controller: _telController,
            decoration: const InputDecoration(labelText: 'TEL'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _updateFarmer,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text('Save', style: TextStyle(fontSize: 23)),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmInsights() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _farmNameController,
            decoration: const InputDecoration(labelText: 'Farm Name'),
          ),
          const SizedBox(height: 20),
          _buildLocationField(),
          const SizedBox(height: 20),
          TextField(
            controller: _dairyBreedController,
            decoration: const InputDecoration(labelText: 'Type of Dairy Breed'),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Number of Cattles:', style: TextStyle(fontSize: 20)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    color: Colors.green,
                    onPressed: () {
                      int currentValue = int.tryParse(_numberOfCattlesController.text) ?? 0;
                      if (currentValue > 0) {
                        _numberOfCattlesController.text = (currentValue - 1).toString();
                      }
                    },
                  ),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _numberOfCattlesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    color: Colors.green,
                    onPressed: () {
                      int currentValue = int.tryParse(_numberOfCattlesController.text) ?? 0;
                      _numberOfCattlesController.text = (currentValue + 1).toString();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Milking Times/Day:', style: TextStyle(fontSize: 20)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    color: Colors.green,
                    onPressed: () {
                      int currentValue = int.tryParse(_numberOfTimesMilkingController.text) ?? 0;
                      if (currentValue > 0) {
                        _numberOfTimesMilkingController.text = (currentValue - 1).toString();
                      }
                    },
                  ),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _numberOfTimesMilkingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    color: Colors.green,
                    onPressed: () {
                      int currentValue = int.tryParse(_numberOfTimesMilkingController.text) ?? 0;
                      _numberOfTimesMilkingController.text = (currentValue + 1).toString();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _updateFarmer,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text('Save', style: TextStyle(fontSize: 23)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      children: [
        TextField(
          controller: _locationAddressController,
          decoration: const InputDecoration(
            labelText: 'Location Address*',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.location_on, color: Colors.red),
          ),
          onChanged: (value) => _searchLocations(value),
        ),
        if (_locationSuggestions.isNotEmpty)
          ..._locationSuggestions.map((location) => ListTile(
                title: Text(location['display_name']),
                onTap: () => _selectLocation(location),
              )),
      ],
    );
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() => _locationSuggestions = []);
      return;
    }

    final response = await http.get(
      Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$query'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _locationSuggestions = data.map<Map<String, dynamic>>((item) => {
          'display_name': item['display_name'],
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
        }).toList();
      });
    }
  }

  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      _locationAddressController.text = location['display_name'];
      _selectedCoordinates = {
        'lat': location['lat'],
        'lon': location['lon'],
      };
      _locationSuggestions = [];
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          if (!kIsWeb) {
            _selectedImage = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_imageBytes == null && _selectedImage == null) {
      throw Exception('No image selected');
    }

    try {
      if (kIsWeb) {
        if (_imageBytes == null) throw Exception('Image bytes are null');
        _imageBase64 = base64Encode(_imageBytes!);
      } else {
        if (_selectedImage == null) throw Exception('Selected image is null');
        final bytes = await _selectedImage!.readAsBytes();
        _imageBase64 = base64Encode(bytes);
      }
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<void> _updateFarmer() async {
    try {
      await farmerRef.update({
        'systemId': _systemIdController.text,
        'nationalId': _nationalIdController.text,
        'fullName': _fullNameController.text,
        'tel': _telController.text,
        'farmName': _farmNameController.text,
        'locationAddress': _locationAddressController.text,
        'lat': _selectedCoordinates?['lat'] ?? 0.0,
        'lon': _selectedCoordinates?['lon'] ?? 0.0,
        'dairyBreed': _dairyBreedController.text,
        'numberOfCattles': int.tryParse(_numberOfCattlesController.text) ?? 0,
        'numberOfTimesMilking': int.tryParse(_numberOfTimesMilkingController.text) ?? 0,
        'imageBase64': _imageBase64 ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farmer updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this farmer?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deleteFarmer();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFarmer() async {
    try {
      await farmerRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farmer deleted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete farmer: $e')),
      );
    }
  }
}