import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_controller.dart';
import '../../../core/utils/logger.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _canResend = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _submitPhone() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    
    // Add default country code if missing
    final number = phone.startsWith('+') ? phone : '+1$phone'; // Assuming US default for MVP
    
    // Log intent
    log.i('[LOGIN] Submitting phone number: $number');
    
    ref.read(authControllerProvider.notifier).sendCode(number);
  }

  void _submitOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;
    
    log.i('[LOGIN] Submitting OTP');
    ref.read(authControllerProvider.notifier).verifyOtp(otp);
  }

  void _resendCode() {
    if (!_canResend) return;
    _startResendTimer();
    _submitPhone();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isCodeSent = authState.verificationId != null;
    final isLoading = authState.status == AuthStatus.loading;

    // Side Effects
    ref.listen(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.codeSent && prev?.status != AuthStatus.codeSent) {
        _startResendTimer();
      }
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'FillExchange',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              if (!isCodeSent) _buildPhoneInput(isLoading),
              if (isCodeSent) _buildOtpInput(isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Sign in with Phone',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: 'e.g. 555-555-5555',
            prefixText: '+1 ',
            border: OutlineInputBorder(),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: isLoading ? null : _submitPhone,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send Verification Code'),
        ),
      ],
    );
  }

  Widget _buildOtpInput(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter Verification Code',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Sent to +1 ${_phoneController.text}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: const InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(),
          ),
          enabled: !isLoading,
          onChanged: (val) {
             if (val.length == 6) _submitOtp();
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: isLoading ? null : _submitOtp,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Verify'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _canResend ? _resendCode : null,
          child: Text(_canResend 
            ? 'Resend Code' 
            : 'Resend in $_secondsRemaining s'
          ),
        ),
        TextButton(
          onPressed: () {
            ref.read(authControllerProvider.notifier).reset();
          },
          child: const Text('Change Number'),
        ),
      ],
    );
  }
}
