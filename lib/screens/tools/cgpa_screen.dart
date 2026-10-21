import 'package:flutter/material.dart';

class CGPACalculatorScreen extends StatefulWidget {
  const CGPACalculatorScreen({super.key});

  @override
  State<CGPACalculatorScreen> createState() => _CGPACalculatorScreenState();
}

class _CGPACalculatorScreenState extends State<CGPACalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // GPA Calculation State
  final List<Map<String, dynamic>> _gpaCourses = [];
  double _calculatedGpa = 0.0;
  final _gpaCreditController = TextEditingController();
  String _gpaSelectedGrade = 'O (10)';

  // CGPA Calculation State
  final List<Map<String, dynamic>> _semesters = [];
  double _calculatedCgpa = 0.0;
  final _semGpaController = TextEditingController();
  final _semCreditController = TextEditingController();

  // Python/Anna Univ Regulation Grade Points
  final Map<String, int> _gradePoints = {
    'O (10)': 10,
    'A+ (9)': 9,
    'A (8)': 8,
    'B+ (7)': 7,
    'B (6)': 6,
    'C (5)': 5,
    'U (0)': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gpaCreditController.dispose();
    _semGpaController.dispose();
    _semCreditController.dispose();
    super.dispose();
  }

  // --- GPA Logic ---
  void _addGpaCourse() {
    if (_gpaCreditController.text.isEmpty) return;
    final int credit = int.tryParse(_gpaCreditController.text) ?? 0;
    if (credit <= 0) return;

    setState(() {
      _gpaCourses.add({
        'credit': credit,
        'grade': _gradePoints[_gpaSelectedGrade],
        'gradeLabel': _gpaSelectedGrade,
      });
      _calculateGpa();
      _gpaCreditController.clear();
    });
  }

  void _calculateGpa() {
    if (_gpaCourses.isEmpty) {
      _calculatedGpa = 0.0;
      return;
    }
    double totalPoints = 0;
    int totalCredits = 0;
    for (var course in _gpaCourses) {
      totalPoints += (course['credit'] as int) * (course['grade'] as int);
      totalCredits += (course['credit'] as int);
    }
    _calculatedGpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }

  // --- CGPA Logic ---
  void _addSemester() {
    final double gpa = double.tryParse(_semGpaController.text) ?? -1;
    final int credits = int.tryParse(_semCreditController.text) ?? 0;

    if (gpa < 0 || gpa > 10 || credits <= 0) return;

    setState(() {
      _semesters.add({'gpa': gpa, 'credits': credits});
      _calculateCgpa();
      _semGpaController.clear();
      _semCreditController.clear();
    });
  }

  void _calculateCgpa() {
    if (_semesters.isEmpty) {
      _calculatedCgpa = 0.0;
      return;
    }
    double totalPoints = 0;
    int totalCredits = 0;
    for (var sem in _semesters) {
      totalPoints += (sem['gpa'] as double) * (sem['credits'] as int);
      totalCredits += (sem['credits'] as int);
    }
    _calculatedCgpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Performance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'GPA (Semester)'),
            Tab(text: 'CGPA (Overall)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildGpaTab(), _buildCgpaTab()],
      ),
    );
  }

  Widget _buildGpaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildResultCard('Projected GPA', _calculatedGpa, Colors.deepPurple),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gpaCreditController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Course Credits',
                    hintText: 'e.g. 3 or 4',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Grade Obtained',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _gpaSelectedGrade,
                      isDense: true,
                      onChanged: (v) => setState(() => _gpaSelectedGrade = v!),
                      items: _gradePoints.keys.map((String grade) {
                        return DropdownMenuItem<String>(
                          value: grade,
                          child: Text(grade),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _addGpaCourse,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Added Courses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          if (_gpaCourses.isEmpty)
            const Text(
              'Add courses to calculate GPA',
              style: TextStyle(color: Colors.grey),
            ),
          ..._gpaCourses.asMap().entries.map((entry) {
            final index = entry.key;
            final c = entry.value;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.shade50,
                child: Text('${c['credit']}'),
              ),
              title: Text('Credits: ${c['credit']}'),
              subtitle: Text('Grade: ${c['gradeLabel']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() {
                  _gpaCourses.removeAt(index);
                  _calculateGpa();
                }),
              ),
            );
          }),
          if (_gpaCourses.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _gpaCourses.clear();
                _calculateGpa();
              }),
              child: const Text('Reset GPA'),
            ),
        ],
      ),
    );
  }

  Widget _buildCgpaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildResultCard('Cumulative CGPA', _calculatedCgpa, Colors.teal),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _semGpaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Semester GPA',
                    hintText: 'e.g. 8.5',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _semCreditController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Credits',
                    hintText: 'e.g. 24',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _addSemester,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Added Semesters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          if (_semesters.isEmpty)
            const Text(
              'Add semesters to calculate CGPA',
              style: TextStyle(color: Colors.grey),
            ),
          ..._semesters.asMap().entries.map((entry) {
            final index = entry.key;
            final sem = entry.value;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade50,
                child: Text('${index + 1}'),
              ),
              title: Text('Semester ${index + 1}'),
              subtitle: Text('GPA: ${sem['gpa']} | Credits: ${sem['credits']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.deepOrange),
                onPressed: () => setState(() {
                  _semesters.removeAt(index);
                  _calculateCgpa();
                }),
              ),
            );
          }),
          if (_semesters.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _semesters.clear();
                _calculateCgpa();
              }),
              child: const Text('Reset CGPA'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, double value, Color color) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value.toStringAsFixed(3),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
