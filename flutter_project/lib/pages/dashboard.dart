import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_event.dart';
import 'event_detail_page.dart';
import 'user_tickets_page.dart';
import 'calendar_page.dart';
import 'favourite_page.dart';
import 'custom_bottom_nav.dart';
import 'user_details.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _favoritedEventIds = {};
  List<QueryDocumentSnapshot> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadFavorites();
    _fetchEvents();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadFavorites() async {
    final favs = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('favorites')
        .get();
    setState(() {
      _favoritedEventIds = favs.docs.map((d) => d['eventId'] as String).toSet();
    });
  }

  Future<void> _fetchEvents() async {
    FirebaseFirestore.instance
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _allEvents = snapshot.docs;
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  String? _getCountdown(String? date, String? time) {
    if (date == null || time == null) return null;
    try {
      final eventDateTime = DateTime.parse('$date $time');
      final now = DateTime.now();
      final diff = eventDateTime.difference(now);
      if (diff.isNegative) return 'Started';
      if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} left';
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      return '$h:$m left';
    } catch (_) {
      return null;
    }
  }

  Widget _buildDashboardBody() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _allEvents.where((doc) {
      final data = doc.data()! as Map<String, dynamic>;
      final name = (data['name'] ?? '').toLowerCase();
      final location = (data['location'] ?? '').toLowerCase();
      return name.contains(_searchQuery) || location.contains(_searchQuery);
    }).toList();

    final upcoming = filtered.where((doc) {
      final d = DateTime.tryParse((doc.data()! as Map)['date'] ?? '') ?? now;
      return d.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse((a.data()! as Map)['date'] ?? '') ?? now;
        final db = DateTime.tryParse((b.data()! as Map)['date'] ?? '') ?? now;
        return da.compareTo(db);
      });

    final top5 = upcoming.take(5).toList();
    final weekList = upcoming.where((doc) {
      final d = DateTime.tryParse((doc.data()! as Map)['date'] ?? '') ?? now;
      return d.isBefore(nextWeek);
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Events',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Heading
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Next Thrilling Events — Tap a Banner to View Details!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Banner Carousel
          Padding(
            padding: const EdgeInsets.all(16),
            child: BannerCarousel(events: top5, userId: widget.userId),
          ),

          const SizedBox(height: 16),

          if (_searchQuery.isNotEmpty) ...[
            if (upcoming.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No events found!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else
              _buildEventList(upcoming),
          ]
          else ...[ 
            if (weekList.isNotEmpty) ...[ 
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Upcoming This Week',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: weekList.length,
                  itemBuilder: (_, i) => _buildWeekCard(weekList[i]),
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'All Upcoming Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildEventList(upcoming),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekCard(QueryDocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final img = data['mediaUrl'] ?? '';
    final countdown = _getCountdown(data['date'], data['time']);
    final eventData = {...data, 'id': doc.id}; // <-- attach the doc.id

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailPage(event: eventData, userId: widget.userId),
        ),
      ),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(data['location'] ?? '', style: const TextStyle(fontSize: 10)),
                    if (countdown != null)
                      Text(countdown, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventList(List<QueryDocumentSnapshot> events) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: events.length,
      itemBuilder: (_, i) {
        final doc = events[i];
        final data = doc.data()! as Map<String, dynamic>;
        final img = data['mediaUrl'] ?? '';
        final isFav = _favoritedEventIds.contains(doc.id);
        final countdown = _getCountdown(data['date'], data['time']);
        final eventData = {...data, 'id': doc.id}; // <-- attach the doc.id

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: eventData, userId: widget.userId),
            ),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                img.startsWith('http')
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(img, height: 180, width: double.infinity, fit: BoxFit.cover),
                      )
                    : Container(height: 180, color: Colors.grey[300]),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(data['location'] ?? '', style: TextStyle(color: Colors.grey[600])),
                      if (data['date'] != null) Text('Date: ${data['date']}'),
                      if (data['time'] != null) Text('Time: ${data['time']}'),
                      if (countdown != null)
                        Text('Starts in: $countdown', style: const TextStyle(color: Colors.deepPurple)),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                          onPressed: () async {
                            final eventId = doc.id;
                            final favRef = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('favorites');
                            if (isFav) {
                              final snap = await favRef.where('eventId', isEqualTo: eventId).get();
                              for (final d in snap.docs) {
                                await d.reference.delete();
                              }
                              setState(() => _favoritedEventIds.remove(eventId));
                            } else {
                              await favRef.add({
                                'eventId': eventId,
                                'eventName': data['name'],
                                'eventDate': data['date'],
                                'mediaUrl': data['mediaUrl'],
                              });
                              setState(() => _favoritedEventIds.add(eventId));
                            }
                          },
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardBody(),
      UserTicketsPage(userId: widget.userId),
      AddEventPage(userId: widget.userId),
      FavouritePage(userId: widget.userId),
      CalendarPage(userId: widget.userId),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Dashboard'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailsPage(
                          username: widget.username,
                          email: widget.email,
                          password: widget.password,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTabChange: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class BannerCarousel extends StatelessWidget {
  final List<QueryDocumentSnapshot> events;
  final String userId;

  const BannerCarousel({Key? key, required this.events, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        itemBuilder: (context, index) {
          final doc = events[index];
          final data = doc.data()! as Map<String, dynamic>;
          final eventData = {...data, 'id': doc.id}; // <-- attach the doc.id

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailPage(event: eventData, userId: userId),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(data['mediaUrl'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
