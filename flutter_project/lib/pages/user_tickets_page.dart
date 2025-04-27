import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'booking_detail_page.dart';
import 'dashboard.dart';  // Import your DashboardPage

class UserTicketsPage extends StatelessWidget {
  final String userId;

  const UserTicketsPage({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    return WillPopScope(
      onWillPop: () async {
        // Navigate to the DashboardPage when back button is pressed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(
              username: userId,
              email: 'user@example.com',  // Replace with actual user data
              password: 'userpassword',   // Replace with actual user data
              userId: userId,
            ),
          ),
        );
        return false; // Prevent the default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Tickets'),
          backgroundColor: Colors.purple,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .orderBy('bookedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text("You have no tickets"));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final bookingDoc = docs[index];
                final booking = bookingDoc.data()! as Map<String, dynamic>;

                final bookingId = bookingDoc.id;
                final eventId = booking['eventId'] as String? ?? '';
                final eventName = booking['eventName'] as String? ?? 'Unknown Event';
                final eventDate = booking['eventDate'] as String? ?? 'Unknown Date';
                final eventTime = booking['eventTime'] as String? ?? 'Unknown Time';
                final bookedAt = (booking['bookedAt'] as Timestamp?)?.toDate();

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.confirmation_num, color: Colors.purple),
                    title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Date: $eventDate   Time: $eventTime\n'
                      'Booked: ${bookedAt != null ? dateFmt.format(bookedAt) : 'Unknown'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailPage(
                            booking: booking,
                            bookingId: bookingId,
                            userId: userId,
                            username: '',
                            email: '',
                            password: '',
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // 1) Confirm
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Cancel Ticket"),
                            content: const Text("Are you sure you want to cancel this ticket?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("No"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("Yes"),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true || eventId.isEmpty) return;

                        // 2) Perform transaction
                        final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);
                        final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);

                        try {
                          await FirebaseFirestore.instance.runTransaction((transaction) async {
                            final eventSnap = await transaction.get(eventRef);
                            if (!eventSnap.exists) {
                              throw Exception("Event not found");
                            }

                            final eventData = eventSnap.data()! as Map<String, dynamic>;
                            final availStr = eventData['availableTickets'] as String? ?? '-1';

                            // Only increment if not unlimited
                            if (availStr != '-1') {
                              final currentAvail = int.tryParse(availStr) ?? 0;
                              transaction.update(eventRef, {
                                'availableTickets': (currentAvail + 1).toString(),
                              });
                            }

                            transaction.delete(bookingRef);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Ticket cancelled successfully")),
                          );
                        } catch (e, stack) {
                          debugPrint("❌ Error cancelling ticket: $e");
                          debugPrint("$stack");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to cancel ticket. Try again.")),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
