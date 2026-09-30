import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoCtrl = TextEditingController();

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  void _showOrderConfirmation(BuildContext context, Cart cart) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 28),
            SizedBox(width: 8.w),
            const Text('Order Confirmed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: #${cart.id}',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 12.sp)),
            SizedBox(height: 8.h),
            Text('Total Products: ${cart.totalProducts}'),
            Text('Total Quantity: ${cart.totalQuantity} items'),
            Text('Original Total: \$${cart.total.toStringAsFixed(2)}'),
            Text(
              'Total Saved: -\$${(cart.total - cart.discountedTotal).toStringAsFixed(2)}',
              style:
                  const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            const Divider(),
            Text(
              'Final Amount Paid: \$${cart.discountedTotal.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: Colors.green.shade800),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              cartService.value.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Cart?>(
      valueListenable: cartService.value.cartNotifier,
      builder: (context, cart, _) {
        final products = cart?.products ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Shopping Cart'),
            actions: [
              if (products.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => cartService.value.clearCart(),
                ),
            ],
          ),
          body: products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove_shopping_cart_outlined,
                          size: 64.r, color: Colors.grey),
                      SizedBox(height: 10.h),
                      const Text('Your cart is empty.',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.all(12.w),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final item = products[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                            child: Padding(
                              padding: EdgeInsets.all(8.w),
                              child: Row(
                                children: [
                                  Image.network(
                                    item.thumbnail,
                                    width: 50.w,
                                    height: 50.w,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.sp),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          '\$${item.price.toStringAsFixed(2)} x ${item.quantity}',
                                          style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          'Total: \$${item.discountedTotal.toStringAsFixed(2)} (-${item.discountPercentage.toStringAsFixed(0)}%)',
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20),
                                        onPressed: () => cartService.value
                                            .decrementQuantity(item.id),
                                      ),
                                      Text('${item.quantity}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.sp)),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 20),
                                        onPressed: () => cartService.value
                                            .incrementQuantity(item.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                      color: Theme.of(context).cardColor,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoCtrl,
                              decoration: InputDecoration(
                                hintText: 'Promo code (e.g. SAVE10, SAVE20)',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 8.h),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r)),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          ElevatedButton(
                            onPressed: () {
                              if (cartService.value
                                  .applyPromo(_promoCtrl.text)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Discount code applied!')),
                                );
                                _promoCtrl.clear();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invalid code')),
                                );
                              }
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Original Total:'),
                              Text('\$${cart!.total.toStringAsFixed(2)}'),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Discount:',
                                  style: TextStyle(color: Colors.red)),
                              Text(
                                '-\$${(cart.total - cart.discountedTotal).toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          if (cartService.value.appliedPromoCode != null) ...[
                            SizedBox(height: 4.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'Promo Code (${cartService.value.appliedPromoCode}):',
                                    style: const TextStyle(color: Colors.red)),
                                Text(
                                  '-${(cartService.value.promoDiscountPercent * 100).toInt()}%',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Grand Total:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp)),
                              Text(
                                '\$${cart.discountedTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: Colors.green.shade800),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          SizedBox(
                            width: double.infinity,
                            height: 40.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () =>
                                  _showOrderConfirmation(context, cart),
                              child: const Text('Confirm Order',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}