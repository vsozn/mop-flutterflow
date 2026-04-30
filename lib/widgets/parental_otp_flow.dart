import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ParentalOTPFlowWidget extends StatefulWidget {
  final String studentName;
  final String phone;

  const ParentalOTPFlowWidget({Key? key, required this.studentName, required this.phone}) : super(key: key);

  @override
  _ParentalOTPFlowWidgetState createState() => _ParentalOTPFlowWidgetState();
}

class _ParentalOTPFlowWidgetState extends State<ParentalOTPFlowWidget> {
  bool _isLoading = false;
  bool _otpSent = false;
  String _deliveryChannel = ''; // 'whatsapp' or 'sms'
  TextEditingController _otpController = TextEditingController();
  
  // URL to the Supabase edge function
  final String _edgeFunctionUrl = 'https://api.myonepercent.in/functions/v1/parental-verify-fallback';

  Future<void> _sendOTP() async {
    setState(() { _isLoading = true; });
    try {
      // For scaffolded logic, we simulate generating a 6 digit OTP.
      String generatedOtp = '123456'; 

      final response = await http.post(
        Uri.parse(_edgeFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'otp': generatedOtp,
          'student_name': widget.studentName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _otpSent = true;
          _deliveryChannel = data['channel'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send OTP.')));
      }
    } catch (e) {
      print('Failed to send OTP: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _verifyOTP() {
    if (_otpController.text == '123456') { 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Parental Verification Successful! ✅')));
      // TODO: Proceed to next onboarding step (update DB profile)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_otpSent) {
      return Center(
        child: _isLoading 
          ? CircularProgressIndicator()
          : ElevatedButton(
              onPressed: _sendOTP,
              child: Text('Send Parental Verification OTP'),
            ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'We sent a verification code to your parent via ${_deliveryChannel.toUpperCase()}',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Enter 6-digit OTP',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _verifyOTP,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: Text('Verify Code', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
