import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class WorkshopHostScreen extends StatefulWidget {
  const WorkshopHostScreen({super.key, required this.switchScreen});

  final void Function(int index) switchScreen;

  @override
  State<WorkshopHostScreen> createState() => _WorkshopHostScreenState();
}

class _WorkshopHostScreenState extends State<WorkshopHostScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Basic Details
  String _workshopTitle = '';
  String _organizerName = '';
  String _organizerContact = '';
  String _organizerEmail = '';
  String _workshopDescription = '';

  // Location & Mode
  String _workshopMode = 'Online'; // Online, Offline, or Hybrid
  String _venue = '';
  String _onlinePlatform = 'Zoom'; // Default platform

  // Participation Details
  String _eligibilityCriteria = '';
  int _maxParticipants = 50;
  bool _isPaid = false;
  String _registrationFee = '0';
  String _paymentMethod = 'UPI';

  // Workshop Content
  String _topicsCovered = '';
  final List<Map<String, String>> _speakers = [
    {'name': '', 'bio': '', 'title': ''}
  ];

  // Resources & Materials
  String _prerequisites = '';
  String _materialsProvided = '';
  bool _provideCertification = true;

  // Miscellaneous
  File? _image;
  bool _isLoading = false;
  String? _imageUrl;
  String _faqs = '';
  String _discordLink = '';
  String _telegramLink = '';
  String _instagramLink = '';

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

  void _addSpeaker() {
    setState(() {
      _speakers.add({'name': '', 'bio': '', 'title': ''});
    });
  }

  void _removeSpeaker(int index) {
    if (_speakers.length > 1) {
      setState(() {
        _speakers.removeAt(index);
      });
    }
  }

  void _updateSpeakerDetail(int index, String key, String value) {
    setState(() {
      _speakers[index][key] = value;
    });
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

  Future<void> _createWorkshop() async {
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

      // Create workshop document in Firestore
      final response = await _firestore.collection('workshops').add({
        // Basic Details
        'workshopTitle': _workshopTitle,
        'organizerName': _organizerName,
        'organizerContact': _organizerContact,
        'organizerEmail': _organizerEmail,
        'workshopDescription': _workshopDescription,

        // Date & Time
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'startTime': _startTimeController.text,
        'endTime': _endTimeController.text,

        // Location & Mode
        'workshopMode': _workshopMode,
        'venue': _venue,
        'onlinePlatform': _workshopMode != 'Offline' ? _onlinePlatform : '',

        // Participation Details
        'eligibilityCriteria': _eligibilityCriteria,
        'maxParticipants': _maxParticipants,
        'isPaid': _isPaid,
        'registrationFee': _isPaid ? int.parse(_registrationFee) : 0,
        'paymentMethod': _isPaid ? _paymentMethod : '',

        // Workshop Content
        'topicsCovered': _topicsCovered,
        'speakers': _speakers,

        // Resources & Materials
        'prerequisites': _prerequisites,
        'materialsProvided': _materialsProvided,
        'provideCertification': _provideCertification,

        // Miscellaneous
        'workshopImage': _imageUrl ?? '',
        'faqs': _faqs,
        'discordLink': _discordLink,
        'telegramLink': _telegramLink,
        'instagramLink': _instagramLink,

        // Metadata
        'hostedBy': _auth.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [],
        'status': 'Upcoming'
      });

      // Update user's hosted workshops
      _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'hostedWorkshops': FieldValue.arrayUnion([response.id]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workshop Created Successfully!')),
      );
      _formKey.currentState!.reset();
      // Navigate back to main screen
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
              const Text(
                'Host a Workshop',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),

              // Basic Details Section
              _buildSectionHeader('Basic Details'),

              // Workshop Title
              TextFormField(
                onSaved: (value) => _workshopTitle = value!,
                decoration: const InputDecoration(
                  labelText: 'Workshop Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().length < 3)
                    ? 'Enter a valid workshop title'
                    : null,
              ),
              const SizedBox(height: 20),

              // Organizer Information
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

              // Workshop Description
              TextFormField(
                onSaved: (value) => _workshopDescription = value!,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Workshop Description',
                  hintText: 'Include overview, purpose, and key takeaways',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().length < 10)
                        ? 'Enter a valid workshop description'
                        : null,
              ),
              const SizedBox(height: 30),

              // Date & Time Section
              _buildSectionHeader('Date & Time'),

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
              const SizedBox(height: 30),

              _buildSectionHeader('Location & Mode'),

              // Workshop Mode
              DropdownButtonFormField<String>(
                value: _workshopMode,
                onChanged: (value) {
                  setState(() {
                    _workshopMode = value!;
                  });
                },
                items: ['Online', 'Offline', 'Hybrid'].map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(mode),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Workshop Mode',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Venue (for Offline or Hybrid)
              if (_workshopMode != 'Online')
                TextFormField(
                  onSaved: (value) => _venue = value!,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (_workshopMode != 'Online' &&
                          (value == null || value.trim().isEmpty))
                      ? 'Enter venue for offline workshop'
                      : null,
                ),
              if (_workshopMode != 'Online') const SizedBox(height: 20),

              // Online Platform (for Online or Hybrid)
              if (_workshopMode != 'Offline')
                DropdownButtonFormField<String>(
                  value: _onlinePlatform,
                  onChanged: (value) {
                    setState(() {
                      _onlinePlatform = value!;
                    });
                  },
                  items: ['Zoom', 'Google Meet', 'Microsoft Teams', 'Other']
                      .map((platform) {
                    return DropdownMenuItem(
                      value: platform,
                      child: Text(platform),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Online Platform',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (_workshopMode != 'Offline') const SizedBox(height: 30),

              // Participation Details Section
              _buildSectionHeader('Participation Details'),

              // Eligibility Criteria
              TextFormField(
                onSaved: (value) => _eligibilityCriteria = value!,
                decoration: const InputDecoration(
                  labelText: 'Eligibility Criteria',
                  hintText: 'Who should attend this workshop?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Maximum Participants
              TextFormField(
                keyboardType: TextInputType.number,
                initialValue: _maxParticipants.toString(),
                onSaved: (value) => _maxParticipants = int.parse(value!),
                decoration: const InputDecoration(
                  labelText: 'Maximum Participants',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter maximum participants';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Paid Workshop
              SwitchListTile(
                title: const Text('Is this a paid workshop?'),
                value: _isPaid,
                onChanged: (value) {
                  setState(() {
                    _isPaid = value;
                  });
                },
              ),

              // Registration Fee (if paid)
              if (_isPaid)
                TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: _registrationFee,
                  onSaved: (value) => _registrationFee = value!,
                  decoration: const InputDecoration(
                    labelText: 'Registration Fee (INR)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_isPaid) return null;
                    if (value == null || value.isEmpty) {
                      return 'Enter registration fee';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
              if (_isPaid) const SizedBox(height: 20),

              // Payment Method (if paid)
              if (_isPaid)
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                  items:
                      ['UPI', 'Bank Transfer', 'Cash', 'Other'].map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (_isPaid) const SizedBox(height: 30),

              // Workshop Content Section
              _buildSectionHeader('Workshop Content'),

              // Topics Covered
              TextFormField(
                onSaved: (value) => _topicsCovered = value!,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Topics Covered',
                  hintText: 'List main topics, separated by commas',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter topics to be covered'
                    : null,
              ),
              const SizedBox(height: 20),

              // Speakers
              const Text('Speakers',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Speaker List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _speakers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Speaker ${index + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              if (_speakers.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeSpeaker(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            initialValue: _speakers[index]['name'],
                            onChanged: (value) =>
                                _updateSpeakerDetail(index, 'name', value),
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            initialValue: _speakers[index]['title'],
                            onChanged: (value) =>
                                _updateSpeakerDetail(index, 'title', value),
                            decoration: const InputDecoration(
                              labelText: 'Title/Position',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            initialValue: _speakers[index]['bio'],
                            onChanged: (value) =>
                                _updateSpeakerDetail(index, 'bio', value),
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Bio',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Add Speaker Button
              ElevatedButton.icon(
                onPressed: _addSpeaker,
                icon: const Icon(Icons.add),
                label: const Text('Add Speaker'),
              ),
              const SizedBox(height: 30),

              // Resources & Materials Section
              _buildSectionHeader('Resources & Materials'),

              // Prerequisites
              TextFormField(
                onSaved: (value) => _prerequisites = value!,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Prerequisites',
                  hintText: 'Knowledge, skills, or items participants need',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Materials Provided
              TextFormField(
                onSaved: (value) => _materialsProvided = value!,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Materials Provided',
                  hintText: 'Handouts, tools, or resources you will provide',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Certification
              SwitchListTile(
                title: const Text('Provide Certification'),
                value: _provideCertification,
                onChanged: (value) {
                  setState(() {
                    _provideCertification = value;
                  });
                },
              ),
              const SizedBox(height: 30),

              // Miscellaneous Section
              _buildSectionHeader('Miscellaneous'),

              // Workshop Image
              ListTile(
                title: const Text('Workshop Image'),
                subtitle: const Text('Upload a banner image for your workshop'),
                trailing: _image == null ? const Icon(Icons.image) : null,
                leading: _image == null
                    ? null
                    : SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
                onTap: _pickImage,
              ),
              const SizedBox(height: 20),

              // FAQs
              TextFormField(
                onSaved: (value) => _faqs = value!,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'FAQs',
                  hintText: 'Common questions and answers',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Social Media Links
              TextFormField(
                onSaved: (value) => _discordLink = value!,
                decoration: const InputDecoration(
                  labelText: 'Discord Link (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                onSaved: (value) => _telegramLink = value!,
                decoration: const InputDecoration(
                  labelText: 'Telegram Link (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                onSaved: (value) => _instagramLink = value!,
                decoration: const InputDecoration(
                  labelText: 'Instagram Link (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createWorkshop,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Workshop',
                            style: TextStyle(fontSize: 16)),
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

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Divider(thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
