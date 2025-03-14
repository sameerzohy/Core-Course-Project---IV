import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class HackathonHostScreen extends StatefulWidget {
  const HackathonHostScreen({super.key, required this.switchScreen});

  final void Function(int index) switchScreen;

  @override
  State<HackathonHostScreen> createState() => _HackathonHostScreenState();
}

class _HackathonHostScreenState extends State<HackathonHostScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _hackathonName = '';
  String _hackathonDescription = '';
  String _hackathonMode = 'Online'; // Online or Offline
  String _participationType = 'Individual'; // Individual or Team
  // String _teamName = '';
  int _maxTeamSize = 4;
  // List<Map<String, String>> _teamMembers = [];
  String _venue = '';
  String _prize = '';
  bool _provideCertification = true;
  String _criteriaAndRules = '';
  String _registrationFee = '0';
  bool _isPaid = false;
  File? _image;
  bool _isLoading = false;
  String? _imageUrl;
  String _organizerName = '';
  String _organizerContact = '';
  String _organizerEmail = '';

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _selectStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first')),
      );
      return;
    }

    DateTime startDate =
        DateFormat('yyyy-MM-dd').parse(_startDateController.text);

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: startDate,
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectStartTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _startTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _selectEndTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _endTimeController.text = picked.format(context);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    try {
      // Replace with your Cloudinary cloud name and upload preset
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/dtirt1zwn/image/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'UNLock'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            image.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<void> _createHackathon() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image to Cloudinary if selected
      if (_image != null) {
        _imageUrl = await _uploadImageToCloudinary(_image!);
        if (_imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image upload failed. Try again!')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Create hackathon document in Firestore
      final response = await _firestore.collection('hackathons').add({
        'hackathonName': _hackathonName,
        'hackathonDescription': _hackathonDescription,
        'hackathonMode': _hackathonMode,
        'participationType': _participationType,
        // 'teamName': _participationType == 'Team' ? _teamName : '',
        'maxTeamSize': _participationType == 'Team' ? _maxTeamSize : 1,
        // 'teamMembers': _participationType == 'Team' ? _teamMembers : [],
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'startTime': _startTimeController.text,
        'endTime': _endTimeController.text,
        'venue': _venue,
        'prize': _prize,
        'provideCertification': _provideCertification,
        'criteriaAndRules': _criteriaAndRules,
        'isPaid': _isPaid,
        'registrationFee': _isPaid ? int.parse(_registrationFee) : 0,
        'hackathonImage': _imageUrl ?? '',
        'organizerName': _organizerName,
        'organizerContact': _organizerContact,
        'organizerEmail': _organizerEmail,
        'hostedBy': _auth.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'hostedHackathons': FieldValue.arrayUnion([response.id]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hackathon Created Successfully!')),
      );

      widget.switchScreen(4);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hackathon Name
              TextFormField(
                onSaved: (value) => _hackathonName = value!,
                decoration: const InputDecoration(
                  labelText: 'Hackathon Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().length < 3)
                    ? 'Enter a valid hackathon name'
                    : null,
              ),
              const SizedBox(height: 20),

              // Hackathon Mode
              DropdownButtonFormField<String>(
                value: _hackathonMode,
                onChanged: (value) => setState(() => _hackathonMode = value!),
                items: const [
                  DropdownMenuItem(value: 'Online', child: Text('Online')),
                  DropdownMenuItem(value: 'Offline', child: Text('Offline')),
                  DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mode of Hackathon',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Participation Type
              DropdownButtonFormField<String>(
                value: _participationType,
                onChanged: (value) =>
                    setState(() => _participationType = value!),
                items: const [
                  DropdownMenuItem(
                      value: 'Individual', child: Text('Individual')),
                  DropdownMenuItem(value: 'Team', child: Text('Team')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Participation Type',
                  border: OutlineInputBorder(),
                ),
              ),
              // const SizedBox(height: 20),

              // Team-related fields (only if Team is selected)
              if (_participationType == 'Team') ...[
                // Team Name

                const SizedBox(height: 20),

                // Max Team Size
                TextFormField(
                  initialValue: _maxTeamSize.toString(),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _maxTeamSize = int.tryParse(value!) ?? 4,
                  decoration: const InputDecoration(
                    labelText: 'Maximum Team Size',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter maximum team size';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 20),

              // Date & Time Section
              const Text(
                'Date & Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Start Date
              TextFormField(
                controller: _startDateController,
                readOnly: true,
                onTap: _selectStartDate,
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Select start date'
                    : null,
              ),
              const SizedBox(height: 20),

              // End Date
              TextFormField(
                controller: _endDateController,
                readOnly: true,
                onTap: _selectEndDate,
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Select end date' : null,
              ),
              const SizedBox(height: 20),

              // Start Time
              TextFormField(
                controller: _startTimeController,
                readOnly: true,
                onTap: _selectStartTime,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Select start time'
                    : null,
              ),
              const SizedBox(height: 20),

              // End Time
              TextFormField(
                controller: _endTimeController,
                readOnly: true,
                onTap: _selectEndTime,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Select end time' : null,
              ),
              const SizedBox(height: 20),

              // Venue (especially for offline mode)
              TextFormField(
                onSaved: (value) => _venue = value!,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_hackathonMode != 'Online' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Enter venue for offline/hybrid hackathon';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Prize
              TextFormField(
                onSaved: (value) => _prize = value!,
                decoration: const InputDecoration(
                  labelText: 'Prize Details',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter prize details'
                    : null,
              ),
              const SizedBox(height: 20),

              // Certification
              Row(
                children: [
                  Checkbox(
                    value: _provideCertification,
                    onChanged: (value) {
                      setState(() {
                        _provideCertification = value!;
                      });
                    },
                  ),
                  const Text('Provide Certification'),
                ],
              ),
              const SizedBox(height: 20),

              // Criteria & Rules
              TextFormField(
                onSaved: (value) => _criteriaAndRules = value!,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Criteria & Rules',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().length < 10)
                        ? 'Enter criteria and rules'
                        : null,
              ),
              const SizedBox(height: 20),

              // Hackathon Description
              TextFormField(
                onSaved: (value) => _hackathonDescription = value!,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Hackathon Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().length < 10)
                        ? 'Enter a valid hackathon description'
                        : null,
              ),
              const SizedBox(height: 20),

              // Registration Fee
              Row(
                children: [
                  Checkbox(
                    value: _isPaid,
                    onChanged: (value) {
                      setState(() {
                        _isPaid = value!;
                        if (!_isPaid) {
                          _registrationFee = '0';
                        }
                      });
                    },
                  ),
                  const Text('Paid Registration'),
                ],
              ),
              if (_isPaid)
                TextFormField(
                  initialValue: _registrationFee,
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _registrationFee = value!,
                  decoration: const InputDecoration(
                    labelText: 'Registration Fee (₹)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_isPaid) {
                      if (value == null || value.isEmpty) {
                        return 'Enter registration fee';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Enter a valid fee amount';
                      }
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 20),

              // Organizer Information
              const Text(
                'Organizer Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Organizer Name
              TextFormField(
                onSaved: (value) => _organizerName = value!,
                decoration: const InputDecoration(
                  labelText: 'Organizer Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter organizer name'
                    : null,
              ),
              const SizedBox(height: 20),

              // Organizer Contact
              TextFormField(
                keyboardType: TextInputType.phone,
                onSaved: (value) => _organizerContact = value!,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter contact number';
                  }
                  if (value.length < 10) {
                    return 'Enter a valid contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Organizer Email
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => _organizerEmail = value!,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter email address';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Hackathon Image Upload
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hackathon Banner Image',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: _image == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt,
                                      size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to select an image',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _createHackathon,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Create Hackathon',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
