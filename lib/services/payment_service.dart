import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:waste_logistics/models/order.dart';

class PaymentService {
  static const String _publishableKey = 'pk_test_your_publishable_key';

  Future<void> initialize() async {
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  Future<Map<String, dynamic>> createPaymentIntent(
    double amount,
    String currency,
  ) async {
    try {
      final response = await _createPaymentIntentBackend(
        amount: (amount * 100).toInt(),
        currency: currency,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  Future<void> processPayment(
    String clientSecret,
    Map<String, dynamic> params,
  ) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Waste Logistics',
          applePay: const PaymentSheetApplePay(merchantCountryCode: 'US'),
          googlePay: const PaymentSheetGooglePay(merchantCountryCode: 'US', testEnv: true),
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntentBackend({
    required int amount,
    required String currency,
  }) async {
    return {
      'clientSecret': 'pi_test_secret',
      'amount': amount,
      'currency': currency,
    };
  }

  Future<void> refundPayment(String paymentId) async {
    await _refundPaymentBackend(paymentId);
  }

  Future<void> _refundPaymentBackend(String paymentId) async {
  }

  Future<double> calculateServiceFee(double amount) {
    const double serviceFeeRate = 0.05;
    const double minimumFee = 2.0;
    final fee = amount * serviceFeeRate;
    return fee < minimumFee ? minimumFee : fee;
  }

  Future<double> calculateDriverEarnings(
    double totalAmount,
    double distanceKm,
  ) async {
    const double baseRate = 10.0;
    const double perKmRate = 1.5;
    const double percentageRate = 0.15;

    final distanceFee = distanceKm * perKmRate;
    final percentageFee = totalAmount * percentageRate;
    final totalEarnings = baseRate + distanceFee + percentageFee;

    return totalEarnings;
  }

  Future<double> calculateRecyclerPayment(
    double totalAmount,
    double weightTons,
  ) async {
    const double processingFee = 5.0;
    final platformFee = totalAmount * 0.10;

    return totalAmount - processingFee - platformFee;
  }
}
