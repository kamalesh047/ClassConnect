import 'package:flutter/material.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../data/student_list.dart' show checkIsAdmin;

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen>
    with SingleTickerProviderStateMixin {
  final AssignmentService _service = AssignmentService();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final bool isAdmin = checkIsAdmin(user?.email);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Assignment Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Implementation of search popup or expansion
              _showSearchDialog(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: StreamBuilder<List<Assignment>>(
        stream: _service.assignments,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;

          // --- SMART SORTING ---
          all.sort((a, b) {
            // First by priority: Urgent (0) > Medium (1) > Low (2)
            int pA = a.priority == 'Urgent'
                ? 0
                : (a.priority == 'Medium' ? 1 : 2);
            int pB = b.priority == 'Urgent'
                ? 0
                : (b.priority == 'Medium' ? 1 : 2);
            if (pA != pB) return pA.compareTo(pB);
            // Then by due date
            return a.dueDate.compareTo(b.dueDate);
          });

          final filtered = all
              .where(
                (a) =>
                    a.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    a.subject.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

          final pending = filtered.where((a) => !a.isCompleted).toList();
          final completed = filtered.where((a) => a.isCompleted).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(pending, false, isAdmin),
              _buildList(completed, true, isAdmin),
            ],
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              backgroundColor: Colors.deepPurple,
              label: const Text(
                'Assign Tasks',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildList(List<Assignment> items, bool isCompleted, bool isAdmin) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.done_all_rounded : Icons.assignment_rounded,
              size: 80,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted
                  ? 'No completed tasks yet'
                  : 'Everything is on track!',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _AssignmentProCard(
          item: item,
          service: _service,
          isAdmin: isAdmin,
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    String priority = 'Medium';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Post New Assignment',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                    labelText: 'Subject/Module',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: InputDecoration(
                    labelText: 'Priority Level',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Urgent', 'Medium', 'Low']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => priority = val!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Deadline'),
                  subtitle: Text(
                    DateFormat('EEE, MMM dd').format(selectedDate),
                  ),
                  trailing: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.deepPurple,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  _service.addAssignment(
                    Assignment(
                      id: '',
                      title: titleCtrl.text,
                      description: '',
                      subject: subjectCtrl.text,
                      dueDate: selectedDate,
                      priority: priority,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Release Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController(text: _searchQuery);
        return AlertDialog(
          title: const Text('Search Assignments'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by title or subject...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}

class _AssignmentProCard extends StatelessWidget {
  final Assignment item;
  final AssignmentService service;
  final bool isAdmin;

  const _AssignmentProCard({
    required this.item,
    required this.service,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = item.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0 && !item.isCompleted;

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: _getPriorityColor(item.priority)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: item.isCompleted,
                            activeColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (_) => service.toggleCompletion(
                              item.id,
                              item.isCompleted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        item.subject,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: isOverdue ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOverdue
                                ? 'Overdue!'
                                : (daysLeft == 0
                                      ? 'Due Today'
                                      : '$daysLeft days left'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOverdue
                                  ? Colors.red
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const Spacer(),
                          _PriorityBadge(priority: item.priority),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!item.isCompleted)
                _ActionButton(
                  icon: Icons.edit_calendar_rounded,
                  color: Colors.blue,
                  onTap: () => _editDate(context),
                ),
              if (isAdmin)
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red,
                  onTap: () => service.deleteAssignment(item.id),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _editDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: item.dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2030),
    );
    if (picked != null) service.updateDueDate(item.id, picked);
  }

  Color _getPriorityColor(String p) {
    if (p == 'Urgent') return Colors.red;
    if (p == 'Medium') return Colors.orange;
    return Colors.blue;
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.blue;
    if (priority == 'Urgent') color = Colors.red;
    if (priority == 'Medium') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 50,
        alignment: Alignment.center,
        color: color.withValues(alpha: 0.05),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
