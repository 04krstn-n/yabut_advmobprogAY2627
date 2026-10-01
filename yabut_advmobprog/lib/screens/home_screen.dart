import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yabut_advmobprog/constants.dart';

import 'cart_screen.dart';
import 'chat_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';
import '../widgets/custom_text.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final UserService _userService = UserService();

  // made the userId not hardcoded it is fetched from the saved/logged-in user so CartScreen and ProfileScreen render user's own data for enhancement 3
  int? _userId;
  bool _resolvingUser = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvingUser) {
      _resolveUserId();
    }
  }

  Future<void> _resolveUserId() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    int? resolvedId;

    if (args is Map) {
      final rawId = args['id'];
      if (rawId is int) {
        resolvedId = rawId;
      } else if (rawId != null) {
        resolvedId = int.tryParse('$rawId');
      }
    }

    resolvedId ??= (await _userService.getUser()).id;

    if (!mounted) return;
    setState(() {
      _userId = resolvedId;
      _resolvingUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // shows a loading state while the logged-in userId is being resolved for enhancement 3
    if (_resolvingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userId = _userId ?? 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          backgroundColor: NU_BLUE,
          foregroundColor: FB_LIGHT_PRIMARY,
          title: (_selectedIndex == 0)
              ? Image.asset('assets/images/nubdexchange_logo.png', scale: 11.sp)
              : CustomText(
                  text: (_selectedIndex == 1)
                      ? 'My Cart'
                      : (_selectedIndex == 2)
                          ? 'Messages'
                          : (_selectedIndex == 3)
                              ? 'Profile'
                              : 'Home',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: <Widget>[
            const ProductScreen(),
            // made it use the resolved logged-in userId to render user's own cart for enhancement 3
            CartScreen(userId: userId),
            const ChatScreen(),
            ProfileScreen(userId: userId),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),

        // converted the chat button into a floating action button positioned at the bottom right for enhancement 2
        // added an instruction to hide it automatically when _selectedIndex == 1 (CartScreen) or 2 (ChatScreen)
        floatingActionButton: (_selectedIndex == 1 || _selectedIndex == 2)
            ? null
            : FloatingActionButton(
                backgroundColor: NU_BLUE,
                child: const Icon(Icons.chat, color: FB_LIGHT_PRIMARY),
                onPressed: () {
                  // Switches to the ChatScreen tab or pushes the chat route
                  _onTappedBar(2);
                },
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}