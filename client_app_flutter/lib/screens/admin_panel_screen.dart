// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/categories.dart';
import '../services/auth_service.dart';
import '../services/remote_admin_service.dart';
import '../services/remote_file_service.dart';
import '../widgets/choice_logo_icon.dart';
import '../widgets/profile_corner_icon.dart';
import 'login_screen.dart';

enum _AdminMode { company, client }

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static const _companySettingsKey = 'company_admin_settings';
  static const _clientSettingsKey = 'client_settings';

  final RemoteAdminService _remote = RemoteAdminService();
  final RemoteFileService _fileService = RemoteFileService();
  final ImagePicker _picker = ImagePicker();

  _AdminMode _mode = _AdminMode.company;
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, bool> _companyChecks = {
    'Название': true,
    'Адрес': true,
    'Mail': true,
    'Телефон': true,
    'Имя специалиста': true,
    'Виды деятельности': true,
    'Сайт': true,
  };
  final Map<String, TextEditingController> _companyControllers = {
    'Название': TextEditingController(),
    'Адрес': TextEditingController(),
    'Mail': TextEditingController(),
    'Телефон': TextEditingController(),
    'Имя специалиста': TextEditingController(),
    'Виды деятельности': TextEditingController(),
    'Сайт': TextEditingController(),
  };

  final Map<String, bool> _clientChecks = {
    'Ф.И.О': true,
    'Адрес': true,
    'Mail': true,
    'Телефон': true,
    'Рейтинг клиента': true,
  };
  final Map<String, TextEditingController> _clientControllers = {
    'Ф.И.О': TextEditingController(),
    'Адрес': TextEditingController(),
    'Mail': TextEditingController(),
    'Телефон': TextEditingController(),
    'Рейтинг клиента': TextEditingController(),
  };

  List<Map<String, dynamic>> _ratingCriteria = [];
  List<Map<String, dynamic>> _categories = [];

  String? _companyPhotoPath;
  String? _companyLogoPath;
  String? _clientPhotoPath;
  Color _selectedCardColor = const Color(0xFFB8E986);
  final Map<String, String> _socialLinks = {};

  Map<String, dynamic>? _selectedCompany;
  Map<String, dynamic>? _selectedClient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    for (final controller in _companyControllers.values) {
      controller.dispose();
    }
    for (final controller in _clientControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    final loggedIn = await AuthService.isLoggedIn();
    final userType = await AuthService.getUserType();
    if (!mounted) {
      return;
    }
    if (!loggedIn || userType != UserType.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Доступ только для администратора')),
      );
      await AuthService.logout();
      if (!mounted) {
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    await _loadSavedState();
    await _loadAdminCatalogs();
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAdminCatalogs() async {
    final categories = await _remote.getCategories();
    if (categories != null && categories.isNotEmpty) {
      _categories = categories;
      updateCategoryCatalog(
        categories.map((item) => (item['title'] ?? '').toString()),
      );
    }

    final criteria = await _remote.getRatingCriteria();
    if (criteria != null && criteria.isNotEmpty) {
      _ratingCriteria = criteria;
    }
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();

    final companyRaw = prefs.getString(_companySettingsKey);
    if (companyRaw != null && companyRaw.isNotEmpty) {
      final companyData = jsonDecode(companyRaw) as Map<String, dynamic>;
      _companyPhotoPath = companyData['photoPath'] as String?;
      _companyLogoPath = companyData['logoPath'] as String?;
      final colorValue = companyData['cardColor'] as int?;
      if (colorValue != null) {
        _selectedCardColor = Color(colorValue);
      }
      final socials = companyData['socialLinks'];
      if (socials is Map) {
        _socialLinks
          ..clear()
          ..addAll(
            socials.map(
              (key, value) => MapEntry(
                key.toString(),
                value?.toString() ?? '',
              ),
            ),
          );
      }
      final selectedCompany = companyData['selectedCompany'];
      if (selectedCompany is Map<String, dynamic>) {
        _selectedCompany = selectedCompany;
      } else if (selectedCompany is Map) {
        _selectedCompany = selectedCompany.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      for (final entry in _companyChecks.entries) {
        _companyChecks[entry.key] =
            companyData['cb_${entry.key}'] as bool? ?? entry.value;
      }
      for (final entry in _companyControllers.entries) {
        entry.value.text = companyData['f_${entry.key}'] as String? ?? '';
      }
      final ratingCriteria = companyData['ratingCriteria'];
      if (ratingCriteria is List) {
        _ratingCriteria = ratingCriteria
            .whereType<Map>()
            .map(
              (item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
            .toList();
      }
      final categories = companyData['categories'];
      if (categories is List) {
        _categories = categories
            .whereType<Map>()
            .map(
              (item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
            .toList();
      }
    }

    final clientRaw = prefs.getString(_clientSettingsKey);
    if (clientRaw != null && clientRaw.isNotEmpty) {
      final clientData = jsonDecode(clientRaw) as Map<String, dynamic>;
      _clientPhotoPath = clientData['avatarPath'] as String?;
      final selectedClient = clientData['selectedAdminClient'];
      if (selectedClient is Map<String, dynamic>) {
        _selectedClient = selectedClient;
      } else if (selectedClient is Map) {
        _selectedClient = selectedClient.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      for (final entry in _clientChecks.entries) {
        _clientChecks[entry.key] =
            clientData['cb_${entry.key}'] as bool? ?? entry.value;
      }
      for (final entry in _clientControllers.entries) {
        entry.value.text = clientData['f_${entry.key}'] as String? ?? '';
      }
    }
  }

  Future<void> _saveCurrentMode() async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      if (_mode == _AdminMode.company) {
        await _saveCompanyToBackend();
        await _saveCompanySettings();
      } else {
        await _saveClientToBackend();
        await _saveClientSettings();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveCompanySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'photoPath': _companyPhotoPath,
      'logoPath': _companyLogoPath,
      'cardColor': _selectedCardColor.toARGB32(),
      'ratingCriteria': _ratingCriteria,
      'categories': _categories,
      'socialLinks': _socialLinks,
      'selectedCompany': _selectedCompany,
    };
    for (final entry in _companyChecks.entries) {
      data['cb_${entry.key}'] = entry.value;
    }
    for (final entry in _companyControllers.entries) {
      data['f_${entry.key}'] = entry.value.text.trim();
    }
    await prefs.setString(_companySettingsKey, jsonEncode(data));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки компании сохранены')),
    );
  }

  Future<void> _saveClientSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'avatarPath': _clientPhotoPath,
      'selectedAdminClient': _selectedClient,
    };
    for (final entry in _clientChecks.entries) {
      data['cb_${entry.key}'] = entry.value;
    }
    for (final entry in _clientControllers.entries) {
      data['f_${entry.key}'] = entry.value.text.trim();
    }
    await prefs.setString(_clientSettingsKey, jsonEncode(data));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки клиента сохранены')),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  (String city, String street) _splitAddress(String raw) {
    final parts = raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return ('', '');
    }
    if (parts.length == 1) {
      return (parts.first, '');
    }
    return (parts.first, parts.sublist(1).join(', '));
  }

  List<int> _selectedCategoryIdsFromField() {
    final titles = _companyControllers['Виды деятельности']!.text
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (titles.isEmpty) {
      return _selectedCompany?['categories_id'] is List
          ? (_selectedCompany!['categories_id'] as List)
              .map((item) => int.tryParse(item.toString()))
              .whereType<int>()
              .toList()
          : <int>[];
    }

    final result = <int>[];
    for (final item in _categories) {
      final id = int.tryParse(item['id']?.toString() ?? '');
      final title = (item['title'] ?? '').toString().trim();
      if (id != null && titles.contains(title)) {
        result.add(id);
      }
    }
    return result.isEmpty
        ? titles.map(categoryTitleToId).toSet().toList()
        : result;
  }

  Future<String?> _uploadIfLocal(String? path) async {
    final value = path?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.contains('/api/objects/')) {
      return value.split('/api/objects/').last;
    }
    if (!value.startsWith('/') && !value.startsWith('file://')) {
      return value;
    }
    return _fileService.uploadFile(value);
  }

  Map<String, String> _extractSocialLinks(Map<String, dynamic> company) {
    final result = <String, String>{};
    final socialMedias = company['social_medias'] ?? company['socialMedias'];
    if (socialMedias is! List) {
      return result;
    }

    for (final raw in socialMedias) {
      final url = raw.toString().trim();
      if (url.isEmpty) continue;
      final lower = url.toLowerCase();
      if (lower.contains('t.me') || lower.contains('telegram')) {
        result['Telegram'] = url;
      } else if (lower.contains('vk.com') || lower.contains('vkontakte')) {
        result['VK'] = url;
      } else if (lower.contains('ok.ru')) {
        result['OK'] = url;
      } else if (lower.contains('facebook.com')) {
        result['Facebook'] = url;
      } else if (lower.contains('instagram.com')) {
        result['Instagram'] = url;
      }
    }
    return result;
  }

  Color _parseHexColor(String input) {
    final normalized = input.replaceAll('#', '');
    final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF66CBFF);
    }
  }

  Future<void> _saveCompanyToBackend() async {
    final guid = _selectedCompany?['guid']?.toString();
    if (guid == null || guid.isEmpty) {
      _showMessage('Сначала выберите компанию');
      return;
    }

    final address = _splitAddress(_companyControllers['Адрес']!.text);
    final logoFile = await _uploadIfLocal(_companyLogoPath);
    final photoFile = await _uploadIfLocal(_companyPhotoPath);
    final socialMedias = _socialLinks.values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final payload = <String, dynamic>{
      'guid': guid,
      'title': _companyControllers['Название']!.text.trim(),
      'phone_number': _companyControllers['Телефон']!.text.trim(),
      'email': _companyControllers['Mail']!.text.trim(),
      'site_url': _companyControllers['Сайт']!.text.trim(),
      'city': address.$1,
      'street': address.$2,
      'social_medias': socialMedias,
      'photo_uris': photoFile == null ? <String>[] : <String>[photoFile],
      'categories_id': _selectedCategoryIdsFromField(),
      'description': _companyControllers['Виды деятельности']!.text.trim(),
      'card_color':
          '#${_selectedCardColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
    };

    final result = await _remote.updateCompanyAdmin(payload);
    if (result == null) {
      _showMessage('Не удалось сохранить карточку компании');
      return;
    }

    if (logoFile != null && logoFile.isNotEmpty) {
      await _remote.changeCompanyIconAdmin(guid: guid, uri: logoFile);
    }

    final fresh = await _remote.getCompanyAdmin(guid) ?? result;
    if (!mounted) return;
    setState(() {
      _selectedCompany = fresh;
      _populateCompanyFields(fresh);
    });
    _showMessage('Карточка компании сохранена');
  }

  Future<void> _saveClientToBackend() async {
    final guid = _selectedClient?['guid']?.toString();
    if (guid == null || guid.isEmpty) {
      _showMessage('Сначала выберите клиента');
      return;
    }

    final fullName = _clientControllers['Ф.И.О']!.text.trim();
    final parts = fullName.split(RegExp(r'\s+')).where((item) => item.isNotEmpty).toList();
    final address = _splitAddress(_clientControllers['Адрес']!.text);

    final payload = <String, dynamic>{
      'name': parts.isEmpty ? '' : parts.first,
      'surname': parts.length > 1 ? parts.sublist(1).join(' ') : '',
      'email': _clientControllers['Mail']!.text.trim(),
      'phone_number': _clientControllers['Телефон']!.text.trim(),
      'city': address.$1,
      'street': address.$2,
    };

    final result = await _remote.updateClientAdmin(guid: guid, body: payload);
    if (result == null) {
      _showMessage('Не удалось сохранить клиента');
      return;
    }

    final avatarFile = await _uploadIfLocal(_clientPhotoPath);
    if (avatarFile != null && avatarFile.isNotEmpty) {
      await _remote.changeClientIconAdmin(guid: guid, uri: avatarFile);
    }

    final fresh = await _remote.getClientAdmin(guid) ?? result;
    if (!mounted) return;
    setState(() {
      _selectedClient = fresh;
      _populateClientFields(fresh);
    });
    _showMessage('Карточка клиента сохранена');
  }

  Future<void> _pickCompanyImage({required bool isLogo}) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }
    setState(() {
      if (isLogo) {
        _companyLogoPath = image.path;
      } else {
        _companyPhotoPath = image.path;
      }
    });
    await _saveCompanySettings();
  }

  Future<void> _pickClientPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }
    setState(() {
      _clientPhotoPath = image.path;
    });
    await _saveClientSettings();
  }

  Future<void> _selectCompany() async {
    final companies = await _remote.getCompaniesAdmin();
    if (!mounted) {
      return;
    }
    if (companies == null || companies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Список компаний недоступен')),
      );
      setState(() {
        _mode = _AdminMode.company;
      });
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Выберите компанию',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: companies.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = companies[index];
                    final title =
                        (item['title'] ?? item['name'] ?? '').toString();
                    final email = (item['email'] ?? '').toString();
                    final phone = (item['phone_number'] ?? '').toString();
                    return ListTile(
                      title: Text(title.isEmpty ? '(без названия)' : title),
                      subtitle: Text(
                        [email, phone].where((e) => e.isNotEmpty).join('\n'),
                      ),
                      isThreeLine: phone.isNotEmpty,
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !mounted) {
      return;
    }
    final guid = selected['guid']?.toString();
    final fullCompany = guid == null ? null : await _remote.getCompanyAdmin(guid);
    setState(() {
      _mode = _AdminMode.company;
      _selectedCompany = fullCompany ?? selected;
      _populateCompanyFields(fullCompany ?? selected);
    });
  }

  void _populateCompanyFields(Map<String, dynamic> company) {
    _companyControllers['Название']!.text =
        (company['title'] ?? company['name'] ?? '').toString();
    _companyControllers['Mail']!.text = (company['email'] ?? '').toString();
    _companyControllers['Телефон']!.text =
        (company['phone_number'] ?? '').toString();
    final city = (company['city'] ?? '').toString();
    final street = (company['street'] ?? '').toString();
    _companyControllers['Адрес']!.text =
        [city, street].where((e) => e.isNotEmpty).join(', ');
    _companyControllers['Имя специалиста']!.text =
        (company['specialist_name'] ?? '').toString();
    final categoryIds = company['categories_id'] ?? company['categoriesId'];
    if (categoryIds is List && categoryIds.isNotEmpty) {
      _companyControllers['Виды деятельности']!.text = categoryIds
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .map((id) {
            final match = _categories.cast<Map<String, dynamic>?>().firstWhere(
                  (entry) => entry?['id']?.toString() == id.toString(),
                  orElse: () => null,
                );
            return match == null
                ? categoryIdToTitle(id)
                : (match['title'] ?? '').toString();
          })
          .where((title) => title.isNotEmpty)
          .join(', ');
    } else {
      _companyControllers['Виды деятельности']!.text =
          (company['description'] ??
                  company['company_type'] ??
                  company['category_name'] ??
                  company['categories'] ??
                  '')
              .toString();
    }
    _companyControllers['Сайт']!.text =
        (company['site_url'] ?? '').toString();
    final iconUri = company['icon_uri']?.toString();
    if (iconUri != null && iconUri.isNotEmpty) {
      _companyLogoPath = iconUri.contains('/api/objects/')
          ? iconUri
          : iconUri;
    }
    final photos = company['photo_uris'] ?? company['photoUris'];
    if (photos is List && photos.isNotEmpty) {
      _companyPhotoPath = photos.first.toString();
    }
    _socialLinks
      ..clear()
      ..addAll(_extractSocialLinks(company));
    final cardColor = company['card_color']?.toString();
    if (cardColor != null && cardColor.isNotEmpty) {
      _selectedCardColor = _parseHexColor(cardColor);
    }
  }

  Future<void> _selectClient() async {
    final clients = await _remote.getClients();
    if (!mounted) {
      return;
    }
    if (clients == null || clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Список клиентов недоступен')),
      );
      setState(() {
        _mode = _AdminMode.client;
      });
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Выберите клиента',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: clients.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = clients[index];
                    final fullName =
                        '${item['name'] ?? ''} ${item['surname'] ?? ''}'.trim();
                    final email = (item['email'] ?? '').toString();
                    final phone = (item['phone_number'] ?? '').toString();
                    return ListTile(
                      title: Text(fullName.isEmpty ? '(без имени)' : fullName),
                      subtitle: Text(
                        [email, phone].where((e) => e.isNotEmpty).join('\n'),
                      ),
                      isThreeLine: phone.isNotEmpty,
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !mounted) {
      return;
    }
    final guid = selected['guid']?.toString();
    final fullClient = guid == null ? null : await _remote.getClientAdmin(guid);
    setState(() {
      _mode = _AdminMode.client;
      _selectedClient = fullClient ?? selected;
      _populateClientFields(fullClient ?? selected);
    });
  }

  void _populateClientFields(Map<String, dynamic> client) {
    final fullName =
        '${client['name'] ?? ''} ${client['surname'] ?? ''}'.trim();
    _clientControllers['Ф.И.О']!.text = fullName;
    _clientControllers['Mail']!.text = (client['email'] ?? '').toString();
    _clientControllers['Телефон']!.text =
        (client['phone_number'] ?? '').toString();
    final city = (client['city'] ?? '').toString();
    final street = (client['street'] ?? '').toString();
    _clientControllers['Адрес']!.text =
        [city, street].where((e) => e.isNotEmpty).join(', ');
    _clientControllers['Рейтинг клиента']!.text =
        (client['rating'] ?? client['average_rating'] ?? '').toString();
    final iconUri = client['icon_uri']?.toString();
    if (iconUri != null && iconUri.isNotEmpty) {
      _clientPhotoPath = iconUri;
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Выйти из админ-аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    await AuthService.logout();
    if (!mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _editSocialLink(String label) {
    final controller = TextEditingController(text: _socialLinks[label] ?? '');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Вставьте ссылку на соцсеть',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  _socialLinks.remove(label);
                } else {
                  _socialLinks[label] = value;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _runCompanyAction(
    Future<bool> Function(String guid) action,
    String successMessage,
  ) async {
    final guid = _selectedCompany?['guid']?.toString();
    if (guid == null || guid.isEmpty) {
      _showMessage('Сначала выберите компанию');
      return;
    }
    final ok = await action(guid);
    if (ok) {
      final fresh = await _remote.getCompanyAdmin(guid);
      if (fresh != null && mounted) {
        setState(() {
          _selectedCompany = fresh;
          _populateCompanyFields(fresh);
        });
      }
    }
    _showMessage(ok ? successMessage : 'Операция не выполнена');
  }

  Future<void> _runClientAction(
    Future<bool> Function(String guid) action,
    String successMessage,
  ) async {
    final guid = _selectedClient?['guid']?.toString();
    if (guid == null || guid.isEmpty) {
      _showMessage('Сначала выберите клиента');
      return;
    }
    final ok = await action(guid);
    if (ok) {
      final fresh = await _remote.getClientAdmin(guid);
      if (fresh != null && mounted) {
        setState(() {
          _selectedClient = fresh;
          _populateClientFields(fresh);
        });
      }
    }
    _showMessage(ok ? successMessage : 'Операция не выполнена');
  }

  Future<void> _deleteSelectedCompany() async {
    final guid = _selectedCompany?['guid']?.toString();
    if (guid == null || guid.isEmpty) {
      _showMessage('Сначала выберите компанию');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить компанию'),
        content: const Text('Компания будет удалена без возможности восстановления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _remote.deleteCompanyByGuid(guid);
    if (ok && mounted) {
      setState(() {
        _selectedCompany = null;
      });
    }
    _showMessage(ok ? 'Компания удалена' : 'Не удалось удалить компанию');
  }

  Future<void> _deleteSelectedClient() async {
    final guid = _selectedClient?['guid']?.toString();
    if (guid == null || guid.isEmpty) {
      _showMessage('Сначала выберите клиента');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить клиента'),
        content: const Text('Клиент будет удален без возможности восстановления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _remote.deleteClientByGuid(guid);
    if (ok && mounted) {
      setState(() {
        _selectedClient = null;
      });
    }
    _showMessage(ok ? 'Клиент удален' : 'Не удалось удалить клиента');
  }

  Future<void> _deleteSelectedReview() async {
    final reviews = await _remote.getAllReviewsAdmin();
    if (!mounted) {
      return;
    }
    if (reviews == null || reviews.isEmpty) {
      _showMessage('Отзывы недоступны');
      return;
    }

    final selectedId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Удалить отзыв',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final id = (review['id'] as num?)?.toInt();
                    final text = (review['text'] ?? '').toString();
                    final grade = (review['grade'] ?? '').toString();
                    return ListTile(
                      title: Text('★ $grade'),
                      subtitle: Text(text.isEmpty ? '(без текста)' : text),
                      onTap: id == null ? null : () => Navigator.pop(context, id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedId == null || !mounted) {
      return;
    }
    final ok = await _remote.deleteReview(selectedId);
    if (!mounted) {
      return;
    }
    _showMessage(ok ? 'Отзыв удалён' : 'Не удалось удалить отзыв');
  }

  void _showEditItemDialog({
    required String title,
    String initialValue = '',
    required ValueChanged<String> onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                return;
              }
              onSave(value);
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCategory() async {
    _showEditItemDialog(
      title: 'Добавить услугу на главный экран',
      onSave: (value) async {
        final created = await _remote.createCategory(title: value);
        if (created == null || !mounted) {
          _showMessage('Не удалось добавить услугу');
          return;
        }
        setState(() {
          _categories.add(created);
          updateCategoryCatalog(
            _categories.map((item) => (item['title'] ?? '').toString()),
          );
        });
        await _saveCompanySettings();
        _showMessage('Услуга добавлена');
      },
    );
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
    final id = int.tryParse(category['id']?.toString() ?? '');
    if (id == null) return;
    _showEditItemDialog(
      title: 'Редактировать услугу',
      initialValue: (category['title'] ?? '').toString(),
      onSave: (value) async {
        final updated = await _remote.updateCategory(id: id, title: value);
        if (updated == null || !mounted) {
          _showMessage('Не удалось обновить услугу');
          return;
        }
        setState(() {
          final index = _categories.indexWhere(
            (item) => item['id']?.toString() == id.toString(),
          );
          if (index >= 0) {
            _categories[index] = {
              ..._categories[index],
              ...updated,
              'id': id,
              'title': value,
            };
          }
          updateCategoryCatalog(
            _categories.map((item) => (item['title'] ?? '').toString()),
          );
        });
        await _saveCompanySettings();
        _showMessage('Услуга обновлена');
      },
    );
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final id = int.tryParse(category['id']?.toString() ?? '');
    if (id == null) return;
    final ok = await _remote.deleteCategory(id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _categories.removeWhere((item) => item['id']?.toString() == id.toString());
        updateCategoryCatalog(
          _categories.map((item) => (item['title'] ?? '').toString()),
        );
      });
      await _saveCompanySettings();
    }
    _showMessage(ok ? 'Услуга удалена' : 'Не удалось удалить услугу');
  }

  Future<void> _createRatingCriterion() async {
    _showEditItemDialog(
      title: 'Добавить фразу для отзыва',
      onSave: (value) async {
        final created = await _remote.createRatingCriterion(name: value);
        if (created == null || !mounted) {
          _showMessage('Не удалось добавить фразу');
          return;
        }
        setState(() {
          _ratingCriteria.add(created);
        });
        await _saveCompanySettings();
        _showMessage('Фраза добавлена');
      },
    );
  }

  Future<void> _editRatingCriterion(Map<String, dynamic> criterion) async {
    final id = int.tryParse(criterion['id']?.toString() ?? '');
    if (id == null) return;
    _showEditItemDialog(
      title: 'Редактировать фразу',
      initialValue: (criterion['name'] ?? '').toString(),
      onSave: (value) async {
        final updated = await _remote.updateRatingCriterion(id: id, name: value);
        if (updated == null || !mounted) {
          _showMessage('Не удалось обновить фразу');
          return;
        }
        setState(() {
          final index = _ratingCriteria.indexWhere(
            (item) => item['id']?.toString() == id.toString(),
          );
          if (index >= 0) {
            _ratingCriteria[index] = {
              ..._ratingCriteria[index],
              ...updated,
              'id': id,
              'name': value,
            };
          }
        });
        await _saveCompanySettings();
        _showMessage('Фраза обновлена');
      },
    );
  }

  Future<void> _deleteRatingCriterion(Map<String, dynamic> criterion) async {
    final id = int.tryParse(criterion['id']?.toString() ?? '');
    if (id == null) return;
    final ok = await _remote.deleteRatingCriterion(id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _ratingCriteria.removeWhere(
          (item) => item['id']?.toString() == id.toString(),
        );
      });
      await _saveCompanySettings();
    }
    _showMessage(ok ? 'Фраза удалена' : 'Не удалось удалить фразу');
  }

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: const ChoiceLogoIcon(size: 30),
        ),
        title: const Text(
          'Кабинет администратора',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Выйти',
            onPressed: _logout,
            icon: const ProfileCornerIcon(userType: UserType.admin, size: 28),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildModeHeading() {
    final title = _mode == _AdminMode.company ? 'КОМПАНИЯ' : 'КЛИЕНТ';
    final subtitle = _mode == _AdminMode.company
        ? 'Отметьте информацию которая будет отображаться в карточке'
        : 'Отметьте информацию которая будет отображаться в кабинете клиента';
    final selectedTitle = _mode == _AdminMode.company
        ? (_selectedCompany?['title'] ?? _selectedCompany?['name'] ?? '')
            .toString()
        : ('${_selectedClient?['name'] ?? ''} ${_selectedClient?['surname'] ?? ''}')
            .trim();

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        if (selectedTitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Выбрано: $selectedTitle',
              style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool checked,
    required ValueChanged<bool> onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 118,
            child: GestureDetector(
              onTap: () => onToggle(!checked),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: checked ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onToggle(!checked),
            child: Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              color: checked ? const Color(0xFFD7E75B) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF66CBFF),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPair({
    required String leftText,
    required VoidCallback onLeftTap,
    required String rightText,
    required VoidCallback onRightTap,
    bool withMiddleIcon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: _buildBlueButton(leftText, onLeftTap)),
          if (withMiddleIcon) ...[
            const SizedBox(width: 10),
            const Icon(Icons.attach_file, size: 26),
            const SizedBox(width: 10),
          ] else
            const SizedBox(width: 16),
          Expanded(child: _buildBlueButton(rightText, onRightTap)),
        ],
      ),
    );
  }

  Widget _buildCompanySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in _companyControllers.entries)
          _buildEditableField(
            label: entry.key,
            controller: entry.value,
            checked: _companyChecks[entry.key] ?? true,
            onToggle: (value) {
              setState(() {
                _companyChecks[entry.key] = value;
              });
            },
          ),
        const SizedBox(height: 18),
        _buildActionPair(
          leftText: 'Добавить услугу',
          onLeftTap: _createCategory,
          rightText: 'Обновить список',
          onRightTap: () async {
            await _loadAdminCatalogs();
            if (mounted) setState(() {});
          },
        ),
        _buildActionPair(
          leftText: 'Фото добавить',
          onLeftTap: () => _pickCompanyImage(isLogo: false),
          rightText: 'Фото удалить',
          onRightTap: () {
            setState(() {
              _companyPhotoPath = null;
            });
          },
          withMiddleIcon: true,
        ),
        _buildActionPair(
          leftText: 'Логотип добавить',
          onLeftTap: () => _pickCompanyImage(isLogo: true),
          rightText: 'Лого удалить',
          onRightTap: () {
            setState(() {
              _companyLogoPath = null;
            });
          },
          withMiddleIcon: true,
        ),
        _buildActionPair(
          leftText: 'Блокировать',
          onLeftTap: () => _runCompanyAction(
            _remote.blockCompany,
            'Компания заблокирована',
          ),
          rightText: 'Разблокировать',
          onRightTap: () => _runCompanyAction(
            _remote.unblockCompany,
            'Компания разблокирована',
          ),
        ),
        _buildActionPair(
          leftText: 'Удалить компанию',
          onLeftTap: _deleteSelectedCompany,
          rightText: 'Сохранить в backend',
          onRightTap: _saveCompanyToBackend,
        ),
        const SizedBox(height: 10),
        const Text('Фразы отзывов', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        _buildActionPair(
          leftText: 'Добавить фразу',
          onLeftTap: _createRatingCriterion,
          rightText: 'Обновить фразы',
          onRightTap: () async {
            final criteria = await _remote.getRatingCriteria();
            if (criteria != null && mounted) {
              setState(() {
                _ratingCriteria = criteria;
              });
            }
          },
        ),
        ..._ratingCriteria.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text((entry.value['name'] ?? '').toString()),
                ),
                IconButton(
                  onPressed: () => _editRatingCriterion(entry.value),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  onPressed: () => _deleteRatingCriterion(entry.value),
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Добавить соц сети', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            ('Telegram', Icons.send, Color(0xFF28A8EA)),
            ('VK', Icons.chat, Color(0xFF4C75A3)),
            ('OK', Icons.circle, Color(0xFFF7931E)),
            ('Facebook', Icons.facebook, Color(0xFF4267B2)),
            ('Instagram', Icons.camera_alt, Color(0xFFE1306C)),
          ].map((item) {
            final label = item.$1;
            final icon = item.$2;
            final color = item.$3;
            final selected = (_socialLinks[label] ?? '').trim().isNotEmpty;
            return GestureDetector(
              onTap: () => _editSocialLink(label),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(icon, color: Colors.white),
              ),
            );
          }).toList(),
        ),
        if (_socialLinks.isNotEmpty) ...[
          const SizedBox(height: 10),
          ..._socialLinks.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${entry.key}: ${entry.value}'),
            ),
          ),
        ],
        const SizedBox(height: 18),
        const Text(
          'Отметить цветом карточку компании',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedCardColor = _selectedCardColor == const Color(0xFFD7E75B)
                    ? const Color(0xFF66CBFF)
                    : const Color(0xFFD7E75B);
              });
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _selectedCardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: Colors.white),
            ),
          ),
        ),
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Услуги на главном экране', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('• ${(category['title'] ?? '').toString()}'),
                  ),
                  IconButton(
                    onPressed: () => _editCategory(category),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    onPressed: () => _deleteCategory(category),
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in _clientControllers.entries)
          _buildEditableField(
            label: entry.key,
            controller: entry.value,
            checked: _clientChecks[entry.key] ?? true,
            onToggle: (value) {
              setState(() {
                _clientChecks[entry.key] = value;
              });
            },
          ),
        const SizedBox(height: 18),
        _buildActionPair(
          leftText: 'Фото добавить',
          onLeftTap: _pickClientPhoto,
          rightText: 'Фото удалить',
          onRightTap: () {
            setState(() {
              _clientPhotoPath = null;
            });
          },
          withMiddleIcon: true,
        ),
        _buildActionPair(
          leftText: 'Блок клиента',
          onLeftTap: () => _runClientAction(
            _remote.blockClient,
            'Клиент заблокирован',
          ),
          rightText: 'Разблокировать',
          onRightTap: () => _runClientAction(
            _remote.unblockClient,
            'Клиент разблокирован',
          ),
        ),
        _buildActionPair(
          leftText: 'Редактировать отзыв',
          onLeftTap: _deleteSelectedReview,
          rightText: 'Удалить клиента',
          onRightTap: _deleteSelectedClient,
        ),
        _buildActionPair(
          leftText: 'Сохранить клиента',
          onLeftTap: _saveClientToBackend,
          rightText: 'Обновить клиента',
          onRightTap: _selectClient,
        ),
      ],
    );
  }

  Widget _buildModeButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildBlueButton('Редактировать компанию', _selectCompany),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildBlueButton('Редактировать клиента', _selectClient),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildTopBar(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE7D1FF),
        onPressed: _saveCurrentMode,
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.edit, color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModeHeading(),
              const SizedBox(height: 24),
              if (_mode == _AdminMode.company)
                _buildCompanySection()
              else
                _buildClientSection(),
              const SizedBox(height: 34),
              _buildModeButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
