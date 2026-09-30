import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'product_screen.dart';
import 'chat_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ChatService _chatService = ChatService();
  late final Stream<int> _unreadCountStream;

  final List<Widget> _pages = const [
    ProductScreen(),
    ChatScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Cache stream in initState so rebuilding widgets doesn't reset stream listeners
    _unreadCountStream = _chatService.getTotalUnreadCountStream();
    cartService.value.initCart();
  }

  void _onTappedBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hideFab = _selectedIndex == 1 || _selectedIndex == 2;

    return ValueListenableBuilder<Cart?>(
      valueListenable: cartService.value.cartNotifier,
      builder: (context, cart, _) {
        final totalCartQty = cart?.totalQuantity ?? 0;

        return StreamBuilder<int>(
          stream: _unreadCountStream,
          builder: (context, unreadSnapshot) {
            final unreadMessages = unreadSnapshot.data ?? 0;

            return PopScope(
              canPop: false,
              child: Scaffold(
                appBar: _selectedIndex == 0
                    ? AppBar(
                        automaticallyImplyLeading: false,
                        elevation: 2,
                        title: CustomText(
                          text: widget.username.isNotEmpty
                              ? 'Welcome, ${widget.username}'
                              : 'Home',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        actions: [
                          IconButton(
                            icon: Icon(Icons.settings, size: 24.sp),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/settings'),
                          ),
                        ],
                      )
                    : null,
                body: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
                floatingActionButton: hideFab
                    ? null
                    : Stack(
                        clipBehavior: Clip.none,
                        children: [
                          FloatingActionButton(
                            backgroundColor: Colors.amber,
                            onPressed: () => _onTappedBar(1),
                            child:
                                const Icon(Icons.chat, color: Colors.black87),
                          ),
                          if (unreadMessages > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  '$unreadMessages',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                bottomNavigationBar: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _selectedIndex,
                  onTap: _onTappedBar,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.shop_2_outlined),
                      activeIcon: Icon(Icons.shop_2),
                      label: 'Shop',
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        isLabelVisible: unreadMessages > 0,
                        backgroundColor: Colors.redAccent,
                        label: Text('$unreadMessages'),
                        child: const Icon(Icons.chat_bubble_outline_rounded),
                      ),
                      activeIcon: Badge(
                        isLabelVisible: unreadMessages > 0,
                        backgroundColor: Colors.redAccent,
                        label: Text('$unreadMessages'),
                        child: const Icon(Icons.chat_bubble_rounded),
                      ),
                      label: 'Chat',
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        isLabelVisible: totalCartQty > 0,
                        label: Text('$totalCartQty'),
                        child: const Icon(Icons.shopping_cart_outlined),
                      ),
                      activeIcon: Badge(
                        isLabelVisible: totalCartQty > 0,
                        label: Text('$totalCartQty'),
                        child: const Icon(Icons.shopping_cart),
                      ),
                      label: 'Cart',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      activeIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}