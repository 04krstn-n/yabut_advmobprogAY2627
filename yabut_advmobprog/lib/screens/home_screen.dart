import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yabut_advmobprog/constants.dart';

import 'product_screen.dart';
import 'cart_screen.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
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
          children: const <Widget>[
            ProductScreen(),
            CartScreen(userId: 5), // added a cart embedded in bottom navigation for enhancement 1
            Center(child: Text('Profile Screen')),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),

        // converted the chat button into a floating action button positioned at the bottom right for enhancement 2
        // added an instruction to hide it automatically when _selectedIndex == 1 (CartScreen) enhancement 2
        floatingActionButton: (_selectedIndex == 1)
            ? null
            : FloatingActionButton(
                backgroundColor: NU_BLUE,
                child: const Icon(Icons.chat, color: FB_LIGHT_PRIMARY),
                onPressed: () {
                  Navigator.pushNamed(context, '/chat');
                },
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        // made the added Cart button placed directly in the middle between Shop and Profile enhancement 1
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
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