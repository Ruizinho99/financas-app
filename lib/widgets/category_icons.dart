import 'package:flutter/material.dart';

/// Ícone de linha para uma categoria sem emoji, escolhido pelo nome (palavras-chave comuns).
/// Sem correspondência, um ícone genérico de categoria.
IconData categoryIconFor(String name) {
  final n = _fold(name);
  for (final (words, icon) in _rules) {
    for (final w in words) {
      if (n.contains(w)) return icon;
    }
  }
  return Icons.category_outlined;
}

/// Minúsculas e sem acentos, para comparar nomes.
String _fold(String s) {
  const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = from.indexOf(c);
    b.write(i >= 0 ? to[i] : c);
  }
  return b.toString();
}

const List<(List<String>, IconData)> _rules = [
  (
    [
      'casa',
      'habita',
      'renda',
      'hipoteca',
      'condominio',
      'home',
      'rent',
      'mortgage',
    ],
    Icons.home_outlined,
  ),
  (
    [
      'supermerc',
      'mercearia',
      'alimenta',
      'compras de comida',
      'grocer',
      'food shop',
    ],
    Icons.shopping_basket_outlined,
  ),
  (
    [
      'restaur',
      'comer fora',
      'cafe',
      'pastelar',
      'refei',
      'jantar',
      'almoco',
      'dining',
      'coffee',
    ],
    Icons.restaurant_outlined,
  ),
  (
    ['delivery', 'takeaway', 'uber eats', 'glovo'],
    Icons.delivery_dining_outlined,
  ),
  (
    [
      'transport',
      'carro',
      'auto',
      'combust',
      'gasol',
      'gasoleo',
      'fuel',
      'car',
    ],
    Icons.directions_car_outlined,
  ),
  (
    ['autocarro', 'comboio', 'metro', 'bus', 'train', 'passe'],
    Icons.directions_bus_outlined,
  ),
  (
    ['estaciona', 'parking', 'portagem', 'via verde', 'toll'],
    Icons.local_parking_outlined,
  ),
  (
    [
      'saude',
      'medic',
      'farmac',
      'hospital',
      'clinica',
      'dentista',
      'health',
      'doctor',
    ],
    Icons.medical_services_outlined,
  ),
  (
    ['ginasio', 'fitness', 'desporto', 'gym', 'sport'],
    Icons.fitness_center_outlined,
  ),
  (['cinema', 'filme', 'movie'], Icons.movie_outlined),
  (
    ['lazer', 'entreten', 'divers', 'leisure', 'fun'],
    Icons.celebration_outlined,
  ),
  (['jogo', 'game', 'aposta', 'bet', 'casino'], Icons.sports_esports_outlined),
  (['musica', 'music', 'concerto', 'spotify'], Icons.music_note_outlined),
  (
    ['subscri', 'netflix', 'streaming', 'tv', 'assinatura'],
    Icons.subscriptions_outlined,
  ),
  (
    ['viagem', 'ferias', 'voo', 'avi', 'travel', 'vacation', 'flight', 'trip'],
    Icons.flight_outlined,
  ),
  (['hotel', 'alojamento', 'estadia'], Icons.hotel_outlined),
  (
    [
      'educa',
      'escola',
      'curso',
      'propina',
      'livro',
      'school',
      'course',
      'book',
      'tuition',
    ],
    Icons.school_outlined,
  ),
  (
    ['crianc', 'filho', 'bebe', 'creche', 'kid', 'child', 'baby'],
    Icons.child_care_outlined,
  ),
  (
    ['animal', 'pet', 'veterin', 'cao', 'gato', 'dog', 'cat'],
    Icons.pets_outlined,
  ),
  (
    ['roupa', 'vestu', 'calcado', 'moda', 'cloth', 'fashion', 'shoe'],
    Icons.checkroom_outlined,
  ),
  (['compras', 'loja', 'shopping', 'store'], Icons.shopping_bag_outlined),
  (['presente', 'oferta', 'prenda', 'gift'], Icons.card_giftcard_outlined),
  (['doa', 'caridade', 'charity', 'donat'], Icons.volunteer_activism_outlined),
  (['luz', 'eletric', 'energia', 'electric', 'power'], Icons.bolt_outlined),
  (['agua', 'water'], Icons.water_drop_outlined),
  (['gas'], Icons.local_fire_department_outlined),
  (
    [
      'internet',
      'wifi',
      'fibra',
      'telem',
      'telefone',
      'telemovel',
      'phone',
      'mobile',
    ],
    Icons.wifi_outlined,
  ),
  (['seguro', 'insurance'], Icons.security_outlined),
  (
    ['imposto', 'irs', 'iva', 'taxa', 'financas', 'tax'],
    Icons.request_quote_outlined,
  ),
  (
    [
      'banco',
      'comissao',
      'juros',
      'emprest',
      'credito',
      'bank',
      'fee',
      'loan',
      'interest',
    ],
    Icons.account_balance_outlined,
  ),
  (
    ['invest', 'acoes', 'etf', 'bolsa', 'cripto', 'stock', 'crypto'],
    Icons.trending_up_outlined,
  ),
  (
    ['poupanca', 'savings', 'reserva', 'emergencia', 'fundo'],
    Icons.savings_outlined,
  ),
  (
    ['salario', 'ordenado', 'vencimento', 'salary', 'wage', 'pay'],
    Icons.payments_outlined,
  ),
  (['trabalho', 'emprego', 'work', 'job', 'freelanc'], Icons.work_outline),
  (['reembolso', 'devolu', 'refund'], Icons.undo_outlined),
  (
    ['manuten', 'repara', 'obra', 'bricolage', 'repair', 'maintenance'],
    Icons.build_outlined,
  ),
  (
    ['cabeleir', 'beleza', 'estetic', 'hair', 'beauty', 'spa'],
    Icons.content_cut_outlined,
  ),
  (
    ['limpeza', 'lavandaria', 'cleaning', 'laundry'],
    Icons.local_laundry_service_outlined,
  ),
  (['cozinha', 'eletrodom', 'kitchen', 'appliance'], Icons.kitchen_outlined),
  (['movel', 'moveis', 'decora', 'furniture'], Icons.weekend_outlined),
  (['jardim', 'garden'], Icons.yard_outlined),
  (
    ['eletron', 'tecnolog', 'computador', 'gadget', 'tech', 'electronics'],
    Icons.devices_outlined,
  ),
  (['foto', 'camera'], Icons.photo_camera_outlined),
  (
    ['festa', 'bar', 'noite', 'drinks', 'party', 'night'],
    Icons.local_bar_outlined,
  ),
  (['outros', 'diversos', 'other', 'misc'], Icons.more_horiz),
];
