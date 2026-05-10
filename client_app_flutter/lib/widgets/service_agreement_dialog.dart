import 'package:flutter/material.dart';

const String serviceAgreementTitle =
    'Соглашение об использовании сервиса «Выбор»';

const String serviceAgreementText = '''
Настоящим соглашением регулируются взаимоотношения между Пользователями (клиентами и исполнителями услуг) и сервисом «Выбор».

Сервис «Выбор» действует исключительно в качестве информационной онлайн-площадки-посредника, обеспечивающей пользователям возможность самостоятельного подбора исполнителей услуг и установления прямого контакта между клиентами и исполнителями.

Сервис «Выбор» не оказывает никаких услуг самостоятельно и не контролирует деятельность пользователей сервиса. Сервис не несет никакой ответственности за качество, сроки, безопасность и результаты оказанных услуг, а также за соответствие деятельности исполнителей требованиям законодательства, наличие лицензий, разрешений, сертификатов и иных официальных документов.

Пользователь самостоятельно осуществляет проверку исполнителя услуг или товаров всеми доступными способами: путем личного общения, телефонной связи, официального сайта исполнителя, государственных реестров, социальных сетей, отзывов третьих лиц или иными законными методами. Пользователь и исполнитель самостоятельно принимает решение о заключении сделки между собой.

Сервис «Выбор» обеспечивает только техническую работу платформы и размещение беседы участников сервиса на момент их размещения. Все договорные обязательства и ответственность возникают исключительно между клиентом и выбранным им исполнителем.

Пользование сервисом «Выбор» означает полное принятие и согласие клиента с условиями настоящего соглашения.
''';

Future<void> showServiceAgreementDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(serviceAgreementTitle),
      content: const SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Text(
            serviceAgreementText,
            style: TextStyle(fontSize: 14, height: 1.45),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    ),
  );
}

class ServiceAgreementCheckbox extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onChanged;

  const ServiceAgreementCheckbox({
    super.key,
    required this.accepted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB5CADD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: accepted,
            onChanged: (value) => onChanged(value ?? false),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 2,
              children: [
                const Text(
                  'Соглашаюсь с условиями сервиса',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                TextButton(
                  onPressed: () => showServiceAgreementDialog(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('«Выбор»'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
