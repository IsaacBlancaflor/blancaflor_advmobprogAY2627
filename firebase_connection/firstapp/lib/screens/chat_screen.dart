import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _chatService.syncCurrentUser();
    _searchChatController.addListener(() {
      setState(() {
        _searchText = _searchChatController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final currentUid = currentUser?.uid ?? '';
    final currentEmail = (currentUser?.email ?? '').trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Chats',
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchChatController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchChatController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          _searchChatController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      text: 'Error loading users: ${snapshot.error}',
                      fontSize: 15.sp,
                    ),
                  );
                }

                final rawUsers = snapshot.data ?? [];

                if (rawUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 54.r, color: Colors.grey.shade400),
                        SizedBox(height: 8.h),
                        CustomText(
                          text: 'No registered users in database.',
                          fontSize: 16.sp,
                        ),
                      ],
                    ),
                  );
                }

                final filteredUsers = rawUsers.where((user) {
                  final targetUid =
                      (user['uid'] ?? user['id'] ?? user['docId'] ?? '')
                          .toString()
                          .trim();
                  final targetEmail =
                      (user['email'] ?? '').toString().trim().toLowerCase();

                  final bool isSameUid =
                      currentUid.isNotEmpty && targetUid == currentUid;
                  final bool isSameEmail = currentEmail.isNotEmpty &&
                      targetEmail.isNotEmpty &&
                      targetEmail == currentEmail;

                  if (isSameUid || isSameEmail) {
                    return false;
                  }

                  if (_searchText.isNotEmpty) {
                    final firstName =
                        (user['firstName'] ?? '').toString().toLowerCase();
                    final lastName =
                        (user['lastName'] ?? '').toString().toLowerCase();
                    final username =
                        (user['username'] ?? '').toString().toLowerCase();
                    final fullName = '$firstName $lastName'.trim();

                    final matchesName = fullName.contains(_searchText);
                    final matchesUsername = username.contains(_searchText);
                    final matchesEmail = targetEmail.contains(_searchText);

                    return matchesName || matchesUsername || matchesEmail;
                  }

                  return true;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: CustomText(
                        text: _searchText.isNotEmpty
                            ? 'No matching users found for "$_searchText"'
                            : 'No other users available to chat with yet.',
                        fontSize: 15.sp,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredUsers.length,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  separatorBuilder: (_, __) => SizedBox(height: 6.h),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final String targetUserId = (user['uid'] ??
                            user['id'] ??
                            user['docId'] ??
                            '')
                        .toString();

                    final String firstName =
                        (user['firstName'] ?? '').toString();
                    final String lastName =
                        (user['lastName'] ?? '').toString();
                    final String email =
                        (user['email'] ?? 'No email').toString();

                    String displayName = '$firstName $lastName'.trim();
                    if (displayName.isEmpty) {
                      displayName = (user['username'] ??
                              (email.isNotEmpty
                                  ? email.split('@').first
                                  : 'User'))
                          .toString();
                    }

                    final String avatarLetter = displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?';

                    return StreamBuilder<int>(
                      stream: _chatService
                          .getUnreadCountFromUserStream(targetUserId),
                      builder: (context, unreadSnapshot) {
                        final unreadCount = unreadSnapshot.data ?? 0;
                        final bool hasUnread = unreadCount > 0;

                        return StreamBuilder<QuerySnapshot>(
                          stream: _chatService
                              .getLastMessageStream(targetUserId),
                          builder: (context, lastMsgSnapshot) {
                            String previewText = email;
                            if (lastMsgSnapshot.hasData &&
                                lastMsgSnapshot.data!.docs.isNotEmpty) {
                              final lastMsgData =
                                  lastMsgSnapshot.data!.docs.first.data()
                                      as Map<String, dynamic>;
                              final msg = (lastMsgData['message'] ?? '')
                                  .toString();
                              final isFromMe = lastMsgData['senderId'] ==
                                  currentUser?.uid;
                              previewText = isFromMe ? 'You: $msg' : msg;
                            }

                            return Card(
                              elevation: hasUnread ? 2 : 0.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                side: hasUnread
                                    ? BorderSide(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.5),
                                        width: 1.2)
                                    : BorderSide.none,
                              ),
                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 22.r,
                                      backgroundColor: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.15),
                                      child: Text(
                                        avatarLetter,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 11.r,
                                        height: 11.r,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  previewText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w400,
                                    color: hasUnread
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (hasUnread) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 7.w, vertical: 3.h),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        child: Text(
                                          '$unreadCount',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14),
                                    ],
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailScreen(
                                        currentUserEmail:
                                            currentUser?.email ?? '',
                                        tappedUser: user,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}