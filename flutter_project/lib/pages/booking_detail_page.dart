import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'custom_bottom_nav.dart';
import 'dashboard.dart';
import 'user_tickets_page.dart';
import 'user_details.dart';
import 'calendar_page.dart';

class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final String bookingId;
  final String username;
  final String email;
  final String password;
  final String userId;

  const BookingDetailPage({
    Key? key,
    required this.booking,
    required this.bookingId,
    required this.username,
    required this.email,
    required this.password,
    required this.userId,
  }) : super(key: key);

  @override
  _BookingDetailPageState createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  int _navIndex = 1; // default to “My Tickets”

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    Widget destination;
    switch (index) {
      case 0:
        destination = DashboardPage(
          username: widget.username,
          email: widget.email,
          password: widget.password,
          userId: widget.userId,
        );
        break;
      case 1:
        destination = UserTicketsPage(userId: widget.userId);
        break;
      case 2:
        destination = UserDetailsPage(
          username: widget.username,
          email: widget.email,
          password: widget.password,
          userId: widget.userId,
        );
        break;
      case 3:
        destination = CalendarPage(userId: widget.userId);
        break;
      default:
        return;
    }

    // Push and replace the current screen with the selected one
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text("$label:", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData = widget.booking['qrCodeData'] as String? ?? widget.bookingId;
    final eventName = widget.booking['eventName'] ?? '';
    final eventDate = widget.booking['eventDate'] ?? '';
    final eventTime = widget.booking['eventTime'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('Ticket Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('🎫 Your Ticket', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            QrImageView(data: qrData, size: 200),
            SizedBox(height: 24),
            _detailRow('Event', eventName),
            _detailRow('Date', eventDate),
            _detailRow('Time', eventTime),
            _detailRow('Booking ID', widget.bookingId),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _navIndex,
        onTabChange: _onNavTap,
      ),
    );
  }
}
