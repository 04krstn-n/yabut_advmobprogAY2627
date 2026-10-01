import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // added a fetch cart for a specific user ID using the DummyJSON endpoint '/carts/user/{id}' for enhancement 3
  Future<Cart?> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      if (cartsJson.isNotEmpty) {
        return Cart.fromJson(cartsJson.first);
      }
      return null;
    } else {
      throw Exception('Failed to load user cart');
    }
  }

  // added a method to add products to cart via DummyJSON endpoint '/carts/add' for enhancement 3
  Future<Cart> addToCart({
    required int userId,
    required List<Map<String, dynamic>> products,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': products,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Cart.fromJson(data);
    } else {
      throw Exception('Failed to add product to cart');
    }
  }

  CollectionReference<Map<String, dynamic>> _cartItems(String uid) =>
      _firestore.collection('carts').doc(uid).collection('items');

  Stream<Cart> firebaseCartStream(String uid) {
    return _cartItems(uid).snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => _toCartProduct(doc.data()))
          .where((p) => p.quantity > 0)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      double total = 0;
      double discountedTotal = 0;
      int totalQuantity = 0;
      for (final p in products) {
        total += p.total;
        discountedTotal += p.discountedTotal;
        totalQuantity += p.quantity;
      }

      return Cart(
        id: 0,
        products: products,
        total: total,
        discountedTotal: discountedTotal,
        userId: 0,
        totalProducts: products.length,
        totalQuantity: totalQuantity,
      );
    });
  }

  Future<void> addToFirebaseCart({
    required String uid,
    required Product product,
    int quantity = 1,
  }) async {
    await _cartItems(uid).doc('${product.id}').set({
      'id': product.id,
      'title': product.title,
      'price': product.price,
      'discountPercentage': product.discountPercentage,
      'thumbnail': product.thumbnail,
      'quantity': FieldValue.increment(quantity),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateFirebaseQuantity({
    required String uid,
    required int productId,
    required int quantity,
  }) async {
    final ref = _cartItems(uid).doc('$productId');
    if (quantity <= 0) {
      await ref.delete();
    } else {
      await ref.update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeFromFirebaseCart({
    required String uid,
    required int productId,
  }) async {
    await _cartItems(uid).doc('$productId').delete();
  }

  Future<String> checkoutFirebaseCart({
    required String uid,
    required String email,
    required Cart cart,
  }) async {
    if (cart.products.isEmpty) {
      throw Exception('Your cart is empty');
    }

    final orderRef = _firestore.collection('orders').doc();
    final batch = _firestore.batch();

    batch.set(orderRef, {
      'orderId': orderRef.id,
      'userId': uid,
      'email': email,
      'products': cart.products.map((p) => p.toJson()).toList(),
      'total': cart.total,
      'discountedTotal': cart.discountedTotal,
      'totalProducts': cart.totalProducts,
      'totalQuantity': cart.totalQuantity,
      'status': 'placed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final items = await _cartItems(uid).get();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    return orderRef.id;
  }

  CartProduct _toCartProduct(Map<String, dynamic> data) {
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
    final discount = (data['discountPercentage'] as num?)?.toDouble() ?? 0.0;
    final total = price * quantity;

    return CartProduct(
      id: (data['id'] as num?)?.toInt() ?? 0,
      title: (data['title'] ?? '').toString(),
      price: price,
      quantity: quantity,
      total: total,
      discountPercentage: discount,
      discountedTotal: total * (1 - discount / 100),
      thumbnail: (data['thumbnail'] ?? '').toString(),
    );
  }
}