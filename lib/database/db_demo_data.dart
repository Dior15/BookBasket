part of 'db.dart';

extension DemoData on DB {
  Future<void> insertDemoData() async {
    await _insertDemoUsers();
    await _insertDemoBooks();
  }

  Future<void> _insertDemoUsers() async {
    await DB._database.insert(
        "users",
        {
          "username": "admin@bookbasket.com",
          "password": "admin123",
          "isAdmin": 1
        }
    );
    await DB._database.insert(
        "users",
        {
          "username": "user@bookbasket.com",
          "password": "user123",
          "isAdmin": 0
        }
    );
  }

  Future<void> _insertDemoBooks() async {
    await DB._database.insert(
      "books",
      {
        "title": "Camp X",
        "author": "Unknown",
        "fileName": "Camp X.epub",
        "isBorrowed": 0
      },
    );
    await DB._database.insert(
      "books",
      {
        "title": "The Gunslinger",
        "author": "Unknown",
        "fileName": "The Gunslinger.epub",
        "isBorrowed": 0
      },
    );
    await DB._database.insert(
      "books",
      {
        "title": "It Ends With Us",
        "author": "Unknown",
        "fileName": "It Ends With Us.epub",
        "isBorrowed": 0
      },
    );
    await DB._database.insert(
      "books",
      {
        "title": "Fantastic 4 Rise of the Silver Surfer",
        "author": "Unknown",
        "fileName": "Fantastic 4 Rise of the Silver Surfer.epub",
        "isBorrowed": 0
      },
    );
    await DB._database.insert(
      "books",
      {
        "title": "My Baby Mama Is A Loser",
        "author": "Unknown",
        "fileName": "My Baby Mama Is A Loser.epub",
        "isBorrowed": 0
      },
    );
    await DB._database.insert(
      "books",
      {
        "title": "Cruel Mate",
        "author": "Unknown",
        "fileName": "Cruel Mate.epub",
        "isBorrowed": 0
      },
    );
    await DB._database.insert(
      "books",
      {
        "title": "Twelve Angry Men",
        "author": "Unknown",
        "fileName": "Twelve Angry Men.epub",
        "isBorrowed": 0
      },
    );
    await DB._database.insert(
      "books",
      {
        "title": "An Omega For Dylan",
        "author": "Unknown",
        "fileName": "An Omega For Dylan.epub",
        "isBorrowed": 0
      },
    );
    await DB._database.insert(
      "books",
      {
        "title": "Under The Dome",
        "author": "Unknown",
        "fileName": "Under The Dome.epub",
        "isBorrowed": 0
      },
    );
    await DB._database.insert(
        "books",
        {
          "title": "Sisters",
          "author": "Unknown",
          "fileName": "Sisters.epub",
          "isBorrowed": 0
        }
    );
  }
}