import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../providers/auth_controller.dart';
import '../../../core/utils/logger.dart';

enum AuthMethod { phone, email }
enum EmailMode { signIn, signUp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Stores the full international phone number (e.g. +213XXXXXXXXX)
  String _fullPhoneNumber = '';
  bool _phoneValid = false;

  AuthMethod _authMethod = AuthMethod.phone;
  EmailMode _emailMode = EmailMode.signIn;
  bool _obscurePassword = true;

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _canResend = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
    if (!_phoneValid || _fullPhoneNumber.isEmpty) return;

    log.i('[LOGIN] Submitting phone number: $_fullPhoneNumber');
    ref.read(authControllerProvider.notifier).sendCode(_fullPhoneNumber);
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

  void _submitEmail() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;
    // Basic validation
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.orange),
      );
      return;
    }

    log.i('[LOGIN] Submitting Email Auth: $_emailMode');
    if (_emailMode == EmailMode.signIn) {
      ref.read(authControllerProvider.notifier).signInWithEmail(email, password);
    } else {
      ref.read(authControllerProvider.notifier).signUpWithEmail(email, password);
    }
  }


  void _toggleEmailMode() {
    setState(() {
      _emailMode = _emailMode == EmailMode.signIn ? EmailMode.signUp : EmailMode.signIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isCodeSent = authState.status == AuthStatus.codeSent;
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
      if (next.status == AuthStatus.emailVerificationRequired) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Check your Email'),
            content: const Text(
                'A confirmation link has been sent to your email address. Please verify your email to complete registration.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Optionally switch to sign in mode
                  setState(() => _emailMode = EmailMode.signIn);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      if (next.status == AuthStatus.passwordResetSent) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email.')),
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
              
              if (!isCodeSent) ...[
                // Auth Method Selector
                if (!isLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMethodChip('Phone', AuthMethod.phone),
                      const SizedBox(width: 16),
                      _buildMethodChip('Email', AuthMethod.email),
                    ],
                  ),
                const SizedBox(height: 32),

                if (_authMethod == AuthMethod.phone) _buildPhoneInput(isLoading),
                if (_authMethod == AuthMethod.email) _buildEmailInput(isLoading),
              ],
              if (isCodeSent) _buildOtpInput(isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodChip(String label, AuthMethod method) {
    final isSelected = _authMethod == method;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _authMethod = method);
      },
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
        IntlPhoneField(
          controller: _phoneController,
          initialCountryCode: 'DZ', // Algeria default; user can change
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          enabled: !isLoading,
          onChanged: (phone) {
            _fullPhoneNumber = phone.completeNumber;
            _phoneValid = true;
          },
          onCountryChanged: (_) {
            _fullPhoneNumber = '';
            _phoneValid = false;
          },
          invalidNumberMessage: 'Invalid phone number',
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: (isLoading || !_phoneValid) ? null : _submitPhone,
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

  Widget _buildEmailInput(bool isLoading) {
    final isSignIn = _emailMode == EmailMode.signIn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isSignIn ? 'Sign In' : 'Create Account',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
            border: OutlineInputBorder(),
          ),
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          enabled: !isLoading,
        ),
        if (isSignIn)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : _showForgotPasswordDialog,
              child: const Text('Forgot Password?'),
            ),
          ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: isLoading ? null : _submitEmail,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isSignIn ? 'Sign In' : 'Sign Up'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: isLoading ? null : _toggleEmailMode,
          child: Text(isSignIn 
            ? 'Don\'t have an account? Sign Up' 
            : 'Already have an account? Sign In'
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to receive a password reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                ref.read(authControllerProvider.notifier).sendPasswordResetEmail(email);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}
