// LearningResource: Wikidata/OpenStax에서 가져온 학습 자료
class LearningResource {
  final String title;
  final String url;
  final String summary;
  final String resourceType; // 'wikidata_concept', 'openstax_chapter', 'openstax_exercise'

  LearningResource({
    required this.title,
    required this.url,
    required this.summary,
    required this.resourceType,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'summary': summary,
        'resourceType': resourceType,
      };

  factory LearningResource.fromJson(Map<String, dynamic> json) =>
      LearningResource(
        title: json['title'],
        url: json['url'],
        summary: json['summary'],
        resourceType: json['resourceType'],
      );
}

// InstructionalTheory: PDF RAG에서 가져온 교수설계 이론
class InstructionalTheory {
  final String theoryName;
  final String description;
  final String applicability;

  InstructionalTheory({
    required this.theoryName,
    required this.description,
    required this.applicability,
  });

  Map<String, dynamic> toJson() => {
        'theoryName': theoryName,
        'description': description,
        'applicability': applicability,
      };

  factory InstructionalTheory.fromJson(Map<String, dynamic> json) =>
      InstructionalTheory(
        theoryName: json['theoryName'],
        description: json['description'],
        applicability: json['applicability'],
      );
}

// ResourceCache: LearningState의 일부
class ResourceCache {
  final String? subject;
  final String sourceId;
  final List<LearningResource> learningResources;
  final List<InstructionalTheory> instructionalTheories;
  final DateTime? lastFetchedAt;

  ResourceCache({
    this.subject,
    required this.sourceId,
    required this.learningResources,
    required this.instructionalTheories,
    this.lastFetchedAt,
  });

  bool get isResourceReady =>
      learningResources.isNotEmpty && instructionalTheories.isNotEmpty;

  ResourceCache copyWith({
    String? subject,
    String? sourceId,
    List<LearningResource>? learningResources,
    List<InstructionalTheory>? instructionalTheories,
    DateTime? lastFetchedAt,
  }) =>
      ResourceCache(
        subject: subject ?? this.subject,
        sourceId: sourceId ?? this.sourceId,
        learningResources: learningResources ?? this.learningResources,
        instructionalTheories:
            instructionalTheories ?? this.instructionalTheories,
        lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      );

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'sourceId': sourceId,
        'learningResources':
            learningResources.map((r) => r.toJson()).toList(),
        'instructionalTheories':
            instructionalTheories.map((t) => t.toJson()).toList(),
        'lastFetchedAt': lastFetchedAt?.toIso8601String(),
      };

  factory ResourceCache.fromJson(Map<String, dynamic> json) => ResourceCache(
        subject: json['subject'],
        sourceId: json['sourceId'] ?? '',
        learningResources: (json['learningResources'] as List?)
                ?.map((r) => LearningResource.fromJson(r))
                .toList() ??
            [],
        instructionalTheories: (json['instructionalTheories'] as List?)
                ?.map((t) => InstructionalTheory.fromJson(t))
                .toList() ??
            [],
        lastFetchedAt: json['lastFetchedAt'] != null
            ? DateTime.parse(json['lastFetchedAt'])
            : null,
      );

  static ResourceCache empty() => ResourceCache(
        sourceId: '',
        learningResources: [],
        instructionalTheories: [],
      );
}
