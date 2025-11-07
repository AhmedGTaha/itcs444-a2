// ITCS444 – Assignment #2: Campus Events Manager (with SmartImage)
// Paste this entire file as lib/main.dart in a new Flutter project.
// Then add these dependencies to your pubspec.yaml and run `flutter pub get`:
//   shared_preferences: ^2.3.2
//   http: ^1.2.2
//
// Android: ensure INTERNET permission in android/app/src/main/AndroidManifest.xml
//   <uses-permission android:name="android.permission.INTERNET"/>

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const EventsApp());
}

// ========================= DOMAIN =========================

enum EventStatus { notStarted, postponed, completed }

String statusToText(EventStatus s) {
  switch (s) {
    case EventStatus.notStarted:
      return 'Not Started';
    case EventStatus.postponed:
      return 'Postponed';
    case EventStatus.completed:
      return 'Completed';
  }
}

EventStatus statusFromText(String t) {
  switch (t) {
    case 'Not Started':
      return EventStatus.notStarted;
    case 'Postponed':
      return EventStatus.postponed;
    case 'Completed':
      return EventStatus.completed;
    default:
      return EventStatus.notStarted;
  }
}

class EventItem {
  final String id;
  String title;
  String description;
  EventStatus status;
  DateTime dateTime;
  String? location;
  String? organizer;
  int? maxAttendees;
  int attendees;
  String? imageUrl; // remote image
  String? imagePath; // local device image path
  bool favorite;

  EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dateTime,
    this.location,
    this.organizer,
    this.maxAttendees,
    this.attendees = 0,
    this.imageUrl,
    this.imagePath,
    this.favorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': statusToText(status),
        'dateTime': dateTime.toIso8601String(),
        'location': location,
        'organizer': organizer,
        'maxAttendees': maxAttendees,
        'attendees': attendees,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'favorite': favorite,
      };

  static EventItem fromJson(Map<String, dynamic> m) => EventItem(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String,
        status: statusFromText(m['status'] as String),
        dateTime: DateTime.parse(m['dateTime'] as String),
        location: (m['location'] as String?)?.trim().isEmpty == true ? null : m['location'] as String?,
        organizer: (m['organizer'] as String?)?.trim().isEmpty == true ? null : m['organizer'] as String?,
        maxAttendees: m['maxAttendees'] as int?,
        attendees: (m['attendees'] as num?)?.toInt() ?? 0,
        imageUrl: (m['imageUrl'] as String?)?.trim().isEmpty == true ? null : m['imageUrl'] as String?,
        imagePath: (m['imagePath'] as String?)?.trim().isEmpty == true ? null : m['imagePath'] as String?,
        favorite: m['favorite'] == true,
      );
}


// ========================= STORAGE =========================

class EventsRepo {
  static const _key = 'itcs444_events_v1';

  Future<List<EventItem>> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(EventItem.fromJson).toList();
  }

  Future<void> save(List<EventItem> items) async {
    final sp = await SharedPreferences.getInstance();
    final payload = jsonEncode(items.map((e) => e.toJson()).toList());
    await sp.setString(_key, payload);
  }
}

// ========================= APP ROOT =========================

class EventsApp extends StatelessWidget {
  const EventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Events',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
        brightness: Brightness.light,
      ),
      home: const EventsHomePage(),
    );
  }
}

// ========================= HOME =========================

class EventsHomePage extends StatefulWidget {
  const EventsHomePage({super.key});

  @override
  State<EventsHomePage> createState() => _EventsHomePageState();
}

enum Filter { all, notStarted, postponed, completed, favorites }

class _EventsHomePageState extends State<EventsHomePage> {
  final _repo = EventsRepo();
  List<EventItem> _items = [];
  Filter _filter = Filter.all;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.load();
    setState(() {
      _items = data..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _loading = false;
    });
  }

  Future<void> _persist() async => _repo.save(_items);

  List<EventItem> get _visible {
    final list = _items.toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    switch (_filter) {
      case Filter.all:
        return list;
      case Filter.notStarted:
        return list.where((e) => e.status == EventStatus.notStarted).toList();
      case Filter.postponed:
        return list.where((e) => e.status == EventStatus.postponed).toList();
      case Filter.completed:
        return list.where((e) => e.status == EventStatus.completed).toList();
      case Filter.favorites:
        return list.where((e) => e.favorite).toList();
    }
  }

  void _onAdd() async {
    final created = await Navigator.of(context).push<EventItem>(
      MaterialPageRoute(
        builder: (_) => AddEditEventPage(),
      ),
    );
    if (created != null) {
      setState(() => _items.add(created));
      await _persist();
      if (!mounted) return;
      _ok('Event added successfully');
    }
  }

  void _onEdit(EventItem e) async {
    final idx = _items.indexWhere((x) => x.id == e.id);
    final updated = await Navigator.of(context).push<EventItem>(
      MaterialPageRoute(
        builder: (_) => AddEditEventPage(original: e),
      ),
    );
    if (updated != null && idx != -1) {
      setState(() => _items[idx] = updated);
      await _persist();
      if (!mounted) return;
      _ok('Event updated');
    }
  }

  void _onDelete(EventItem e) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('Are you sure you want to delete "${e.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (sure == true) {
      setState(() => _items.removeWhere((x) => x.id == e.id));
      await _persist();
      if (!mounted) return;
      _ok('Event deleted');
    }
  }

  void _changeStatus(EventItem e, EventStatus s) async {
    final idx = _items.indexWhere((x) => x.id == e.id);
    if (idx == -1) return;
    setState(() => _items[idx] = _items[idx]
      ..status = s);
    await _persist();
    _ok('Status changed to ${statusToText(s)}');
  }

  void _bumpAtt(EventItem e, int delta) async {
    final idx = _items.indexWhere((x) => x.id == e.id);
    if (idx == -1) return;
    final max = e.maxAttendees ?? 1 << 30;
    final next = (e.attendees + delta).clamp(0, max);
    setState(() => _items[idx] = _items[idx]
      ..attendees = next);
    await _persist();
  }

  void _toggleFav(EventItem e) async {
    final idx = _items.indexWhere((x) => x.id == e.id);
    if (idx == -1) return;
    setState(() => _items[idx] = _items[idx]
      ..favorite = !e.favorite);
    await _persist();
  }

  void _ok(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Events'),
        actions: [
          IconButton(onPressed: _load, tooltip: 'Reload', icon: const Icon(Icons.refresh)),
          PopupMenuButton<Filter>(
            tooltip: 'Filter',
            initialValue: _filter,
            onSelected: (f) => setState(() => _filter = f),
            itemBuilder: (c) => const [
              PopupMenuItem(value: Filter.all, child: Text('All')),
              PopupMenuItem(value: Filter.favorites, child: Text('Favorites')),
              PopupMenuDivider(),
              PopupMenuItem(value: Filter.notStarted, child: Text('Not Started')),
              PopupMenuItem(value: Filter.postponed, child: Text('Postponed')),
              PopupMenuItem(value: Filter.completed, child: Text('Completed')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAdd,
        label: const Text('Add Event'),
        icon: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _visible.isEmpty
              ? const _EmptyView()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: _visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _EventCard(
                    event: _visible[i],
                    onEdit: _onEdit,
                    onDelete: _onDelete,
                    onStatus: _changeStatus,
                    onInc: (e) => _bumpAtt(e, 1),
                    onDec: (e) => _bumpAtt(e, -1),
                    onFav: _toggleFav,
                  ),
                ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy, size: 72),
          const SizedBox(height: 12),
          Text('No events yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Tap “Add Event” to create your first one.'),
        ],
      ),
    );
  }
}

// ========================= EVENT CARD =========================

class _EventCard extends StatelessWidget {
  final EventItem event;
  final void Function(EventItem) onEdit;
  final void Function(EventItem) onDelete;
  final void Function(EventItem, EventStatus) onStatus;
  final void Function(EventItem) onInc;
  final void Function(EventItem) onDec;
  final void Function(EventItem) onFav;

  const _EventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.onStatus,
    required this.onInc,
    required this.onDec,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = switch (event.status) {
      EventStatus.notStarted => cs.primaryContainer,
      EventStatus.postponed => cs.tertiaryContainer,
      EventStatus.completed => cs.secondaryContainer,
    };

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onLongPress: () => onEdit(event),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(statusToText(event.status), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Favorite',
                    onPressed: () => onFav(event),
                    icon: Icon(event.favorite ? Icons.favorite : Icons.favorite_border),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          onEdit(event);
                          break;
                        case 'delete':
                          onDelete(event);
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 4),
              Text(event.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (event.imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(event.imagePath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 160, child: Center(child: Text('Image failed to load'))),
                  ),
                )
              else if (event.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _SmartImage(url: event.imageUrl!, height: 160),
                ),
              if (event.imagePath != null || event.imageUrl != null) const SizedBox(height: 8),
              Text(event.description, maxLines: 4, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _IconText(icon: Icons.event, text: _fmtDate(event.dateTime)),
                  if ((event.location ?? '').isNotEmpty) _IconText(icon: Icons.place, text: event.location!),
                  if ((event.organizer ?? '').isNotEmpty) _IconText(icon: Icons.person, text: event.organizer!),
                  _IconText(icon: Icons.people, text: event.maxAttendees != null ? '${event.attendees} / ${event.maxAttendees}' : '${event.attendees}'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SegmentedButton<EventStatus>(
                    segments: const [
                      ButtonSegment(value: EventStatus.notStarted, icon: Icon(Icons.hourglass_empty), label: Text('Not Started')),
                      ButtonSegment(value: EventStatus.postponed, icon: Icon(Icons.schedule), label: Text('Postponed')),
                      ButtonSegment(value: EventStatus.completed, icon: Icon(Icons.check_circle), label: Text('Completed')),
                    ],
                    selected: {event.status},
                    onSelectionChanged: (s) => onStatus(event, s.first),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(onPressed: () => onDec(event), icon: const Icon(Icons.remove)),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text('${event.attendees}'),
                  ),
                  IconButton.filled(onPressed: () => onInc(event), icon: const Icon(Icons.add)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

String _fmtDate(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final am = dt.hour < 12 ? 'AM' : 'PM';
  return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}  $h:$m $am';
}

// ========================= ADD / EDIT PAGE =========================

class AddEditEventPage extends StatefulWidget {
  final EventItem? original;
  AddEditEventPage({super.key, this.original});

  @override
  State<AddEditEventPage> createState() => _AddEditEventPageState();
}

class _AddEditEventPageState extends State<AddEditEventPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  EventStatus _status = EventStatus.notStarted;
  DateTime? _date;
  TimeOfDay? _time;
  final _location = TextEditingController();
  final _organizer = TextEditingController();
  final _maxAtt = TextEditingController();
  final _imageUrl = TextEditingController();
  String? _imagePath; // local file path

  @override
  void initState() {
    super.initState();
    final e = widget.original;
    if (e != null) {
      _title.text = e.title;
      _desc.text = e.description;
      _status = e.status;
      _date = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      _time = TimeOfDay(hour: e.dateTime.hour, minute: e.dateTime.minute);
      _location.text = e.location ?? '';
      _organizer.text = e.organizer ?? '';
      _maxAtt.text = e.maxAttendees?.toString() ?? '';
      _imageUrl.text = e.imageUrl ?? '';
      _imagePath = e.imagePath;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    _organizer.dispose();
    _maxAtt.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _date ?? now,
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.fromDateTime(now),
    );
    if (pickedTime == null) return;
    setState(() {
      _date = pickedDate;
      _time = pickedTime;
    });
  }

  DateTime? get _combinedDT {
    if (_date == null || _time == null) return null;
    return DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final dt = _combinedDT;
    if (dt == null) {
      _alert('Please choose date/time');
      return;
    }

    final max = _maxAtt.text.trim().isEmpty ? null : int.tryParse(_maxAtt.text.trim());
    if (_maxAtt.text.trim().isNotEmpty && max == null) {
      _alert('Max attendees must be a number');
      return;
    }

    final existing = widget.original;
    final item = EventItem(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      description: _desc.text.trim(),
      status: _status,
      dateTime: dt,
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      organizer: _organizer.text.trim().isEmpty ? null : _organizer.text.trim(),
      maxAttendees: max,
      attendees: existing?.attendees ?? 0,
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      imagePath: _imagePath,
      favorite: existing?.favorite ?? false,
    );

    Navigator.of(context).pop(item);
  }

  void _alert(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Attention'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.original != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit Event' : 'Add Event'),
      ),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _desc,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes)),
              validator: (v) => (v == null || v.trim().length < 8) ? 'Please add at least 8 characters' : null,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<EventStatus>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: EventStatus.notStarted, child: Text('Not Started')),
                    DropdownMenuItem(value: EventStatus.postponed, child: Text('Postponed')),
                    DropdownMenuItem(value: EventStatus.completed, child: Text('Completed')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_combinedDT == null ? 'Pick date & time' : _fmtDate(_combinedDT!)),
              subtitle: const Text('Tap to choose a date and time'),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location (optional)', prefixIcon: Icon(Icons.place)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _organizer,
              decoration: const InputDecoration(labelText: 'Organizer (optional)', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _maxAtt,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max attendees (optional)', prefixIcon: Icon(Icons.people)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageUrl,
              decoration: const InputDecoration(labelText: 'Image URL (optional)', prefixIcon: Icon(Icons.image)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(type: FileType.image);
                      if (res != null && res.files.single.path != null) {
                        setState(() {
                          _imagePath = res.files.single.path;
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick from device'),
                  ),
                ),
                const SizedBox(width: 8),
                if (_imagePath != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _imagePath = null),
                      icon: const Icon(Icons.clear),
                      label: const Text('Remove local image'),
                    ),
                  ),
              ],
            ),
            if (_imagePath != null) Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Selected: '+ (File(_imagePath!).uri.pathSegments.isNotEmpty ? File(_imagePath!).uri.pathSegments.last : _imagePath!),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(editing ? 'Save Changes' : 'Add Event'),
                  ),
                ),
              ],
            )
          ],
        ),
      )
      );
  }
}

// ========================= SMART IMAGE (hotlink/CORS-friendly) =========================
class _SmartImage extends StatelessWidget {
  final String url;
  final double height;
  const _SmartImage({required this.url, required this.height});

  Future<Uint8List> _load() async {
    final uri = Uri.parse(url);
    final resp = await http.get(
      uri,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Flutter)',
        'Referer': '${uri.scheme}://${uri.host}',
      },
    );
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    return resp.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || snap.data == null) {
          return SizedBox(
            height: height,
            child: const Center(child: Text('Image failed to load')),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            snap.data!,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}