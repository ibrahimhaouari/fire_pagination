# FirePagination

`FirePagination` is an improved version of the [`firebase_pagination`](https://github.com/OutdatedGuy/firebase_pagination) package that simplifies the implementation of paginated Firestore queries. It provides automatic pagination, supports multiple view types (ListView, GridView, Wrap, PageView), and includes additional features such as error handling, initial item limits, and real-time updates.

## Features ✨

- **Automatic Pagination**: Automatically loads more data as the user scrolls.
- **Multiple View Types**: Supports ListView, GridView, Wrap, and PageView.
- **Real-Time Updates**: Optionally listens for newly added or updated documents in Firestore.
- **Customizable UI**: Customize loaders, error screens, empty states, and more.
- **Enhanced Functionality**:
  - **OnError**: Custom error handling widget. ❌
  - **InitialLimit**: Set an initial limit for the number of items to load. 📊
  - **ListenForAdd**: Automatically load newly added documents in real-time. ➕
  - **ListenForUpdates**: Listen for real-time updates to existing documents. 🔔

## Installation 🛠️

This package is not published yet. To use `FirePagination` in your project:

1. Copy the `lib` folder under `fire_pagination` in your Flutter project directory. 📁
2. Import the `FirePagination` widget into your Dart files as needed. 📝

Example import statement:

```dart
import 'fire_pagination/fire_pagination.dart';
```

## Usage 🚀

### Basic Example

Here's a simple example of using `FirePagination` to display a paginated list of documents from Firestore:

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fire_pagination/fire_pagination.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FirePagination Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirePaginationDemo(),
    );
  }
}

class FirePaginationDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('items')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('FirePagination Example'),
      ),
      body: FirePagination(
        query: query,
        limit: 10,
        initialLimit: 5, // Load 5 items initially
        listenForAdd: true, // Listen for newly added documents
        listenForUpdates: true, // Listen for updates to existing documents
        itemBuilder: (context, docs, index) {
          final doc = docs[index];
          return ListTile(
            title: Text(doc['name']),
            subtitle: Text(doc['description']),
          );
        },
        onEmpty: Center(child: Text('No items found.')),
        onError: (retry) => Center(
          child: ElevatedButton(
            onPressed: retry,
            child: Text('Retry'),
          ),
        ),
        bottomLoader: CircularProgressIndicator(),
      ),
    );
  }
}
```

### Parameters 🔧

- **query**: The Firestore query to paginate.
- **itemBuilder**: A builder function that returns a widget for each document.
- **limit**: The number of items to load per page (default is 10).
- **initialLimit**: The number of items to load initially (default is the same as `limit`).
- **listenForAdd**: Automatically load newly added documents.
- **listenForUpdates**: Listen for real-time updates to existing documents.
- **onEmpty**: A widget to display when no documents are found.
- **onError**: A callback that returns a widget to display when an error occurs.

## Credits 🙏

This package is based on the [`firebase_pagination`](https://github.com/OutdatedGuy/firebase_pagination) package by [OutdatedGuy](https://github.com/OutdatedGuy). We've extended it with additional features like error handling, initial limits, and real-time updates to better suit our project's needs.
