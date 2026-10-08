import '../../../core/api/backend.dart';

class GlossaryTerm {
  const GlossaryTerm({
    required this.term,
    required this.explanation,
    required this.category,
  });

  final String term;
  final String explanation;
  final String category;

  factory GlossaryTerm.fromJson(Json json) => GlossaryTerm(
    term: json['termino'] as String? ?? '',
    explanation: json['explicacion'] as String? ?? '',
    category: json['categoria'] as String? ?? '',
  );
}

class NewsItem {
  const NewsItem({
    required this.title,
    required this.summary,
    required this.source,
    required this.link,
    required this.published,
    required this.validUntil,
  });

  final String title;
  final String summary;
  final String source;
  final String link;
  final String published;
  final String validUntil;

  factory NewsItem.fromJson(Json json) => NewsItem(
    title: json['titulo'] as String? ?? '',
    summary: json['resumen'] as String? ?? '',
    source: json['fuente'] as String? ?? '',
    link: json['enlace'] as String? ?? '',
    published: json['publicada'] as String? ?? '',
    validUntil: json['vigente_hasta'] as String? ?? '',
  );

  int get daysLeft {
    final end = DateTime.tryParse(validUntil);
    if (end == null) return 0;
    return end.difference(DateTime.now()).inDays;
  }
}

class KnowledgeItem {
  const KnowledgeItem({
    required this.id,
    required this.name,
    required this.type,
    required this.state,
  });

  final String id;
  final String name;
  final String type;
  final String state;

  factory KnowledgeItem.fromJson(Json json) => KnowledgeItem(
    id: json['id'] as String,
    name: json['nombre'] as String? ?? '',
    type: json['tipo'] as String? ?? '',
    state: json['estado'] as String? ?? '',
  );
}

class KnowledgeDetail {
  const KnowledgeDetail({
    required this.item,
    required this.cause,
    required this.symptoms,
    required this.handling,
    this.notice,
  });

  final KnowledgeItem item;
  final String cause;
  final List<String> symptoms;
  final List<String> handling;
  final String? notice;

  factory KnowledgeDetail.fromJson(Json json) => KnowledgeDetail(
    item: KnowledgeItem.fromJson(json),
    cause: json['causa'] as String? ?? '',
    symptoms: (json['sintomas'] as List? ?? const [])
        .whereType<Json>()
        .map((s) => s['descripcion'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList(),
    handling: (json['manejos'] as List? ?? const [])
        .whereType<Json>()
        .map((s) => s['descripcion'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList(),
    notice: json['aviso'] as String?,
  );
}

class ContentRepository {
  const ContentRepository(this._backend);

  final Backend _backend;

  Future<List<GlossaryTerm>> glossary() async =>
      (await _backend.getList('glosario')).map(GlossaryTerm.fromJson).toList();

  Future<List<NewsItem>> news() async {
    final page = await _backend.getPage('noticias', query: {'limit': '50'});
    return page.items.map(NewsItem.fromJson).toList();
  }

  Future<List<KnowledgeItem>> knowledge({String? search}) async {
    final page = await _backend.getPage(
      'conocimiento',
      query: {
        'limit': '50',
        if (search != null && search.isNotEmpty) 'q': search,
      },
    );
    return page.items.map(KnowledgeItem.fromJson).toList();
  }

  Future<KnowledgeDetail> knowledgeDetail(String id) async =>
      KnowledgeDetail.fromJson(await _backend.getJson('conocimiento/$id'));
}
