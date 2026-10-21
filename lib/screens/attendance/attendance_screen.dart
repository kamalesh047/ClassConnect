import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../data/student_list.dart' show checkIsAdmin; // Reuse function
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view attendance")),
      );
    }

    // Check if Admin
    final bool isAdmin = checkIsAdmin(user.email);
    final db = DatabaseService(uid: user.uid);

    if (isAdmin) {
      return _AdminAttendanceView(db: db);
    }

    return _StudentAttendanceView(db: db);
  }
}

// --- STUDENT VIEW ---
class _StudentAttendanceView extends StatelessWidget {
  final DatabaseService db;
  const _StudentAttendanceView({required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Attendance Predictor',
            onPressed: () => _showCalculator(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.attendance,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final attendanceList = snapshot.data ?? [];
          if (attendanceList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No records found',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Calculate overall
          int totalClassesAll = 0;
          int attendedClassesAll = 0;
          for (var item in attendanceList) {
            totalClassesAll += (item['totalClasses'] as int? ?? 0);
            attendedClassesAll += (item['attendedClasses'] as int? ?? 0);
          }
          double overallPercentage = totalClassesAll > 0
              ? (attendedClassesAll / totalClassesAll * 100)
              : 0.0;

          return AnimationLimiter(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildOverallCard(overallPercentage)),
                SliverToBoxAdapter(
                  child: _buildInsightCard(attendedClassesAll, totalClassesAll),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      'Subject-wise Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = attendanceList[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        child: SlideAnimation(
                          horizontalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildSubjectCard(item),
                          ),
                        ),
                      );
                    }, childCount: attendanceList.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(int attended, int total) {
    String insightText = "";
    Color insightColor = Colors.grey;
    IconData insightIcon = Icons.info_outline;

    if (total == 0) return const SizedBox.shrink();

    double current = (attended / total) * 100;

    if (current >= 75) {
      // How many can I miss?
      // (attended) / (total + x) = 0.75  => attended = 0.75 * (total + x) => x = (attended / 0.75) - total
      int canMiss = ((attended / 0.75) - total).floor();
      insightText = canMiss > 0
          ? "Safe Zone: You can skip up to $canMiss more classes and stay above 75%."
          : "Caution: You are right at the 75% limit. Don't miss the next class!";
      insightColor = Colors.green.shade700;
      insightIcon = Icons.verified_user_rounded;
    } else {
      // How many must I attend?
      // (attended + x) / (total + x) = 0.75 => attended + x = 0.75 * total + 0.75 * x => 0.25 * x = 0.75 * total - attended
      int mustAttend = ((0.75 * total - attended) / 0.25).ceil();
      insightText =
          "Goal: You need to attend $mustAttend more classes consecutively to reach 75%.";
      insightColor = Colors.orange.shade800;
      insightIcon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insightColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: insightColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(insightIcon, color: insightColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insightText,
              style: TextStyle(
                color: insightColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallCard(double percentage) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Total Score',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  percentage >= 75 ? '👍 Looking Great!' : '⚠️ Below Threshold',
                  style: TextStyle(
                    color: percentage >= 75
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.white12,
                  color: Colors.white,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                ),
              ),
              const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> data) {
    final name = data['subject'] ?? 'Unknown';
    final total = data['totalClasses'] ?? 0;
    final attended = data['attendedClasses'] ?? 0;
    final percentage = total > 0 ? (attended / total * 100) : 0.0;
    final isLow = percentage < 75;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attended: $attended / $total',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLow ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isLow
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: total > 0 ? attended / total : 0,
                minHeight: 10,
                backgroundColor: Colors.grey.shade100,
                color: isLow ? Colors.red.shade400 : Colors.green.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCalculator(BuildContext context) {
    final attendedController = TextEditingController();
    final totalController = TextEditingController();
    final targetController = TextEditingController(text: '75');

    // These need to be mutable for the closure, OR use ValueNotifier.
    // Simplifying by using a stateful widget approach via StatefulBuilder.
    // However, variables must be outside the builder to persist.
    // EXCEPT: TextControllers are already persistent.
    // Result string needs state.

    String result = '';
    Color resultColor = Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void calculate() {
              final attended = int.tryParse(attendedController.text);
              final total = int.tryParse(totalController.text);
              final targetVal = double.tryParse(targetController.text);

              if (attended == null ||
                  total == null ||
                  targetVal == null ||
                  total == 0) {
                setState(() {
                  result = "Please enter valid numbers.";
                  resultColor = Colors.orange;
                });
                return;
              }

              final target = targetVal / 100.0;
              final current = attended / total;

              if (current < target) {
                // (A + x) / (T + x) >= P
                // x >= (P*T - A) / (1 - P)
                double x = (target * total - attended) / (1 - target);
                int required = x.ceil();

                setState(() {
                  result =
                      "Attend next $required classes to reach ${targetVal.toStringAsFixed(0)}% 📚";
                  resultColor = Colors.red;
                });
              } else {
                // A / (T + y) >= P
                // y <= (A/P) - T
                double y = (attended / target) - total;
                int bunkable = y.floor();

                setState(() {
                  result =
                      "You can bunk $bunkable classes and stay above ${targetVal.toStringAsFixed(0)}% 🥳";
                  resultColor = Colors.green;
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.calculate, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Bunk Manager'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Calculate how many classes you can skip or need to attend.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: attendedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Attended Classes',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Classes',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target %',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (result.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: resultColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        result,
                        style: TextStyle(
                          color: resultColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Calculate'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// --- ADMIN VIEW ---
class _AdminAttendanceView extends StatefulWidget {
  final DatabaseService db;
  const _AdminAttendanceView({required this.db});

  @override
  State<_AdminAttendanceView> createState() => _AdminAttendanceViewState();
}

class _AdminAttendanceViewState extends State<_AdminAttendanceView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Manage Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by student name or register no...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: widget.db.allStudents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var students = snapshot.data ?? [];
          if (_searchQuery.isNotEmpty) {
            students = students
                .where(
                  (s) =>
                      s.name.toLowerCase().contains(_searchQuery) ||
                      s.registerNumber.toLowerCase().contains(_searchQuery),
                )
                .toList();
          }

          if (students.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? "No students registered yet."
                    : "No matching students found.",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      student.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    student.registerNumber,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _AdminEditStudentAttendance(
                          student: student,
                          adminDb: widget.db,
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _showBulkUpdateDialog(context, student),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showBulkUpdateDialog(BuildContext context, UserModel student) {
    // This allows admin to update multiple subjects at once via a simple text format
    // Format: Subject1:Attended/Total, Subject2:Attended/Total
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Update: ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Format: Subject:Attended/Total\nExample: Maths:10/12, Physics:8/10',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter data here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              final parts = text.split(',');
              for (var part in parts) {
                final subParts = part.trim().split(':');
                if (subParts.length == 2) {
                  final subject = subParts[0].trim();
                  final valParts = subParts[1].trim().split('/');
                  if (valParts.length == 2) {
                    final att = int.tryParse(valParts[0].trim()) ?? 0;
                    final tot = int.tryParse(valParts[1].trim()) ?? 0;
                    await widget.db.updateStudentAttendance(
                      student.uid,
                      subject,
                      att,
                      tot,
                    );
                  }
                }
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Attendance updated successfully!'),
                  ),
                );
              }
            },
            child: const Text('Update All'),
          ),
        ],
      ),
    );
  }
}

class _AdminEditStudentAttendance extends StatelessWidget {
  final UserModel student;
  final DatabaseService adminDb;

  const _AdminEditStudentAttendance({
    required this.student,
    required this.adminDb,
  });

  @override
  Widget build(BuildContext context) {
    // We need a new db instance pointing to THE STUDENT'S uid
    final studentDb = DatabaseService(uid: student.uid);

    return Scaffold(
      appBar: AppBar(title: Text('Editing: ${student.name}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectDialog(context, adminDb, student.uid),
        label: const Text('Add Subject'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: studentDb.attendance, // Stream specific student's attendance
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final attendanceList = snapshot.data ?? [];
          // If empty, offer to initialize? (Student might not have logged in yet to trigger init)
          // But saveUserData in AuthService handles it.
          // If manually created, maybe missing?

          if (attendanceList.isEmpty) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  await studentDb.saveUserData(student); // force init
                },
                child: const Text("Initialize Default Subjects"),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 80, // Space for FAB
            ),
            itemCount: attendanceList.length,
            itemBuilder: (context, index) {
              final subjectData = attendanceList[index];
              final total = subjectData['totalClasses'] ?? 0;
              final attended = subjectData['attendedClasses'] ?? 0;
              final percentage = total > 0 ? (attended / total * 100) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  title: Text(
                    subjectData['subject'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Attended: $attended / $total (${percentage.toStringAsFixed(0)}%)',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.indigo,
                      ),
                      onPressed: () => _showEditDialog(
                        context,
                        subjectData,
                        adminDb,
                        student.uid,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSubjectDialog(
    BuildContext context,
    DatabaseService db,
    String studentUid,
  ) {
    final subjectCtrl = TextEditingController();
    final attendedCtrl = TextEditingController(text: '0');
    final totalCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: attendedCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Classes Attended'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: totalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Classes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (subjectCtrl.text.trim().isEmpty) return;

              final att = int.tryParse(attendedCtrl.text) ?? 0;
              final tot = int.tryParse(totalCtrl.text) ?? 0;

              await db.updateStudentAttendance(
                studentUid,
                subjectCtrl.text.trim(),
                att,
                tot,
              );

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    Map<String, dynamic> data,
    DatabaseService db,
    String studentUid,
  ) {
    final attendedCtrl = TextEditingController(
      text: data['attendedClasses'].toString(),
    );
    final totalCtrl = TextEditingController(
      text: data['totalClasses'].toString(),
    );
    final subject = data['subject'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Icon(
              Icons.edit_calendar_rounded,
              color: Colors.indigo,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Update $subject',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Specify the number of classes attended and total held.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: attendedCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Classes Attended',
                prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total Classes Held',
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                final att = int.tryParse(attendedCtrl.text) ?? 0;
                final tot = int.tryParse(totalCtrl.text) ?? 0;

                await db.updateStudentAttendance(studentUid, subject, att, tot);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Attendance for $subject updated!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.indigo,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ),
        ],
      ),
    );
  }
}
