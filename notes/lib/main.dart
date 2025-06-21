import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Note {
  String text;

  Note({
    required this.text,
  });

  factory Note.fromJson(String jsonStr) {
    final map = json.decode(jsonStr);
    return Note(
      text: map['text'] ?? '',
    );
  }

  String toJson() {
    return json.encode({
      'text': text,
    });
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('darkMode') ?? false;
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  MyApp({required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isDark;

  @override
  void initState() {
    super.initState();
    isDark = widget.isDarkMode;
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = !isDark;
    });
    prefs.setBool('darkMode', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apple Notes Clone',
      debugShowCheckedModeBanner: false,
      theme: isDark ? _darkTheme() : _lightTheme(),
      home: NotesListPage(onToggleTheme: toggleTheme),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFEF7), // light ivory
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFFEF7),
        foregroundColor: Colors.black87,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          fontFamily: 'SFProDisplay',
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
            fontSize: 17, color: Colors.black, fontFamily: 'SFProDisplay'),
        bodyMedium: TextStyle(fontSize: 15, fontFamily: 'SFProDisplay'),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: Colors.black54,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFFD60A), // Apple yellow
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      dividerColor: Colors.grey.shade300,
      useMaterial3: false,
    );
  }

  ThemeData _darkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1C1C1E),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          fontFamily: 'SFProDisplay',
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
            fontSize: 17, color: Colors.white, fontFamily: 'SFProDisplay'),
        bodyMedium: TextStyle(fontSize: 15, fontFamily: 'SFProDisplay'),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: Colors.white70,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFFD60A),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      dividerColor: Colors.grey.shade800,
      useMaterial3: false,
    );
  }
}

class NotesListPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const NotesListPage({required this.onToggleTheme});

  @override
  _NotesListPageState createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  Map<String, List<Note>> allFolders = {};
  String currentFolder = 'Default';

  List<Note> get currentNotes => allFolders[currentFolder] ?? [];
  List<Note> filteredNotes = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newFolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_filterNotes);
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('folders');

    // Step 1: Add defaults first, in order
    allFolders = {
      'Default': [],
      'Work': [],
      'Personal': [],
      'Ideas': [],
      'Notes': [],
    };

    // Step 2: If user has saved folders, override or add
    if (raw != null) {
      final map = json.decode(raw) as Map<String, dynamic>;
      map.forEach((folder, notesJson) {
        final notes = List<String>.from(notesJson);
        allFolders[folder] = notes.map((e) => Note.fromJson(e)).toList();
      });
    }

    await _saveNotes(); // Persist merged result
    _filterNotes();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final rawMap = allFolders.map((folder, notes) =>
        MapEntry(folder, notes.map((n) => n.toJson()).toList()));
    await prefs.setString('folders', json.encode(rawMap));
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    final all = currentNotes;
    setState(() {
      filteredNotes = all.where((note) {
        return note.text.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _openEditor({Note? existingNote, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(
          initialText: existingNote?.text ?? '',
        ),
      ),
    );

    if (result != null && result is Note && result.text.trim().isNotEmpty) {
      setState(() {
        if (index != null) {
          allFolders[currentFolder]![index] = result;
        } else {
          allFolders[currentFolder]!.insert(0, result);
        }
        _filterNotes();
      });
      _saveNotes();
    }
  }

  void _deleteNote(int index) {
    setState(() {
      final original = filteredNotes[index];
      allFolders[currentFolder]!.remove(original);
      _filterNotes();
    });
    _saveNotes();
  }

  void _addFolder(String folderName) {
    folderName = folderName.trim();
    if (folderName.isEmpty || allFolders.containsKey(folderName)) return;

    setState(() {
      allFolders[folderName] = [];
      currentFolder = folderName;
      _newFolderController.clear();
      _filterNotes(); // ← This is important to update the notes list
    });

    _saveNotes();
    Navigator.pop(context);
  }

  bool isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                setState(() => isSidebarCollapsed = !isSidebarCollapsed);
              },
            ),
            Text('Notes'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_round),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Row(
        children: [
          if (!isSidebarCollapsed) _buildSidebar(),
          if (!isSidebarCollapsed) VerticalDivider(width: 1),
          Expanded(child: _buildNoteListArea()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Icon(Icons.add, color: Colors.black, size: 28),
        backgroundColor: Color(0xFFFFD60A),
        elevation: 0,
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade900
          : Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Folders',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).iconTheme.color),
              onPressed: _showAddFolderDialog,
            ),
          ),
          Expanded(
            child: ListView(
              children: allFolders.keys.map((folder) {
                final selected = folder == currentFolder;
                return ListTile(
                  title: Text(
                    _getFolderIcon(folder) + ' ' + folder,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  selected: selected,
                  onTap: () {
                    setState(() {
                      currentFolder = folder;
                      _filterNotes();
                    });
                  },
                  trailing: folder == 'Default'
                      ? null
                      : IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDeleteFolder(folder),
                        ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog() {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'New Folder',
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: _newFolderController,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: textColor.withOpacity(0.3)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFD60A)), // Apple yellow
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              _addFolder(_newFolderController.text);
              Navigator.pop(context);
            },
            child: Text('Create', style: TextStyle(color: Color(0xFFFFD60A))),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(String folder) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        title: Text(
          'Delete "$folder"?',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'All notes in this folder will also be deleted.',
          style: TextStyle(color: textColor.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                allFolders.remove(folder);
                if (currentFolder == folder) {
                  currentFolder = 'Default';
                }
                _filterNotes();
                _saveNotes();
              });
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getFolderIcon(String name) {
    final lower = name.toLowerCase();
    if (lower == 'default') return '📁';
    if (lower == 'work') return '💼';
    if (lower == 'personal') return '🏠';
    if (lower == 'ideas') return '🧠';
    if (lower == 'notes') return '📝';
    return '📂';
  }

  Widget _buildNoteListArea() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search notes...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: filteredNotes.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              final lines = note.text.split('\n');

              return Dismissible(
                key: Key(note.text + index.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  color: Colors.red.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteNote(index),
                child: ListTile(
                  title: Text(
                    lines.first,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: lines.length > 1
                      ? Text(
                          lines[1],
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                        )
                      : null,
                  onTap: () {
                    final originalIndex =
                        allFolders[currentFolder]!.indexOf(note);
                    _openEditor(existingNote: note, index: originalIndex);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class NoteEditorPage extends StatefulWidget {
  final String initialText;

  const NoteEditorPage({required this.initialText});

  @override
  _NoteEditorPageState createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
  }

  void _saveAndExit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      Navigator.pop(context, Note(text: text));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _saveAndExit),
        title: Text(''),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: TextField(
          controller: _textController,
          maxLines: null,
          autofocus: true,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
          cursorColor: Color(0xFFFFD60A), // Apple yellow
          decoration: InputDecoration.collapsed(
            hintText: 'Start typing your note...',
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor.withOpacity(0.4),
                  fontSize: 18,
                ),
          ),
        ),
      ),
    );
  }
}
