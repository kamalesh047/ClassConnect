// This file acts as the "Master Record" of your class.
// You (the Admin) should add all 60 students here.

const String adminEmail = 'kamalesh.240060@aiml.ritchennai.edu.in';
bool checkIsAdmin(String? email) {
  if (email == null) return false;
  final e = email.toLowerCase().trim();
  return e == adminEmail.toLowerCase();
}

final List<Map<String, String>> classStudentList = [
  {
    'regNo': '2117240030060',
    'name': 'Kamalesh', // Updated name to match new admin
    'email': 'kamalesh.240060@aiml.ritchennai.edu.in',
  },
  {
    'regNo': '2117240030060',
    'name': 'kamalesh',
    'email': 'kamalesh240060@aiml.ritchennai.edu.in', // Replace with real Gmail
  },
  {
    'regNo': '2117240030063',
    'name': 'kathiravan',
    'email': 'kamaleshsaravanan2007.n@gmail.com',
  },
  {
    'regNo': '2117240030077',
    'name': 'madhusudhanan',
    'email': 'madusudanan.240077@aiml.ritchennai.edu.in',
  },
  {
    'regNo': '2117240030069',
    'name': 'Sneha Gupta',
    'email': 'sneha.gupta@gmail.com',
  },
  {
    'regNo': '2117240030064',
    'name': 'Mohamed Ali',
    'email': 'mohamed.ali@gmail.com',
  },
  // ... Add all 60 students here
];
