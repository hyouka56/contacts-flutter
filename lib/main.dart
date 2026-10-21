import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:call_log/call_log.dart';

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
      home: const DialerHome(),
    );
  }
}

Future<void> _openPhoneDialer(BuildContext context, String phoneNumber) async {
  final number = phoneNumber
      .trim()
      .replaceAll(RegExp(r'[\s\u00A0\u2007\u202F().\-\u2010-\u2015]'), '');
  if (number.isEmpty) return;
  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.DIAL',
      data: Uri.encodeFull('tel:$number'),
    );
    await intent.launch();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the phone app. Check that a phone app is installed.'),
      ),
    );
  }
}

class DialerHome extends StatefulWidget {
  const DialerHome({super.key});

  @override
  State<DialerHome> createState() => _DialerHomeState();
}

class _DialerHomeState extends State<DialerHome> {
  final _number = TextEditingController();
  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'];

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _append(String digit) {
    if (_number.text.length >= 32) return;
    setState(() {
      _number.text += digit;
      _number.selection = TextSelection.collapsed(offset: _number.text.length);
    });
  }

  void _deleteLast() {
    if (_number.text.isEmpty) return;
    setState(() {
      _number.text = _number.text.substring(0, _number.text.length - 1);
      _number.selection = TextSelection.collapsed(offset: _number.text.length);
    });
  }

  void _openRecents() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecentsPage()));
  }

  void _openContacts() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ContactsHome()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialer', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: _openRecents, child: const Text('Recents')),
          TextButton(onPressed: _openContacts, child: const Text('Contacts')),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              TextField(
                key: const ValueKey('dialer-number'),
                controller: _number,
                readOnly: true,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 30, letterSpacing: 1.2),
                decoration: InputDecoration(
                  hintText: 'Enter number',
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 22),
                  border: InputBorder.none,
                  suffixIcon: _number.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Delete last digit',
                          onPressed: _deleteLast,
                          icon: const Icon(Icons.backspace_outlined, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _keys.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisExtent: 62,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final digit = _keys[index];
                  return TextButton(
                    key: ValueKey('dialer-key-$digit'),
                    onPressed: () => _append(digit),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(digit, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w400)),
                  );
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  key: const ValueKey('dialer-call'),
                  onPressed: _number.text.trim().isEmpty
                      ? null
                      : () => _openPhoneDialer(context, _number.text),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF303030),
                    disabledForegroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentsPage extends StatefulWidget {
  const RecentsPage({super.key});

  @override
  State<RecentsPage> createState() => _RecentsPageState();
}

class _RecentsPageState extends State<RecentsPage> with WidgetsBindingObserver {
  final _search = TextEditingController();
  List<CallLogEntry> _entries = [];
  bool _loading = true;
  bool _permissionOrReadError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _search.addListener(_onSearchChanged);
    _loadRecents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadRecents();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecents() async {
    if (mounted) setState(() => _loading = true);
    try {
      final entries = (await CallLog.get()).toList()
        ..sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
        _permissionOrReadError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = [];
        _loading = false;
        _permissionOrReadError = true;
      });
    }
  }

  List<CallLogEntry> get _filteredEntries {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _entries;
    final compactQuery = query.replaceAll(RegExp(r'\s+'), '');
    return _entries.where((entry) {
      final name = (entry.name ?? '').toLowerCase();
      final number = entry.number ?? '';
      return name.contains(query) || number.toLowerCase().contains(query) ||
          number.replaceAll(RegExp(r'\s+'), '').contains(compactQuery);
    }).toList();
  }

  String _timeLabel(BuildContext context, int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final localizations = MaterialLocalizations.of(context);
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    return isToday
        ? localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))
        : localizations.formatShortDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: TextField(
                controller: _search,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search calls or numbers',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: _search.clear,
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                  border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _permissionOrReadError
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Allow call-history access to show your recent calls.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, height: 1.5),
                                ),
                                TextButton(onPressed: _loadRecents, child: const Text('Try again')),
                              ],
                            ),
                          ),
                        )
                      : entries.isEmpty
                          ? Center(
                              child: Text(
                                _search.text.trim().isEmpty ? 'No recent calls' : 'No matching calls',
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: entries.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white24),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                final number = (entry.number ?? '').trim();
                                final name = (entry.name ?? '').trim();
                                final hasName = name.isNotEmpty;
                                final title = hasName ? name : (number.isEmpty ? 'Unknown number' : number);
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  title: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: hasName && number.isNotEmpty
                                      ? Text(number, style: const TextStyle(color: Colors.white70, fontSize: 13))
                                      : null,
                                  trailing: Text(
                                    _timeLabel(context, entry.timestamp),
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  onTap: number.isEmpty ? null : () => _openPhoneDialer(context, number),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
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
      final permissionStatus = await FlutterContacts.permissions.request(PermissionType.read);
      if (permissionStatus != PermissionStatus.granted) {
        if (mounted) {
          setState(() {
            _permissionDenied = true;
            _loading = false;
          });
        }
        return;
      }
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      contacts.sort((a, b) =>
          _displayName(a).toLowerCase().compareTo(_displayName(b).toLowerCase()));
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

  Future<void> _addContact() async {
    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const AddContactPage(),
        ),
      );
      if (!mounted || saved != true) return;

      await _loadContacts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact saved')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open add-contact form')),
      );
    }
  }

  Future<void> _confirmDeleteContact(Contact contact) async {
    final name = _displayName(contact);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text('Delete contact?', style: TextStyle(color: ink)),
        content: Text(
          'Delete $name from your contacts? This cannot be undone.',
          style: const TextStyle(color: muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel', style: TextStyle(color: muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (!mounted || shouldDelete != true) return;

    try {
      final permissionStatus = await FlutterContacts.permissions.request(
        PermissionType.write,
      );
      if (!mounted) return;
      if (permissionStatus != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Allow contacts write access to delete contacts.')),
        );
        return;
      }
      final contactId = contact.id;
      if (contactId == null || contactId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This contact has no valid ID and cannot be deleted.'),
          ),
        );
        return;
      }
      await FlutterContacts.delete(contactId);
      await _loadContacts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $name')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete contact. Try again.')),
      );
    }
  }

  List<Contact> get _filtered {
    if (_query.isEmpty) return _contacts;
    final q = _query.toLowerCase();
    return _contacts.where((c) {
      if (_displayName(c).toLowerCase().contains(q)) return true;
      return c.phones.any((p) => p.number.replaceAll(' ', '').contains(q.replaceAll(' ', '')));
    }).toList();
  }

  String _displayName(Contact contact) {
    final name = contact.displayName?.trim();
    return name == null || name.isEmpty ? 'Unnamed contact' : name;
  }

  Color _avatarColor(String name) => const Color(0xFF151515);

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return (words.first.characters.first + words.last.characters.first).toUpperCase();
  }

  Future<void> _openDialer(String phoneNumber) async {
    await _openPhoneDialer(context, phoneNumber);
  }

  void _showContact(Contact contact) {
    final displayName = _displayName(contact);
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
                backgroundColor: _avatarColor(displayName),
                child: Text(_initials(displayName),
                  style: const TextStyle(fontSize: 24, color: ink, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 14),
              Text(displayName, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PHONE NUMBERS',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          phone.number,
                          style: const TextStyle(
                            fontSize: 17,
                            color: ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Call ${phone.number}',
                        onPressed: phone.number.trim().isEmpty
                            ? null
                            : () => _openDialer(phone.number),
                        icon: const Icon(Icons.call_rounded, color: Colors.white),
                      ),
                    ],
                  ),
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
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add contact',
        onPressed: _addContact,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
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
                          separatorBuilder: (_, _) => const Divider(
                            height: 1, indent: 76, endIndent: 8, color: Colors.white24),
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            final numbers = contact.phones.map((p) => p.number).where((n) => n.isNotEmpty).toList();
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: _avatarColor(_displayName(contact)),
                                child: Text(_initials(_displayName(contact)),
                                  style: const TextStyle(color: ink, fontWeight: FontWeight.w600)),
                              ),
                              title: Text(_displayName(contact),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                numbers.isEmpty ? 'No phone number' : numbers.join(' ÃÂ· '),
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: muted, fontSize: 13, height: 1.45)),
                              onTap: () => _showContact(contact),
                              onLongPress: () => _confirmDeleteContact(contact),
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
            ?action,
          ],
        ),
      ),
    );
  }
}


class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final permissionStatus = await FlutterContacts.permissions.request(
        PermissionType.write,
      );
      if (!mounted) return;

      if (permissionStatus != PermissionStatus.granted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Allow contacts write access to save this contact.'),
          ),
        );
        return;
      }

      final fullName = _nameController.text.trim();
      final nameParts = fullName.split(RegExp(r'\s+'));
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.skip(1).join(' ')
          : '';

      await FlutterContacts.create(
        Contact(
          name: Name(first: firstName, last: lastName),
          phones: [Phone(number: _phoneController.text.trim())],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save contact. Check permission and try again.'),
        ),
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: muted),
      prefixIcon: Icon(icon, color: muted),
      filled: true,
      fillColor: page,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white54),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white38),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: page,
      appBar: AppBar(
        title: const Text(
          'New contact',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFF151515),
                child: Icon(Icons.person_add_alt_1_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add to contacts',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a name and phone number. The contact will be saved to your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 28),
              TextFormField(
                key: const ValueKey('contact-name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: ink),
                decoration: _fieldDecoration(
                  label: 'Name',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('contact-phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: ink),
                decoration: _fieldDecoration(
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a phone number';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _saveContact(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
              key: const ValueKey('save-contact'),
              onPressed: _saving ? null : _saveContact,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'Saving…' : 'Save contact'),
            ),
          ),
        ),
      ),
    );
  }
}
