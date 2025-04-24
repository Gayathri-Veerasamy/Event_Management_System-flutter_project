// lib/pages/user_details_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'edit_event_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text("Full Name: ${widget.username}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Email: ${widget.email}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text("Password:", style: TextStyle(fontSize: 18)),
            _isEditing
                ? TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter new password',
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(_password, style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed:
                      _isEditing ? _savePassword : () => setState(() => _isEditing = true),
                  child: Text(_isEditing ? 'Save' : 'Edit Password'),
                ),
              ],
            ),
            Divider(height: 40),
            Text('My Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  return Text("No events created yet.");
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
                      child: ListTile(
                        title: Text(data['name'] ?? 'Untitled Event'),
                        subtitle: Text(data['date'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
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
                              icon: Icon(Icons.delete, color: Colors.red),
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
    );
  }
}
