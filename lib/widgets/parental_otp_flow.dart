import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class ParentalOTPFlowWidget extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String phone;
  final VoidCallback? onVerified;

  const ParentalOTPFlowWidget({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.phone,
    this.onVerified,
  }) : super(key: key);

  @override
  _ParentalOTPFlowWidgetState createState() => _ParentalOTPFlowWidgetState();
}

class _ParentalOTPFlowWidgetState extends State<ParentalOTPFlowWidget> {
  bool _isLoading = false;
  bool _otpSent = false;
  String _deliveryChannel = ''; // 'whatsapp' or 'sms'
  final TextEditingController _otpController = TextEditingController();

  final String _edgeFunctionUrl =
      'https://api.myonepercent.in/functions/v1/parental-verify-fallback';

  Future<void> _sendOTP() async {
    setState(() { _isLoading = true; });
    try {
      // OTP is generated and stored server-side; we pass the phone number.
      final response = await http.post(
        Uri.parse(_edgeFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'student_name': widget.studentName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _otpSent = true;
            _deliveryChannel = data['channel'] ?? 'sms';
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to send OTP.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _verifyOTP() async {
    // TODO: replace client-side check with a server-side verify-otp call.
    if (_otpController.text.trim() != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')));
      return;
    }

    setState(() { _isLoading = true; });
    try {
      await Supabase.instance.client.from('parental_consents').upsert({
        'student_id': widget.studentId,
        'parent_mobile': widget.phone,
        'status': 'verified',
        'consent_timestamp': DateTime.now().toUtc().toIso8601String(),
        'notice_version': 'v1.0',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parental Verification Successful! ✅')));
        widget.onVerified?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save verification: $e')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_otpSent) {
      return Center(
        child: ElevatedButton(
          onPressed: _sendOTP,
          child: const Text('Send Parental Verification OTP'),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'We sent a verification code to your parent via ${_deliveryChannel.toUpperCase()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter 6-digit OTP',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _verifyOTP,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: const Text('Verify Code', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
