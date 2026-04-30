import 'package:flutter/material.dart';

class DPDPLayeredNoticeWidget extends StatelessWidget {
  const DPDPLayeredNoticeWidget({Key? key, required this.onAccept, required this.onDecline}) : super(key: key);

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Privacy Notice (DPDP Act)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'What data are we collecting and why?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          _buildBulletItem('School & UDISE ID', 'To verify student status and enable school-level leaderboards.'),
          _buildBulletItem('Climate Action Proof', 'To verify CO2 savings (e.g., photos of waste segregation or cycling).'),
          _buildBulletItem('Location (City/Ward)', 'To calculate city-specific carbon math (via Climatiq) and local rankings.'),
          _buildBulletItem('Contact Details', 'For account security, impact updates, and parental notifications.'),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: onDecline,
                child: Text('Decline'),
              ),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('I Understand & Agree'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBulletItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: '$title: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
