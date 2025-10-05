
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/main_sidebar.dart';
import '../database.dart';

class FarmServicesPage extends StatefulWidget {
  const FarmServicesPage({super.key});

  @override
  State<FarmServicesPage> createState() => _FarmServicesPageState();
}

class _FarmServicesPageState extends State<FarmServicesPage> {
  String searchQuery = '';
  String filterStatus = 'All';
  Future<void> _editServiceDialog(Map<String, dynamic> service) async {
    final nameEdit = TextEditingController(text: service['customerName'] ?? '');
    final phoneEdit = TextEditingController(text: service['phone'] ?? '');
    final animalCropEdit = TextEditingController(text: service['animalCropType'] ?? '');
    final serviceTypeEdit = TextEditingController(text: service['serviceType'] ?? service['name'] ?? '');
    final dateEdit = TextEditingController(text: service['preferredDate'] ?? '');
    final timeEdit = TextEditingController(text: service['preferredTime'] ?? '');
    final locationEdit = TextEditingController(text: service['location'] ?? '');
    final staffEdit = TextEditingController(text: service['assignedStaff'] ?? '');
    final feeEdit = TextEditingController(text: (service['amount'] ?? '').toString());
    final notesEdit = TextEditingController(text: service['notes'] ?? '');
    String statusEdit = service['status'] ?? 'Pending';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Service'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameEdit, decoration: const InputDecoration(labelText: 'Customer Name')),
              TextField(controller: phoneEdit, decoration: const InputDecoration(labelText: 'Phone Number / Contact'), keyboardType: TextInputType.phone),
              TextField(controller: animalCropEdit, decoration: const InputDecoration(labelText: 'Animal/Crop Type')),
              TextField(controller: serviceTypeEdit, decoration: const InputDecoration(labelText: 'Service Type')),
              Row(
                children: [
                  Expanded(child: TextField(controller: dateEdit, decoration: const InputDecoration(labelText: 'Preferred Date'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: timeEdit, decoration: const InputDecoration(labelText: 'Preferred Time'))),
                ],
              ),
              TextField(controller: locationEdit, decoration: const InputDecoration(labelText: 'Location')),
              TextField(controller: staffEdit, decoration: const InputDecoration(labelText: 'Assigned Staff (optional)')),
              TextField(controller: feeEdit, decoration: const InputDecoration(labelText: 'Service Fee'), keyboardType: TextInputType.number),
              DropdownButtonFormField<String>(
                initialValue: statusEdit,
                items: ['Pending', 'Confirmed', 'Completed', 'Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => statusEdit = val ?? 'Pending',
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextField(controller: notesEdit, decoration: const InputDecoration(labelText: 'Notes/Remarks')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = Map<String, dynamic>.from(service);
              updated['customerName'] = nameEdit.text;
              updated['phone'] = phoneEdit.text;
              updated['animalCropType'] = animalCropEdit.text;
              updated['serviceType'] = serviceTypeEdit.text;
              updated['preferredDate'] = dateEdit.text;
              updated['preferredTime'] = timeEdit.text;
              updated['location'] = locationEdit.text;
              updated['assignedStaff'] = staffEdit.text;
              updated['amount'] = double.tryParse(feeEdit.text) ?? 0.0;
              updated['status'] = statusEdit;
              updated['notes'] = notesEdit.text;
              await POSDatabase.updateFarmService(updated);
              Navigator.pop(context);
              _loadServices();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(int id) async {
    await POSDatabase.deleteFarmService(id);
    _loadServices();
  }

  List<Map<String, dynamic>> get filteredServices {
    return services.where((s) {
      final matchesSearch = searchQuery.isEmpty ||
        (s['customerName'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
        (s['serviceType'] ?? s['name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
        (s['animalCropType'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
        (s['location'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());
      final matchesStatus = filterStatus == 'All' || (s['status'] ?? '') == filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final animalCropController = TextEditingController();
  final serviceTypeController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final locationController = TextEditingController();
  final staffController = TextEditingController();
  final feeController = TextEditingController();
  final notesController = TextEditingController();
  String status = 'Pending';
  List<Map<String, dynamic>> services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final dbServices = await POSDatabase.getFarmServices();
    setState(() {
      services = dbServices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Services'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const FaIcon(FontAwesomeIcons.bars),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: const Color(0xFFFFF8E1), // creamy
        elevation: 0,
      ),
      drawer: const MainSidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.cow, color: Color(0xFFFFF8E1)),
                label: const Text('Book Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade200,
                  foregroundColor: Colors.brown,
                ),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Book Farm Service'),
                        content: SingleChildScrollView(
                          child: Column(
                            children: [
                              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
                              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number / Contact'), keyboardType: TextInputType.phone),
                              TextField(controller: animalCropController, decoration: const InputDecoration(labelText: 'Animal/Crop Type')),
                              TextField(controller: serviceTypeController, decoration: const InputDecoration(labelText: 'Service Type')),
                              Row(
                                children: [
                                  Expanded(child: TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Preferred Date'))),
                                  const SizedBox(width: 8),
                                  Expanded(child: TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Preferred Time'))),
                                ],
                              ),
                              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                              TextField(controller: staffController, decoration: const InputDecoration(labelText: 'Assigned Staff (optional)')),
                              TextField(controller: feeController, decoration: const InputDecoration(labelText: 'Service Fee'), keyboardType: TextInputType.number),
                              DropdownButtonFormField<String>(
                                initialValue: status,
                                items: ['Pending', 'Confirmed', 'Completed', 'Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) => setState(() => status = val ?? 'Pending'),
                                decoration: const InputDecoration(labelText: 'Status'),
                              ),
                              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes/Remarks')),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final service = {
                                'name': serviceTypeController.text,
                                'due': dateController.text,
                                'amount': double.tryParse(feeController.text) ?? 0.0,
                                'status': status,
                              };
                              await POSDatabase.insertFarmService(service);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Service booked successfully!')));
                              nameController.clear();
                              phoneController.clear();
                              animalCropController.clear();
                              serviceTypeController.clear();
                              dateController.clear();
                              timeController.clear();
                              locationController.clear();
                              staffController.clear();
                              feeController.clear();
                              notesController.clear();
                              setState(() => status = 'Pending');
                              Navigator.pop(dialogContext);
                              _loadServices();
                            },
                            child: const Text('Book'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text('Booked Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search by customer, service, animal/crop, location',
                        prefixIcon: FaIcon(FontAwesomeIcons.magnifyingGlass, color: Colors.brown),
                        filled: true,
                        fillColor: Color(0xFFFFF8E1),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: filterStatus,
                    icon: const FaIcon(FontAwesomeIcons.angleDown, color: Colors.brown),
                    items: ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled']
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  FaIcon(
                                    s == 'All'
                                        ? FontAwesomeIcons.list
                                        : s == 'Pending'
                                            ? FontAwesomeIcons.hourglassHalf
                                            : s == 'Confirmed'
                                                ? FontAwesomeIcons.circleCheck
                                                : s == 'Completed'
                                                    ? FontAwesomeIcons.checkDouble
                                                    : FontAwesomeIcons.circleXmark,
                                    size: 16,
                                    color: Colors.brown,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(s),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => filterStatus = val ?? 'All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
        ...filteredServices.isEmpty
          ? [const Text('No services booked yet.')]
          : filteredServices.map((s) => Card(
              color: const Color(0xFFFFF8E1),
              child: ListTile(
                title: Text('${s['serviceType'] ?? s['name']} (${s['animalCropType'] ?? ''})'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer: ${s['customerName'] ?? ''}'),
                    Text('Phone: ${s['phone'] ?? ''}'),
                    Text('Date: ${s['preferredDate'] ?? ''} ${s['preferredTime'] ?? ''}'),
                    Text('Location: ${s['location'] ?? ''}'),
                    Text('Staff: ${s['assignedStaff'] ?? ''}'),
                    Text('Fee: KSh ${s['amount'] ?? ''}'),
                    Row(
                      children: [
                        const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: s['status'] ?? 'Pending',
                          icon: const FaIcon(FontAwesomeIcons.angleDown, color: Colors.brown),
                          items: ['Pending', 'Confirmed', 'Completed', 'Cancelled']
                              .map((st) => DropdownMenuItem(
                                    value: st,
                                    child: Row(
                                      children: [
                                        FaIcon(
                                          st == 'Pending'
                                              ? FontAwesomeIcons.hourglassHalf
                                              : st == 'Confirmed'
                                                  ? FontAwesomeIcons.circleCheck
                                                  : st == 'Completed'
                                                      ? FontAwesomeIcons.checkDouble
                                                      : FontAwesomeIcons.circleXmark,
                                          size: 16,
                                          color: Colors.brown,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(st),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) async {
                            final updated = Map<String, dynamic>.from(s);
                            updated['status'] = val;
                            await POSDatabase.updateFarmService(updated);
                            _loadServices();
                          },
                        ),
                      ],
                    ),
                    if ((s['notes'] ?? '').toString().isNotEmpty) Text('Notes: ${s['notes']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.orange),
                      tooltip: 'Edit',
                      onPressed: () => _editServiceDialog(s),
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _deleteService(s['id']),
                    ),
                  ],
                ),
              ),
            )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
