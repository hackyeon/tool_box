import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ads/ad_support.dart';
import '../../core/ads/banner_ad_widget.dart';
import 'qr_image_saver.dart';

enum QrType {
  text('텍스트'),
  url('링크'),
  wifi('와이파이'),
  phone('전화번호'),
  sms('문자'),
  email('이메일'),
  contact('연락처');

  const QrType(this.label);

  final String label;
}

class QrGeneratorPage extends StatefulWidget {
  const QrGeneratorPage({super.key});

  @override
  State<QrGeneratorPage> createState() => _QrGeneratorPageState();
}

class _QrGeneratorPageState extends State<QrGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  final _qrPreviewKey = GlobalKey();

  final _textController = TextEditingController();
  final _urlController = TextEditingController();
  final _ssidController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _memoController = TextEditingController();

  QrType _selectedType = QrType.text;
  String _wifiSecurity = 'WPA/WPA2';
  String? _qrData;
  String? _generationError;
  bool _isHandlingImage = false;

  @override
  void dispose() {
    for (final controller in [
      _textController,
      _urlController,
      _ssidController,
      _wifiPasswordController,
      _phoneController,
      _messageController,
      _emailController,
      _subjectController,
      _bodyController,
      _nameController,
      _companyController,
      _jobTitleController,
      _websiteController,
      _addressController,
      _memoController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR 생성기')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '어떤 QR 코드를 만들까요?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: QrType.values.map((type) {
                      return ChoiceChip(
                        label: Text(type.label),
                        selected: _selectedType == type,
                        onSelected: (_) => _selectType(type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ..._buildFields(),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _generateQr,
                              icon: const Icon(Icons.qr_code_2),
                              label: const Text('QR 생성하기'),
                            ),
                            if (_generationError != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _generationError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_qrData != null) ...[
                    const SizedBox(height: 20),
                    _QrResultCard(
                      qrPreviewKey: _qrPreviewKey,
                      qrData: _qrData!,
                      isHandlingImage: _isHandlingImage,
                      onCopy: _copyQrData,
                      onSave: _saveQrImage,
                      onShare: _shareQrImage,
                      onReset: _resetAll,
                    ),
                  ],
                  if (isMobileAdSupported) ...[
                    const SizedBox(height: 20),
                    const Center(child: BannerAdWidget()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    return switch (_selectedType) {
      QrType.text => [
        _textField(
          controller: _textController,
          label: '내용',
          maxLines: 4,
          validator: _requiredValidator('내용을 입력해 주세요.'),
        ),
      ],
      QrType.url => [
        _textField(
          controller: _urlController,
          label: '웹사이트 주소',
          keyboardType: TextInputType.url,
          hintText: 'naver.com',
          validator: _urlValidator,
        ),
      ],
      QrType.wifi => [
        _textField(
          controller: _ssidController,
          label: '와이파이 이름',
          validator: _requiredValidator('와이파이 이름을 입력해 주세요.'),
        ),
        _fieldGap,
        DropdownButtonFormField<String>(
          initialValue: _wifiSecurity,
          decoration: const InputDecoration(
            labelText: '보안 방식',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'WPA/WPA2', child: Text('WPA/WPA2')),
            DropdownMenuItem(value: 'WEP', child: Text('WEP')),
            DropdownMenuItem(value: '없음', child: Text('없음')),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _wifiSecurity = value;
              _qrData = null;
            });
          },
        ),
        _fieldGap,
        _textField(
          controller: _wifiPasswordController,
          label: '비밀번호',
          obscureText: false,
          validator: _wifiPasswordValidator,
        ),
      ],
      QrType.phone => [
        _textField(
          controller: _phoneController,
          label: '전화번호',
          keyboardType: TextInputType.phone,
          validator: _requiredValidator('전화번호를 입력해 주세요.'),
        ),
      ],
      QrType.sms => [
        _textField(
          controller: _phoneController,
          label: '전화번호',
          keyboardType: TextInputType.phone,
          validator: _requiredValidator('전화번호를 입력해 주세요.'),
        ),
        _fieldGap,
        _textField(
          controller: _messageController,
          label: '메시지 내용',
          maxLines: 3,
          validator: _requiredValidator('내용을 입력해 주세요.'),
        ),
      ],
      QrType.email => [
        _textField(
          controller: _emailController,
          label: '이메일 주소',
          keyboardType: TextInputType.emailAddress,
          validator: _emailValidator,
        ),
        _fieldGap,
        _textField(controller: _subjectController, label: '제목'),
        _fieldGap,
        _textField(controller: _bodyController, label: '내용', maxLines: 4),
      ],
      QrType.contact => [
        _textField(controller: _nameController, label: '이름'),
        _fieldGap,
        _textField(controller: _companyController, label: '회사'),
        _fieldGap,
        _textField(controller: _jobTitleController, label: '직책'),
        _fieldGap,
        _textField(
          controller: _phoneController,
          label: '전화번호',
          keyboardType: TextInputType.phone,
          validator: _contactValidator,
        ),
        _fieldGap,
        _textField(
          controller: _emailController,
          label: '이메일',
          keyboardType: TextInputType.emailAddress,
          validator: _optionalEmailValidator,
        ),
        _fieldGap,
        _textField(
          controller: _websiteController,
          label: '웹사이트',
          keyboardType: TextInputType.url,
        ),
        _fieldGap,
        _textField(controller: _addressController, label: '주소'),
        _fieldGap,
        _textField(controller: _memoController, label: '메모', maxLines: 3),
      ],
    };
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: obscureText ? 1 : maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      onChanged: (_) {
        if (_qrData == null && _generationError == null) {
          return;
        }
        setState(() {
          _qrData = null;
          _generationError = null;
        });
      },
    );
  }

  Widget get _fieldGap => const SizedBox(height: 14);

  String? Function(String?) _requiredValidator(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  String? _urlValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '내용을 입력해 주세요.';
    }

    final normalized = _normalizeUrl(value);
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return '올바른 웹사이트 주소를 입력해 주세요.';
    }

    return null;
  }

  String? _wifiPasswordValidator(String? value) {
    if (_wifiSecurity == '없음') {
      return null;
    }

    return value == null || value.trim().isEmpty ? '비밀번호를 입력해 주세요.' : null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '내용을 입력해 주세요.';
    }

    if (!_isValidEmail(value)) {
      return '올바른 이메일 주소를 입력해 주세요.';
    }

    return null;
  }

  String? _optionalEmailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (!_isValidEmail(value)) {
      return '올바른 이메일 주소를 입력해 주세요.';
    }

    return null;
  }

  String? _contactValidator(String? value) {
    if (_nameController.text.trim().isEmpty &&
        (value == null || value.trim().isEmpty)) {
      return '이름 또는 전화번호 중 하나는 입력해 주세요.';
    }

    return null;
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  void _selectType(QrType type) {
    if (_selectedType == type) {
      return;
    }

    setState(() {
      _selectedType = type;
      _qrData = null;
      _generationError = null;
    });
    _formKey.currentState?.reset();
  }

  void _generateQr() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _qrData = null;
        _generationError = null;
      });
      return;
    }

    final data = _buildQrData();
    try {
      QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M);
    } catch (_) {
      setState(() {
        _qrData = null;
        _generationError = 'QR로 만들 수 없는 내용입니다.';
      });
      return;
    }

    setState(() {
      _qrData = data;
      _generationError = null;
    });
  }

  String _buildQrData() {
    return switch (_selectedType) {
      QrType.text => _textController.text.trim(),
      QrType.url => _normalizeUrl(_urlController.text),
      QrType.wifi => _buildWifiData(),
      QrType.phone => 'tel:${_phoneController.text.trim()}',
      QrType.sms =>
        'SMSTO:${_phoneController.text.trim()}:${_messageController.text.trim()}',
      QrType.email => _buildEmailData(),
      QrType.contact => _buildContactData(),
    };
  }

  String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return 'https://$trimmed';
  }

  String _buildWifiData() {
    final security = switch (_wifiSecurity) {
      'WEP' => 'WEP',
      '없음' => 'nopass',
      _ => 'WPA',
    };
    final ssid = _escapeWifi(_ssidController.text.trim());
    final password = _wifiSecurity == '없음'
        ? ''
        : _escapeWifi(_wifiPasswordController.text.trim());

    return 'WIFI:T:$security;S:$ssid;P:$password;;';
  }

  String _buildEmailData() {
    final email = _escapeMatMsg(_emailController.text.trim());
    final subject = _escapeMatMsg(_subjectController.text.trim());
    final body = _escapeMatMsg(_bodyController.text.trim());

    return 'MATMSG:TO:$email;SUB:$subject;BODY:$body;;';
  }

  String _buildContactData() {
    final lines = [
      'BEGIN:VCARD',
      'VERSION:3.0',
      if (_nameController.text.trim().isNotEmpty)
        'N:${_escapeVCard(_nameController.text.trim())}',
      if (_nameController.text.trim().isNotEmpty)
        'FN:${_escapeVCard(_nameController.text.trim())}',
      if (_companyController.text.trim().isNotEmpty)
        'ORG:${_escapeVCard(_companyController.text.trim())}',
      if (_jobTitleController.text.trim().isNotEmpty)
        'TITLE:${_escapeVCard(_jobTitleController.text.trim())}',
      if (_phoneController.text.trim().isNotEmpty)
        'TEL:${_escapeVCard(_phoneController.text.trim())}',
      if (_emailController.text.trim().isNotEmpty)
        'EMAIL:${_escapeVCard(_emailController.text.trim())}',
      if (_websiteController.text.trim().isNotEmpty)
        'URL:${_normalizeUrl(_websiteController.text)}',
      if (_addressController.text.trim().isNotEmpty)
        'ADR:${_escapeVCard(_addressController.text.trim())}',
      if (_memoController.text.trim().isNotEmpty)
        'NOTE:${_escapeVCard(_memoController.text.trim())}',
      'END:VCARD',
    ];

    return lines.join('\n');
  }

  String _escapeWifi(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll(':', r'\:')
        .replaceAll('"', r'\"');
  }

  String _escapeMatMsg(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll(';', r'\;');
  }

  String _escapeVCard(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,');
  }

  Future<void> _copyQrData() async {
    final data = _qrData;
    if (data == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: data));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('QR 내용이 복사되었습니다.')));
  }

  Future<void> _saveQrImage() async {
    await _handleQrImage((bytes, fileName) async {
      await saveQrPng(bytes, fileName);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('QR 이미지가 저장되었습니다.')));
    });
  }

  Future<void> _shareQrImage() async {
    await _handleQrImage((bytes, fileName) async {
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;

      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        text: _qrData,
        subject: 'QR 코드',
        fileNameOverrides: [fileName],
        sharePositionOrigin: sharePositionOrigin,
      );
    });
  }

  Future<void> _handleQrImage(
    Future<void> Function(Uint8List bytes, String fileName) action,
  ) async {
    if (_isHandlingImage || _qrData == null) {
      return;
    }

    setState(() {
      _isHandlingImage = true;
    });

    try {
      final bytes = await _captureQrImage();
      await action(bytes, _createFileName());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('QR 이미지를 처리할 수 없습니다.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isHandlingImage = false;
        });
      }
    }
  }

  Future<Uint8List> _captureQrImage() async {
    final boundary =
        _qrPreviewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('QR preview is not ready.');
    }

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('QR image bytes are empty.');
    }

    return byteData.buffer.asUint8List();
  }

  String _createFileName() {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return 'qr_${now.year}${twoDigits(now.month)}${twoDigits(now.day)}_'
        '${twoDigits(now.hour)}${twoDigits(now.minute)}${twoDigits(now.second)}.png';
  }

  void _resetAll() {
    for (final controller in [
      _textController,
      _urlController,
      _ssidController,
      _wifiPasswordController,
      _phoneController,
      _messageController,
      _emailController,
      _subjectController,
      _bodyController,
      _nameController,
      _companyController,
      _jobTitleController,
      _websiteController,
      _addressController,
      _memoController,
    ]) {
      controller.clear();
    }

    setState(() {
      _qrData = null;
      _generationError = null;
      _wifiSecurity = 'WPA/WPA2';
    });
    _formKey.currentState?.reset();
  }
}

class _QrResultCard extends StatelessWidget {
  final GlobalKey qrPreviewKey;
  final String qrData;
  final bool isHandlingImage;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onReset;

  const _QrResultCard({
    required this.qrPreviewKey,
    required this.qrData,
    required this.isHandlingImage,
    required this.onCopy,
    required this.onSave,
    required this.onShare,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '생성된 QR 코드',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Center(
              child: RepaintBoundary(
                key: qrPreviewKey,
                child: Container(
                  width: 260,
                  height: 260,
                  padding: const EdgeInsets.all(18),
                  color: Colors.white,
                  child: CustomPaint(painter: _QrCodePainter(qrData)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                qrData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isHandlingImage ? null : onSave,
                  icon: const Icon(Icons.download),
                  label: const Text('이미지 저장'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isHandlingImage ? null : onShare,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('공유하기'),
                ),
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                  label: const Text('내용 복사'),
                ),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('다시 만들기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  final String data;

  const _QrCodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final side = size.shortestSide;
    final quietZone = side * 0.08;
    final qrSide = side - quietZone * 2;
    final moduleSize = qrSide / qrImage.moduleCount;
    final offset = Offset(
      (size.width - qrSide) / 2,
      (size.height - qrSide) / 2,
    );
    final paint = Paint()..color = Colors.black;

    for (var row = 0; row < qrImage.moduleCount; row++) {
      for (var col = 0; col < qrImage.moduleCount; col++) {
        if (!qrImage.isDark(row, col)) {
          continue;
        }

        canvas.drawRect(
          Rect.fromLTWH(
            offset.dx + col * moduleSize,
            offset.dy + row * moduleSize,
            moduleSize.ceilToDouble(),
            moduleSize.ceilToDouble(),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
