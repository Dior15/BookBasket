import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';

import '../basket.dart';
import '../database/db.dart';

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

class BookStore {
  static List<Book> books = [];
}

class ManageBooks extends StatefulWidget {
  const ManageBooks({super.key});

  @override
  State<ManageBooks> createState() => _ManageBooksState();
}

class _ManageBooksState extends State<ManageBooks> {
  static const _accent = Color(0xFF3949AB);

  Future<void> _pickEpubFile(TextEditingController fileController) async {
    const XTypeGroup epubType = XTypeGroup(
      label: 'EPUB',
      extensions: ['epub'],
    );

    final XFile? file = await openFile(
      acceptedTypeGroups: [epubType],
    );

    if (file != null) {
      fileController.text = file.name;
      // use file.path instead if you want the absolute path
    }
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "EPUB File",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: () => _pickEpubFile(fileController),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _pickEpubFile(fileController),
                icon: const Icon(Icons.folder_open),
                label: const Text("Choose EPUB from Device"),
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
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  authorController.text.isEmpty ||
                  fileController.text.isEmpty) {
                return;
              }

              if (book == null) {
                DB db = await DB.getReference();
                db.addNewBook(
                  titleController.text,
                  authorController.text,
                  fileController.text,
                );

                context.read<BasketContentManager>().reload();

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
  void initState() {
    super.initState();
    getBooks();
  }

  void getBooks() async {
    BookStore.books = [];

    DB db = await DB.getReference();
    List<Map<String, Object?>> books = await db.getBooks();

    for (Map<String, Object?> book in books) {
      BookStore.books.add(
        Book(
          title: book["title"].toString(),
          author: book["author"].toString(),
          epubFile: book["fileName"].toString(),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Books"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                'Manage Books (${BookStore.books.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BookStore.books.isEmpty
                  ? const Center(child: Text('No books available yet.'))
                  : ListView.builder(
                itemCount: BookStore.books.length,
                itemBuilder: (context, index) {
                  final book = BookStore.books[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: Key(book.title + index.toString()),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onDismissed: (_) => _deleteBook(index),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.book_rounded,
                              color: _accent,
                            ),
                          ),
                          title: Text(
                            book.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            "${book.author} • ${book.epubFile}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () =>
                                _addOrEditBook(book: book, index: index),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditBook(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}