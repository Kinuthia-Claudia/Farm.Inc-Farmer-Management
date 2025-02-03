import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class FarmersDetails extends StatefulWidget {
  const FarmersDetails({super.key});

  @override
  FarmersDetailsPageState createState() => FarmersDetailsPageState();
}

class FarmersDetailsPageState extends State<FarmersDetails> {
  final TextEditingController _systemIdController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _kraPinController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountNoController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _kinFullNameController = TextEditingController();
  final TextEditingController _kinNationalIdController = TextEditingController();
  final TextEditingController _kinTelController = TextEditingController();

  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  String? _imageBase64;
  List<Map<String, dynamic>> _locationSuggestions = [];
  Map<String, double>? _selectedCoordinates;
  bool _isLoading = false;

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

  Future<bool> _farmerExists() async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('farmers')
        .where('nationalId', isEqualTo: _nationalIdController.text.trim())
        .where('systemId', isEqualTo: _systemIdController.text.trim())
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  void _clearForm() {
    _systemIdController.clear();
    _nationalIdController.clear();
    _fullNameController.clear();
    _kraPinController.clear();
    _bankNameController.clear();
    _bankAccountNoController.clear();
    _telController.clear();
    _locationController.clear();
    _kinFullNameController.clear();
    _kinNationalIdController.clear();
    _kinTelController.clear();
    setState(() {
      _selectedImage = null;
      _imageBase64 = null;
      _imageBytes = null;
    });
  }

  Future<void> _saveFarmer(BuildContext context) async {
    if (_fullNameController.text.isEmpty || 
        _systemIdController.text.isEmpty ||
        _nationalIdController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _kraPinController.text.isEmpty) {
      _showErrorDialog(context, "Please fill in all required fields (marked with *)");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog(context, "You must be logged in to save a farmer.");
        return;
      }

      // Check for duplicates
      if (await _farmerExists()) {
        _showErrorDialog(context, "Farmer exists within the system");
        return;
      }

      // Upload image if selected
      if (_imageBytes != null || _selectedImage != null) {
        await _uploadImage();
      }

      // Prepare farmer data
      final farmerData = {
        'systemId': _systemIdController.text.trim(),
        'nationalId': _nationalIdController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'kraPin': _kraPinController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'bankAccountNo': _bankAccountNoController.text.trim(),
        'tel': _telController.text.trim(),
        'location': {
          'address': _locationController.text.trim(),
          'coordinates': _selectedCoordinates,
        },
        'kinFullName': _kinFullNameController.text.trim(),
        'kinNationalId': _kinNationalIdController.text.trim(),
        'kinTel': _kinTelController.text.trim(),
        'imageBase64': _imageBase64 ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('farmers').add(farmerData);
      
      _clearForm();
      _showSuccessDialog(context);
    } catch (e) {
      _showErrorDialog(context, "Error saving farmer: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Farmer details saved successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() => _locationSuggestions = []);
      return;
    }

    final response = await http.get(
      Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$query')
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
      _locationController.text = location['display_name'];
      _selectedCoordinates = {
        'lat': location['lat'],
        'lon': location['lon']
      };
      _locationSuggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmers Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageUploadSection(),
                  const SizedBox(height: 20),
                  _buildTextField(_systemIdController, 'System ID *'),
                  _buildTextField(_nationalIdController, 'National ID *'),
                  _buildTextField(_fullNameController, 'Full Name *'),
                  _buildTextField(_kraPinController, 'KRA PIN *'),
                  _buildTextField(_bankNameController, 'Bank Name'),
                  _buildTextField(_bankAccountNoController, 'Bank Account NO.'),
                  _buildTextField(_telController, 'Phone Number'),
                  _buildLocationField(),
                  ..._buildLocationSuggestions(),
                  const SizedBox(height: 20),
                  const Text(
                    'Next of Kin Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  _buildTextField(_kinFullNameController, 'Full Name'),
                  _buildTextField(_kinNationalIdController, 'National ID'),
                  _buildTextField(_kinTelController, 'Phone Number'),
                  const SizedBox(height: 30),
                  _buildSaveButton(context),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: Container(
          width: 150,
          height: 150,
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: _locationController,
        decoration: const InputDecoration(
          labelText: 'Location Address*',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.location_on, color: Colors.red),
        ),
        onChanged: (value) => _searchLocations(value),
      ),
    );
  }

  List<Widget> _buildLocationSuggestions() {
    return _locationSuggestions.map((location) => ListTile(
      title: Text(location['display_name']),
      onTap: () => _selectLocation(location),
    )).toList();
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _saveFarmer(context),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
        ),
        child: const Text(
          'SAVE DETAILS',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}