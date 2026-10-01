import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
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
  User? _firebaseUser;
  Stream<Cart>? _firebaseCartStream;
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _firebaseUser = FirebaseAuth.instance.currentUser;
    if (_firebaseUser != null) {
      _firebaseCartStream = _cartService.firebaseCartStream(_firebaseUser!.uid);
    } else {
      // added a new feature to fetch the cart specifically for this user to comply with enhancement 3
      _userCartFuture = _cartService.getCartByUserId(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firebaseUser != null) {
      return Scaffold(
        body: StreamBuilder<Cart>(
          stream: _firebaseCartStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final cart = snapshot.data;
            if (cart == null || cart.products.isEmpty) {
              return _emptyCart();
            }
            return _cartBody(cart, editable: true);
          },
        ),
      );
    }

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
            return _emptyCart();
          }

          return _cartBody(cart, editable: false);
        },
      ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64.sp, color: Colors.grey),
          SizedBox(height: 12.h),
          Text('Your cart is empty', style: TextStyle(fontSize: 16.sp)),
          SizedBox(height: 4.h),
          Text(
            'Add products from the Shop tab',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _cartBody(Cart cart, {required bool editable}) {
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  subtitle: editable
                      ? _quantityControls(product)
                      : Text(
                          'Qty: ${product.quantity} × \$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${product.discountedTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      if (editable)
                        InkWell(
                          onTap: () => _remove(product),
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Icon(Icons.delete_outline,
                                size: 20.sp, color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: \$${cart.discountedTotal.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${cart.totalQuantity} item(s)',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NU_BLUE,
                  foregroundColor: Colors.white,
                ),
                onPressed: !editable
                    ? () {}
                    : (_checkingOut ? null : () => _checkout(cart)),
                child: _checkingOut
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Checkout'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quantityControls(CartProduct product) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        children: [
          _qtyButton(Icons.remove, () => _setQuantity(product, product.quantity - 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              '${product.quantity}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
          _qtyButton(Icons.add, () => _setQuantity(product, product.quantity + 1)),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              '× \$${product.price.toStringAsFixed(2)}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(6.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(icon, size: 16.sp),
      ),
    );
  }

  Future<void> _setQuantity(CartProduct product, int quantity) async {
    try {
      await _cartService.updateFirebaseQuantity(
        uid: _firebaseUser!.uid,
        productId: product.id,
        quantity: quantity,
      );
    } catch (e) {
      _showSnack('Could not update quantity: $e');
    }
  }

  Future<void> _remove(CartProduct product) async {
    try {
      await _cartService.removeFromFirebaseCart(
        uid: _firebaseUser!.uid,
        productId: product.id,
      );
      _showSnack('${product.title} removed from cart');
    } catch (e) {
      _showSnack('Could not remove item: $e');
    }
  }

  Future<void> _checkout(Cart cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout'),
        content: Text(
          'Place an order for ${cart.totalQuantity} item(s) totaling '
          '\$${cart.discountedTotal.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Place order'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _checkingOut = true);
    try {
      await _cartService.checkoutFirebaseCart(
        uid: _firebaseUser!.uid,
        email: _firebaseUser!.email ?? '',
        cart: cart,
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Order placed!'),
          content: const Text('Thank you for your purchase.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnack('Checkout failed: $e');
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}