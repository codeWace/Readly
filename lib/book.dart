import 'dart:convert';

class Book {
  String title;
  String author;
  bool isRead;
  String? notes; // <-- NEW: optional notes field

  Book({required this.title, required this.author, this.isRead = false, this.notes});

  // Convert Book to Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'isRead': isRead,
      'notes': notes, // <-- include notes
    };
  }

  // Convert Map to Book
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      title: map['title'],
      author: map['author'],
      isRead: map['isRead'] ?? false,
      notes: map['notes'], // <-- load notes
    );
  }

  // Convert Book to JSON string
  String toJson() => json.encode(toMap());

  // Convert JSON string to Book
  factory Book.fromJson(String source) => Book.fromMap(json.decode(source));
}
