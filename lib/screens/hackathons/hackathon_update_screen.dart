import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class HackathonUpdateScreen extends StatefulWidget {
  final String hackathonId;
  final void Function(int index) switchScreen;

  const HackathonUpdateScreen({
    super.key,
    required this.hackathonId,
    required this.switchScreen,
  });

  @override
  State<HackathonUpdateScreen> createState() => _HackathonUpdateScreenState();
}

class _HackathonUpdateScreenState extends State<HackathonUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _hackathonNameController =
      TextEditingController();
  final TextEditingController _hackathonDescriptionController =
      TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _prizeController = TextEditingController();
  final TextEditingController _criteriaAndRulesController =
      TextEditingController();
  final TextEditingController _registrationFeeController =
      TextEditingController();
  final TextEditingController _organizerNameController =
      TextEditingController();
  final TextEditingController _organizerContactController =
      TextEditingController();
  final TextEditingController _organizerEmailController =
      TextEditingController();
  final TextEditingController _maxTeamSizeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  String _hackathonMode = 'Online'; // Online or Offline
  String _participationType = 'Individual'; // Individual or Team
  int _maxTeamSize = 4;
  bool _provideCertification = true;
  bool _isPaid = false;
  File? _image;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _existingImageUrl;
  String? _newImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchHackathonData();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _hackathonNameController.dispose();
    _hackathonDescriptionController.dispose();
    _venueController.dispose();
    _prizeController.dispose();
    _criteriaAndRulesController.dispose();
    _registrationFeeController.dispose();
    _organizerNameController.dispose();
    _organizerContactController.dispose();
    _organizerEmailController.dispose();
    _maxTeamSizeController.dispose();
    super.dispose();
  }

  Future<void> _fetchHackathonData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final hackathonDoc = await _firestore
          .collection('hackathons')
          .doc(widget.hackathonId)
          .get();

      if (!hackathonDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hackathon not found!')),
        );
        widget.switchScreen(0);
        return;
      }

      final hackathonData = hackathonDoc.data() as Map<String, dynamic>;

      // Populate controllers with existing data
      _hackathonNameController.text = hackathonData['hackathonName'] ?? '';
      _hackathonDescriptionController.text =
          hackathonData['hackathonDescription'] ?? '';
      _venueController.text = hackathonData['venue'] ?? '';
      _startDateController.text = hackathonData['startDate'] ?? '';
      _endDateController.text = hackathonData['endDate'] ?? '';
      _startTimeController.text = hackathonData['startTime'] ?? '';
      _endTimeController.text = hackathonData['endTime'] ?? '';
      _prizeController.text = hackathonData['prize'] ?? '';
      _criteriaAndRulesController.text =
          hackathonData['criteriaAndRules'] ?? '';
      _maxTeamSizeController.text =
          (hackathonData['maxTeamSize'] ?? 4).toString();
      _organizerNameController.text = hackathonData['organizerName'] ?? '';
      _organizerContactController.text =
          hackathonData['organizerContact'] ?? '';
      _organizerEmailController.text = hackathonData['organizerEmail'] ?? '';

      // Set registration fee
      _isPaid = hackathonData['isPaid'] ?? false;
      _registrationFeeController.text =
          (hackathonData['registrationFee'] ?? 0).toString();

      // Set dropdown values
      setState(() {
        _hackathonMode = hackathonData['hackathonMode'] ?? 'Online';
        _participationType = hackathonData['participationType'] ?? 'Individual';
        _provideCertification = hackathonData['provideCertification'] ?? true;
        _maxTeamSize = hackathonData['maxTeamSize'] ?? 4;
        _existingImageUrl = hackathonData['hackathonImage'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading hackathon: $e')),
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
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
      initialDate: _startDateController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_startDateController.text)
          : DateTime.now(),
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
      initialDate: _endDateController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_endDateController.text)
          : startDate,
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
      initialTime: _startTimeController.text.isNotEmpty
          ? TimeOfDay.fromDateTime(
              DateFormat.jm().parse(_startTimeController.text),
            )
          : TimeOfDay.now(),
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
      initialTime: _endTimeController.text.isNotEmpty
          ? TimeOfDay.fromDateTime(
              DateFormat.jm().parse(_endTimeController.text),
            )
          : TimeOfDay.now(),
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

  Future<void> _updateHackathon() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image to Cloudinary if new image selected
      if (_image != null) {
        _newImageUrl = await _uploadImageToCloudinary(_image!);
        if (_newImageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image upload failed. Try again!')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Update hackathon document in Firestore
      await _firestore.collection('hackathons').doc(widget.hackathonId).update({
        'hackathonName': _hackathonNameController.text,
        'hackathonDescription': _hackathonDescriptionController.text,
        'hackathonMode': _hackathonMode,
        'participationType': _participationType,
        'maxTeamSize': _participationType == 'Team'
            ? int.parse(_maxTeamSizeController.text)
            : 1,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'startTime': _startTimeController.text,
        'endTime': _endTimeController.text,
        'venue': _venueController.text,
        'prize': _prizeController.text,
        'provideCertification': _provideCertification,
        'criteriaAndRules': _criteriaAndRulesController.text,
        'isPaid': _isPaid,
        'registrationFee':
            _isPaid ? int.parse(_registrationFeeController.text) : 0,
        'hackathonImage': _newImageUrl ?? _existingImageUrl ?? '',
        'organizerName': _organizerNameController.text,
        'organizerContact': _organizerContactController.text,
        'organizerEmail': _organizerEmailController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hackathon Updated Successfully!')),
      );
      widget.switchScreen(0);
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
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Hackathon',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Hackathon Name
              TextFormField(
                controller: _hackathonNameController,
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

              // Team Size (if Team is selected)
              if (_participationType == 'Team') ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _maxTeamSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maximum Team Size',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter maximum team size';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Team size must be a positive number';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              // Hackathon Description
              TextFormField(
                controller: _hackathonDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Hackathon Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please provide a description'
                    : null,
              ),
              const SizedBox(height: 20),

              // Venue (displayed only for Offline or Hybrid mode)
              if (_hackathonMode != 'Online') ...[
                TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (_hackathonMode != 'Online' &&
                          (value == null || value.trim().isEmpty))
                      ? 'Venue is required for offline/hybrid events'
                      : null,
                ),
                const SizedBox(height: 20),
              ],

              // Start Date and Time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _selectStartDate,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Start date is required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: _selectStartTime,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Start time is required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // End Date and Time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _selectEndDate,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'End date is required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: _selectEndTime,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'End time is required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prize
              TextFormField(
                controller: _prizeController,
                decoration: const InputDecoration(
                  labelText: 'Prize Details',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter prize details'
                    : null,
              ),
              const SizedBox(height: 20),

              // Criteria and Rules
              TextFormField(
                controller: _criteriaAndRulesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Judging Criteria & Rules',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Criteria and rules are required'
                    : null,
              ),
              const SizedBox(height: 20),

              // Certificate
              SwitchListTile(
                title: const Text('Provide Certificate?'),
                value: _provideCertification,
                onChanged: (bool value) {
                  setState(() {
                    _provideCertification = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Is Paid
              SwitchListTile(
                title: const Text('Paid Registration?'),
                value: _isPaid,
                onChanged: (bool value) {
                  setState(() {
                    _isPaid = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Registration Fee (if Paid)
              if (_isPaid) ...[
                TextFormField(
                  controller: _registrationFeeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Registration Fee',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_isPaid && (value == null || value.isEmpty)) {
                      return 'Please enter registration fee';
                    }
                    if (_isPaid &&
                        (int.tryParse(value!) == null ||
                            int.parse(value) < 0)) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Organizer Details
              const Text(
                'Organizer Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _organizerNameController,
                decoration: const InputDecoration(
                  labelText: 'Organizer Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Organizer name is required'
                    : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _organizerContactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Contact number is required'
                    : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _organizerEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email address is required';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Hackathon Banner Image
              const Text(
                'Hackathon Banner Image',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),

              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _image != null
                      ? Image.file(_image!, fit: BoxFit.cover)
                      : _existingImageUrl != null &&
                              _existingImageUrl!.isNotEmpty
                          ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload, size: 50),
                                  SizedBox(height: 10),
                                  Text('Tap to select an image'),
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateHackathon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Hackathon',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
