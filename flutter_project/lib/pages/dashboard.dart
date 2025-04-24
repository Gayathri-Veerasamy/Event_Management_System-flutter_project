import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_event.dart';
import 'event_detail_page.dart';
import 'user_details.dart';
import 'user_tickets_page.dart';
import 'calendar_page.dart';
import 'favourite_page.dart'; // ← import the new FavouritePage
import 'custom_bottom_nav.dart'; // ← import your new nav

class DashboardPage extends StatefulWidget {
  final String username;
  final String email;
  final String password;
  final String userId;

  const DashboardPage({
    required this.username,
    required this.email,
    required this.password,
    required this.userId,
    super.key,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  Timer? _timer;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildDashboard(), // Home - Dashboard Page
      UserTicketsPage(userId: widget.userId), // Ticket - User Tickets Page
      AddEventPage(userId: widget.userId), // + - Add Event Page
      FavouritePage(userId: widget.userId), // Favourite - Favourite Page
      CalendarPage(userId: widget.userId), // Calendar - Calendar Page
    ];

    // Listen to changes in the search input and update the search query
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Keep the timer for countdown updates
    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String? _getCountdown(String? date, String? time) {
    if (date == null || time == null) return null;
    try {
      final eventDateTime = DateTime.parse("$date $time");
      final now = DateTime.now();
      final duration = eventDateTime.difference(now);

      if (duration.isNegative) return "Started";
      if (duration.inDays >= 1) {
        return "${duration.inDays} day${duration.inDays > 1 ? 's' : ''} left";
      } else {
        final h = duration.inHours;
        final m = duration.inMinutes % 60;
        return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} left";
      }
    } catch (_) {
      return null;
    }
  }

  Widget _buildDashboard() {
    final now = DateTime.now();
    final nextWeek = now.add(Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        final allDocs = snap.data!.docs;
        if (allDocs.isEmpty) return Center(child: Text("No events"));

        // Filter events by search query
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data()! as Map<String, dynamic>;
          final name = (data['name'] ?? '').toLowerCase();
          final location = (data['location'] ?? '').toLowerCase();
          return name.contains(_searchQuery) || location.contains(_searchQuery);
        }).toList();

        // Filter & sort upcoming events
        final sorted = filteredDocs
            .where((d) {
              final dt = DateTime.tryParse(
                      (d.data() as Map<String, dynamic>)['date'] ?? '') ?? 
                  now;
              return dt.isAfter(now);
            })
            .toList()
              ..sort((a, b) {
                final da = DateTime.tryParse(
                        (a.data() as Map<String, dynamic>)['date'] ?? '') ?? 
                    now;
                final db = DateTime.tryParse(
                        (b.data() as Map<String, dynamic>)['date'] ?? '') ?? 
                    now;
                return da.compareTo(db);
              });

        final top5 = sorted.take(5).toList();
        final upcomingWeek = sorted.where((d) {
          final dt = DateTime.tryParse(
                  (d.data() as Map<String, dynamic>)['date'] ?? '') ?? 
              now;
          return dt.isAfter(now) && dt.isBefore(nextWeek);
        }).toList();
        final remainingEvents = sorted;

        return SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.deepPurpleAccent, Colors.purple]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔥 Next thrilling events — tap to view details & book! 🔥',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Events',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            // Top 5 Carousel
            if (top5.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: top5.length,
                  itemBuilder: (_, i) {
                    final doc = top5[i];
                    final data = doc.data()! as Map<String, dynamic>;
                    data['id'] = doc.id;
                    final img = data['mediaUrl'] ?? '';
                    bool isFavorited = false;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EventDetailPage(event: data, userId: widget.userId),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            margin: EdgeInsets.only(
                                left: i == 0 ? 16 : 8,
                                right: i == top5.length - 1 ? 16 : 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: img.startsWith('http')
                                  ? Image.network(img, fit: BoxFit.cover)
                                  : Container(color: Colors.grey[300]),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                isFavorited ? Icons.favorite : Icons.favorite_border,
                                color: isFavorited ? Colors.red : Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  isFavorited = !isFavorited;
                                });

                                // Add or remove from favorites (update Firestore)
                                if (isFavorited) {
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.userId)
                                      .collection('favorites')
                                      .add({
                                    'eventId': data['id'],
                                    'eventName': data['name'],
                                    'eventDate': data['date'],
                                  });
                                } else {
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.userId)
                                      .collection('favorites')
                                      .where('eventId', isEqualTo: data['id'])
                                      .get()
                                      .then((snapshot) {
                                    snapshot.docs.forEach((doc) {
                                      doc.reference.delete();
                                    });
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Upcoming This Week
            if (upcomingWeek.isNotEmpty) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Upcoming This Week",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingWeek.length,
                  itemBuilder: (_, i) {
                    final doc = upcomingWeek[i];
                    final data = doc.data()! as Map<String, dynamic>;
                    data['id'] = doc.id;
                    final img = data['mediaUrl'] ?? '';
                    final countdown =
                        _getCountdown(data['date'], data['time']);
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EventDetailPage(event: data, userId: widget.userId),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: 150,
                            margin: EdgeInsets.only(
                                left: i == 0 ? 16 : 8,
                                right:
                                    i == upcomingWeek.length - 1 ? 16 : 8),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              clipBehavior: Clip.antiAlias,
                              elevation: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: img.startsWith('http')
                                        ? Image.network(img, fit: BoxFit.cover)
                                        : Container(color: Colors.grey[300]),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(data['name'] ?? '',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        SizedBox(height: 4),
                                        Text(data['location'] ?? '',
                                            style: TextStyle(fontSize: 10)),
                                        SizedBox(height: 4),
                                        if (countdown != null)
                                          Text(countdown,
                                              style: TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
