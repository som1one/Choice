import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/order_request_model.dart';
import '../services/remote_inquiry_service.dart';
import '../constants/categories.dart';
import 'order_screen.dart';

class OrderRequestScreen extends StatefulWidget {
  final OrderRequestModel orderRequest;

  const OrderRequestScreen({super.key, required this.orderRequest});

  @override
  State<OrderRequestScreen> createState() => _OrderRequestScreenState();
}

class _OrderRequestScreenState extends State<OrderRequestScreen> {
  late OrderRequestModel _orderRequest;
  late String _selectedCategory;
  late TextEditingController _descriptionController;
  late bool _toKnowPrice;
  late bool _toKnowDeadline;
  late bool _toKnowSpecialist;
  late bool _toKnowEnrollmentDate;
  late double _radiusKm;
  late List<String> _photoUris;
  bool _isLoading = false;
  bool _showCategoryModal = false;

  @override
  void initState() {
    super.initState();
    _orderRequest = widget.orderRequest;
    _selectedCategory = categoryIdToTitle(_orderRequest.categoryId);
    _descriptionController = TextEditingController(text: _orderRequest.description);
    _toKnowPrice = _orderRequest.toKnowPrice;
    _toKnowDeadline = _orderRequest.toKnowDeadline;
    _toKnowSpecialist = _orderRequest.toKnowSpecialist;
    _toKnowEnrollmentDate = _orderRequest.toKnowEnrollmentDate;
    _radiusKm = _orderRequest.searchRadius / 1000.0;
    _photoUris = List<String>.from(_orderRequest.photoUris);
    // Обеспечиваем 3 элемента
    while (_photoUris.length < 3) {
      _photoUris.add('');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isActive => _orderRequest.isActive;
  bool get _canEdit => _isActive;

  bool get _isFormValid {
    if (_descriptionController.text.trim().isEmpty) return false;
    if (!_toKnowPrice &&
        !_toKnowDeadline &&
        !_toKnowSpecialist &&
        !_toKnowEnrollmentDate) {
      return false;
    }
    return true;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
      case 1:
        return 'Активен';
      case 2:
        return 'Завершен';
      default:
        return 'Отменен';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
      case 1:
        return const Color(0xFF6DC876);
      case 2:
        return const Color(0xFF2D81E0);
      default:
        return const Color(0xFFAEAEB2);
    }
  }

  Future<void> _pickImage(int index) async {
    if (!_canEdit) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _photoUris[index] = result.files.single.path!;
      });
    }
  }

  void _removeImage(int index) {
    if (!_canEdit) return;
    setState(() {
      _photoUris[index] = '';
    });
  }

  Future<void> _saveChanges() async {
    if (!_isFormValid || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Загрузить изображения на сервер через File Service
      // Пока оставляем локальные пути (в реальности нужно загрузить и получить URL)
      final photoUrisToSend = _photoUris.where((uri) => uri.isNotEmpty && !uri.startsWith('http')).toList();

      final remoteService = RemoteInquiryService();
      final result = await remoteService.updateOrderRequest(
        id: _orderRequest.id,
        categoryId: categoryTitleToId(_selectedCategory),
        description: _descriptionController.text.trim(),
        searchRadius: (_radiusKm * 1000).toInt(),
        toKnowPrice: _toKnowPrice,
        toKnowDeadline: _toKnowDeadline,
        toKnowSpecialist: _toKnowSpecialist,
        toKnowEnrollmentDate: _toKnowEnrollmentDate,
        photoUris: photoUrisToSend,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка успешно обновлена')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrderScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при обновлении заявки')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF2688EB), size: 40),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Заказ №${_orderRequest.id}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Дата и статус
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_orderRequest.creationDate ?? DateTime.now()),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_orderRequest.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(_orderRequest.status),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Категория услуг
                const Text(
                  'Категория услуг',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6D7885),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _canEdit ? () => setState(() => _showCategoryModal = true) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedCategory,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (_canEdit)
                          const Icon(Icons.expand_more, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Описание задачи
                const Text(
                  'Описание задачи',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6D7885),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  enabled: _canEdit,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Введите подробности задачи, в чем вам нужна помощь и какой вы ожидаете результат',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_canEdit) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mic, color: Color(0xFF3F8AE0)),
                        const SizedBox(width: 8),
                        const Text(
                          'Записать голосом',
                          style: TextStyle(
                            color: Color(0xFF2688EB),
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                // Что узнать у продавца
                const Text(
                  'Что узнать у продавца',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6D7885),
                  ),
                ),
                const SizedBox(height: 10),
                _buildCheckbox(
                  'Узнать стоимость',
                  _toKnowPrice,
                  _canEdit && _orderRequest.toKnowPrice,
                  (value) {
                    if (_canEdit) {
                      setState(() => _toKnowPrice = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildCheckbox(
                  'Узнать время выполнения работ',
                  _toKnowDeadline,
                  _canEdit && _orderRequest.toKnowDeadline,
                  (value) {
                    if (_canEdit) {
                      setState(() => _toKnowDeadline = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildCheckbox(
                  'Узнать имя специалиста',
                  _toKnowSpecialist,
                  _canEdit && _orderRequest.toKnowSpecialist,
                  (value) {
                    if (_canEdit) {
                      setState(() => _toKnowSpecialist = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildCheckbox(
                  'Узнать время записи',
                  _toKnowEnrollmentDate,
                  _canEdit && _orderRequest.toKnowEnrollmentDate,
                  (value) {
                    if (_canEdit) {
                      setState(() => _toKnowEnrollmentDate = value);
                    }
                  },
                ),
                const SizedBox(height: 30),
                // Фото
                Text(
                  _canEdit ? 'Приложите файлы к заказу' : 'Приложенные файлы',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6D7885),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) => _buildImageBox(index)),
                ),
                if (_canEdit) ...[
                  const SizedBox(height: 30),
                  // Радиус поиска
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Радиус поиска',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6D7885),
                        ),
                      ),
                      Text(
                        '${_radiusKm.toInt()} км',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _radiusKm,
                    min: 5,
                    max: 25,
                    divisions: 20,
                    label: '${_radiusKm.toInt()} км',
                    onChanged: (value) {
                      setState(() {
                        _radiusKm = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'от 5 км',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6D7885),
                        ),
                      ),
                      Text(
                        'до 25 км',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6D7885),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Кнопка сохранения
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFormValid && !_isLoading ? _saveChanges : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid && !_isLoading
                            ? const Color(0xFF2D81E0)
                            : const Color(0xFFABCDf3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Сохранить изменения',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
          // Модальное окно выбора категории
          if (_showCategoryModal)
            _buildCategoryModal(),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, bool enabled, ValueChanged<bool> onChanged) {
    final isDisabled = !_canEdit || !enabled;
    return Row(
      children: [
        GestureDetector(
          onTap: isDisabled ? null : () => onChanged(!value),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDisabled ? Colors.grey.shade400 : const Color(0xFFB8C1CC),
                width: value ? 0 : 2,
              ),
              color: isDisabled
                  ? const Color(0xFF7DB8F3)
                  : value
                      ? const Color(0xFF2688EB)
                      : Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.white, size: 15)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildImageBox(int index) {
    final hasImage = _photoUris[index].isNotEmpty;
    final isLocalFile = hasImage && !_photoUris[index].startsWith('http');

    return GestureDetector(
      onTap: _canEdit
          ? () {
              if (hasImage) {
                _removeImage(index);
              } else {
                _pickImage(index);
              }
            }
          : null,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  isLocalFile
                      ? Image.file(
                          File(_photoUris[index]),
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          _photoUris[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 40);
                          },
                        ),
                  if (_canEdit)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              )
            : _canEdit
                ? const Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey)
                : const SizedBox(),
      ),
    );
  }

  Widget _buildCategoryModal() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    const Text(
                      'Категория услуг',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFeff1f2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Color(0xFF818C99), size: 27),
                      ),
                      onPressed: () => setState(() => _showCategoryModal = false),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: kSystemCategories.length,
                  itemBuilder: (context, index) {
                    final category = kSystemCategories[index];
                    final isSelected = category == _selectedCategory;
                    return ListTile(
                      title: Text(category),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF2688EB))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                          _showCategoryModal = false;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
