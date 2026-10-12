# 📹 Telegram Video Uploader & Compressor (with SSL Pinning)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Security](https://img.shields.io/badge/Security-SSL%20Pinning-red?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

</div>

---

## 📌 عن المشروع (About The Project)

تطبيق **Flutter** متكامل وضخم مخصص لمعالجة الفيديوهات ورفعها تلقائياً عبر **Telegram Bot API**. يتميز التطبيق بضغط الفيديوهات وتقليل حجمها قبل الرفع لضمان السرعة وتوفير استهلاك البيانات، مع تطبيق معايير **الأمن السيبراني (SSL/TLS Certificate Pinning)** للحماية من هجمات (Man-in-the-Middle).

---

## ✨ الميزات الرئيسية (Key Features)

- 🎥 **اختيار الفيديوهات:** اختيار الفيديوهات بسهولة من معرض الصور/الفيديو باستخدام `image_picker`.
- 📉 **ضغط الفيديوهات (Video Compression):** ضغط الفيديو وتقليل حجمه مع إمكانية متابعة نسبة التقدم (Progress Indicator).
- 🤖 **التكامل مع تلجرام بوت:** رفع الفيديوهات المضغوطة مباشرة إلى القنوات أو المحادثات عبر HTTP Multipart Request.
- 🔐 **تعزيز الأمان (Certificate Pinning):** استخدام مكتبة `http_certificate_pinning` للتحقق من شهادة SSL والوقاية من الاعتراض الشبكي.
- ⚙️ **إعدادات ديناميكية:** دعم تمرير `BOT_TOKEN` و `CHAT_ID` عبر بيئة التشغيل (`String.fromEnvironment`).

---

## 🛠️ التقنيات والمكتبات المستخدمة (Tech Stack)

- **إطار العمل:** [Flutter](https://flutter.dev) (Dart)
- **معالجة وضغط الفيديو:** `video_compress`
- **الأمن والحماية الشبكية:** `http_certificate_pinning`
- **الشبكات والرفع:** `http`
- **التقاط الصور والفيديو:** `image_picker`

---

## 🚀 كيفية التشغيل والتجربة (Getting Started)

### المتطلبات الأساسية
* بيئة [Flutter SDK](https://docs.flutter.dev/get-started/install) مثبتة.

### التشغيل (Run)

1. استنساخ المستودع:
   ```bash
   git clone [https://github.com/Hassen77/my_security_app.git](https://github.com/Hassen77/my_security_app.git)
