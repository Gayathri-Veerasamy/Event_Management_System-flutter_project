import 'package:flutter/material.dart';
import 'ticket_details_page.dart';

class EventDetailPage extends StatelessWidget {
  final Map<String, dynamic> event;
  final String userId;

  const EventDetailPage({Key? key, required this.event, required this.userId}) : super(key: key);

  Future<void> _onBookTap(BuildContext context) async {
    final availableTickets = int.tryParse(event['availableTickets'].toString()) ?? 0;

    if (availableTickets == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Sorry, no tickets available.')),
      );
      return;
    }

    final eventId = event['id'];
    if (eventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event ID missing. Please try again.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketDetailsPage(
          userId: userId,
          eventId: eventId,
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
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
    final isFree = event['ticketPrice'] != null && event['ticketPrice'].toString() == '0';

    return Scaffold(
      appBar: AppBar(
        title: Text(event['name'] ?? 'Event Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((event['mediaUrl'] ?? '').toString().startsWith('http'))
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Image.network(
                  event['mediaUrl'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['name'] ?? '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  _buildDetailRow('Date', event['date'] ?? ''),
                  _buildDetailRow('Time', event['time'] ?? ''),
                  _buildDetailRow('Location', event['location'] ?? '', trailingIcon: const Icon(Icons.location_on)),
                  _buildDetailRow('Tickets', availableTickets < 0 ? 'Unlimited' : '$availableTickets left'),
                  _buildDetailRow('Price', isFree ? 'Free' : '₹${event['ticketPrice']}'),

                  if ((event['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(event['description']),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: availableTickets == 0 ? null : () => _onBookTap(context),
                      icon: const Icon(Icons.event_available),
                      label: Text(availableTickets == 0 ? 'Sold Out' : 'Book Ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: availableTickets == 0 ? Colors.grey : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
