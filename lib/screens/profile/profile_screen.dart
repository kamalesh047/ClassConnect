import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:file_picker/file_picker.dart'; // Disabled
import 'package:url_launcher/url_launcher.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../data/student_list.dart' show checkIsAdmin;
import 'id_card_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _instaController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  DateTime? _selectedDOB;
  // bool _isUploading = false; // Disabled

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not Logged In")));
    }

    final db = DatabaseService(uid: user.uid);
    // final storage = StorageService(); // Disabled

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: StreamBuilder<UserModel?>(
        stream: db.userProfile,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data!;
          if (!_isEditing) {
            _nameController.text = profile.name;
            _instaController.text = profile.instagram;
            _whatsappController.text = profile.whatsapp;
            _imageUrlController.text = profile.profileImageUrl;
            _selectedDOB = profile.dateOfBirth;
          }

          final bool isAdmin =
              checkIsAdmin(profile.email) || profile.role == 'admin';

          return CustomScrollView(
            slivers: [
              _buildHeader(context, profile, db),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSocialStats(profile),
                      const SizedBox(height: 24),
                      _buildIDCardButton(context, profile),
                      const SizedBox(height: 16),
                      _buildInfoSection(profile),
                      const SizedBox(height: 32),
                      if (isAdmin) _buildAdvancedAdminDashboard(context, db),
                      const SizedBox(height: 32),
                      _buildLogoutButton(context),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    UserModel profile,
    DatabaseService db,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.deepPurple,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.indigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'profile_pic',
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: profile.profileImageUrl.isNotEmpty
                            ? NetworkImage(profile.profileImageUrl)
                            : null,
                        child: profile.profileImageUrl.isEmpty
                            ? Text(
                                profile.name.isNotEmpty
                                    ? profile.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _showImageLinkDialog(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!_isEditing)
                  Text(
                    profile.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),

                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  profile.role.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isEditing ? Icons.check : Icons.edit,
            color: Colors.white,
          ),
          onPressed: () async {
            if (_isEditing) {
              await db.updateProfile(
                name: _nameController.text.trim(),
                instagram: _instaController.text.trim(),
                whatsapp: _whatsappController.text.trim(),
                bio: _bioController.text.trim(),
                imageUrl: _imageUrlController.text.trim(),
                dateOfBirth: _selectedDOB,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
            }
            setState(() => _isEditing = !_isEditing);
          },
        ),
      ],
    );
  }

  Widget _buildSocialStats(UserModel profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (profile.instagram.isNotEmpty)
          _buildSocialBadge(
            Icons.camera_alt,
            'Instagram',
            Colors.purple,
            () async {
              final url = Uri.parse(
                'https://instagram.com/${profile.instagram.replaceAll('@', '')}',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        if (profile.whatsapp.isNotEmpty)
          _buildSocialBadge(Icons.message, 'WhatsApp', Colors.green, () async {
            final url = Uri.parse(
              'https://wa.me/${profile.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}',
            );
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          }),
      ],
    );
  }

  Widget _buildSocialBadge(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(UserModel profile) {
    return Column(
      children: [
        _buildInfoCard(
          'Register ID',
          profile.registerNumber,
          Icons.badge_outlined,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Email',
          profile.email,
          Icons.email_outlined,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        if (_isEditing) ...[
          _buildEditCard(
            'Instagram Username',
            _instaController,
            Icons.camera_alt_outlined,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildEditCard(
            'WhatsApp Number',
            _whatsappController,
            Icons.phone_android_outlined,
            Colors.green,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDOB ?? DateTime(2005),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDOB = date);
              }
            },
            child: _buildInfoCard(
              'Date of Birth',
              _selectedDOB == null
                  ? 'Select Date'
                  : "${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}",
              Icons.cake_outlined,
              Colors.pinkAccent,
            ),
          ),
        ] else ...[
          if (profile.dateOfBirth != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              'Birthday',
              "${profile.dateOfBirth!.day}/${profile.dateOfBirth!.month}/${profile.dateOfBirth!.year}",
              Icons.cake_outlined,
              Colors.pinkAccent,
            ),
          ],
          if (profile.instagram.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              'Instagram',
              '@${profile.instagram}',
              Icons.camera_alt_outlined,
              Colors.purple,
            ),
          ],
          if (profile.whatsapp.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              'WhatsApp',
              profile.whatsapp,
              Icons.phone_android_outlined,
              Colors.green,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildEditCard(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, color: color),
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showImageLinkDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: TextField(
          controller: _imageUrlController,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'Paste a direct link to an image',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedAdminDashboard(
    BuildContext context,
    DatabaseService db,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3436),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Console',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage users',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAdminActionTile(
            Icons.people_outline_rounded,
            'Student Directory',
            'View & Edit Students',
            () => _showUserManagementDialog(context, db),
          ),
          const SizedBox(height: 12),
          _buildAdminActionTile(
            Icons.notifications_active_outlined,
            'Broadcast Center',
            'Send Alerts',
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white30,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserManagementDialog(BuildContext context, DatabaseService db) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Student Directory',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: db.allUsers,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final u = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade50,
                            child: Text(
                              u.name[0],
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            u.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(u.email),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'block') {
                                db.blockUser(u.uid);
                              } else if (val == 'unblock') {
                                db.unblockUser(u.uid);
                              } else {
                                db.updateRole(u.uid, val);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'student',
                                child: Text('Make Student'),
                              ),
                              const PopupMenuItem(
                                value: 'admin',
                                child: Text('Make Admin'),
                              ),
                              if (!u.isBanned)
                                const PopupMenuItem(
                                  value: 'block',
                                  child: Text(
                                    'Block User',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              if (u.isBanned)
                                const PopupMenuItem(
                                  value: 'unblock',
                                  child: Text(
                                    'Unblock User',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                            ],
                            child: Chip(
                              label: Text(
                                u.isBanned ? 'BLOCKED' : u.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: u.isBanned
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              backgroundColor: u.isBanned
                                  ? Colors.red
                                  : (u.role == 'admin'
                                        ? Colors.orange.shade100
                                        : Colors.blue.shade100),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (!context.mounted) return;
          Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          side: BorderSide(color: Colors.red.shade200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: Colors.red,
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Sign Out of Connect',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildIDCardButton(BuildContext context, UserModel profile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentIDCard(user: profile)),
          ),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.badge_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'View Digital ID Card',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /*
  Future<void> _uploadProfileImage(...) async { ... }
  */
}
