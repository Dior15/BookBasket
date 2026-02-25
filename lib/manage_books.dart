import 'package:flutter/material.dart';

import 'admin.dart';
import 'manage_users.dart';
import 'reports.dart';
import 'system_settings.dart';

/// ------------------------------
/// BOOK MODEL
/// ------------------------------
class Book {
  String title;
  String author;
  String epubFile;

  Book({
    required this.title,
    required this.author,
    required this.epubFile,
  });
}

/// ------------------------------
/// SHARED BOOK STORE (UI ONLY)
/// ------------------------------
class BookStore {
  static List<Book> books = [
    Book(title: "Sample Book", author: "Admin", epubFile: "sample.epub"),
  ];
}

/// ------------------------------
/// MANAGE BOOKS PAGE
/// ------------------------------
class ManageBooks extends StatefulWidget {
  const ManageBooks({super.key});

  @override
  State<ManageBooks> createState() => _ManageBooksState();
}

class _ManageBooksState extends State<ManageBooks>
{

  void _addOrEditBook({Book? book, int? index}) {
    final titleController =
    TextEditingController(text: book != null ? book.title : "");
    final authorController =
    TextEditingController(text: book != null ? book.author : "");
    final fileController =
    TextEditingController(text: book != null ? book.epubFile : "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(book == null ? "Add Book" : "Edit Book"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: "Author"),
              ),
              TextField(
                controller: fileController,
                decoration: const InputDecoration(
                  labelText: "EPUB File Name",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (book == null) {
                // ADD
                setState(() {
                  BookStore.books.add(
                    Book(
                      title: titleController.text,
                      author: authorController.text,
                      epubFile: fileController.text,
                    ),
                  );
                });
              } else {
                // EDIT
                setState(() {
                  BookStore.books[index!] = Book(
                    title: titleController.text,
                    author: authorController.text,
                    epubFile: fileController.text,
                  );
                });
              }

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteBook(int index) {
    setState(() {
      BookStore.books.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Books"),
      ),
      body: ListView.builder(
        itemCount: BookStore.books.length,
        itemBuilder: (context, index) {
          final book = BookStore.books[index];

          return Dismissible(
            key: Key(book.title + index.toString()),
            background: Container(color: Colors.red),
            onDismissed: (_) => _deleteBook(index),
            child: ListTile(
              leading: const Icon(Icons.book),
              title: Text(book.title),
              subtitle: Text("${book.author} • ${book.epubFile}"),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    _addOrEditBook(book: book, index: index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditBook(),
        child: const Icon(Icons.add),
      ),
    );
  }
}