import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FileDownloader(),
    );
  }
}

class FileDownloader extends StatefulWidget {
  const FileDownloader({super.key});

  @override
  _FileDownloaderState createState() => _FileDownloaderState();
}

class _FileDownloaderState extends State<FileDownloader> {
  double _progress = 0.0;
  bool _isDownloading = false;
  String? _filePath;

  Future<void> _downloadFile() async {
    Dio dio = Dio();
    String url =
        "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";

    try {
      setState(() {
        _progress = 0.0;
        _isDownloading = true;
      });

      Directory directory = await getApplicationDocumentsDirectory();
      String savePath = "${directory.path}/sample.pdf";

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _filePath = savePath;
        _openFile();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download Complete! File saved to: $savePath")),
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download Failed: $e")),
      );
    }
  }

  void _openFile() {
    if (_filePath != null) {
      OpenFile.open(_filePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("File Downloader")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isDownloading
                  ? Column(
                      children: [
                        CircularProgressIndicator(value: _progress),
                        const SizedBox(height: 10),
                        Text(
                          "${(_progress * 100).toStringAsFixed(0)}% Downloaded",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _downloadFile,
                      child: const Text("Download File"),
                    ),
              const SizedBox(height: 20),
              _filePath != null
                  ? ElevatedButton(
                      onPressed: _openFile,
                      child: const Text("Open File"),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
