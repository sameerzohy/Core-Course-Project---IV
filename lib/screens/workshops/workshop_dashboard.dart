import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkshopDashBoard extends StatefulWidget {
  const WorkshopDashBoard({super.key, required this.workshopId});

  final String workshopId;

  @override
  State<WorkshopDashBoard> createState() => _WorkshopDashBoardState();
}

class _WorkshopDashBoardState extends State<WorkshopDashBoard> {
  void switchScreen(index) {
    setState(() {
      _currentIndex = index;
    });
  }

  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      WorkshopDetailsScreen(workshopId: widget.workshopId),
      WorkshopUpdateScreen(
          workshopId: widget.workshopId, switchScreen: switchScreen),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Workshop Dashboard'),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          switchScreen(index);
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.details), label: 'Details'),
          BottomNavigationBarItem(icon: Icon(Icons.update), label: 'Update'),
        ],
      ),
    );
  }
}

class WorkshopDetailsScreen extends StatefulWidget {
  const WorkshopDetailsScreen({super.key, required this.workshopId});

  final String workshopId;

  @override
  State<WorkshopDetailsScreen> createState() => _WorkshopDetailsScreenState();
}

class _WorkshopDetailsScreenState extends State<WorkshopDetailsScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final user = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .get();

  Future<Map<String, dynamic>?> getWorkshopDetails(String workshopId) async {
    try {
      var response = await FirebaseFirestore.instance
          .collection('workshops')
          .doc(workshopId)
          .get();
      return response.data();
    } catch (e) {
      debugPrint("Error fetching workshop details: $e");
      return null;
    }
  }

  bool registeredStatus(workshopDetails) {
    return !workshopDetails.containsKey('participants') ||
        !workshopDetails['participants'].contains(userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getWorkshopDetails(widget.workshopId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Workshop details not found."));
        }

        var workshopDetails = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Workshop Banner Image
              workshopDetails['workshopImage'] != null
                  ? Image.network(
                      workshopDetails['workshopImage'],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(child: Text('No Image Available')),
                    ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workshop Name
                    Text(
                      workshopDetails['workshopTitle'] ?? 'Unnamed Workshop',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    // Workshop Description
                    Text(
                      workshopDetails['workshopDescription'] ??
                          'No description available.',
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 20),

                    // Workshop Date
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Date: ${workshopDetails['startDate'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Workshop Time
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Time: ${workshopDetails['startTime'] ?? 'Unknown'} - ${workshopDetails['endTime'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Workshop Mode
                    Row(
                      children: [
                        const Icon(Icons.laptop, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Mode: ${workshopDetails['workshopMode'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Location for offline/hybrid workshops
                    if (workshopDetails['workshopMode'] != 'Online')
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Venue: ${workshopDetails['venue'] ?? 'Location not specified'}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Workshop Fee
                    Row(
                      children: [
                        const Icon(Icons.money, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          workshopDetails['isPaid'] == false
                              ? "Free Workshop"
                              : "Fee: ₹${workshopDetails['registrationFee']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Certification Status
                    Row(
                      children: [
                        const Icon(Icons.card_membership, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Certification: ${workshopDetails['provideCertification'] == true ? 'Yes' : 'No'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Organizer Details
                    const Divider(thickness: 1),
                    const SizedBox(height: 10),
                    const Text(
                      "Organizer Information",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.person, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Name: ${workshopDetails['organizerName'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.email, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Email: ${workshopDetails['organizerEmail'] ?? 'Not available'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.phone, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Contact: ${workshopDetails['organizerContact'] ?? 'Not available'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Registration Capacity & Available Slots
                    const Text(
                      "Registration Information",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.group, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Maximum Capacity: ${workshopDetails['maxParticipants'] ?? 'Unlimited'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.people, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Available slots: ${workshopDetails.containsKey('participants') ? workshopDetails['maxParticipants'] - workshopDetails['participants'].length ?? 'N/A' : workshopDetails['maxCapacity']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Registered Members
                    const Divider(thickness: 1),
                    Container(
                      margin: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Registered Participants",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount:
                                workshopDetails.containsKey('participants')
                                    ? workshopDetails['participants'].length
                                    : 0,
                            itemBuilder: (context, index) {
                              return FutureBuilder<Map<String, dynamic>>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(workshopDetails['participants'][index])
                                    .get()
                                    .then((snapshot) => snapshot.data()
                                        as Map<String, dynamic>),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Text("Error: ${snapshot.error}");
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data == null) {
                                    return Text("No Data Found");
                                  }

                                  // Extract user data
                                  Map<String, dynamic> userData =
                                      snapshot.data!;

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Text(
                                        "${index + 1}) ${userData['name']}"),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WorkshopUpdateScreen extends StatefulWidget {
  const WorkshopUpdateScreen({
    super.key,
    required this.workshopId,
    required this.switchScreen,
  });

  final String workshopId;
  final void Function(int index) switchScreen;

  @override
  State<WorkshopUpdateScreen> createState() => _WorkshopUpdateScreenState();
}

class _WorkshopUpdateScreenState extends State<WorkshopUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  Map<String, dynamic>? workshopData;

  // Controllers
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _workshopNameController = TextEditingController();
  final TextEditingController _workshopDescriptionController =
      TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _organizerNameController =
      TextEditingController();
  final TextEditingController _organizerContactController =
      TextEditingController();
  final TextEditingController _organizerEmailController =
      TextEditingController();
  final TextEditingController _registrationFeeController =
      TextEditingController();
  final TextEditingController _maxCapacityController = TextEditingController();

  String _workshopMode = 'Online';
  bool _provideCertification = true;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _loadWorkshopData();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _workshopNameController.dispose();
    _workshopDescriptionController.dispose();
    _venueController.dispose();
    _organizerNameController.dispose();
    _organizerContactController.dispose();
    _organizerEmailController.dispose();
    _registrationFeeController.dispose();
    _maxCapacityController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkshopData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot =
          await _firestore.collection('workshops').doc(widget.workshopId).get();

      if (docSnapshot.exists) {
        workshopData = docSnapshot.data();

        // Set controllers with existing data
        _workshopNameController.text = workshopData?['workshopName'] ?? '';
        _workshopDescriptionController.text =
            workshopData?['workshopDescription'] ?? '';
        _startDateController.text = workshopData?['startDate'] ?? '';
        _endDateController.text = workshopData?['endDate'] ?? '';
        _startTimeController.text = workshopData?['startTime'] ?? '';
        _endTimeController.text = workshopData?['endTime'] ?? '';
        _venueController.text = workshopData?['venue'] ?? '';
        _organizerNameController.text = workshopData?['organizerName'] ?? '';
        _organizerContactController.text =
            workshopData?['organizerContact'] ?? '';
        _organizerEmailController.text = workshopData?['organizerEmail'] ?? '';
        _registrationFeeController.text =
            workshopData?['registrationFee']?.toString() ?? '0';
        _maxCapacityController.text =
            workshopData?['maxCapacity']?.toString() ?? '';

        // Set dropdown and toggle values
        setState(() {
          _workshopMode = workshopData?['workshopMode'] ?? 'Online';
          _provideCertification = workshopData?['provideCertification'] ?? true;
          _isPaid = workshopData?['isPaid'] ?? false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading workshop data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  Future<void> _updateWorkshop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('workshops').doc(widget.workshopId).update({
        'workshopName': _workshopNameController.text,
        'workshopDescription': _workshopDescriptionController.text,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'startTime': _startTimeController.text,
        'endTime': _endTimeController.text,
        'venue': _venueController.text,
        'workshopMode': _workshopMode,
        'provideCertification': _provideCertification,
        'isPaid': _isPaid,
        'registrationFee':
            _isPaid ? int.parse(_registrationFeeController.text) : 0,
        'maxCapacity': int.parse(_maxCapacityController.text),
        'organizerName': _organizerNameController.text,
        'organizerContact': _organizerContactController.text,
        'organizerEmail': _organizerEmailController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workshop updated successfully!')),
      );

      // Switch back to details screen
      widget.switchScreen(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating workshop: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Workshop Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Workshop Name
            TextFormField(
              controller: _workshopNameController,
              decoration: const InputDecoration(
                labelText: 'Workshop Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter workshop name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Workshop Description
            TextFormField(
              controller: _workshopDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Workshop Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter workshop description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Workshop Dates
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _startDateController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select start date';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _endDateController),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Workshop Times
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(context, _startTimeController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select start time';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(context, _endTimeController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select end time';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Workshop Mode
            DropdownButtonFormField<String>(
              value: _workshopMode,
              decoration: const InputDecoration(
                labelText: 'Workshop Mode',
                border: OutlineInputBorder(),
              ),
              items: ['Online', 'Offline', 'Hybrid'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _workshopMode = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Venue (only for offline/hybrid)
            if (_workshopMode != 'Online')
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_workshopMode != 'Online' &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter venue for offline/hybrid workshop';
                  }
                  return null;
                },
              ),
            if (_workshopMode != 'Online') const SizedBox(height: 16),

            // Certification
            SwitchListTile(
              title: const Text('Provide Certification'),
              value: _provideCertification,
              onChanged: (value) {
                setState(() {
                  _provideCertification = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Registration Fee
            SwitchListTile(
              title: const Text('Paid Workshop'),
              value: _isPaid,
              onChanged: (value) {
                setState(() {
                  _isPaid = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            if (_isPaid)
              TextFormField(
                controller: _registrationFeeController,
                decoration: const InputDecoration(
                  labelText: 'Registration Fee (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_isPaid && (value == null || value.isEmpty)) {
                    return 'Please enter registration fee';
                  }
                  return null;
                },
              ),
            if (_isPaid) const SizedBox(height: 16),

            // Maximum Capacity
            TextFormField(
              controller: _maxCapacityController,
              decoration: const InputDecoration(
                labelText: 'Maximum Capacity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter maximum capacity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Organizer Info
            const Text(
              'Organizer Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _organizerNameController,
              decoration: const InputDecoration(
                labelText: 'Organizer Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter organizer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _organizerContactController,
              decoration: const InputDecoration(
                labelText: 'Organizer Contact',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter organizer contact';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _organizerEmailController,
              decoration: const InputDecoration(
                labelText: 'Organizer Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter organizer email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: _updateWorkshop,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'Update Workshop',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
