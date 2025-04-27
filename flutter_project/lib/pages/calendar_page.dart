import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_detail_page.dart';
import 'event_detail_page.dart';
import 'dashboard.dart';

class CalendarPage extends StatefulWidget {
  final String userId;

  const CalendarPage({required this.userId, Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  Map<String, List<Map<String, dynamic>>> _bookingsByDate = {};
  Map<String, List<Map<String, dynamic>>> _availableEventsByDate = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchUserBookings();
    await _fetchAvailableEvents();
  }

  Future<void> _fetchUserBookings() async {
    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: widget.userId)
        .get();

    final bookings = snap.docs.map((doc) {
      var bookingData = doc.data();
      bookingData['bookingId'] = doc.id;
      return bookingData;
    }).toList();

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var booking in bookings) {
      final dateStr = booking['eventDate'] ?? '';
      if (dateStr.isNotEmpty) {
        grouped.putIfAbsent(dateStr, () => []).add(booking);
      }
    }

    setState(() {
      _bookingsByDate = grouped;
    });
  }

  Future<void> _fetchAvailableEvents() async {
    final snap = await FirebaseFirestore.instance
        .collection('events')
        .get();

    final events = snap.docs.map((doc) {
      var eventData = doc.data();
      eventData['eventId'] = doc.id;
      return eventData;
    }).toList();

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var event in events) {
      final dateStr = event['eventDate'] ?? '';
      if (dateStr.isNotEmpty) {
        grouped.putIfAbsent(dateStr, () => []).add(event);
      }
    }

    setState(() {
      _availableEventsByDate = grouped;
    });
  }

  // Method to check if the event is in the past
  bool _isPastEvent(DateTime eventDate) {
    return eventDate.isBefore(DateTime.now());
  }

  // Method to get booked events for the selected date, past and upcoming
  List<Map<String, dynamic>> _getBookedEventsForSelectedDate() {
    if (_selectedDate == null) return [];
    final key = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    return _bookingsByDate[key] ?? [];
  }

  // Method to get available events for the selected date, past and upcoming
  List<Map<String, dynamic>> _getAvailableEventsForSelectedDate() {
    if (_selectedDate == null) return [];
    final key = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    return _availableEventsByDate[key] ?? [];
  }

  Future<bool> _onBackPressed() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardPage(
          username: widget.userId,
          email: 'user@example.com',
          password: 'userpassword',
          userId: widget.userId,
        ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final totalDays = lastDayOfMonth.day;

    List<Widget> dayWidgets = [];
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

    for (int i = 1; i <= totalDays; i++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, i);
      final isToday = DateTime.now().day == i &&
          DateTime.now().month == _focusedMonth.month &&
          DateTime.now().year == _focusedMonth.year;
      final isSelected = _selectedDate != null &&
          _selectedDate!.day == i &&
          _selectedDate!.month == _focusedMonth.month &&
          _selectedDate!.year == _focusedMonth.year;

      final hasBookingOrEvent = _bookingsByDate.containsKey(DateFormat('yyyy-MM-dd').format(date)) ||
          _availableEventsByDate.containsKey(DateFormat('yyyy-MM-dd').format(date));

      Color dayColor = isToday
          ? Colors.orange.shade100
          : hasBookingOrEvent
              ? Colors.green.shade100
              : Colors.grey.shade200;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.purple.shade100 : dayColor,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: Colors.deepOrange, width: 2)
                  : isSelected
                      ? Border.all(color: Colors.purple, width: 2)
                      : null,
            ),
            height: 40,
            child: Text(
              '$i',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.deepOrange : isSelected ? Colors.purple : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Calendar'),
          // backgroundColor: Colors.purple,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_left),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                        _selectedDate = null;
                      });
                    },
                  ),
                  Text(DateFormat.yMMMM().format(_focusedMonth), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.arrow_right),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                        _selectedDate = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((d) => Expanded(
                        child: Center(child: Text(d, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]))),
                      ))
                  .toList(),
            ),
            SizedBox(height: 8),
            Expanded(
              flex: _selectedDate == null ? 2 : 1,
              child: GridView.count(
                crossAxisCount: 7,
                children: dayWidgets,
                padding: EdgeInsets.all(8),
              ),
            ),
            if (_selectedDate != null)
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Events on ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final bookedEvents = _getBookedEventsForSelectedDate();
                          final availableEvents = _getAvailableEventsForSelectedDate();

                          if (bookedEvents.isEmpty && availableEvents.isEmpty) {
                            return Center(
                              child: Text(
                                'No events for this date',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            );
                          }

                          return ListView(
                            children: [
                              if (bookedEvents.isNotEmpty) ...[ // Past and Upcoming Booked Events
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Booked Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                ...bookedEvents.where((event) {
                                  DateTime eventDate = DateTime.parse(event['eventDate']);
                                  return _isPastEvent(eventDate);
                                }).map((event) => _buildEventTile(event, true)),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Upcoming Booked Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                ...bookedEvents.where((event) {
                                  DateTime eventDate = DateTime.parse(event['eventDate']);
                                  return !_isPastEvent(eventDate);
                                }).map((event) => _buildEventTile(event, true)),
                              ],
                              if (availableEvents.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Available Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                ...availableEvents.map((event) => _buildEventTile(event, false)),
                              ],
                            ],
                          );
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
  }

  Widget _buildEventTile(Map<String, dynamic> event, bool isBooked) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(event['eventName'] ?? ''),
        subtitle: Text(event['eventTime'] ?? ''),
        trailing: isBooked
            ? Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.event_available, color: Colors.blue),
        onTap: () {
          if (isBooked) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailPage(
                  booking: event,
                  bookingId: event['bookingId'],
                  username: widget.userId,
                  email: 'user@example.com',
                  password: 'userpassword',
                  userId: widget.userId,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailPage(
                  event: event,
                  userId: widget.userId,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
