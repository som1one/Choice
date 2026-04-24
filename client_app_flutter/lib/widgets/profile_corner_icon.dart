import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/remote_client_service.dart';
import '../services/remote_company_service.dart';

class ProfileCornerIcon extends StatefulWidget {
  final UserType userType;
  final String? imagePath;
  final double size;

  const ProfileCornerIcon({
    super.key,
    required this.userType,
    this.imagePath,
    this.size = 30,
  });

  @override
  State<ProfileCornerIcon> createState() => _ProfileCornerIconState();
}

class _ProfileCornerIconState extends State<ProfileCornerIcon> {
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _imagePath = _normalizeImagePath(widget.imagePath);
    _loadProfileImage();
  }

  @override
  void didUpdateWidget(covariant ProfileCornerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _imagePath = _normalizeImagePath(widget.imagePath);
      _loadProfileImage();
    }
  }

  Future<void> _loadProfileImage() async {
    final explicit = _normalizeImagePath(widget.imagePath);
    if (explicit != null && explicit.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _imagePath = explicit;
      });
      return;
    }

    final prefImage = await _loadSavedImagePath();
    if (prefImage != null && mounted) {
      setState(() {
        _imagePath = prefImage;
      });
    }

    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return;

    try {
      final remoteImage = await _loadRemoteImagePath();
      if (remoteImage != null && mounted) {
        setState(() {
          _imagePath = remoteImage;
        });
      }
    } catch (_) {
      // Fallback to saved image or generic icon.
    }
  }

  Future<String?> _loadSavedImagePath() async {
    if (widget.userType == UserType.admin) {
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    final settingsKey = widget.userType == UserType.company
        ? 'company_settings'
        : 'client_settings';
    final imageKey = widget.userType == UserType.company
        ? 'logoPath'
        : 'avatarPath';
    final raw = prefs.getString(settingsKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return _normalizeImagePath(data[imageKey]?.toString());
    } catch (_) {
      return null;
    }
  }

  Future<String?> _loadRemoteImagePath() async {
    if (widget.userType == UserType.admin) {
      return null;
    }
    if (widget.userType == UserType.company) {
      final profile = await RemoteCompanyService().getCompanyProfile();
      final icon = profile?['icon_uri'] ?? profile?['iconUri'];
      return _normalizeImagePath(icon?.toString());
    }

    final profile = await RemoteClientService().getClientProfile();
    final icon = profile?['icon_uri'] ?? profile?['iconUri'];
    return _normalizeImagePath(icon?.toString());
  }

  String? _normalizeImagePath(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('blob:') ||
        value.startsWith('data:')) {
      return value;
    }
    if (value.startsWith('/api/objects/')) {
      return '${ApiConfig.fileBaseUrl}$value';
    }
    if (value.contains('/api/objects/')) {
      return value;
    }
    if (value.startsWith('/') || value.startsWith('file://')) {
      return null;
    }
    return '${ApiConfig.fileBaseUrl}/api/objects/$value';
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _imagePath;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB5CADD)),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath != null
          ? Image.network(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallback(),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return const Icon(
      Icons.person,
      color: Color(0xFF4B5B6B),
      size: 18,
    );
  }
}
