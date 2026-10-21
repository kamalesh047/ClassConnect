import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
// import 'package:file_picker/file_picker.dart'; // Disabled
// import '../../services/storage_service.dart'; // Disabled

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isUploading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'PDF',
    'Images',
    'Docs',
    'PPT',
    'Link',
  ];

  Future<void> _addNoteFromLink(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<User?>();
    if (user == null) return;

    final metadata = await _showAddLinkDialog(context);
    if (metadata == null) return;

    setState(() => _isUploading = true);

    try {
      final db = DatabaseService(uid: user.uid);
      await db.addNote(
        metadata['title'] ?? 'Untitled',
        metadata['description'] ?? '',
        metadata['url'] ?? '',
        metadata['type'] ?? 'Link',
        user.displayName ?? 'Student',
        'Link', // Size placeholder
      );

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Resource link added to library!')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to add link: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<Map<String, String>?> _showAddLinkDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'Link';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Resource Link'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: linkCtrl,
                decoration: InputDecoration(
                  labelText: 'URL (Drive, Dropbox, Website)',
                  hintText: 'https://...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                items: ['PDF', 'Images', 'Docs', 'PPT', 'Link']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => selectedType = val!,
                decoration: InputDecoration(
                  labelText: 'Resource Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
              if (titleCtrl.text.isNotEmpty && linkCtrl.text.isNotEmpty) {
                Navigator.pop(context, {
                  'title': titleCtrl.text,
                  'url': linkCtrl.text,
                  'type': selectedType,
                  'description': descCtrl.text,
                });
              }
            },
            child: const Text('Add Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final db = DatabaseService(uid: user?.uid);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildCategoryBar(),
          _buildNotesGrid(db, user?.uid),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : () => _addNoteFromLink(context),
        backgroundColor: Colors.deepPurple,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.link_rounded, color: Colors.white),
        label: Text(
          _isUploading ? 'Saving...' : 'Add Link',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.deepPurple,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 60),
        title: const Text(
          'Note Vault',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            onChanged: (val) =>
                setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search notes, files...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) => setState(() => _selectedCategory = cat),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.deepPurple;
                  }
                  return Colors.white;
                }),
                elevation: 2,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotesGrid(DatabaseService? db, String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: db?.notes,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        var docs = snapshot.data!.docs;

        // Filter by search and category
        var filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final titleMatch =
              data['title']?.toString().toLowerCase().contains(_searchQuery) ??
              false;
          final categoryMatch =
              _selectedCategory == 'All' || data['type'] == _selectedCategory;
          return titleMatch && categoryMatch;
        }).toList();

        if (filtered.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                'No notes found in this vault.',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _NoteCard(doc: filtered[index], db: db!, userId: userId),
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final DatabaseService db;
  final String? userId;

  const _NoteCard({required this.doc, required this.db, this.userId});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final type = data['type'] ?? 'Other';
    final url = data['fileUrl'] ?? '';
    final likes = (data['likes'] as List?)?.length ?? 0;
    final isLiked = (data['likes'] as List?)?.contains(userId) ?? false;
    final views = data['views'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                db.incrementNoteView(doc.id);
                _openFile(url);
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getBgColor(type),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Icon(_getIcon(type), size: 40, color: _getColor(type)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Untitled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      data['fileSize'] ?? '0 MB',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.visibility_outlined,
                      size: 10,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$views',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => db.toggleLikeNote(doc.id, userId!),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likes',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_vert,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'Images':
        return Icons.image_rounded;
      case 'Docs':
        return Icons.description_rounded;
      case 'PPT':
        return Icons.slideshow_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'PDF':
        return Colors.red.shade700;
      case 'Images':
        return Colors.blue.shade700;
      case 'Docs':
        return Colors.indigo.shade700;
      case 'PPT':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getBgColor(String type) {
    return _getColor(type).withValues(alpha: 0.1);
  }
}
