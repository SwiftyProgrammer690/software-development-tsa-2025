// Written by 2152-901

// Imports all nessary toolkits and services
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Initializes the notes screen where users can create, edit, delete, and listen to their notes
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

// Main code for the logic and UI of the screen
class _NotesScreenState extends State<NotesScreen> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _searchController = TextEditingController();

  // Create arrays and variables to store the notes
  List<Note> _notes = [];
  List<Note> _filtered = [];
  String? _speakingNoteId;
  bool _isLoading = true;
  double _speechRate = 0.45;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadNotes();
  }

  // Logic for initializing and starting the TTS service
  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingNoteId = null);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speakingNoteId = null);
    });
  }

  // Logic for loading and saving the notes using shared preferences, as well as filtering and speaking the notes
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('notes') ?? [];
    final notes = raw
        .map((s) => Note.fromJson(jsonDecode(s)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _notes = notes;
      _filtered = notes;
      _isLoading = false;
    });
  }

  // Logic for saving the notes using shared preferences, as well as filtering and speaking the notes
  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'notes',
      _notes.map((n) => jsonEncode(n.toJson())).toList(),
    );
  }

  // Logic for filtering the notes based on the search query, as well as speaking the notes
  void _filterNotes(String query) {
    setState(() {
      _searchQuery = query;
      _filtered = query.isEmpty
          ? _notes
          : _notes
              .where((n) =>
                  n.title.toLowerCase().contains(query.toLowerCase()) ||
                  n.content.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  // Logic for speaking the notes using the TTS service, as well as stopping the speech if the same note is tapped again
  Future<void> _speakNote(Note note) async {
    if (_speakingNoteId == note.id) {
      await _tts.stop();
      setState(() => _speakingNoteId = null);
      return;
    }
    await _tts.stop();
    await _tts.setSpeechRate(_speechRate);
    setState(() => _speakingNoteId = note.id);
    await _tts.speak('${note.title}. ${note.content}');
  }

  // Logic for opening the note editor bottom sheet, as well as saving the new or edited note and updating the list
  void _openNoteEditor({Note? note}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteEditor(
        note: note,
        onSave: (title, content) {
          if (note == null) {
            final newNote = Note(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              content: content,
              createdAt: DateTime.now(),
            );
            setState(() {
              _notes.insert(0, newNote);
              _filterNotes(_searchQuery);
            });
          } else {
            final idx = _notes.indexWhere((n) => n.id == note.id);
            if (idx != -1) {
              setState(() {
                _notes[idx] = Note(
                  id: note.id,
                  title: title,
                  content: content,
                  createdAt: note.createdAt,
                );
                _filterNotes(_searchQuery);
              });
            }
          }
          _saveNotes();
        },
      ),
    );
  }

  // Logic for deleting a note, including stopping the speech if the deleted note is currently being spoken, and showing a snackbar with an undo option
  void _deleteNote(Note note) {
    if (_speakingNoteId == note.id) _tts.stop();
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
      _filterNotes(_searchQuery);
    });
    _saveNotes();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Note deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _notes.insert(0, note);
              _filterNotes(_searchQuery);
            });
            _saveNotes();
          },
        ),
      ));
  }

  // Logic for disposing the controllers and stopping the TTS service when the screen is closed
  @override
  void dispose() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _tts.stop();
    _searchController.dispose();
    super.dispose();
  }

  // UI for this page
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spoken notes'),
        actions: [
          // Speech rate control
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Icon(Icons.speed, size: 16, color: scheme.onSurface.withOpacity(0.5)),
                SizedBox(
                  width: 80,
                  child: Slider(
                    value: _speechRate,
                    min: 0.2,
                    max: 0.9,
                    divisions: 7,
                    onChanged: (v) {
                      setState(() => _speechRate = v);
                      _tts.setSpeechRate(v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterNotes,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterNotes('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: scheme.onSurface.withOpacity(0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: scheme.onSurface.withOpacity(0.15)),
                ),
              ),
            ),
          ),

          // Notes list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notes,
                                size: 64,
                                color: scheme.onSurface.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No notes match your search'
                                  : 'No notes yet\nTap + to create one',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: scheme.onSurface.withOpacity(0.4),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final note = _filtered[i];
                          final isSpeaking = _speakingNoteId == note.id;

                          return Dismissible(
                            key: Key(note.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                            ),
                            onDismissed: (_) => _deleteNote(note),
                            child: GestureDetector(
                              onTap: () => _openNoteEditor(note: note),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSpeaking
                                      ? scheme.primary.withOpacity(0.08)
                                      : scheme.surfaceContainerHighest
                                          .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSpeaking
                                        ? scheme.primary.withOpacity(0.4)
                                        : scheme.onSurface.withOpacity(0.08),
                                    width: isSpeaking ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            note.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: isSpeaking
                                                  ? scheme.primary
                                                  : scheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (note.content.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              note.content,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: scheme.onSurface
                                                    .withOpacity(0.55),
                                                height: 1.4,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatDate(note.createdAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: scheme.onSurface
                                                  .withOpacity(0.35),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => _deleteNote(note),
                                      child: Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red.withOpacity(0.08),
                                        ),
                                        child: Icon(Icons.delete_outline,
                                            color: Colors.red.withOpacity(0.6), size: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _speakNote(note),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSpeaking
                                              ? scheme.primary
                                              : scheme.primary.withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          isSpeaking ? Icons.stop : Icons.volume_up,
                                          color: isSpeaking ? Colors.white : scheme.primary,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _NoteEditor extends StatefulWidget {
  final Note? note;
  final void Function(String title, String content) onSave;

  const _NoteEditor({this.note, required this.onSave});

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

// The page that shows up when you want to create or edit a note
class _NoteEditorState extends State<_NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _previewSpeech() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    final text =
        '${_titleController.text}. ${_contentController.text}'.trim();
    if (text.isEmpty) return;
    setState(() => _isSpeaking = true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  void _save() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) return;
    _tts.stop();
    widget.onSave(title, content);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _tts.stop();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // UI for overwrite or new note creation
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.note == null ? 'New note' : 'Edit note',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: _previewSpeech,
                icon: Icon(
                  _isSpeaking ? Icons.stop : Icons.volume_up,
                  color: _isSpeaking ? scheme.primary : scheme.onSurface.withOpacity(0.5),
                ),
                tooltip: 'Preview speech',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              hintText: 'Write your note here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Save note', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// OOP for the note objects so it is easier and more efficient to program
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}