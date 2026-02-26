// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile_model.dart';
import 'client_registration_screen.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';

class ClientAdminCabinetScreen extends StatefulWidget {
  const ClientAdminCabinetScreen({super.key});

  @override
  State<ClientAdminCabinetScreen> createState() => _ClientAdminCabinetScreenState();
}

class _ClientAdminCabinetScreenState extends State<ClientAdminCabinetScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  
  UserProfileModel? _profile;
  bool _isLoading = true;
  String? _photoUrl;
  bool _askPrice = true;
  bool _askSpecialist = true;
  bool _askAppointmentTime = true;
  bool _askAvailability = true;
  bool _askWorkTime = true;
  int _searchRadiusKm = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureAuthorized();
    });
  }

  Future<void> _ensureAuthorized() async {
    final loggedIn = await AuthService.isLoggedIn();
    final userType = await AuthService.getUserType();
    final ok = loggedIn && (userType == UserType.client || userType == UserType.admin);

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала войдите как клиент')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfileService.getProfile();
    setState(() {
      _profile = profile;
      _fullNameController.text = profile?.fullName ?? '';
      _addressController.text = profile?.address ?? '';
      _emailController.text = profile?.email ?? '';
      _phoneController.text = profile?.phone ?? '';
      _ratingController.text = profile?.rating ?? '';
      _photoUrl = profile?.photoUrl;
      _askPrice = profile?.askPrice ?? true;
      _askSpecialist = profile?.askSpecialist ?? true;
      _askAppointmentTime = profile?.askAppointmentTime ?? true;
      _askAvailability = profile?.askAvailability ?? true;
      _askWorkTime = profile?.askWorkTime ?? true;
      _searchRadiusKm = profile?.searchRadiusKm ?? 20;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final profile = UserProfileModel(
      fullName: _fullNameController.text.isNotEmpty ? _fullNameController.text : null,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      rating: _ratingController.text.isNotEmpty ? _ratingController.text : null,
      photoUrl: _photoUrl,
      isBlocked: _profile?.isBlocked ?? false,
      askPrice: _askPrice,
      askSpecialist: _askSpecialist,
      askAppointmentTime: _askAppointmentTime,
      askAvailability: _askAvailability,
      askWorkTime: _askWorkTime,
      searchRadiusKm: _searchRadiusKm,
    );

    await UserProfileService.saveProfile(profile);
    
    setState(() {
      _profile = profile;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль сохранен')),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _photoUrl = image.path;
        });
        await _saveProfile();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе фото: $e')),
      );
    }
  }

  Future<void> _deletePhoto() async {
    setState(() {
      _photoUrl = null;
    });
    await _saveProfile();
  }

  Future<void> _blockClient() async {
    final profile = (_profile ?? UserProfileModel()).copyWith(isBlocked: true);
    await UserProfileService.saveProfile(profile);
    setState(() {
      _profile = profile;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Клиент заблокирован')),
    );
  }

  Future<void> _unblockClient() async {
    final profile = (_profile ?? UserProfileModel()).copyWith(isBlocked: false);
    await UserProfileService.saveProfile(profile);
    setState(() {
      _profile = profile;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Клиент разблокирован')),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Вы уже в настройках клиента')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Отметьте информацию которая будет отображаться в карточке клиента',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              _buildTextField(Icons.person, 'Ф.И.О.', _fullNameController),
              _buildTextField(Icons.home, 'Адрес', _addressController),
              _buildTextField(Icons.mail, 'Mail', _emailController),
              _buildTextField(Icons.phone, 'Телефон', _phoneController),
              _buildTextField(Icons.star, 'Рейтинг клиента', _ratingController),
              const SizedBox(height: 8),
              _buildSettingToggle(
                'Узнать стоимость',
                _askPrice,
                (v) => setState(() => _askPrice = v),
              ),
              _buildSettingToggle(
                'Узнать имя специалиста',
                _askSpecialist,
                (v) => setState(() => _askSpecialist = v),
              ),
              _buildSettingToggle(
                'Узнать время записи',
                _askAppointmentTime,
                (v) => setState(() => _askAppointmentTime = v),
              ),
              _buildSettingToggle(
                'Узнать наличие товара',
                _askAvailability,
                (v) => setState(() => _askAvailability = v),
              ),
              _buildSettingToggle(
                'Узнать время выполнения работ',
                _askWorkTime,
                (v) => setState(() => _askWorkTime = v),
              ),
              const SizedBox(height: 12),
              const Text(
                'Выбрать радиус поиска',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [5, 10, 15, 20, 50]
                    .map((km) => _buildRadiusButton(km))
                    .toList(),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: _buildAttachmentButton('Фото добавить', onTap: _pickImage),
                  ),
                  if (_photoUrl != null)
                    const Icon(Icons.check_circle, size: 32, color: Colors.green)
                  else
                    const Icon(Icons.attach_file, size: 32, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAttachmentButton('Фото удалить', onTap: _photoUrl != null ? _deletePhoto : null),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildAttachmentButton(
                      'Блок клиента',
                      onTap: _profile?.isBlocked == true ? null : _blockClient,
                      color: _profile?.isBlocked == true ? Colors.grey : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAttachmentButton(
                      'Разблокировать',
                      onTap: _profile?.isBlocked == true ? _unblockClient : null,
                      color: _profile?.isBlocked == true ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildAttachmentButton(
                      'Редактировать отзыв',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Редактирование отзыва сохранено')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAttachmentButton(
                      'Блокировать отзыв',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Отзыв заблокирован')),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Text('Регистрация клиента', style: TextStyle(fontSize: 16)),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Icon(Icons.telegram, color: Colors.blue),
                  const Icon(Icons.facebook, color: Colors.blue),
                  const Icon(Icons.share, color: Colors.pink),
                ],
              ),

              const SizedBox(height: 32),

              _buildButton('Сохранить профиль', onTap: _saveProfile),

            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _buildLogoutButton(context),
        ),
      ),

    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
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

    if (confirm == true) {
      await AuthService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ClientRegistrationScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => _logout(context),
        child: const Text(
          'Выйти из аккаунта',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTextField(IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: label,
                border: const UnderlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton(String text, {VoidCallback? onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color ?? (onTap != null ? Colors.blue : Colors.grey),
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

  Widget _buildButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
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

  Widget _buildSettingToggle(String text, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 20, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: Colors.lightBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusButton(int km) {
    final selected = _searchRadiusKm == km;
    return GestureDetector(
      onTap: () => setState(() => _searchRadiusKm = km),
      child: Container(
        width: 48,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.green[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$km км', style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
