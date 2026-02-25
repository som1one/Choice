/// Системные категории (должны соответствовать системным категориям на бэке, ID 1..7).
const List<String> kSystemCategories = <String>[
  'Автоуслуги',
  'Услуги строителя',
  'Красота',
  'Бытовые услуги',
  'Финансовые услуги',
  'Парфюм',
  'Автотовары',
];

int categoryTitleToId(String title) {
  final idx = kSystemCategories.indexOf(title);
  return idx >= 0 ? idx + 1 : 1;
}

String categoryIdToTitle(int id) {
  final idx = id - 1;
  if (idx < 0 || idx >= kSystemCategories.length) return 'Категория #$id';
  return kSystemCategories[idx];
}

