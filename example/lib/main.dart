import 'dart:developer';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: CameraAwesomeBuilder.awesome(
          saveConfig: SaveConfig.photo(
            pathBuilder: () => Future.value(''),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            var res = await CamerawesomePlugin.takePhoto();
            if (res == null) return;
            if (!mounted) return;
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return Scaffold(
                body: Center(
                  child: Image.memory(res),
                ),
              );
            }));
          } catch (e) {
            log(e.toString());
          }
        },
      ),
    );
  }
}
