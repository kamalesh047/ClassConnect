import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/timetable_model.dart';
import '../../services/timetable_service.dart';
import '../../data/student_list.dart' show checkIsAdmin;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../services/storage_service.dart';
import 'package:file_picker/file_picker.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TimetableService _timetableService = TimetableService();
  String _selectedDay = DateFormat('EEEE').format(DateTime.now());
  bool _showImage = false;
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    if (!_days.contains(_selectedDay)) {
      _selectedDay = 'Monday'; // Default to Monday if today is Sunday
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final bool isAdmin = checkIsAdmin(user?.email);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Timetable'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showImage ? Icons.list_alt_rounded : Icons.image_rounded,
            ),
            tooltip: _showImage ? 'View List' : 'View Photo',
            onPressed: () => setState(() => _showImage = !_showImage),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings_overscan_rounded),
              tooltip: 'Update Timetable Photo',
              onPressed: () => _showUpdatePhotoDialog(context),
            ),
        ],
      ),
      body: _showImage
          ? _buildTimetablePhoto(isAdmin)
          : Column(
              children: [
                // Day Selector
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    itemBuilder: (context, index) {
                      final day = _days[index];
                      final isSelected = day == _selectedDay;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 8.0,
                        ),
                        child: ChoiceChip(
                          label: Text(day.substring(0, 3)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedDay = day;
                              });
                            }
                          },
                          color: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.deepPurple;
                            }
                            return Colors.white;
                          }),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: StreamBuilder<List<ClassSession>>(
                    stream: _timetableService.getClassesForDay(_selectedDay),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading timetable'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final classes = snapshot.data ?? [];

                      if (classes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No classes on $_selectedDay',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return AnimationLimiter(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: classes.length,
                          itemBuilder: (context, index) {
                            final session = classes[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 600),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                session.startTime,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                session.endTime,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            width: 4,
                                            height: 50,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  session.subject,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Room: ${session.room} • ${session.teacher}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isAdmin)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed: () => _timetableService
                                                  .deleteClassSession(
                                                    session.id,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddClassDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddClassDialog(BuildContext context) {
    final subjectController = TextEditingController();
    final teacherController = TextEditingController();
    final roomController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    String day = _selectedDay;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add Class'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  TextField(
                    controller: teacherController,
                    decoration: const InputDecoration(labelText: 'Teacher'),
                  ),
                  TextField(
                    controller: roomController,
                    decoration: const InputDecoration(labelText: 'Room'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (picked != null) {
                              setState(() => startTime = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(startTime.format(context)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (picked != null) {
                              setState(() => endTime = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(endTime.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Day'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: day,
                        isDense: true,
                        items: _days
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => day = val!),
                      ),
                    ),
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
                onPressed: () {
                  if (subjectController.text.isNotEmpty) {
                    // Format time manually to ensure sorting works if desired,
                    // or just use 24h format for storage and display format(context) for UI.
                    // For simplicity, sticking to HH:mm string format for storage
                    // to ensure orderBy works correctly.
                    final startStr =
                        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                    final endStr =
                        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                    final session = ClassSession(
                      id: '',
                      subject: subjectController.text,
                      teacher: teacherController.text,
                      room: roomController.text,
                      startTime: startStr,
                      endTime: endStr,
                      day: day,
                    );
                    _timetableService.addClassSession(session);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimetablePhoto(bool isAdmin) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('timetable_photo')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No timetable photo uploaded yet.',
                  style: TextStyle(color: Colors.grey),
                ),
                if (isAdmin)
                  ElevatedButton(
                    onPressed: () => _showUpdatePhotoDialog(context),
                    child: const Text('Upload Now'),
                  ),
              ],
            ),
          );
        }

        final url = (snapshot.data!.data() as Map<String, dynamic>)['url'];

        return InteractiveViewer(
          child: Center(
            child: Image.network(
              url,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        );
      },
    );
  }

  void _showUpdatePhotoDialog(BuildContext context) {
    final urlController = TextEditingController();
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Timetable Photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 20),
              const Text('OR', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (result != null) {
                            setDialogState(() => isUploading = true);
                            try {
                              final url = await StorageService().uploadFile(
                                file: result.files.first,
                                path:
                                    'timetable/photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
                              );
                              if (url != null) {
                                await FirebaseFirestore.instance
                                    .collection('settings')
                                    .doc('timetable_photo')
                                    .set({'url': url});
                                if (context.mounted) Navigator.pop(context);
                              }
                            } catch (e) {
                              debugPrint('Error uploading: $e');
                            } finally {
                              setDialogState(() => isUploading = false);
                            }
                          }
                        },
                  icon: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library_rounded),
                  label: Text(isUploading ? 'Uploading...' : 'Upload Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (!isUploading)
              ElevatedButton(
                onPressed: () async {
                  if (urlController.text.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('settings')
                        .doc('timetable_photo')
                        .set({'url': urlController.text.trim()});
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Save URL'),
              ),
          ],
        ),
      ),
    );
  }
}
