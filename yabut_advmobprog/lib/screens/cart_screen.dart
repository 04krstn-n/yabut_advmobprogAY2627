import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import 'detail_screen.dart';

// created CartScreen to fetch and render user cart data to comply with enhancement 3
// userId is now supplied by HomeScreen based on the actually logged-in/saved user for enhancement 3
class CartScreen extends StatefulWidget {
  final int userId;
  const CartScreen({super.key, this.userId = 5});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  late Future<Cart?> _userCartFuture;

  @override
  void initState() {
    super.initState();
    // added a new feature to fetch the cart specifically for this user to comply with enhancement 3
    _userCartFuture = _cartService.getCartByUserId(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Cart?>(
        future: _userCartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final cart = snapshot.data;
          if (cart == null || cart.products.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.products.length,
                  padding: EdgeInsets.all(12.w),
                  itemBuilder: (context, index) {
                    final product = cart.products[index];

                    // made item clickable to navigate to DetailScreen with product id for enhancement 1
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6.h),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(product: product),
                            ),
                          );
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: Image.network(
                            product.thumbnail,
                            width: 50.w,
                            height: 50.h,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                        title: Text(
                          product.title,
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Qty: ${product.quantity} × \$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        trailing: Text(
                          '\$${product.discountedTotal.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${cart.discountedTotal.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}