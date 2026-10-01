import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yabut_advmobprog/constants.dart';
import '../models/product.dart';
import '../widgets/custom_text.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cart_service.dart';

// added details page when clicking a product card to comply with enhancement 2
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = CartService();
  int _quantity = 1;
  bool _adding = false;

  Product get product => widget.product;

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Sign in with a Firebase account to add items to your cart.'),
        ));
      return;
    }

    setState(() => _adding = true);
    try {
      await _cartService.addToFirebaseCart(
        uid: user.uid,
        product: product,
        quantity: _quantity,
      );
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Added $_quantity × ${product.title} to your cart'),
        ));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not add to cart: $e')));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Widget _buildBottomBar(bool isDark) {
    final outOfStock = product.stock <= 0;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  CustomText(
                    text: '$_quantity',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add),
                    onPressed: (product.stock > 0 && _quantity >= product.stock)
                        ? null
                        : () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: SizedBox(
                height: 48.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NU_BLUE,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: (_adding || outOfStock) ? null : () => _addToCart(),
                  icon: _adding
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_shopping_cart),
                  label: Text(
                    outOfStock
                        ? 'Out of stock'
                        : 'Add to Cart · \$${(product.price * _quantity).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      bottomNavigationBar: _buildBottomBar(isDark),
      body: Stack(
        children: [
          // added header and product image container for design
         Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300.h,
            child: Container(
              color: const Color(0xD4DDD9EC),
              padding: EdgeInsets.only(top: 70.h, bottom: 40.h, left: 32.w, right: 32.w),
              child: Image.network(
                product.thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.image, size: 60.sp),
              ),
            ),
          ),

          Positioned(
            top: 40.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: NU_BLUE,
                  radius: 20.r,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                CustomText(
                  text: 'Details',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(width: 40.w), 
              ],
            ),
          ),

          // added bottom content container that is styled to adapt Light/Dark mode
          Positioned(
            top: 260.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28.r),
                  topRight: Radius.circular(28.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.3) 
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomText(
                              text: product.title,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          CustomText(
                            text: '\$${product.price.toStringAsFixed(2)}',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Rating Indicator
                    Row(
                      children: [
                        CustomText(
                          text: '${product.rating}',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.star, color: Colors.amber, size: 16.sp),
                        SizedBox(width: 6.w),
                        CustomText(
                          text: '(${product.reviews.length} reviews)',
                          fontSize: 12.sp,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // added container for the description that adapt to Light/Dark mode for better user experience
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF2C2C3A) 
                            : Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: 'Description',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(height: 6.h),
                          CustomText(
                            text: product.description,
                            fontSize: 14.sp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}