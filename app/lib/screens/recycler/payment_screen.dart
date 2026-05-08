import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class PaymentScreen extends StatefulWidget {
  final String haulId;
  final double amount;
  const PaymentScreen({super.key, required this.haulId, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _processing = false;

  Future<void> _processPayment() async {
    setState(() => _processing = true);
    try {
      await SupabaseService.client.functions.invoke(
        'release_payment',
        body: {'haul_id': widget.haulId, 'amount': widget.amount},
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Payment Successful'),
          content: const Text('Your payment has been processed. The hauler and developer will receive their shares.'),
          actions: [TextButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.payment, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text('Amount: \$${widget.amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('This will release payment to the hauler and developer after delivery confirmation.', textAlign: TextAlign.center),
            const Spacer(),
            ElevatedButton(
              onPressed: _processing ? null : _processPayment,
              child: _processing ? const CircularProgressIndicator() : const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }
}
