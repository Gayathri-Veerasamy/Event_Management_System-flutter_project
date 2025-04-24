// lib/pages/edit_event.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEventPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> initialData;

  const EditEventPage({
    required this.eventId,
    required this.initialData,
    Key? key,
  }) : super(key: key);

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _mediaUrlController;
  late TextEditingController _locationController;
  late TextEditingController _ticketPriceController;
  late TextEditingController _availableTicketsController;
  late TextEditingController _descriptionController;

  // Date & Time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Event Type
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
    final data = widget.initialData;

    _nameController = TextEditingController(text: data['name'] ?? '');
    _mediaUrlController = TextEditingController(text: data['mediaUrl'] ?? '');
    _locationController = TextEditingController(text: data['location'] ?? '');
    _ticketPriceController = TextEditingController(text: data['ticketPrice'] ?? '');
    _availableTicketsController =
        TextEditingController(text: data['availableTickets'] ?? '');
    _descriptionController = TextEditingController(text: data['description'] ?? '');

    _isFree = (data['ticketPrice'] ?? '') == '0';
    _isUnlimited = (data['availableTickets'] ?? '') == '-1';

    // Event type
    _selectedType = data['eventType'];

    // Parse date/time
    _selectedDate = DateTime.tryParse(data['date'] ?? '');
    final timeParts = (data['time'] ?? '00:00:00').split(':');
    _selectedTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 0,
      minute: int.tryParse(timeParts[1]) ?? 0,
    );
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

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an event type')),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please pick both date & time')),
      );
      return;
    }

    final formattedDate = _selectedDate!.toIso8601String().split('T').first;
    final formattedTime =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update({
        'name': _nameController.text.trim(),
        'mediaUrl': _mediaUrlController.text.trim(),
        'eventType': _selectedType,
        'date': formattedDate,
        'time': formattedTime,
        'location': _locationController.text.trim(),
        'ticketPrice': _isFree ? '0' : _ticketPriceController.text.trim(),
        'availableTickets': _isUnlimited
            ? '-1'
            : _availableTicketsController.text.trim(),
        'description': _descriptionController.text.trim(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Event updated!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (val) =>
            val == null || val.isEmpty ? '$label required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Update Event Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              // Name & Media URL
              _buildTextField('Event Name', _nameController),
              _buildTextField('Media URL', _mediaUrlController),

              // Event Type Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _eventTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  value: _selectedType,
                  onChanged: (v) => setState(() => _selectedType = v),
                  validator: (v) =>
                      v == null ? 'Please select an event type' : null,
                ),
              ),

              // Date Picker
              ListTile(
                title: Text(
                  'Date: ${_selectedDate != null ? _selectedDate!.toLocal().toIso8601String().split('T')[0] : 'Pick a date'}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final pd = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pd != null) setState(() => _selectedDate = pd);
                },
              ),

              // Time Picker
              ListTile(
                title: Text(
                  'Time: ${_selectedTime != null ? _selectedTime!.format(context) : 'Pick a time'}',
                ),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final pt = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                  );
                  if (pt != null) setState(() => _selectedTime = pt);
                },
              ),

              // Location
              _buildTextField('Location', _locationController),

              // Free / Paid toggle
              SwitchListTile(
                title: Text('Free Event'),
                value: _isFree,
                onChanged: (v) => setState(() => _isFree = v),
              ),
              if (!_isFree)
                _buildTextField('Ticket Price (₹)', _ticketPriceController,
                    keyboardType: TextInputType.number),

              // Unlimited slots toggle
              SwitchListTile(
                title: Text('Unlimited Slots'),
                value: _isUnlimited,
                onChanged: (v) => setState(() => _isUnlimited = v),
              ),
              if (!_isUnlimited)
                _buildTextField(
                    'Available Tickets', _availableTicketsController,
                    keyboardType: TextInputType.number),

              // Description
              _buildTextField('Description', _descriptionController,
                  maxLines: 3),

              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text('Save Changes'),
                onPressed: _updateEvent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
