// lib/pages/event_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ticket_details_page.dart'; // Make sure this path is correct

class EventDetailPage extends StatelessWidget {
  final Map<String, dynamic> event;
  final String userId;

  const EventDetailPage({
    Key? key,
    required this.event,
    required this.userId,
  }) : super(key: key);

  /// Navigate to the TicketDetailsPage if tickets are available
  Future<void> _onBookTap(BuildContext context) async {
    final availableTickets = int.tryParse(event['availableTickets'].toString()) ?? 0;
    if (availableTickets == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Sorry, no tickets available.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketDetailsPage(
          userId: userId,
          eventId: event['id'],
          eventData: event,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? trailingIcon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(child: Text(value)),
                if (trailingIcon != null) trailingIcon,
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableTickets = int.tryParse(event['availableTickets'].toString()) ?? 0;
    final isFree = event['ticketPrice'] == '0';

    return Scaffold(
      appBar: AppBar(
        title: Text(event['name'] ?? 'Event Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if ((event['mediaUrl'] ?? '').toString().startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Image.network(
                  event['mediaUrl'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),

            // Padding around content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event['name'] ?? '',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 12),
                  Divider(),

                  // Date & Time
                  _buildDetailRow('Date', event['date'] ?? ''),
                  _buildDetailRow('Time', event['time'] ?? ''),

                  // Location with icon
                  _buildDetailRow(
                    'Location',
                    event['location'] ?? '',
                    trailingIcon: Icon(Icons.location_on, color: Colors.blue),
                  ),

                  // Tickets left
                  _buildDetailRow(
                    'Tickets',
                    availableTickets < 0 ? 'Unlimited' : '$availableTickets left',
                  ),

                  // Price
                  _buildDetailRow('Price', isFree ? 'Free' : '₹${event['ticketPrice']}'),

                  SizedBox(height: 16),

                  // Description
                  if ((event['description'] ?? '').toString().isNotEmpty) ...[
                    Text(
                      'Description',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      event['description'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Book Ticket button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: availableTickets == 0 ? null : () => _onBookTap(context),
                      icon: Icon(Icons.event_available),
                      label: Text(
                        availableTickets == 0 ? 'Sold Out' : 'Book Ticket',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: availableTickets == 0
                            ? Colors.grey
                            : Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
