import 'package:flutter/material.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Agreement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF3030),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terms & Agreement',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildSection(
                      '1. Purpose',
                      'NexAid helps users send emergency alerts to registered emergency contacts during genuine emergencies.',
                    ),

                    _buildSection(
                      '2. Proper Use',
                      'Use the SOS and voice commands only when emergency assistance is actually needed.',
                    ),

                    _buildSection(
                      '3. Prohibited Use',
                      'Do not use NexAid to intentionally send false, prank, or unnecessary emergency alerts.',
                    ),

                    _buildSection(
                      '4. False Emergency Alerts',
                      'Intentional or repeated misuse of emergency alerts may result in warnings, account restrictions, suspension, or other penalties according to app policies and applicable rules.',
                    ),

                    _buildSection(
                      '5. Voice Commands',
                      'The voice commands “Help me,” “SOS,” and “Emergency” are intended for emergency activation. Do not intentionally use these commands to create false alerts.',
                    ),

                    _buildSection(
                      '6. Emergency Contacts',
                      'You are responsible for providing accurate and reachable emergency contacts.',
                    ),

                    _buildSection(
                      '7. Location',
                      'When an emergency alert is activated, NexAid may use available device location information to help provide your location to your registered emergency contacts.',
                    ),

                    _buildSection(
                      '8. Service Limitations',
                      'Emergency alerts depend on internet connection, GPS, cellular service, and the availability of your emergency contacts. NexAid cannot guarantee that an alert will always be delivered successfully.',
                    ),

                    _buildSection(
                      '9. User Responsibility',
                      'You are responsible for using NexAid properly and for complying with these terms and applicable rules.',
                    ),

                    _buildSection(
                      '10. Privacy and User Information',
                      'Personal information such as name, age, gender, disability information, email address, location, and emergency contact information may be used only for NexAid functions and services. This information will not be used, sold, or shared for unrelated purposes without your consent, except when required by law or regulations.',
                    ),

                    const SizedBox(height: 10),

                    const Divider(),

                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _isAgreed,
                          activeColor: const Color(0xFFFF3030),
                          onChanged: (value) {
                            setState(() {
                              _isAgreed = value ?? false;
                            });
                          },
                        ),

                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'I have read and agree to the Terms & Agreement and Privacy Policy.',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                10,
                24,
                24,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isAgreed
                      ? () {
                    Navigator.pop(context, true);
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3030),
                    disabledBackgroundColor:
                    Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Agree & Continue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title,
      String content,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}