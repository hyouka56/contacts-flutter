import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

void main() => runApp(const ContactsApp());

const teal = Color(0xFFFFFFFF);
const ink = Color(0xFFFFFFFF);
const muted = Color(0xFFFFFFFF);
const page = Color(0xFF000000);

class ContactsApp extends StatelessWidget {
  const ContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: page,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
          surface: page,
        ).copyWith(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.white,
          onSecondary: Colors.black,
          surface: Colors.black,
          onSurface: Colors.white,
          outline: Colors.white,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: page,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const ContactsHome(),
    );
  }
}

class ContactsHome extends StatefulWidget {
  const ContactsHome({super.key});

  @override
  State<ContactsHome> createState() => _ContactsHomeState();
}

class _ContactsHomeState extends State<ContactsHome> {
  final _search = TextEditingController();
  List<Contact> _contacts = [];
  bool _loading = true;
  bool _permissionDenied = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
    });
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (mounted) {
          setState(() {
            _permissionDenied = true;
            _loading = false;
          });
        }
        return;
      }
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      contacts.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Contact> get _filtered {
    if (_query.isEmpty) return _contacts;
    final q = _query.toLowerCase();
    return _contacts.where((c) {
      if (c.displayName.toLowerCase().contains(q)) return true;
      return c.phones.any((p) => p.number.replaceAll(' ', '').contains(q.replaceAll(' ', '')));
    }).toList();
  }

  Color _avatarColor(String name) => const Color(0xFF151515);

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return (words.first.characters.first + words.last.characters.first).toUpperCase();
  }

  void _showContact(Contact contact) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.white54, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 38,
                backgroundColor: _avatarColor(contact.displayName),
                child: Text(_initials(contact.displayName),
                  style: const TextStyle(fontSize: 24, color: ink, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 14),
              Text(contact.displayName, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 24),
              Align(alignment: Alignment.centerLeft,
                child: Text('PHONE NUMBERS', style: TextStyle(
                  color: muted, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700))),
              const SizedBox(height: 8),
              if (contact.phones.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('No phone numbers saved', style: TextStyle(color: muted)))
              else
                ...contact.phones.map((phone) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: page, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)), 
                  child: SelectableText(phone.number,
                    style: const TextStyle(fontSize: 17, color: ink, fontWeight: FontWeight.w500)),
                )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh contacts',
            onPressed: _loadContacts,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: TextField(
                controller: _search,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search contacts or numbers',
                  hintStyle: const TextStyle(color: muted, fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded, color: muted),
                  suffixIcon: _query.isEmpty ? null : IconButton(
                    tooltip: 'Clear search',
                    onPressed: _search.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
                  filled: true,
                  fillColor: page,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Row(
                children: [
                  const Text('ALL CONTACTS', style: TextStyle(
                    color: muted, fontSize: 12, letterSpacing: 1.25, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${contacts.length}', style: const TextStyle(
                    color: muted, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: teal))
                : _permissionDenied
                  ? _emptyState(Icons.contacts_outlined, 'Contacts permission needed',
                      'Allow contacts access to show the numbers saved on your phone.',
                      action: TextButton(onPressed: _loadContacts, child: const Text('Try again')))
                  : contacts.isEmpty
                    ? _emptyState(Icons.person_search_rounded,
                        _query.isEmpty ? 'No contacts found' : 'No matching contacts',
                        _query.isEmpty ? 'Contacts saved on your phone will appear here.' : 'Try another name or phone number.')
                    : RefreshIndicator(
                        color: teal,
                        onRefresh: _loadContacts,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: contacts.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: 76, endIndent: 8, color: Colors.white24),
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            final numbers = contact.phones.map((p) => p.number).where((n) => n.isNotEmpty).toList();
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: _avatarColor(contact.displayName),
                                child: Text(_initials(contact.displayName),
                                  style: const TextStyle(color: ink, fontWeight: FontWeight.w600)),
                              ),
                              title: Text(contact.displayName.isEmpty ? 'Unnamed contact' : contact.displayName,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                numbers.isEmpty ? 'No phone number' : numbers.join(' Â· '),
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: muted, fontSize: 13, height: 1.45)),
                              onTap: () => _showContact(contact),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String message, {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: muted, height: 1.5)),
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}
