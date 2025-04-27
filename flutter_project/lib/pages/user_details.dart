// lib/pages/user_details_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart';
import 'login.dart';
import 'edit_event_page.dart';
import 'custom_bottom_nav.dart'; // Your custom bottom nav

class UserDetailsPage extends StatefulWidget {
  final String username;
  final String email;
  final String password;
  final String userId;

  const UserDetailsPage({
    required this.username,
    required this.email,
    required this.password,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  late String _password;
  bool _isEditing = false;
  final _passwordController = TextEditingController();
  int _selectedIndex = 4; // Assuming 4th tab is Profile

  @override
  void initState() {
    super.initState();
    _password = widget.password;
    _passwordController.text = _password;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final newPassword = _passwordController.text.trim();
    if (newPassword.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'password': newPassword});

      setState(() {
        _password = newPassword;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            username: widget.username,
            email: widget.email,
            password: widget.password,
            userId: widget.userId,
          ),
        ),
      );
    }
    // Add navigation for other tabs if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // User Info
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(widget.username,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text(widget.email, style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 20),

            // Password Edit Section
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Password',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    _isEditing
                        ? TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline),
                              hintText: 'Enter new password',
                              border: OutlineInputBorder(),
                            ),
                          )
                        : Text('•' * _password.length,
                            style: TextStyle(fontSize: 16)),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: _savePassword,
                            child: Text('Save'),
                          ),
                        if (_isEditing) SizedBox(width: 10),
                        if (_isEditing)
                          OutlinedButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: Text('Cancel'),
                          ),
                        if (!_isEditing)
                          OutlinedButton(
                            onPressed: () => setState(() => _isEditing = true),
                            child: Text('Edit Password'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Events Section
            Text('My Events',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('createdBy', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final events = snapshot.data?.docs ?? [];
                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("No events created yet.")),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final eventDoc = events[index];
                    final data = eventDoc.data()! as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        title: Text(data['name'] ?? 'Untitled Event',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['date'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditEventPage(
                                      eventId: eventDoc.id,
                                      initialData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_forever,
                                  color: Colors.redAccent),
                              onPressed: () => _deleteEvent(eventDoc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabTapped,
      ),
    );
  }
}
