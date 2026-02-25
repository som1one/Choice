import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/auth_guard.dart';

class CompanyAdminCabinetScreen extends StatefulWidget {
  const CompanyAdminCabinetScreen({super.key});

  @override
  State<CompanyAdminCabinetScreen> createState() => _CompanyAdminCabinetScreenState();
}

class _CompanyAdminCabinetScreenState extends State<CompanyAdminCabinetScreen> {
  static const _prefsKey = 'company_admin_cabinet_v1';

  final _fio = TextEditingController();
  final _address = TextEditingController();
  final _mail = TextEditingController();
  final _phone = TextEditingController();
  final _rating = TextEditingController();

  bool _showFio = true;
  bool _showAddress = true;
  bool _showMail = true;
  bool _showPhone = true;
  bool _showRating = true;

  bool _onMap = false;
  String? _logoPath;
  final List<String> _photoPaths = [];
  final List<String> _products = [];
  final List<String> _services = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fio.dispose();
    _address.dispose();
    _mail.dispose();
    _phone.dispose();
    _rating.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _fio.text = (data['fio'] as String?) ?? '';
        _address.text = (data['address'] as String?) ?? '';
        _mail.text = (data['mail'] as String?) ?? '';
        _phone.text = (data['phone'] as String?) ?? '';
        _rating.text = (data['rating'] as String?) ?? '';

        _showFio = (data['showFio'] as bool?) ?? true;
        _showAddress = (data['showAddress'] as bool?) ?? true;
        _showMail = (data['showMail'] as bool?) ?? true;
        _showPhone = (data['showPhone'] as bool?) ?? true;
        _showRating = (data['showRating'] as bool?) ?? true;

        _onMap = (data['onMap'] as bool?) ?? false;
        _logoPath = data['logoPath'] as String?;
        _photoPaths
          ..clear()
          ..addAll(((data['photoPaths'] as List?) ?? const []).whereType<String>());
        _products
          ..clear()
          ..addAll(((data['products'] as List?) ?? const []).whereType<String>());
        _services
          ..clear()
          ..addAll(((data['services'] as List?) ?? const []).whereType<String>());
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'fio': _fio.text.trim(),
      'address': _address.text.trim(),
      'mail': _mail.text.trim(),
      'phone': _phone.text.trim(),
      'rating': _rating.text.trim(),
      'showFio': _showFio,
      'showAddress': _showAddress,
      'showMail': _showMail,
      'showPhone': _showPhone,
      'showRating': _showRating,
      'onMap': _onMap,
      'logoPath': _logoPath,
      'photoPaths': _photoPaths,
      'products': _products,
      'services': _services,
    };
    await prefs.setString(_prefsKey, jsonEncode(data));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Данные кабинета компании сохранены')),
    );
  }

  Future<void> _addListItem({
    required String title,
    required List<String> target,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Название',
            border: OutlineInputBorder(),
          ),
          maxLines: 1,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    setState(() => target.insert(0, value));
    await _save();
  }

  Future<void> _pickImage({required bool forLogo}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: !forLogo,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      if (forLogo) {
        _logoPath = result.files.first.path ?? result.files.first.name;
      } else {
        for (final f in result.files) {
          final p = f.path ?? f.name;
          if (!_photoPaths.contains(p)) _photoPaths.insert(0, p);
        }
      }
    });
    await _save();
  }

  Future<void> _deleteLogo() async {
    if (_logoPath == null) return;
    setState(() => _logoPath = null);
    await _save();
  }

  Future<void> _deleteAllPhotos() async {
    if (_photoPaths.isEmpty) return;
    setState(() => _photoPaths.clear());
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.favorite, color: Colors.blue, size: 32),
        title: const Text(
          'Кабинет администратора',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            onPressed: () => AuthGuard.openCompanySettings(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Отметьте информацию которая будет отображаться в карточке компании',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      icon: Icons.person,
                      label: 'Ф.И.О.',
                      controller: _fio,
                      checked: _showFio,
                      onChecked: (v) => setState(() => _showFio = v),
                    ),
                    _buildTextField(
                      icon: Icons.home,
                      label: 'Адрес',
                      controller: _address,
                      checked: _showAddress,
                      onChecked: (v) => setState(() => _showAddress = v),
                    ),
                    _buildTextField(
                      icon: Icons.mail,
                      label: 'Mail',
                      controller: _mail,
                      checked: _showMail,
                      onChecked: (v) => setState(() => _showMail = v),
                    ),
                    _buildTextField(
                      icon: Icons.phone,
                      label: 'Телефон',
                      controller: _phone,
                      checked: _showPhone,
                      onChecked: (v) => setState(() => _showPhone = v),
                    ),
                    _buildTextField(
                      icon: Icons.star,
                      label: 'Рейтинг',
                      controller: _rating,
                      checked: _showRating,
                      onChecked: (v) => setState(() => _showRating = v),
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text('Сохранить'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            text: 'Добавить товар',
                            onTap: () => _addListItem(title: 'Добавить товар', target: _products),
                          ),
                        ),
                        const Icon(Icons.attach_file, size: 32, color: Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            text: 'Добавить услугу',
                            onTap: () => _addListItem(title: 'Добавить услугу', target: _services),
                          ),
                        ),
                      ],
                    ),
                    if (_products.isNotEmpty || _services.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      if (_products.isNotEmpty) ...[
                        const Text('Товары:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ..._products.take(5).map((e) => Text('- $e')),
                      ],
                      if (_services.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('Услуги:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ..._services.take(5).map((e) => Text('- $e')),
                      ],
                    ],

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            text: 'Фото добавить',
                            onTap: () => _pickImage(forLogo: false),
                          ),
                        ),
                        const Icon(Icons.attach_file, size: 32, color: Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            text: 'Фото удалить',
                            onTap: _deleteAllPhotos,
                          ),
                        ),
                      ],
                    ),
                    if (_photoPaths.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Фото: ${_photoPaths.length}'),
                    ],

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            text: 'Логотип добавить',
                            onTap: () => _pickImage(forLogo: true),
                          ),
                        ),
                        const Icon(Icons.attach_file, size: 32, color: Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            text: 'Лого удалить',
                            onTap: _deleteLogo,
                          ),
                        ),
                      ],
                    ),
                    if (_logoPath != null) ...[
                      const SizedBox(height: 10),
                      const Text('Логотип выбран'),
                    ],

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            text: _onMap ? 'На карте: да' : 'На карте: нет',
                            onTap: () async {
                              setState(() => _onMap = true);
                              await _save();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            text: 'Удалить с карты',
                            onTap: () async {
                              setState(() => _onMap = false);
                              await _save();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text('Рейтинг', style: TextStyle(fontSize: 16)),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        Icon(Icons.telegram, color: Colors.blue),
                        Icon(Icons.facebook, color: Colors.blue),
                        Icon(Icons.share, color: Colors.pink),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Отметить цветом карточку компании',
                      style: TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 24),

                    _buildButton(context, 'Редактировать компанию'),

                    const SizedBox(height: 16),

                    _buildButton(context, 'Редактировать клиента'),
                  ],
                ),
              ),
            ),

    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool checked,
    required ValueChanged<bool> onChecked,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Checkbox(
            value: checked,
            onChanged: (v) => onChecked(v ?? true),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: label,
                border: const UnderlineInputBorder(),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    return GestureDetector(
      onTap: () {
        if (text == 'Редактировать компанию') {
          AuthGuard.openCompanySettings(context);
          return;
        }
        if (text == 'Редактировать клиента') {
          AuthGuard.openClientCabinet(context);
          return;
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
