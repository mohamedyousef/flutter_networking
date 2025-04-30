import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:network/network.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GraphQL Upload Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _selectedFile;
  bool _isLoading = false;
  String? _response;
  final TextEditingController _textController = TextEditingController();

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = File(result.files.first.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      const query = '''
        query GetTodos {
          todos {
            id
            title
            completed
          }
        }
      ''';

      final request = NetworkRequest.graphQl(
        query: query,
        variables: {},
      );

      final response =
          await networkService.executeGraphQLRequest<Map<String, dynamic>>(
        request: request,
        fromJson: (json) => json,
      );

      setState(() {
        _response = response.when(
          success: (data) => 'Success: ${data.toString()}',
          failure: (error) {
            final test = response.getDataOnError(
              fromJson: Test.fromJson,
            );
            return 'Error: ${error.toString()}  ${test}';
          },
        );
      });

      await networkService.executeGraphQLRequest(
          request: request, fromJson: (fromJson) {});
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GraphQL Upload Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Pick File'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to send as multipart',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendTextMultipart,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Text Multipart'),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Selected file: ${_selectedFile!.path.split('/').last}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _uploadFile,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Upload File'),
              ),
            ],
            if (_response != null) ...[
              const SizedBox(height: 16),
              Text(
                _response!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendTextMultipart() async {
    setState(() {
      _isLoading = true;
      _response = null;
    });
    try {
      final request = NetworkRequest.post(
        endpoint: '/describe-damage',
        body: {
          'images': [_selectedFile],
        },
      );
      final response = await networkService.requestMultipart(
        request: request,
      );
      setState(() {
        _response = response.when(
          success: (data) => 'Success: ${data.toString()}',
          failure: (error) => 'Error: $error',
        );
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

final networkService = NetworkService(
  baseUrlBuilder: () async => 'http://127.0.0.1:8000',
  enableLogging: true,
  onUnAuthorizedCallback: () {
    // You can use context if needed, e.g. showDialog or ScaffoldMessenger
    debugPrint('Unauthorized! Callback triggered.');
  },
);

class Test {
  const Test();
  factory Test.fromJson(Map<String, dynamic> data) {
    return Test();
  }
}
