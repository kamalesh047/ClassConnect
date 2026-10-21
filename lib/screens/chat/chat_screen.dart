import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// import 'package:file_picker/file_picker.dart'; // Disabled
import 'package:url_launcher/url_launcher.dart';
import '../../services/chat_service.dart';
import '../../services/database_service.dart';
// import '../../services/storage_service.dart'; // Storage disabled
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../data/student_list.dart' show checkIsAdmin;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  // final StorageService _storageService = StorageService(); // Disabled
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isSearching = false;

  // bool _isUploadingImage = false; // Disabled

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final db = DatabaseService(uid: user.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // Classic Chat Background base
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF075E54), // Deep Teal
        leadingWidth: 0,
        title: InkWell(
          onTap: () => _showGroupInfo(context, db),
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                Hero(
                  tag: 'group_icon',
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.groups_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect Group',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.5,
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: db.usersCollection.snapshots(),
                      builder: (context, snapshot) {
                        final users =
                            snapshot.data?.docs
                                .map(
                                  (doc) => UserModel.fromMap(
                                    doc.data() as Map<String, dynamic>,
                                    doc.id,
                                  ),
                                )
                                .toList() ??
                            [];
                        final onlineCount = users
                            .where((u) => u.isOnline)
                            .length;
                        return Text(
                          onlineCount > 0
                              ? '$onlineCount online'
                              : 'Tap for info',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () {},
            tooltip: 'Video Call',
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () {},
            tooltip: 'Voice Call',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showGroupInfo(context, db),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFECE5DD),
          image: DecorationImage(
            image: NetworkImage(
              'https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png',
            ),
            fit: BoxFit.cover,
            opacity: 0.06,
          ),
        ),
        child: Column(
          children: [
            if (_isSearching)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.white,
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search chat...',
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            _buildActiveUsersBar(db),
            Expanded(
              child: StreamBuilder<UserModel?>(
                stream: db.userProfile,
                builder: (context, userSnapshot) {
                  final currentUser = userSnapshot.data;
                  final isAdmin =
                      currentUser?.role == 'admin' || checkIsAdmin(user.email);

                  return StreamBuilder<List<MessageModel>>(
                    stream: _chatService.messages,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allMessages = snapshot.data!;
                      final messages = allMessages
                          .where(
                            (m) =>
                                m.text.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                m.senderName.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();

                      if (messages.isEmpty) return _buildEmptyState();

                      final pinnedMessage = messages
                          .where((m) => m.isPinned)
                          .firstOrNull;

                      return Column(
                        children: [
                          if (pinnedMessage != null)
                            _buildPinnedMessageBar(pinnedMessage, isAdmin),
                          Expanded(
                            child: ListView.builder(
                              reverse: true,
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isMe = msg.senderId == user.uid;
                                bool showDate = false;
                                if (index == messages.length - 1 ||
                                    !_isSameDay(
                                      msg.timestamp,
                                      messages[index + 1].timestamp,
                                    )) {
                                  showDate = true;
                                }
                                return Column(
                                  children: [
                                    if (showDate)
                                      _buildDateSeparator(msg.timestamp),
                                    _AdvancedMessageBubble(
                                      message: msg,
                                      isMe: isMe,
                                      db: db,
                                      canDelete: isMe || isAdmin,
                                      isAdmin: isAdmin,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputArea(user, db),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveUsersBar(DatabaseService db) {
    return StreamBuilder<List<UserModel>>(
      stream: db.allUsers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final activeUsers = snapshot.data!.where((u) => u.isOnline).toList();
        if (activeUsers.isEmpty) return const SizedBox.shrink();

        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: activeUsers.length,
                itemBuilder: (context, index) {
                  final u = activeUsers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00BFA5), Color(0xFF2196F3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF00BFA5,
                                ).withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: u.profileImageUrl.isNotEmpty
                                  ? NetworkImage(u.profileImageUrl)
                                  : null,
                              child: u.profileImageUrl.isEmpty
                                  ? Text(
                                      u.name[0],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          u.name.split(' ').first,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGroupInfo(BuildContext context, DatabaseService db) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF0F2F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF128C7E),
                child: Icon(Icons.group, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 10),
              const Text(
                'Connect Group',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Group · 60 Participants',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: db.usersCollection.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = snapshot.data!.docs
                        .map(
                          (doc) => UserModel.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          ),
                        )
                        .toList();

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final u = users[index];
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage: u.profileImageUrl.isNotEmpty
                                    ? NetworkImage(u.profileImageUrl)
                                    : null,
                                child: u.profileImageUrl.isEmpty
                                    ? Text(u.name[0])
                                    : null,
                              ),
                              if (u.isOnline)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            u.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            u.isOnline
                                ? 'Online'
                                : 'Last seen ${_formatRelativeTime(u.lastSeen)}',
                          ),
                          trailing: u.role == 'admin'
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.green),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Group Admin',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              : null,
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

  String _formatRelativeTime(DateTime? time) {
    if (time == null) return 'recently';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, size: 16, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Messages are end-to-end encrypted',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD7EAF1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _isToday(date)
              ? 'TODAY'
              : DateFormat('MMMM dd').format(date).toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D7D88),
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildInputArea(User user, DatabaseService db) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        onSubmitted: (_) => _sendMessage(user, db),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: Colors.grey.shade600,
                      ),
                      onPressed:
                          () {}, // Attachment handling disabled, but icon kept for UI
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.grey.shade600),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(user, db),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00897B),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00897B).withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(User? user, DatabaseService db) async {
    if (_messageController.text.trim().isEmpty || user == null) return;
    final text = _messageController.text.trim();
    _messageController.clear();
    final profile = await db.userProfile.first;

    if (profile?.isBanned == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are blocked from sending messages'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final bool isAdmin = profile?.role == 'admin' || checkIsAdmin(user.email);
    await _chatService.sendMessage(
      text,
      user.uid,
      profile?.name ?? 'Student',
      isAdmin,
    );
  }

  Widget _buildPinnedMessageBar(MessageModel message, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin, size: 20, color: Color(0xFFF57F17)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pinned'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFF57F17),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  message.text.isNotEmpty
                      ? message.text
                      : (message.imageUrl != null ? '[Image]' : ''),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isAdmin)
            GestureDetector(
              onTap: () => ChatService().unpinMessage(message.id),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }

  // File attachment methods removed for non-storage version
  /*
  void _showAttachmentOptions(
    BuildContext context,
    User user,
    DatabaseService db,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 250,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachOption(
                  Icons.insert_drive_file,
                  'Document',
                  Colors.indigo,
                  () async {
                    Navigator.pop(context);
                    _sendDocument(user, db);
                  },
                ),
                _buildAttachOption(
                  Icons.camera_alt,
                  'Camera',
                  Colors.pink,
                  () {},
                ),
                _buildAttachOption(
                  Icons.image,
                  'Gallery',
                  Colors.purple,
                  () async {
                    Navigator.pop(context);
                    _sendImage(user, db);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachOption(
                  Icons.headphones,
                  'Audio',
                  Colors.orange,
                  () {},
                ),
                _buildAttachOption(
                  Icons.location_on,
                  'Location',
                  Colors.green,
                  () {},
                ),
                _buildAttachOption(Icons.person, 'Contact', Colors.blue, () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Future<void> _sendDocument(User user, DatabaseService db) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'],
    );
    if (result == null) return;
    final file = result.files.first;

    setState(() => _isUploadingImage = true);
    try {
      final url = await _storageService.uploadFile(file, 'chat_docs');
      if (url != null) {
        final profile = await db.userProfile.first;
        final isAdmin =
            profile?.role == 'admin' ||
            user.email?.toLowerCase() == adminEmail.toLowerCase();
        await _chatService.sendMessage(
          '[Document: ${file.name}]',
          user.uid,
          profile?.name ?? 'Student',
          isAdmin,
          imageUrl: url, // Re-using imageUrl field as a generic file link
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _sendImage(User user, DatabaseService db) async {
    if (user == null) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    final file = result.files.first;

    setState(() => _isUploadingImage = true);
    try {
      final url = await _storageService.uploadFile(file, 'chat_images');
      if (url != null) {
        final profile = await db.userProfile.first;
        final bool isAdmin =
            profile?.role == 'admin' ||
            user.email?.toLowerCase() == adminEmail.toLowerCase();
        await _chatService.sendMessage(
          '[Image]',
          user.uid,
          profile?.name ?? 'Student',
          isAdmin,
          imageUrl: url,
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }
  */
}

class _AdvancedMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final DatabaseService db;
  final bool canDelete;
  final bool isAdmin;

  const _AdvancedMessageBubble({
    required this.message,
    required this.isMe,
    required this.db,
    required this.canDelete,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        if (!message.isDeleted) {
          showDialog(
            context: context,
            builder: (ctx) => SimpleDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Center(
                child: Text(
                  'Options',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              children: [
                if (isAdmin)
                  SimpleDialogOption(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (message.isPinned) {
                        ChatService().unpinMessage(message.id);
                      } else {
                        ChatService().pinMessage(message.id);
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            message.isPinned
                                ? Icons.push_pin_outlined
                                : Icons.push_pin,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          message.isPinned ? 'Unpin Message' : 'Pin Message',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (canDelete)
                  SimpleDialogOption(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(context);
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Delete Message',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 4, top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                    if (message.isSenderAdmin) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 14),
                    ],
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: StreamBuilder<UserModel?>(
                      stream: db.getPresence(message.senderId),
                      builder: (context, snapshot) {
                        final u = snapshot.data;
                        return Stack(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.purple.shade50,
                              backgroundImage:
                                  (u?.profileImageUrl.isNotEmpty ?? false)
                                  ? NetworkImage(u!.profileImageUrl)
                                  : null,
                              child: (u?.profileImageUrl.isEmpty ?? true)
                                  ? Text(
                                      message.senderName[0],
                                      style: TextStyle(
                                        color: Colors.purple.shade300,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            if (u?.isOnline ?? false)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [Color(0xFF00AA9D), Color(0xFF00897B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isMe ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 2),
                        bottomRight: Radius.circular(isMe ? 2 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isDeleted)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.block,
                                size: 14,
                                color: isMe ? Colors.white70 : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'This message was deleted',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: isMe ? Colors.white70 : Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          if (message.imageUrl != null) _buildImage(context),
                          if (message.text.isNotEmpty)
                            _buildHighlightedText(message.text, isMe),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('h:mm a').format(message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white70
                                    : Colors.grey.shade500,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.done_all_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    bool isDoc = message.text.startsWith('[Document:');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isDoc
            ? GestureDetector(
                onTap: () async {
                  final url = Uri.parse(message.imageUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        color: Colors.deepPurple,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          message.text
                              .replaceAll('[Document: ', '')
                              .replaceAll(']', ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.download_rounded,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              )
            : Image.network(
                message.imageUrl!,
                fit: BoxFit.cover,
                width: 200,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
                loadingBuilder: (context, child, loadingProgress) =>
                    loadingProgress == null
                    ? child
                    : const SizedBox(
                        width: 200,
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text(
          'This message will be permanently removed for everyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ChatService().deleteMessage(message.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

Widget _buildHighlightedText(String text, bool isMe) {
  const keywords = [
    'deadline',
    'exam',
    'viva',
    'result',
    'urgent',
    'cancelled',
    'timetable',
    'assignment',
  ];
  final lowerText = text.toLowerCase();
  bool hasKeyword = keywords.any((k) => lowerText.contains(k));

  if (!hasKeyword) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: isMe ? Colors.white : Colors.black87,
        height: 1.3,
      ),
    );
  }

  return RichText(
    text: TextSpan(
      style: TextStyle(
        fontSize: 16,
        color: isMe ? Colors.white : Colors.black87,
        height: 1.3,
        fontFamily: 'Roboto', // Standard Flutter font
      ),
      children: _processText(text, keywords, isMe),
    ),
  );
}

List<TextSpan> _processText(String text, List<String> keywords, bool isMe) {
  List<TextSpan> spans = [];
  String remaining = text;

  while (remaining.isNotEmpty) {
    int earliestIndex = -1;
    String currentKeyword = '';

    for (var k in keywords) {
      int index = remaining.toLowerCase().indexOf(k);
      if (index != -1 && (earliestIndex == -1 || index < earliestIndex)) {
        earliestIndex = index;
        currentKeyword = remaining.substring(index, index + k.length);
      }
    }

    if (earliestIndex == -1) {
      spans.add(TextSpan(text: remaining));
      break;
    }

    if (earliestIndex > 0) {
      spans.add(TextSpan(text: remaining.substring(0, earliestIndex)));
    }

    spans.add(
      TextSpan(
        text: currentKeyword,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          backgroundColor: isMe ? Colors.black26 : Colors.yellow.shade100,
          color: isMe ? Colors.white : Colors.red.shade900,
        ),
      ),
    );

    remaining = remaining.substring(earliestIndex + currentKeyword.length);
  }
  return spans;
}
