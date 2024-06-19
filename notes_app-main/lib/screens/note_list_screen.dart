import 'dart:io';

import 'package:flutter/material.dart';
import 'package:notes/models/note.dart';
import 'package:notes/screens/google_maps_screen.dart';
import 'package:notes/services/note_service.dart';
import 'package:notes/widgets/note_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NoteListScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const NoteListScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: const NoteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return NoteDialog();
            },
          );
        },
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteList extends StatelessWidget {
  const NoteList({Key? key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: NoteService.getNoteList(),
      builder: (context, AsyncSnapshot<List<Note>> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final notes = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final document = notes[index];

            return Card(
              child: Column(
                children: [
                  if (document.imageUrl != null &&
                      Uri.parse(document.imageUrl!).isAbsolute)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        document.imageUrl!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ListTile(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return NoteDialog(note: document);
                        },
                      );
                    },
                    title: Text(document.title),
                    subtitle: Text(document.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GoogleMapsScreen(
                                  latitude: double.parse(document.lat!),
                                  longitude: double.parse(document.lng!),
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Icon(Icons.map),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        InkWell(
                          onTap: () {
                            _shareImage(document);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Icon(Icons.share),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        InkWell(
                          onTap: () {
                            showAlertDialog(context, document);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Icon(Icons.delete),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _shareImage(Note document) async {
    try {
      final response = await http.get(Uri.parse(document.imageUrl!));
      final documentDirectory = (await getTemporaryDirectory()).path;
      final imgFile = File('$documentDirectory/flutter.png');
      imgFile.writeAsBytesSync(response.bodyBytes);

      final message =
          'Title: ${document.title}\nDescription: ${document.description}\n'
          'Location: https://www.google.com/maps/search/?api=1&query=${document.lat},${document.lng}';

      Share.shareXFiles([XFile(imgFile.path)], text: message);
    } catch (e) {
      print('Error sharing image: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await canLaunch(url)) {
      throw Exception('Could Not Launch $url');
    }
    await launch(url);
  }

  void showAlertDialog(BuildContext context, Note document) {
    Widget cancelButton = ElevatedButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = ElevatedButton(
      child: const Text("Yes"),
      onPressed: () {
        NoteService.deleteNote(document).whenComplete(() {
          Navigator.of(context).pop();
        });
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Delete Note"),
      content: const Text("Are you sure to delete Note?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
