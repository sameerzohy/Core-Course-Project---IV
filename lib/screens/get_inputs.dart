import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:students_connect/screens/nav_bar.dart';
// import 'package:students_connect/screens/home.dart';
// import 'package:students_connect/widgets/get_college_details.dart';
import 'package:unstop_clone/screens/home_screen.dart';

class GetInputs extends StatefulWidget {
  const GetInputs({super.key});

  @override
  _GetInputsState createState() => _GetInputsState();
}

class _GetInputsState extends State<GetInputs> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _studentDetailsFormKey = GlobalKey<FormState>();
  final _collegeDetailsFormKey = GlobalKey<FormState>();

  String studentName = '';
  DateTime? dateOfBirth;
  String collegeName = '';
  String selectedDepartment = 'CSBS';
  String rollNo = '';
  final List<String> departments = [
    'CSBS',
    'CZ',
    'CSE',
    'IT',
    'AIML',
    'AIDS',
    'EEE',
    'ECE',
    'ACT',
    'VLSI',
    'BME',
    'MECH',
    'CIVIL',
    'MCT',
  ];

  int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _nextPage() {
    // print(_currentPage);
    // print(_studentDetailsFormKey.currentState!.validate());
    if (_currentPage == 0 && _studentDetailsFormKey.currentState!.validate()) {
      // _studentDetailsFormKey.currentState!.save();
      print(true);
      saveStudentDetails();
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else if (_currentPage == 1 &&
        _collegeDetailsFormKey.currentState!.validate()) {
      _collegeDetailsFormKey.currentState!.save();
      saveCollegeDetails();
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != dateOfBirth) {
      setState(() {
        dateOfBirth = picked;
      });
    }
  }

  void saveStudentDetails() async {
    if (_studentDetailsFormKey.currentState!.validate()) {
      _studentDetailsFormKey.currentState!.save();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({});
    }
  }

  void saveCollegeDetails() async {
    if (collegeName.isEmpty) {
      // Handle the error, e.g., show a message to the user
      print('College name cannot be empty');
      return;
    }
    if (rollNo.isEmpty) {
      print('Roll number cannot be empty');
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'collegeName': collegeName,
        'department': selectedDepartment,
        'rollNo': rollNo,
        'name': studentName,
        'dateOfBirth': dateOfBirth,
        'email': FirebaseAuth.instance.currentUser!.email
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Get User Information')),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildStudentDetailsPage(),
          _buildCollegeDetailsPage(),
          _buildSummaryPage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_currentPage > 0)
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 2.0),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _previousPage,
                ),
              ),
            const Spacer(),
            if (_currentPage < 2)
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 2.0),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _nextPage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentDetailsPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
        child: Form(
          key: _studentDetailsFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Enter your Details'),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.blue, width: 1.0),
                  ),
                ),
                onSaved: (value) => studentName = value!,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.blue, width: 1.0),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                controller: TextEditingController(
                  text: dateOfBirth == null
                      ? ''
                      : '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}',
                ),
                validator: (value) {
                  if (dateOfBirth == null) {
                    return 'Please select your date of birth';
                  }
                  int age = calculateAge(dateOfBirth!);
                  if (age < 17) {
                    return 'You must be 17 years or older';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollegeDetailsPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _collegeDetailsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'College Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.blue, width: 1.0),
                  ),
                ),
                initialValue: 'Chennai Institute of Technology',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your college name';
                  }
                  return null;
                },
                onSaved: (value) => collegeName = value!,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.blue, width: 1.0),
                  ),
                ),
                value: selectedDepartment,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedDepartment = newValue!;
                  });
                },
                items:
                    departments.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your department';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Roll Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.blue, width: 1.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your roll number';
                  }
                  return null;
                },
                onSaved: (value) => rollNo = value!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('That\'s all folks!'),
            SizedBox(height: 16),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(),
                    ),
                  );
                },
                child: Text('Get Started')),
            // Add summary details here
          ],
        ),
      ),
    );
  }
}
