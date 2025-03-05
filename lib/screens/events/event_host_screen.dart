import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class EventHostScreen extends StatefulWidget {
  const EventHostScreen({super.key, required this.switchScreen});

  final void Function(int index) switchScreen;

  @override
  State<EventHostScreen> createState() => _EventHostScreenState();
}

class _EventHostScreenState extends State<EventHostScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _eventName = '';
  String _eventDescription = '';
  String _eventType = 'Technical';
  String _eventLocation = '';
  String _eventPayment = 'Unpaid';
  int _eventFee = 0;
  int _maxParticipants = 100;
  String _organizerName = '';
  String _organizerContact = '';
  String _organizerEmail = '';
  File? _image;
  bool _isLoading = false;
  String? _imageUrl;

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
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

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
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

  Future<void> _createEvent() async {
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

      // Create event document in Firestore
      final response = await _firestore.collection('events').add({
        'eventName': _eventName,
        'eventDescription': _eventDescription,
        'eventType': _eventType,
        'eventLocation': _eventLocation,
        'eventDate': _dateController.text,
        'eventTime': _timeController.text,
        'eventPayment': _eventPayment,
        'eventFee': _eventFee,
        'maxParticipants': _maxParticipants,
        'organizerName': _organizerName,
        'organizerContact': _organizerContact,
        'organizerEmail': _organizerEmail,
        'eventImage': _imageUrl ?? '',
        'hostedBy': _auth.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'hostedEvents': FieldValue.arrayUnion([response.id]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event Created Successfully!')),
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
              // Event Name
              TextFormField(
                onSaved: (value) => _eventName = value!,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().length < 3)
                    ? 'Enter a valid event name'
                    : null,
              ),
              const SizedBox(height: 20),

              // Event Description
              TextFormField(
                onSaved: (value) => _eventDescription = value!,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Event Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().length < 10)
                        ? 'Enter a valid event description'
                        : null,
              ),
              const SizedBox(height: 20),

              // Event Type Dropdown
              DropdownButtonFormField<String>(
                value: _eventType,
                onChanged: (value) => setState(() => _eventType = value!),
                items: const [
                  DropdownMenuItem(
                      value: 'Technical', child: Text('Technical')),
                  DropdownMenuItem(
                      value: 'Non-Technical', child: Text('Non-Technical')),
                  DropdownMenuItem(value: 'Cultural', child: Text('Cultural')),
                  DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Event Location
              TextFormField(
                onSaved: (value) => _eventLocation = value!,
                decoration: const InputDecoration(
                  labelText: 'Event Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter event location'
                    : null,
              ),
              const SizedBox(height: 20),

              // Event Date
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  labelText: 'Event Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Select event date'
                    : null,
              ),
              const SizedBox(height: 20),

              // Event Time
              TextFormField(
                controller: _timeController,
                readOnly: true,
                onTap: _selectTime,
                decoration: const InputDecoration(
                  labelText: 'Event Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Select event time'
                    : null,
              ),
              const SizedBox(height: 20),

              // Event Payment Type
              DropdownButtonFormField<String>(
                value: _eventPayment,
                onChanged: (value) {
                  setState(() {
                    _eventPayment = value!;
                    if (value == 'Unpaid') {
                      _eventFee = 0;
                    }
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'Unpaid', child: Text('Free Entry')),
                  DropdownMenuItem(value: 'Paid', child: Text('Paid Entry')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Event Payment Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Event Fee (only if paid)
              if (_eventPayment == 'Paid')
                TextFormField(
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _eventFee = int.tryParse(value!) ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Entry Fee (₹)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter entry fee';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Enter a valid fee amount';
                    }
                    return null;
                  },
                ),
              if (_eventPayment == 'Paid') const SizedBox(height: 20),

              // Max Participants
              TextFormField(
                initialValue: _maxParticipants.toString(),
                keyboardType: TextInputType.number,
                onSaved: (value) =>
                    _maxParticipants = int.tryParse(value!) ?? 100,
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

              // Event Image Upload
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event Banner Image',
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
                        onPressed: _createEvent,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Create Event',
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
