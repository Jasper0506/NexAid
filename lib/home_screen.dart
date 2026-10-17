import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

// ⚠️ IMPORTANT: Adjust this import path to match where your login_page.dart is located!
import '../pages/login_page.dart';

class AppSettings {
  static final ValueNotifier<bool> highContrastMode = ValueNotifier(false);
  static final ValueNotifier<double> fontSize = ValueNotifier(16.0);

  static bool voiceCommandEnabled = true;
  static bool vibrationAlertsEnabled = true;
  static bool flashAlertEnabled = true;
}

// ---------------------------------------------------------
// CONTACT MODEL
// ---------------------------------------------------------
class EmergencyContact {
  String key;
  String name;
  String phone;
  String relationship;
  String category;

  EmergencyContact({
    required this.key,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.category,
  });

  factory EmergencyContact.fromMap(String key, Map<dynamic, dynamic> map) {
    return EmergencyContact(
      key: key,
      name: map['name'] ?? 'Unknown',
      phone: map['phone'] ?? '',
      relationship: map['relationship'] ?? 'Contact',
      category: map['category'] ?? 'Emergency Contacts',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'category': category,
    };
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return 'Emergency Contacts';
      case 1: return 'NexAid';
      case 2: return 'Profile';
      default: return 'NexAid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.highContrastMode,
      builder: (context, isHC, _) {
        return ValueListenableBuilder<double>(
          valueListenable: AppSettings.fontSize,
          builder: (context, fontSizeValue, _) {
            final List<Widget> pages = [
              ContactsPage(isHC: isHC),
              HomeDashboardContent(),
              ProfilePage(),
            ];

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: isHC
                  ? ThemeData.dark().copyWith(
                scaffoldBackgroundColor: Colors.black,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  backgroundColor: Colors.black,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white60,
                ),
              )
                  : ThemeData.light().copyWith(
                scaffoldBackgroundColor: Colors.white,
                appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFF3B30)),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  backgroundColor: Colors.white,
                  selectedItemColor: Color(0xFFFF3B30),
                  unselectedItemColor: Colors.grey,
                ),
              ),
              home: Scaffold(
                backgroundColor: isHC ? Colors.black : Colors.white,
                appBar: AppBar(
                  elevation: 0,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedIndex == 0 ? Icons.contacts : Icons.emergency,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getAppBarTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                ),
                body: pages[_selectedIndex],
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.contacts, size: 28), label: 'Contact List'),
                    BottomNavigationBarItem(icon: Icon(Icons.home, size: 28), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.person, size: 28), label: 'Profile'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------
// CONTACTS PAGE (WITH SIM/PHONEBOOK IMPORT)
// ---------------------------------------------------------
class ContactsPage extends StatefulWidget {
  final bool isHC;
  const ContactsPage({super.key, required this.isHC});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (currentUser == null) return;

    try {
      final DatabaseReference contactsRef = FirebaseDatabase.instance
          .ref('users/${currentUser!.uid}/contacts');

      final snapshot = await contactsRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<EmergencyContact> loaded = [];
        data.forEach((key, value) {
          loaded.add(EmergencyContact.fromMap(key.toString(), value as Map<dynamic, dynamic>));
        });
        if (mounted) {
          setState(() {
            _contacts = loaded;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddContactOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFFFF3B30), size: 28),
                title: const Text('Add Manually', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _addContactManually();
                },
              ),
              ListTile(
                leading: const Icon(Icons.contact_phone, color: Color(0xFFFF3B30), size: 28),
                title: const Text('Import from Phone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _importFromPhone();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addContactManually() async {
    final String? name = await _showInputDialog('Contact Name', 'e.g., Mother');
    if (name == null || name.isEmpty) return;

    final String? phone = await _showInputDialog('Phone Number', 'e.g., 09171234567');
    if (phone == null || phone.isEmpty) return;

    final String? relationship = await _showInputDialog('Relationship', 'e.g., Mother, Father, Caregiver');
    if (relationship == null || relationship.isEmpty) return;

    await _saveContactToFirebase(name, phone, relationship);
  }

  // ✅ FIXED: Using getAll with properties parameter for version 2.6.0
  Future<void> _importFromPhone() async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission to read contacts is required.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // CORRECT METHOD FOR VERSION 2.6.0
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.name, ContactProperty.phone},
      );

      if (!mounted) return;

      final validContacts = contacts.where((c) => c.phones.isNotEmpty).toList();

      if (validContacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts with phone numbers found on this device.')),
        );
        return;
      }

      _showPhoneContactsDialog(validContacts);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing contacts: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPhoneContactsDialog(List<Contact> contacts) {
    List<Contact> filteredContacts = contacts;
    final searchController = TextEditingController();
    final bool isHC = widget.isHC;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isHC ? Colors.black : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Select a Contact',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isHC ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: searchController,
                    style: TextStyle(color: isHC ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search name or number...',
                      hintStyle: TextStyle(color: isHC ? Colors.white54 : Colors.grey),
                      prefixIcon: Icon(Icons.search, color: isHC ? Colors.white54 : Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isHC ? Colors.white54 : Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF3B30)),
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        filteredContacts = contacts.where((c) {
                          final name = (c.displayName ?? '').toLowerCase();
                          final phone = c.phones.first.number;
                          final search = value.toLowerCase();
                          return name.contains(search) || phone.contains(search);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        final phone = contact.phones.first.number;
                        final displayName = contact.displayName ?? 'Unknown Contact';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFF3B30).withOpacity(0.2),
                            child: const Icon(Icons.person, color: Color(0xFFFF3B30)),
                          ),
                          title: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isHC ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            phone,
                            style: TextStyle(color: isHC ? Colors.white70 : Colors.black54),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _promptRelationshipAndSave(displayName, phone);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _promptRelationshipAndSave(String name, String phone) async {
    final String? relationship = await _showInputDialog(
        'Relationship to $name',
        'e.g., Mother, Caregiver, Doctor'
    );
    if (relationship == null || relationship.isEmpty) return;

    await _saveContactToFirebase(name, phone, relationship);
  }

  Future<void> _saveContactToFirebase(String name, String phone, String relationship) async {
    final category = relationship.toLowerCase().contains('care')
        ? 'Caregivers'
        : 'Emergency Contacts';

    final newRef = FirebaseDatabase.instance
        .ref('users/${currentUser!.uid}/contacts')
        .push();

    await newRef.set({
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'category': category,
    });

    await _loadContacts();
  }

  Future<String?> _showInputDialog(String title, String hint) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: title == 'Phone Number' ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(hintText: hint),
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteContact(String key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: const Text('This contact will be removed from your emergency list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseDatabase.instance
          .ref('users/${currentUser!.uid}/contacts/$key')
          .remove();
      await _loadContacts();
    }
  }

  Future<void> _callContact(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot call $phone')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHC = widget.isHC;
    final Color bgColor = isHC ? Colors.black : Colors.white;
    final Color textColor = isHC ? Colors.white : Colors.black;
    final Color tileColor = isHC ? Colors.grey.shade900 : const Color(0xFFF2F2F2);
    final Color dividerColor = isHC ? Colors.white24 : Colors.black12;
    final Color accentColor = isHC ? Colors.white : const Color(0xFFFF3B30);

    final emergencyContacts = _contacts.where((c) => c.category == 'Emergency Contacts').toList();
    final caregivers = _contacts.where((c) => c.category == 'Caregivers').toList();

    if (_isLoading) {
      return Container(
        color: bgColor,
        child: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (emergencyContacts.isNotEmpty) ...[
                for (final contact in emergencyContacts)
                  _buildContactTile(contact, textColor, tileColor, accentColor),
              ] else if (_contacts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No contacts yet.\nTap the + button to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.6)),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              Divider(color: dividerColor),
              const SizedBox(height: 10),

              if (caregivers.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHC ? Colors.grey.shade900 : Colors.white,
                    border: Border.all(color: accentColor, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Caregivers',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (final contact in caregivers)
                  _buildContactTile(contact, textColor, tileColor, accentColor),
              ] else if (emergencyContacts.isNotEmpty) ...[
                Text(
                  'No caregivers added yet.',
                  style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.5), fontStyle: FontStyle.italic),
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),

          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _showAddContactOptions,
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 28),
              label: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(EmergencyContact contact, Color textColor, Color tileColor, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: textColor.withOpacity(0.7), size: 26),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.relationship.isNotEmpty ? contact.relationship : contact.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                ),
                if (contact.name != contact.relationship)
                  Text(
                    contact.name,
                    style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6)),
                  ),
              ],
            ),
          ),

          IconButton(
            icon: Icon(Icons.phone, color: accentColor, size: 24),
            onPressed: () => _callContact(contact.phone),
            tooltip: 'Call ${contact.name}',
          ),

          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteContact(contact.key);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// HOME DASHBOARD UI
// ---------------------------------------------------------
class HomeDashboardContent extends StatefulWidget {
  const HomeDashboardContent({super.key});

  @override
  State<HomeDashboardContent> createState() => _HomeDashboardContentState();
}

class _HomeDashboardContentState extends State<HomeDashboardContent> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isHC = AppSettings.highContrastMode.value;
    final double fontMultiplier = AppSettings.fontSize.value / 16;

    final Color bgColor = isHC ? Colors.black : Colors.white;
    final Color textColor = isHC ? Colors.white : Colors.black;
    final Color subTextColor = isHC ? Colors.white70 : Colors.grey;
    final Color iconBgColor = isHC ? Colors.grey.shade900 : const Color(0xFFF2F2F2);
    final Color iconBorderColor = isHC ? Colors.white54 : Colors.black12;
    final Color dividerColor = isHC ? Colors.white38 : Colors.black12;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Text(
                _formatTime(_now),
                style: TextStyle(fontSize: 48 * fontMultiplier, fontWeight: FontWeight.bold, color: textColor),
              ),
              Text(
                _formatDate(_now),
                style: TextStyle(fontSize: 20 * fontMultiplier, fontWeight: FontWeight.w500, color: subTextColor),
              ),
              const SizedBox(height: 50),
              GestureDetector(
                onTap: () => print("SOS Button Pressed"),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 260, height: 260,
                      decoration: BoxDecoration(
                        color: isHC ? Colors.white.withOpacity(0.1) : const Color(0xFFFF3B30).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(
                        color: isHC ? Colors.white.withOpacity(0.2) : const Color(0xFFFF3B30).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        color: isHC ? Colors.white : const Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))],
                      ),
                      child: Center(
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            fontSize: 56 * fontMultiplier,
                            fontWeight: FontWeight.bold,
                            color: isHC ? Colors.black : Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Divider(thickness: 1, color: dividerColor),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.mic,
                    label: 'Voice Command',
                    iconBgColor: iconBgColor,
                    iconBorderColor: iconBorderColor,
                    textColor: textColor,
                    fontSize: 12 * fontMultiplier,
                    isHC: isHC,
                    onTap: () => print("Voice Command Pressed"),
                  ),
                  _buildActionButton(
                    icon: Icons.email_outlined,
                    label: 'SMS Fallback',
                    iconBgColor: iconBgColor,
                    iconBorderColor: iconBorderColor,
                    textColor: textColor,
                    fontSize: 12 * fontMultiplier,
                    isHC: isHC,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SmsFallbackPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color iconBgColor,
    required Color iconBorderColor,
    required Color textColor,
    required double fontSize,
    required bool isHC,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: iconBorderColor),
            ),
            child: Icon(icon, color: isHC ? Colors.white : const Color(0xFFFF3B30), size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// SMS FALLBACK PAGE
// ---------------------------------------------------------
class SmsFallbackPage extends StatefulWidget {
  const SmsFallbackPage({super.key});

  @override
  State<SmsFallbackPage> createState() => _SmsFallbackPageState();
}

class _SmsFallbackPageState extends State<SmsFallbackPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _locationText = '';
  String _locationStatus = 'Getting location...';
  bool _isLoadingLocation = true;
  bool _locationFailed = false;
  double? _latitude;
  double? _longitude;
  List<String> _contactPhones = [];
  List<String> _contactNames = [];

  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadContacts();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationFailed = false;
      _locationStatus = 'Getting location...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationText = 'Location services are OFF';
            _locationStatus = 'Please enable GPS in your phone settings.';
            _isLoadingLocation = false;
            _locationFailed = true;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationText = 'Location permission DENIED';
            _locationStatus = 'Please allow location access when prompted.';
            _isLoadingLocation = false;
            _locationFailed = true;
          });
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationText = 'Location permission BLOCKED';
            _locationStatus = 'Go to App Settings and allow location.';
            _isLoadingLocation = false;
            _locationFailed = true;
          });
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (e) {
        print('Last known position failed: $e');
      }

      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 20),
          );
        } catch (e) {
          print('High accuracy failed, trying medium: $e');
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 15),
            );
          } catch (e2) {
            print('Medium accuracy failed, trying low: $e2');
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 10),
            );
          }
        }
      }

      if (position == null) {
        throw Exception('No location available');
      }

      final String lat = position.latitude.toStringAsFixed(6);
      final String lon = position.longitude.toStringAsFixed(6);
      final String accuracy = position.accuracy.toStringAsFixed(0);

      if (mounted) {
        setState(() {
          _latitude = position!.latitude;
          _longitude = position!.longitude;
          _locationText = 'Lat: $lat\nLon: $lon\nAccuracy: ±${accuracy}m';
          _locationStatus = 'Location found ✓';
          _isLoadingLocation = false;
          _locationFailed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to get location';
          _locationStatus = 'Make sure GPS is on and try again.';
          _isLoadingLocation = false;
          _locationFailed = true;
        });
      }
    }
  }

  Future<void> _loadContacts() async {
    if (currentUser == null) return;
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/${currentUser!.uid}/contacts')
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<String> phones = [];
        List<String> names = [];
        data.forEach((key, value) {
          final map = value as Map<dynamic, dynamic>;
          if (map['phone'] != null && map['phone'].toString().isNotEmpty) {
            phones.add(map['phone'].toString());
            names.add(map['name']?.toString() ?? map['relationship']?.toString() ?? 'Contact');
          }
        });
        if (mounted) {
          setState(() {
            _contactPhones = phones;
            _contactNames = names;
          });
        }
      }
    } catch (e) {
      print('Error loading contacts: $e');
    }
  }

  Future<void> _sendSosViaSms() async {
    if (_contactPhones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts saved. Please add contacts first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot get your location. Please enable GPS first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String mapsLink = 'https://maps.google.com/?q=$_latitude,$_longitude';

    final String message = Uri.encodeComponent(
      '🚨 EMERGENCY ALERT from NexAid 🚨\n\n'
          'I need help. This is an automated SOS message.\n\n'
          '📍 My Location:\n'
          '$_locationText\n\n'
          '🗺️ Open in Google Maps:\n'
          '$mapsLink\n\n'
          'Please send help immediately.\n\n'
          '— Sent via NexAid App',
    );

    final String phones = _contactPhones.join(',');
    final Uri smsUri = Uri.parse('sms:$phones?body=$message');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open SMS app.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHC = AppSettings.highContrastMode.value;
    final Color bgColor = isHC ? Colors.black : Colors.white;
    final Color textColor = isHC ? Colors.white : Colors.black;
    final Color subTextColor = isHC ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF3B30),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 30),

              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF3B30), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B30).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Text(
                'You are offline',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Don't worry, we've got your back",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHC ? Colors.grey.shade900 : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isHC ? Colors.white24 : Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SMS Fallback activated',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF3B30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We will send SMS to your emergency contacts with your last known location.',
                      style: TextStyle(fontSize: 14, color: subTextColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHC ? Colors.grey.shade900 : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isHC ? Colors.white24 : Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Last Known Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: _isLoadingLocation ? Colors.grey : const Color(0xFFFF3B30),
                            size: 24,
                          ),
                          onPressed: _isLoadingLocation ? null : _getLocation,
                          tooltip: 'Refresh location',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingLocation)
                      Row(
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Getting your location...', style: TextStyle(fontSize: 14)),
                        ],
                      )
                    else ...[
                      Text(
                        _locationText,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _locationStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: _locationFailed ? Colors.red : Colors.green.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (_locationFailed)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _getLocation,
                              icon: const Icon(Icons.refresh, size: 20),
                              label: const Text('Try Again'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFF3B30),
                                side: const BorderSide(color: Color(0xFFFF3B30)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _sendSosViaSms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.sms, size: 26),
                  label: const Text(
                    'SEND SOS VIA SMS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_contactPhones.isNotEmpty)
                Text(
                  'Will send to ${_contactPhones.length} contact${_contactPhones.length > 1 ? 's' : ''}: ${_contactNames.join(", ")}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: subTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Text(
                  'No emergency contacts found. Add contacts first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// PROFILE PAGE
// ---------------------------------------------------------
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String _fullName = 'Loading...';
  String _disability = 'Loading...';
  String _email = 'Loading...';
  String _age = 'Loading...';
  String _gender = 'Loading...';

  File? _localImage;
  String? _base64Image;
  bool _isUploading = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;

    try {
      final DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${currentUser!.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (mounted) {
          setState(() {
            _fullName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
            if (_fullName.isEmpty) _fullName = 'No Name Set';
            _disability = data['typeOfDisability'] ?? 'Not specified';
            _email = data['email'] ?? currentUser?.email ?? 'No Email';
            _age = data['age']?.toString() ?? 'Not set';
            _gender = data['gender'] ?? 'Not set';
            _base64Image = data['profileImageBase64'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _localImage = File(pickedFile.path);
        _isUploading = true;
      });

      try {
        final bytes = await File(pickedFile.path).readAsBytes();
        final String base64Image = base64Encode(bytes);

        await FirebaseDatabase.instance
            .ref('users/${currentUser!.uid}')
            .update({'profileImageBase64': base64Image});

        if (mounted) {
          setState(() {
            _base64Image = base64Image;
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture saved successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save image. Try a smaller image.')),
          );
        }
      }
    }
  }

  Future<void> _logOut() async {
    final bool isHC = AppSettings.highContrastMode.value;

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isHC ? Colors.grey.shade900 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(
                'Log Out?',
                style: TextStyle(
                  color: isHC ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of NexAid?\n\nYou will need to enter your email and password again to log back in.',
            style: TextStyle(
              fontSize: 16,
              color: isHC ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isHC ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30)));
    }

    final bool isHC = AppSettings.highContrastMode.value;

    final Color bgColor = isHC ? Colors.black : Colors.white;
    final Color textColor = isHC ? Colors.white : Colors.black;
    final Color fieldBgColor = isHC ? Colors.black : Colors.white;
    final Color borderColor = isHC ? Colors.white54 : Colors.grey.shade400;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: isHC ? Colors.black : const Color(0xFFF5332C).withOpacity(0.8),
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: _localImage != null
                              ? FileImage(_localImage!) as ImageProvider
                              : (_base64Image != null && _base64Image!.isNotEmpty
                              ? MemoryImage(base64Decode(_base64Image!)) as ImageProvider
                              : null),
                          child: (_localImage == null && (_base64Image == null || _base64Image!.isEmpty))
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        if (!_isUploading)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isHC ? Colors.white : const Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: isHC ? Colors.black : Colors.white,
                              size: 20,
                            ),
                          ),
                        if (_isUploading)
                          const Positioned.fill(
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFFFF3B30)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(_fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(_disability, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildInfoField(label: 'Email', value: _email, textColor: textColor, fieldBgColor: fieldBgColor, borderColor: borderColor),
                  _buildInfoField(label: 'Age', value: _age, textColor: textColor, fieldBgColor: fieldBgColor, borderColor: borderColor),
                  _buildInfoField(label: 'Gender', value: _gender, textColor: textColor, fieldBgColor: fieldBgColor, borderColor: borderColor),
                  const SizedBox(height: 20),
                  _buildActionTile(
                    icon: Icons.settings,
                    label: 'Settings',
                    textColor: textColor,
                    fieldBgColor: fieldBgColor,
                    borderColor: borderColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    icon: Icons.logout,
                    label: 'Log Out',
                    textColor: Colors.red,
                    fieldBgColor: fieldBgColor,
                    borderColor: borderColor,
                    isDestructive: true,
                    onTap: _logOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({required String label, required String value, required Color textColor, required Color fieldBgColor, required Color borderColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(color: fieldBgColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
            child: Text(value, style: TextStyle(fontSize: 16, color: textColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required String label, required Color textColor, required Color fieldBgColor, required Color borderColor, required VoidCallback onTap, bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(color: fieldBgColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : textColor),
            const SizedBox(width: 15),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : textColor)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: isDestructive ? Colors.red : textColor),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// SETTINGS PAGE
// ---------------------------------------------------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.highContrastMode,
      builder: (context, isHC, _) {
        return ValueListenableBuilder<double>(
          valueListenable: AppSettings.fontSize,
          builder: (context, fontSizeValue, _) {
            final Color bgColor = isHC ? Colors.black : Colors.white;
            final Color textColor = isHC ? Colors.white : Colors.black87;
            final Color subTextColor = isHC ? Colors.white70 : Colors.black54;

            return Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: isHC ? Colors.black : const Color(0xFFFF3B30),
                foregroundColor: Colors.white,
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Accessibility & Emergency Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 15),

                  SwitchListTile(
                    title: Text('Voice Command Activation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    subtitle: Text('Trigger SOS via voice phrases like "Help me"', style: TextStyle(color: subTextColor)),
                    value: AppSettings.voiceCommandEnabled,
                    activeColor: isHC ? Colors.white : const Color(0xFFFF3B30),
                    onChanged: (val) => setState(() => AppSettings.voiceCommandEnabled = val),
                  ),

                  SwitchListTile(
                    title: Text('Vibration Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    subtitle: Text('Vibrate phone when an alert is sent or received', style: TextStyle(color: subTextColor)),
                    value: AppSettings.vibrationAlertsEnabled,
                    activeColor: isHC ? Colors.white : const Color(0xFFFF3B30),
                    onChanged: (val) => setState(() => AppSettings.vibrationAlertsEnabled = val),
                  ),

                  SwitchListTile(
                    title: Text('Flash Alert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    subtitle: Text('Flash the camera light during an emergency', style: TextStyle(color: subTextColor)),
                    value: AppSettings.flashAlertEnabled,
                    activeColor: isHC ? Colors.white : const Color(0xFFFF3B30),
                    onChanged: (val) => setState(() => AppSettings.flashAlertEnabled = val),
                  ),

                  SwitchListTile(
                    title: Text('High Contrast Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    subtitle: Text('Black background with white text for low vision', style: TextStyle(color: subTextColor)),
                    value: AppSettings.highContrastMode.value,
                    activeColor: isHC ? Colors.white : const Color(0xFFFF3B30),
                    onChanged: (val) {
                      AppSettings.highContrastMode.value = val;
                    },
                  ),

                  const SizedBox(height: 20),
                  Divider(color: isHC ? Colors.white24 : Colors.black12),
                  const SizedBox(height: 15),

                  Text('Font Size Adjustment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 10),
                  Slider(
                    value: AppSettings.fontSize.value,
                    min: 14.0,
                    max: 24.0,
                    divisions: 5,
                    label: '${AppSettings.fontSize.value.toInt()} pt',
                    activeColor: isHC ? Colors.white : const Color(0xFFFF3B30),
                    onChanged: (val) {
                      AppSettings.fontSize.value = val;
                    },
                  ),
                  Center(child: Text('Current: ${AppSettings.fontSize.value.toInt()} pt', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),

                  const SizedBox(height: 30),
                  Divider(color: isHC ? Colors.white24 : Colors.black12),
                  const SizedBox(height: 15),

                  Text('Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 10),

                  ListTile(
                    leading: Icon(Icons.manage_accounts, color: isHC ? Colors.white : const Color(0xFFFF3B30)),
                    title: Text('Manage Your Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                    subtitle: Text('Update your personal information and profile details', style: TextStyle(color: subTextColor)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manage Account page coming soon!')));
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}