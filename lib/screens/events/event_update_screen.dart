import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class EventUpdateScreen extends StatefulWidget {
  final String eventId;
  final void Function(int index) switchScreen;
  // final int screenIndex;

  const EventUpdateScreen({
    super.key,
    required this.eventId,
    required this.switchScreen,
  });

  @override
  State<EventUpdateScreen> createState() => _EventUpdateScreenState();
}

class _EventUpdateScreenState extends State<EventUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();
  final TextEditingController _eventLocationController =
      TextEditingController();
  final TextEditingController _maxParticipantsController =
      TextEditingController();
  final TextEditingController _eventFeeController = TextEditingController();
  final TextEditingController _organizerNameController =
      TextEditingController();
  final TextEditingController _organizerContactController =
      TextEditingController();
  final TextEditingController _organizerEmailController =
      TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  String _eventType = 'Technical';
  String _eventPayment = 'Unpaid';

  File? _image;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _existingImageUrl;
  String? _newImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchEventData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _eventLocationController.dispose();
    _maxParticipantsController.dispose();
    _eventFeeController.dispose();
    _organizerNameController.dispose();
    _organizerContactController.dispose();
    _organizerEmailController.dispose();
    super.dispose();
  }

  Future<void> _fetchEventData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final eventDoc =
          await _firestore.collection('events').doc(widget.eventId).get();

      if (!eventDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event not found!')),
        );
        widget.switchScreen(0);
        return;
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;

      // Populate text controllers with existing data
      _eventNameController.text = eventData['eventName'] ?? '';
      _eventDescriptionController.text = eventData['eventDescription'] ?? '';
      _eventLocationController.text = eventData['eventLocation'] ?? '';
      _dateController.text = eventData['eventDate'] ?? '';
      _timeController.text = eventData['eventTime'] ?? '';
      _maxParticipantsController.text =
          (eventData['maxParticipants'] ?? 100).toString();
      _eventFeeController.text = (eventData['eventFee'] ?? 0).toString();
      _organizerNameController.text = eventData['organizerName'] ?? '';
      _organizerContactController.text = eventData['organizerContact'] ?? '';
      _organizerEmailController.text = eventData['organizerEmail'] ?? '';

      // Set dropdown values
      setState(() {
        _eventType = eventData['eventType'] ?? 'Technical';
        _eventPayment = eventData['eventPayment'] ?? 'Unpaid';
        _existingImageUrl = eventData['eventImage'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading event: $e')),
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

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_dateController.text)
          : DateTime.now(),
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
      initialTime: _timeController.text.isNotEmpty
          ? TimeOfDay.fromDateTime(
              DateFormat.jm().parse(_timeController.text),
            )
          : TimeOfDay.now(),
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

  Future<void> _updateEvent() async {
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

      // Update event document in Firestore
      await _firestore.collection('events').doc(widget.eventId).update({
        'eventName': _eventNameController.text,
        'eventDescription': _eventDescriptionController.text,
        'eventType': _eventType,
        'eventLocation': _eventLocationController.text,
        'eventDate': _dateController.text,
        'eventTime': _timeController.text,
        'eventPayment': _eventPayment,
        'eventFee': int.tryParse(_eventFeeController.text) ?? 0,
        'maxParticipants': int.tryParse(_maxParticipantsController.text) ?? 100,
        'organizerName': _organizerNameController.text,
        'organizerContact': _organizerContactController.text,
        'organizerEmail': _organizerEmailController.text,
        'eventImage': _newImageUrl ?? _existingImageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event Updated Successfully!')),
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
                'Update Event',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Event Name
              TextFormField(
                controller: _eventNameController,
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
                controller: _eventDescriptionController,
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
                controller: _eventLocationController,
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
                      _eventFeeController.text = '0';
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
                  controller: _eventFeeController,
                  keyboardType: TextInputType.number,
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
                controller: _maxParticipantsController,
                keyboardType: TextInputType.number,
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
                controller: _organizerNameController,
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
                controller: _organizerContactController,
                keyboardType: TextInputType.phone,
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
                controller: _organizerEmailController,
                keyboardType: TextInputType.emailAddress,
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
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            )
                          : _existingImageUrl != null &&
                                  _existingImageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _existingImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error,
                                                size: 50, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text('Error loading image',
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const Center(
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
                                ),
                    ),
                  ),
                  if (_image != null ||
                      (_existingImageUrl != null &&
                          _existingImageUrl!.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _image != null
                                  ? 'New image selected. Click Update Event to save changes.'
                                  : 'Using existing image. Tap above to change.',
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 12),
                            ),
                          ),
                        ],
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
                        onPressed: _updateEvent,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Update Event',
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
