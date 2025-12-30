import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui'; // For blur/glass effect
import 'book.dart';

void main() {
  runApp(Readly());
}

class Readly extends StatefulWidget {
  @override
  _ReadlyState createState() => _ReadlyState();
}

class _ReadlyState extends State<Readly> {
  bool isDarkTheme = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Readly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Colors.black),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        brightness: Brightness.dark,
        iconTheme: IconThemeData(color: Colors.purple),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: BookListPage(
        toggleTheme: () {
          setState(() {
            isDarkTheme = !isDarkTheme;
          });
        },
        isDarkTheme: isDarkTheme,
      ),
    );
  }
}

class BookListPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkTheme;

  BookListPage({required this.toggleTheme, required this.isDarkTheme});

  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage>
    with TickerProviderStateMixin {
  List<Book> books = [];
  bool showUnreadOnly = false; // Filter state
  String sortOption = 'None';   // Sort state
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? booksJson = prefs.getString('books');
    if (booksJson != null) {
      List decoded = json.decode(booksJson);
      setState(() {
        books = decoded.map((b) => Book.fromMap(b)).toList();
      });
    }
  }

  void _saveBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> booksMap = books.map((b) => b.toMap()).toList();
    prefs.setString('books', json.encode(booksMap));
  }

  void _addBook(String title, String author) {
    setState(() {
      books.add(Book(title: title, author: author));
      _saveBooks();
    });
  }

  void _toggleRead(Book book) {
    setState(() {
      book.isRead = !book.isRead;
      _saveBooks();
    });
  }

  void _deleteBook(Book book) {
    setState(() {
      books.remove(book);
      _saveBooks();
    });
  }

  void _editBook(Book book) {
    String title = book.title;
    String author = book.author;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(hintText: 'Title'),
              controller: TextEditingController(text: title),
              onChanged: (val) => title = val,
            ),
            TextField(
              decoration: InputDecoration(hintText: 'Author'),
              controller: TextEditingController(text: author),
              onChanged: (val) => author = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                book.title = title;
                book.author = author;
                _saveBooks();
              });
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editNotes(Book book) {
    String notes = book.notes ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reading Notes'),
        content: TextField(
          decoration: InputDecoration(hintText: 'Write your notes here...'),
          controller: TextEditingController(text: notes),
          maxLines: 5,
          onChanged: (val) => notes = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                book.notes = notes;
                _saveBooks();
              });
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog() {
    String title = '';
    String author = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add a Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(hintText: 'Title'),
              onChanged: (val) => title = val,
            ),
            TextField(
              decoration: InputDecoration(hintText: 'Author'),
              onChanged: (val) => author = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (title.isNotEmpty) _addBook(title, author);
              Navigator.of(context).pop();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply filter, sort, search
    List<Book> displayedBooks = books;

    if (showUnreadOnly) {
      displayedBooks = displayedBooks.where((book) => !book.isRead).toList();
    }

    if (sortOption == 'Title') {
      displayedBooks.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (sortOption == 'Author') {
      displayedBooks.sort(
          (a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()));
    }

    if (searchQuery.isNotEmpty) {
      displayedBooks = displayedBooks.where((book) {
        final query = searchQuery.toLowerCase();
        return book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query);
      }).toList();
    }

    // Statistics
    int totalBooks = books.length;
    int readBooks = books.where((b) => b.isRead).length;
    int unreadBooks = totalBooks - readBooks;

    return Scaffold(
      appBar: AppBar(
        title: Text('Readly',
            style: TextStyle(
                color: widget.isDarkTheme ? Colors.white : Colors.black)),
        backgroundColor: widget.isDarkTheme ? Colors.black : Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6,
                color: widget.isDarkTheme ? Colors.purple : Colors.black),
            onPressed: widget.toggleTheme,
          ),
          // ====== Filter & Sort Menu ======
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list,
                color: widget.isDarkTheme ? Colors.purple : Colors.black),
            onSelected: (value) {
              setState(() {
                if (value == 'All') {
                  showUnreadOnly = false;
                } else if (value == 'Unread') {
                  showUnreadOnly = true;
                } else if (value == 'Title' || value == 'Author') {
                  sortOption = value;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'All', child: Text('All Books')),
              PopupMenuItem(value: 'Unread', child: Text('Unread Books')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'Title', child: Text('Sort by Title')),
              PopupMenuItem(value: 'Author', child: Text('Sort by Author')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title or author...',
                prefixIcon: Icon(Icons.search,
                    color:
                        widget.isDarkTheme ? Colors.purple : Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
          ),
          // Statistics Card
          GlassCard(
            darkMode: widget.isDarkTheme,
            child: ListTile(
              leading: Icon(Icons.bar_chart,
                  color:
                      widget.isDarkTheme ? Colors.purple : Colors.black),
              title: Text('Total Books: $totalBooks',
                  style: TextStyle(
                      color: widget.isDarkTheme ? Colors.white : Colors.black)),
              subtitle: Text('Read: $readBooks | Unread: $unreadBooks',
                  style: TextStyle(
                      color:
                          widget.isDarkTheme ? Colors.white70 : Colors.black87)),
            ),
          ),
          // Book List
          Expanded(
            child: ListView.builder(
              itemCount: displayedBooks.length,
              itemBuilder: (context, index) {
                final book = displayedBooks[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Dismissible(
                    key: Key(book.title + book.author),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      _deleteBook(book);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${book.title} deleted')),
                      );
                    },
                    background: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: widget.isDarkTheme ? Colors.purple : Colors.black,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        height: double.infinity,
                        child: Icon(Icons.delete,
                            color:
                                widget.isDarkTheme ? Colors.black : Colors.white),
                      ),
                    ),
                    child: GlassCard(
                      darkMode: widget.isDarkTheme,
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        title: Text(book.title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.isDarkTheme
                                    ? Colors.white
                                    : Colors.black)),
                        subtitle: Text(book.author,
                            style: TextStyle(
                                color: widget.isDarkTheme
                                    ? Colors.white70
                                    : Colors.black87)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.notes,
                                  color: widget.isDarkTheme
                                      ? Colors.purple
                                      : Colors.black),
                              onPressed: () => _editNotes(book),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: widget.isDarkTheme
                                      ? Colors.purple
                                      : Colors.black),
                              onPressed: () => _editBook(book),
                            ),
                            IconButton(
                              icon: Icon(
                                book.isRead
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: widget.isDarkTheme
                                    ? Colors.purple
                                    : Colors.black,
                              ),
                              onPressed: () => _toggleRead(book),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookDialog,
        child: Icon(
          Icons.add,
          color: widget.isDarkTheme ? Colors.black : Colors.purple,
        ),
        backgroundColor: widget.isDarkTheme ? Colors.purple : Colors.white,
      ),
    );
  }
}

// Glass Card Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final bool darkMode;

  const GlassCard({required this.child, this.darkMode = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: darkMode ? 0 : 2,
      color: darkMode ? Colors.transparent : Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: darkMode
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: child,
                ),
              ),
            )
          : child,
    );
  }
}
