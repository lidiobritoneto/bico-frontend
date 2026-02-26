import 'dart:math';
import '../../models/bico_category.dart';
import '../../models/bico_message.dart';
import '../../models/bico_order.dart';
import '../../models/bico_provider.dart';

class MockRepo {
  static final _rnd = Random(7);

  static const clientId = "client";
  static const providerId = "provider";

  static final List<BicoCategory> categories = const [
    BicoCategory(id: "cat_eletrica", name: "Eletricista"),
    BicoCategory(id: "cat_hidraulica", name: "Encanador"),
    BicoCategory(id: "cat_pintura", name: "Pintor"),
    BicoCategory(id: "cat_informatica", name: "TI / Computador"),
    BicoCategory(id: "cat_manicure", name: "Manicure"),
    BicoCategory(id: "cat_pedreiro", name: "Pedreiro"),
    BicoCategory(id: "cat_arcond", name: "Ar-condicionado"),
    BicoCategory(id: "cat_limpeza", name: "Limpeza"),
  ];

  static final List<BicoProvider> providers = [
    const BicoProvider(
      id: "p1",
      name: "Rafael Silva",
      city: "São Luís",
      state: "MA",
      rating: 4.8,
      reviewsCount: 126,
      priceBase: 120,
      priceType: "por hora",
      categories: ["Eletricista", "Ar-condicionado"],
      bio: "Atendo instalações e reparos elétricos, manutenção preventiva e soluções rápidas com segurança.",
      isActive: true,
    ),
    const BicoProvider(
      id: "p2",
      name: "Mariana Costa",
      city: "Fortaleza",
      state: "CE",
      rating: 4.6,
      reviewsCount: 88,
      priceBase: 80,
      priceType: "por serviço",
      categories: ["Manicure"],
      bio: "Atendimento domiciliar com horário flexível. Higiene e acabamento premium.",
      isActive: true,
    ),
    const BicoProvider(
      id: "p3",
      name: "Bruno Almeida",
      city: "São Paulo",
      state: "SP",
      rating: 4.7,
      reviewsCount: 214,
      priceBase: 150,
      priceType: "por serviço",
      categories: ["TI / Computador"],
      bio: "Formatação, backup, redes, instalação de programas e suporte presencial/rápido.",
      isActive: true,
    ),
    const BicoProvider(
      id: "p4",
      name: "Carlos Souza",
      city: "Rio de Janeiro",
      state: "RJ",
      rating: 4.4,
      reviewsCount: 51,
      priceBase: 200,
      priceType: "por serviço",
      categories: ["Encanador", "Pedreiro"],
      bio: "Reparos hidráulicos, vazamentos, manutenção em geral e pequenos serviços de obra.",
      isActive: true,
    ),
  ];

  static final List<BicoOrder> _orders = [
    BicoOrder(
      id: "o1",
      clientName: "Cliente",
      providerId: "p1",
      providerName: "Rafael Silva",
      categoryName: "Eletricista",
      description: "Tomada da sala está faiscando. Preciso revisar e trocar se necessário.",
      city: "São Luís",
      state: "MA",
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: "new",
    ),
  ];

  static final Map<String, List<BicoMessage>> _messagesByOrder = {
    "o1": [
      BicoMessage(
        id: "m1",
        orderId: "o1",
        senderId: clientId,
        senderName: "Cliente",
        type: "text",
        content: "Olá! Pode vir hoje ainda?",
        createdAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 2)),
      ),
      BicoMessage(
        id: "m2",
        orderId: "o1",
        senderId: "p1",
        senderName: "Rafael",
        type: "text",
        content: "Consigo sim. Qual seu bairro?",
        createdAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 1)),
      ),
      BicoMessage(
        id: "m3",
        orderId: "o1",
        senderId: clientId,
        senderName: "Cliente",
        type: "text",
        content: "Cohama. É só uma tomada, mas tá perigoso.",
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  };

  // --- queries ---
  static List<BicoProvider> searchProviders({
    required String city,
    required String state,
    String? categoryName,
  }) {
    final c = city.trim().toLowerCase();
    final s = state.trim().toLowerCase();

    return providers.where((p) {
      final sameCity = p.city.toLowerCase().contains(c.isEmpty ? p.city.toLowerCase() : c);
      final sameState = p.state.toLowerCase() == (s.isEmpty ? p.state.toLowerCase() : s);
      final matchesCat = categoryName == null ? true : p.categories.contains(categoryName);
      return p.isActive && sameCity && sameState && matchesCat;
    }).toList();
  }

  static List<BicoOrder> getMyOrders() {
    return List.unmodifiable(_orders);
  }

  static List<BicoMessage> getMessages(String orderId) {
    return List.unmodifiable(_messagesByOrder[orderId] ?? []);
  }

  // --- mutations (mock) ---
  static BicoOrder createOrder({
    required String providerId,
    required String providerName,
    required String categoryName,
    required String description,
    required String city,
    required String state,
  }) {
    final id = "o${100 + _rnd.nextInt(900)}";
    final order = BicoOrder(
      id: id,
      clientName: "Cliente",
      providerId: providerId,
      providerName: providerName,
      categoryName: categoryName,
      description: description,
      city: city,
      state: state,
      createdAt: DateTime.now(),
      status: "new",
    );
    _orders.insert(0, order);
    _messagesByOrder[id] = [
      BicoMessage(
        id: "m${1000 + _rnd.nextInt(9000)}",
        orderId: id,
        senderId: clientId,
        senderName: "Cliente",
        type: "text",
        content: "Olá! Acabei de enviar o pedido. Podemos combinar por aqui?",
        createdAt: DateTime.now(),
      )
    ];
    return order;
  }

  static void sendMessage({
    required String orderId,
    required String senderId,
    required String senderName,
    required String text,
  }) {
    final msg = BicoMessage(
      id: "m${1000 + _rnd.nextInt(9000)}",
      orderId: orderId,
      senderId: senderId,
      senderName: senderName,
      type: "text",
      content: text,
      createdAt: DateTime.now(),
    );
    final list = _messagesByOrder.putIfAbsent(orderId, () => []);
    list.add(msg);
  }
}