import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telegram Video Uploader',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const VideoUploaderScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VideoUploaderScreen extends StatefulWidget {
  const VideoUploaderScreen({super.key});

  @override
  State<VideoUploaderScreen> createState() => _VideoUploaderScreenState();
}

class _VideoUploaderScreenState extends State<VideoUploaderScreen> {
  final TextEditingController _tokenController = TextEditingController(
    text: String.fromEnvironment('BOT_TOKEN', defaultValue: ''),
  );
  final TextEditingController _chatIdController = TextEditingController(
    text: String.fromEnvironment('CHAT_ID', defaultValue: ''),
  );

  final ImagePicker _picker = ImagePicker();
  File? _selectedVideo;
  Subscription? _subscription;

  bool _isProcessing = false;
  double _compressProgress = 0.0;
  String _statusMessage = "اختر فيديو للبدء";

  @override
  void initState() {
    super.initState();
    _subscription = VideoCompress.compressProgress$.subscribe((progress) {
      if (mounted) {
        setState(() {
          _compressProgress = progress;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _tokenController.dispose();
    _chatIdController.dispose();
    VideoCompress.cancelCompression();
    super.dispose();
  }

  /// اختيار فيديو باستخدام image_picker
  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
          double sizeInMB = _selectedVideo!.lengthSync() / (1024 * 1024);
          _statusMessage =
              "تم اختيار الفيديو (${sizeInMB.toStringAsFixed(2)} MB)";
          _compressProgress = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "خطأ أثناء اختيار الفيديو: $e";
      });
    }
  }

  /// دالة التحقق من أمان شهادة تليجرام (SSL Pinning)
  /// دالة التحقق من أمان شهادة تليجرام (SSL Pinning)
  Future<bool> _verifyTelegramCertificate() async {
    try {
      List<String> allowedFingerprints = [
        "BB:20:79:88:EC:3F:B4:EC:71:00:23:AA:88:51:7A:B3:26:FA:F8:78:E5:EE:DF:BB:EA:BD:38:71:71:17:84:12",
      ];

      String result = await HttpCertificatePinning.check(
        serverURL: "https://api.telegram.org",
        headerHttp: {},
        sha: SHA.SHA256, // إرسال الـ Enum مباشرة
        allowedSHAFingerprints:
            allowedFingerprints, // استخدام الاسم الصحيح للمعامل
        timeout: 10,
      );

      return result.contains("SECURE") || result == "CONNECTION_SECURE";
    } catch (e) {
      return false;
    }
  }

  /// ضغط الفيديو ورفعه إلى تليجرام
  Future<void> _compressAndUpload() async {
    if (_selectedVideo == null) {
      setState(() => _statusMessage = "يرجى اختيار فيديو أولاً!");
      return;
    }

    final token = _tokenController.text.trim();
    final chatId = _chatIdController.text.trim();

    if (token.isEmpty || chatId.isEmpty) {
      setState(() => _statusMessage = "يرجى ملء بيانات البوت والـ Chat ID");
      return;
    }

    setState(() {
      _isProcessing = true;
      _compressProgress = 0.0;
      _statusMessage = "جاري التحقق من أمان الاتصال الشبكي (SSL Pinning)...";
    });

    // 1. إجراء فحص الشهادة الأمنية قبل البدء في معالجة أو رفع أي شيء
    bool isSecure = await _verifyTelegramCertificate();
    if (!isSecure) {
      if (mounted) {
        setState(() {
          _statusMessage =
              "خطأ أمني: فشل التحقق من شهادة السيرفر! قد يكون الاتصال مخترقاً (MitM Attack).";
          _isProcessing = false;
        });
      }
      return;
    }

    setState(() {
      _statusMessage = "الاتصال آمن! جاري ضغط الفيديو...";
    });

    try {
      MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        _selectedVideo!.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: false,
      );

      File fileToUpload = (mediaInfo != null && mediaInfo.file != null)
          ? mediaInfo.file!
          : _selectedVideo!;

      double originalSizeMB = _selectedVideo!.lengthSync() / (1024 * 1024);
      double compressedSizeMB = fileToUpload.lengthSync() / (1024 * 1024);

      if (mounted) {
        setState(() {
          _statusMessage =
              "تم الضغط بنجاح (${originalSizeMB.toStringAsFixed(1)}MB -> ${compressedSizeMB.toStringAsFixed(1)}MB)\nجاري الرفع إلى تليجرام...";
        });
      }

      var uri = Uri.parse("https://api.telegram.org/bot$token/sendVideo");
      var request = http.MultipartRequest("POST", uri);

      request.fields['chat_id'] = chatId;
      request.fields['caption'] =
          "فيديو مضغوط | الحجم: ${compressedSizeMB.toStringAsFixed(2)} MB 🚀";

      var stream = http.ByteStream(fileToUpload.openRead());
      var length = await fileToUpload.length();

      var multipartFile = http.MultipartFile(
        'video',
        stream,
        length,
        filename: fileToUpload.path.split('/').last,
      );

      request.files.add(multipartFile);

      var response = await request.send();

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _statusMessage =
                "تم الرفع بنجاح! 🎉\nالحجم النهائي: ${compressedSizeMB.toStringAsFixed(2)} MB";
            _selectedVideo = null;
          });
        } else {
          setState(() {
            _statusMessage = "فشل الرفع. كود الاستجابة: ${response.statusCode}";
          });
        }
      }

      await VideoCompress.deleteAllCache();
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = "حدث خطأ غير متوقع: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("نظام معالجة ورفع الفيديو"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: "Bot Token",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _chatIdController,
              decoration: const InputDecoration(
                labelText: "Chat ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickVideo,
              icon: const Icon(Icons.video_library),
              label: const Text("اختيار فيديو"),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_isProcessing || _selectedVideo == null)
                  ? null
                  : _compressAndUpload,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("ضغط ورفع الفيديو"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (_isProcessing) ...[
              LinearProgressIndicator(
                value: _compressProgress > 0 ? _compressProgress / 100 : null,
              ),
              const SizedBox(height: 10),
              Text(
                "نسبة الضغط: ${_compressProgress.toStringAsFixed(0)}%",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
