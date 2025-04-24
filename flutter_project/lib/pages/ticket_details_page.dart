import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketDetailsPage extends StatefulWidget {
  final String userId;
  final String eventId;
  final Map<String, dynamic> eventData;

  const TicketDetailsPage({
    required this.userId,
    required this.eventId,
    required this.eventData,
    Key? key,
  }) : super(key: key);

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  late String qrData;
  late DateTime bookedAt;

  @override
  void initState() {
    super.initState();
    bookedAt = DateTime.now();
    qrData = generateQRData(); // QR data generated on page load
  }

  String generateQRData() {
    return '${widget.userId}_${widget.eventId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> confirmBooking() async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.eventId);
    final eventSnapshot = await eventRef.get();
    final eventData = eventSnapshot.data();
    if (eventData == null) return;

    int available = int.tryParse(eventData['availableTickets'] ?? '-1') ?? -1;

    if (available == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ No tickets available")));
      return;
    }

    if (available != -1) {
      await eventRef.update({'availableTickets': (available - 1).toString()});
    }

    // Save booking to Firestore
    await FirebaseFirestore.instance.collection('bookings').add({
      'qrCodeData': qrData,
      'userId': widget.userId,
      'eventId': widget.eventId,
      'eventName': widget.eventData['name'] ?? 'Unknown Event', // Handle null with default value
      'eventDate': widget.eventData['date'] ?? 'Unknown Date', // Handle null with default value
      'eventTime': widget.eventData['time'] ?? 'Unknown Time', // Handle null with default value
      'bookedAt': Timestamp.fromDate(bookedAt),
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🎉 Booking Confirmed!")));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.eventData;

    return Scaffold(
      appBar: AppBar(title: Text("Ticket Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("🎫 QR Code Ticket", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Center(
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 180,
                  ),
                ),
                SizedBox(height: 24),
                Text("📌 Event: ${e['name'] ?? 'Unknown Event'}"),  // Handle null
                Text("📅 Date: ${e['date'] ?? 'Unknown Date'}"),  // Handle null
                Text("🕒 Time: ${e['time'] ?? 'Unknown Time'}"),  // Handle null
                SizedBox(height: 16),
                Text("🕐 Booked At: ${bookedAt.toLocal()}"),
                SizedBox(height: 24),
                Text(
                  e['availableTickets'] == '-1'
                      ? '🎟 Tickets: Unlimited'
                      : '🎟 Tickets Left: ${e['availableTickets'] ?? 'Unknown'}', // Handle null
                  style: TextStyle(fontSize: 16),
                ),
                Spacer(),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: confirmBooking,
                    icon: Icon(Icons.check_circle),
                    label: Text("Confirm Booking"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
