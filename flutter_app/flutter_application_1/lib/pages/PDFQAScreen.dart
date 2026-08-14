import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF QA App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const PDFQAScreen(),
    );
  }
}

class PDFQAScreen extends StatefulWidget {
  const PDFQAScreen({super.key});

  @override
  State<PDFQAScreen> createState() => _PDFQAScreenState();
}

class _PDFQAScreenState extends State<PDFQAScreen> {

  // Android emulator uses 10.0.2.2 to reach localhost
  final String baseUrl = "http://10.0.2.2:8000";

  final TextEditingController _questionController =
      TextEditingController();

  bool _pdfUploaded = false;
  bool _isUploading = false;
  bool _isAsking = false;
  String _uploadedFileName = "";
  List<Map<String, String>> _chatHistory = [];


  Future<void> _pickAndUploadPDF() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-pdf'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        setState(() {
          _pdfUploaded = true;
          _uploadedFileName = fileName;
          _chatHistory = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PDF uploaded successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Upload failed. Try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

 
  Future<void> _askQuestion() async {
    String question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isAsking = true;
      _chatHistory.add({
        "role": "user",
        "text": question,
      });
      _questionController.clear();
    });

    try {
      var response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": question}),
      );

      var data = jsonDecode(response.body);

      setState(() {
        _chatHistory.add({
          "role": "ai",
          "text": data["answer"],
        });
      });
    } catch (e) {
      setState(() {
        _chatHistory.add({
          "role": "ai",
          "text": "Error: $e",
        });
      });
    } finally {
      setState(() {
        _isAsking = false;
      });
    }
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          "PDF QA System",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [

          // Upload Section
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.deepPurple,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  _pdfUploaded
                      ? _uploadedFileName
                      : "No PDF uploaded",
                  style: TextStyle(
                    color: _pdfUploaded
                        ? Colors.green
                        : Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed:
                      _isUploading ? null : _pickAndUploadPDF,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    _isUploading
                        ? "Uploading..."
                        : "Upload PDF",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Chat History
          Expanded(
            child: _pdfUploaded
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    itemCount: _chatHistory.length,
                    itemBuilder: (context, index) {
                      var message = _chatHistory[index];
                      bool isUser =
                          message["role"] == "user";

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context)
                                        .size
                                        .width *
                                    0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.deepPurple
                                : const Color(0xFF16213E),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(
                            message["text"]!,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child:
                     Text(
                      "Upload a PDF to start asking questions",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
          ),

          // Loading Indicator
          if (_isAsking)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            ),

          // Question Input
          if (_pdfUploaded)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF16213E),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            "Ask a question about the PDF...",
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.deepPurple,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.deepPurple,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.deepPurple,
                            width: 2,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        _isAsking ? null : _askQuestion,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.deepPurple,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}