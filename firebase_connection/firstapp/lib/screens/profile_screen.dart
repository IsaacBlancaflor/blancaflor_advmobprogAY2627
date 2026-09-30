// Enhancement 3: profile screen rendering user data via
// UserService().getUserData(), showing different fields depending on
// loginType (dummyjson vs firebase), with update username, change
// password, and delete account actions
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../models/cart.dart';
import '../services/user_service.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> _userDataFuture;
  Future<Cart?>? _cartFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Enhancement 3: fetch user data via UserService().getUserData()
  void _loadProfile() {
    _userDataFuture = _userService.getUserData().then((data) {
      final user = User.fromJson(data);
      // Only DummyJSON users have a numeric id usable against the Cart
      // API; skip the cart fetch for Firebase-only accounts.
      if (data['loginType'] == 'dummyjson' && user.id != 0) {
        _cartFuture = CartService().getCartByUserId(user.id);
      }
      return data;
    });
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SigninScreen()),
      (route) => false,
    );
  }

  // Enhancement 1/3: update username via Firebase (updateDisplayName)
  Future<void> _showUpdateUsernameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    try {
      await _userService.updateUsername(username: result);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username updated!')));
      setState(_loadProfile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update username: $e')));
    }
  }

  // Enhancement 1/3: change password via Firebase (reauth + updatePassword)
  Future<void> _showChangePasswordDialog(String email) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentController.text,
        newPassword: newController.text,
        email: email,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to change password: $e')));
    }
  }

  // Enhancement 1/3: delete account via Firebase (reauth + delete)
  Future<void> _showDeleteAccountDialog(String email) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _userService.deleteAccount(
        email: email,
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SigninScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: CustomText(
                text: 'Error loading profile: ${snapshot.error}',
                fontSize: 14.sp,
              ),
            );
          }

          final data = snapshot.data!;
          final user = User.fromJson(data);
          final loginType = data['loginType'] ?? '';
          final isFirebase = loginType == 'firebase';

          return Scaffold(
            appBar: AppBar(
              elevation: 2,
              title: CustomText(
                text: user.firstName.isNotEmpty ? user.firstName : 'Profile',
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        children: [
                          ClipOval(
                            child: user.image.isNotEmpty
                                ? Image.network(
                                    user.image,
                                    width: 80.r,
                                    height: 80.r,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 80.r,
                                      height: 80.r,
                                      color: Colors.grey.shade300,
                                      child: Icon(
                                        Icons.person,
                                        size: 40.sp,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 80.r,
                                    height: 80.r,
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.person,
                                      size: 40.sp,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                          ),
                          SizedBox(height: 12.h),
                          CustomText(
                            text: user.fullName.trim().isNotEmpty
                                ? user.fullName
                                : user.email,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          if (user.username.isNotEmpty)
                            CustomText(
                              text: '@${user.username}',
                              fontSize: 13.sp,
                            ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: isFirebase
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: CustomText(
                              text: isFirebase
                                  ? 'Firebase Account'
                                  : 'DummyJSON Account',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const CustomText(text: 'Email', fontSize: 13),
                          trailing: CustomText(text: user.email, fontSize: 13),
                        ),
                        // DummyJSON-specific fields
                        if (!isFirebase) ...[
                          ListTile(
                            leading: const Icon(Icons.wc_outlined),
                            title: const CustomText(
                              text: 'Gender',
                              fontSize: 13,
                            ),
                            trailing: CustomText(
                              text: user.gender,
                              fontSize: 13,
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.badge_outlined),
                            title: const CustomText(
                              text: 'User ID',
                              fontSize: 13,
                            ),
                            trailing: CustomText(
                              text: '#${user.id}',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Enhancement 1/3: account management actions
                  // (available for Firebase accounts)
                  if (isFirebase) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CustomText(
                        text: 'Account Settings',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const CustomText(
                              text: 'Update Username',
                              fontSize: 13,
                            ),
                            onTap: () =>
                                _showUpdateUsernameDialog(user.firstName),
                          ),
                          ListTile(
                            leading: const Icon(Icons.lock_outline),
                            title: const CustomText(
                              text: 'Change Password',
                              fontSize: 13,
                            ),
                            onTap: () => _showChangePasswordDialog(user.email),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            title: const CustomText(
                              text: 'Delete Account',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            onTap: () => _showDeleteAccountDialog(user.email),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  // Cart section (only rendered for DummyJSON users with a
                  // resolvable numeric userId)
                  if (!isFirebase) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CustomText(
                        text: 'My Cart',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    FutureBuilder<Cart?>(
                      future: _cartFuture,
                      builder: (context, cartSnapshot) {
                        if (cartSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          );
                        }
                        final cart = cartSnapshot.data;
                        if (cart == null || cart.products.isEmpty) {
                          return CustomText(
                            text: 'No cart items for this user.',
                            fontSize: 13.sp,
                          );
                        }
                        return Column(
                          children: cart.products
                              .map(
                                (item) => Card(
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(6.r),
                                      child: Image.network(
                                        item.thumbnail,
                                        width: 40.w,
                                        height: 40.w,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.image),
                                      ),
                                    ),
                                    title: CustomText(
                                      text: item.title,
                                      fontSize: 13.sp,
                                    ),
                                    trailing: CustomText(
                                      text: 'x${item.quantity}',
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    SizedBox(height: 24.h),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
