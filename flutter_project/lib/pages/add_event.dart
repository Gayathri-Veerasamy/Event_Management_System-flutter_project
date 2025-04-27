import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart';  // Import your DashboardPage

class AddEventPage extends StatefulWidget {
  final String userId;

  const AddEventPage({required this.userId, Key? key}) : super(key: key);

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _mediaUrlController;
  late TextEditingController _locationController;
  late TextEditingController _ticketPriceController;
  late TextEditingController _availableTicketsController;
  late TextEditingController _descriptionController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _eventTypes = [
    'Concert',
    'Workshop',
    'Meetup',
    'Festival',
    'Conference',
    'Webinar',
    'Other',
  ];
  String? _selectedType;

  bool _isFree = false;
  bool _isUnlimited = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _mediaUrlController = TextEditingController();
    _locationController = TextEditingController();
    _ticketPriceController = TextEditingController();
    _availableTicketsController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mediaUrlController.dispose();
    _locationController.dispose();
    _ticketPriceController.dispose();
    _availableTicketsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please choose an event type')),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both date and time')),
      );
      return;
    }

    final date = _selectedDate!.toIso8601String().split('T')[0];
    final time =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

    final price = _isFree ? '0' : (_ticketPriceController.text.isNotEmpty ? _ticketPriceController.text.trim() : '0');
    final slots = _isUnlimited ? '-1' : (_availableTicketsController.text.isNotEmpty ? _availableTicketsController.text.trim() : '0');

    try {
      await FirebaseFirestore.instance.collection('events').add({
        'name': _nameController.text.trim(),
        'mediaUrl': _mediaUrlController.text.trim(),
        'eventType': _selectedType,
        'date': date,
        'time': time,
        'location': _locationController.text.trim(),
        'ticketPrice': price,
        'availableTickets': slots,
        'description': _descriptionController.text.trim(),
        'createdBy': widget.userId,  // Added the user ID to associate with this event
        'createdAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event created successfully')),
      );

      // After the event is saved, navigate back to DashboardPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            username: widget.userId,
            email: 'user@example.com',  // Replace with actual user data
            password: 'userpassword',   // Replace with actual user data
            userId: widget.userId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating event: $e')),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? inputType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? '$label required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to the DashboardPage when back button is pressed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(
              username: widget.userId,
              email: 'user@example.com',  // Replace with actual user data
              password: 'userpassword',   // Replace with actual user data
              userId: widget.userId,
            ),
          ),
        );
        return false; // Prevent the default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Add Event')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text("Add Event Details",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),

                _buildTextField('Event Name', _nameController),
                _buildTextField('Media URL (image/video)', _mediaUrlController),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Event Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _eventTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    value: _selectedType,
                    onChanged: (val) => setState(() => _selectedType = val),
                    validator: (val) =>
                        val == null ? 'Please select an event type' : null,
                  ),
                ),

                ListTile(
                  title: Text(
                    'Date: ${_selectedDate != null ? _selectedDate!.toLocal().toIso8601String().split("T")[0] : 'Pick a date'}',
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),

                ListTile(
                  title: Text(
                    'Time: ${_selectedTime != null ? _selectedTime!.format(context) : 'Pick a time'}',
                  ),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedTime = picked);
                    }
                  },
                ),

                _buildTextField('Location', _locationController),

                SwitchListTile(
                  title: Text('Free Event'),
                  value: _isFree,
                  onChanged: (v) => setState(() => _isFree = v),
                ),
                if (!_isFree)
                  _buildTextField('Ticket Price (₹)', _ticketPriceController,
                      inputType: TextInputType.number),

                SwitchListTile(
                  title: Text('Unlimited Slots'),
                  value: _isUnlimited,
                  onChanged: (v) => setState(() => _isUnlimited = v),
                ),
                if (!_isUnlimited)
                  _buildTextField(
                      'Available Tickets', _availableTicketsController,
                      inputType: TextInputType.number),

                _buildTextField('Description', _descriptionController,
                    maxLines: 3),

                SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text('Save Event'),
                  onPressed: _saveEvent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
