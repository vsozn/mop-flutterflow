// In FlutterFlow, custom widgets are self-contained. Here is the implementation.
import 'package:flutter/material.dart'; 
import 'dart:async'; 
import 'dart:convert'; 
import 'dart:math'; 
import 'package:qr_flutter/qr_flutter.dart'; 

class DynamicQRGenerator extends StatefulWidget { 
  const DynamicQRGenerator({
    Key? key, 
    this.width, 
    this.height, 
    required this.studentId, 
    required this.qrSize, 
    required this.primaryColor
  }) : super(key: key); 
  
  final double? width; 
  final double? height; 
  final String studentId; 
  final double qrSize; 
  final Color primaryColor; 
  
  @override 
  _DynamicQRGeneratorState createState() => _DynamicQRGeneratorState(); 
} 

class _DynamicQRGeneratorState extends State<DynamicQRGenerator> { 
  String _nonce = ""; 
  int _secondsLeft = 60; 
  Timer? _timer; 
  
  @override 
  void initState() { 
    super.initState(); 
    _refreshQR(); 
    _startTimer(); 
  } 
  
  void _refreshQR() { 
    setState(() { 
      _nonce = Random().nextInt(1000000).toString().padLeft(6, '0'); 
      _secondsLeft = 60; 
    }); 
  } 
  
  void _startTimer() { 
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) { 
      if (_secondsLeft > 0) { 
        setState(() { _secondsLeft--; }); 
      } else { 
        _refreshQR(); 
      } 
    }); 
  } 
  
  @override 
  void dispose() { 
    _timer?.cancel(); 
    super.dispose(); 
  } 
  
  @override 
  Widget build(BuildContext context) { 
    final String qrData = jsonEncode({ "sid": widget.studentId, "n": _nonce, "v": "1.0" }); 
    
    return Column( 
      mainAxisSize: MainAxisSize.min, 
      children: [ 
        Container( 
          padding: const EdgeInsets.all(12), 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), 
          child: QrImageView(
            data: qrData, 
            version: QrVersions.auto, 
            size: widget.qrSize, 
            eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: widget.primaryColor), 
            dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: widget.primaryColor)
          ) 
        ), 
        const SizedBox(height: 16), 
        Text(
          "Refreshes in ${_secondsLeft}s", 
          style: TextStyle(fontFamily: 'Readex Pro', color: Colors.grey)
        ) 
      ] 
    ); 
  } 
}
