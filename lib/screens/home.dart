import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final titleTextController = TextEditingController();
  final contentTextController = TextEditingController();
  final labelTextController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  void openNoteBox({String? docId, String? existingTitle, String? existingNote, String? existingLabel}) {
    if (docId != null) {
      titleTextController.text = existingTitle ?? '';
      contentTextController.text = existingNote ?? '';
      labelTextController.text = existingLabel ?? '';
    } else {
      titleTextController.clear();
      contentTextController.clear();
      labelTextController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? "Create new Note" : "Edit Note"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Title"),
                controller: titleTextController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(labelText: "Content"),
                controller: contentTextController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(labelText: "Label"),
                controller: labelTextController,
              ),
            ],
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                if (titleTextController.text.isEmpty || contentTextController.text.isEmpty || labelTextController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                
                if (docId == null) {
                  firestoreService.addNote(
                    titleTextController.text,
                    contentTextController.text,
                    labelTextController.text,
                  );
                } else {
                  firestoreService.updateNote(
                    docId,
                    titleTextController.text,
                    contentTextController.text,
                    labelTextController.text,
                  );
                }
                titleTextController.clear();
                contentTextController.clear();
                labelTextController.clear();
                Navigator.pop(context);
              },
              child: Text(docId == null ? "Create" : "Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Notes'),
            centerTitle: true,
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text(authSnapshot.data?.email ?? 'User', style: const TextStyle(fontSize: 11)),
                  ),
                  PopupMenuItem(
                    child: const Text('Logout'),
                    onTap: logout,
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    authSnapshot.data?.email ?? 'User',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: openNoteBox,
            child: const Icon(Icons.add),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getNotes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List notesList = snapshot.data!.docs;
                
                if (notesList.isEmpty) {
                  return const Center(
                    child: Text('No notes yet. Create one to get started!'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: notesList.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot document = notesList[index];
                    String docId = document.id;
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    String noteTitle = data['title'] ?? 'Untitled';
                    String noteContent = data['content'] ?? '';
                    String noteLabel = data['label'] ?? 'General';
                    Timestamp? timestamp = data['createdAt'] as Timestamp?;
                    String noteDate = timestamp != null ? timestamp.toDate().toString().split(' ')[0] : 'N/A';

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 28,
                              child: Chip(
                                label: Text(
                                  noteLabel,
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              height: 40,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  noteTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              height: 24,
                              child: Text(
                                noteContent,
                                style: const TextStyle(fontSize: 9),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 24,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      noteDate,
                                      style: const TextStyle(fontSize: 7, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          openNoteBox(
                                            docId: docId,
                                            existingNote: noteContent,
                                            existingTitle: noteTitle,
                                            existingLabel: noteLabel,
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(1),
                                          child: Icon(Icons.edit, size: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete Note'),
                                              content: const Text('Are you sure?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    firestoreService.deleteNote(docId);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(1),
                                          child: Icon(Icons.delete, size: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    titleTextController.dispose();
    contentTextController.dispose();
    labelTextController.dispose();
    super.dispose();
  }
}