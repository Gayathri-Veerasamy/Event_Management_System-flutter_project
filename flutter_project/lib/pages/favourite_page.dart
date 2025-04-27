import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'event_detail_page.dart';
import 'dashboard.dart';  // Import the DashboardPage if it's in a different file

class FavouritePage extends StatelessWidget {
  final String userId;

  const FavouritePage({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to the DashboardPage when back button is pressed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(
              username: userId,
              email: 'user@example.com',  // You can replace with actual user data
              password: 'userpassword',   // You can replace with actual user data
              userId: userId,
            ),
          ),
        );
        return false; // Prevent the default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Favourites'),
          backgroundColor: Colors.purple,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('favorites')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No favorite events found.'));
            }

            final favoriteDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: favoriteDocs.length,
              itemBuilder: (context, index) {
                final favData = favoriteDocs[index].data() as Map<String, dynamic>;
                final eventId = favData['eventId'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
                  builder: (context, eventSnapshot) {
                    if (eventSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                      return SizedBox(); // skip if event doesn't exist
                    }

                    final eventData = eventSnapshot.data!.data() as Map<String, dynamic>;
                    final eventName = eventData['name'] ?? 'Unnamed Event';
                    final eventDate = eventData['date'] ?? '';
                    final location = eventData['location'] ?? '';
                    final mediaUrl = eventData['mediaUrl'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        eventData['id'] = eventSnapshot.data!.id;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailPage(event: eventData, userId: userId),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            mediaUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.network(
                                      mediaUrl,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 100),
                                    ),
                                  )
                                : Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    child: Icon(Icons.event, size: 100, color: Colors.grey[700]),
                                  ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eventName,
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      SizedBox(width: 6),
                                      Text(eventDate),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                                      SizedBox(width: 6),
                                      Text(location),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
