class Step {
  final int step;
  final String topic;
  final String objective;

  Step({
    required this.step,
    required this.topic,
    required this.objective,
  });

  Step copyWith({
    int? step,
    String? topic,
    String? objective,
  }) {
    return Step(
      step: step ?? this.step,
      topic: topic ?? this.topic,
      objective: objective ?? this.objective,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'topic': topic,
      'objective': objective,
    };
  }

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      step: json['step'] as int,
      topic: json['topic'] as String,
      objective: json['objective'] as String,
    );
  }
}

class InstructionalDesign {
  final List<Step> syllabus;

  InstructionalDesign({
    List<Step>? syllabus,
  }) : syllabus = syllabus ?? [];

  bool get designFilled => syllabus.isNotEmpty;
  int get totalSteps => syllabus.length;

  InstructionalDesign copyWith({
    List<Step>? syllabus,
  }) {
    return InstructionalDesign(
      syllabus: syllabus ?? this.syllabus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'syllabus': syllabus.map((step) => step.toJson()).toList(),
    };
  }

  factory InstructionalDesign.fromJson(Map<String, dynamic> json) {
    final rawSyllabus = json['syllabus'];
    return InstructionalDesign(
      syllabus: rawSyllabus is List
          ? rawSyllabus
              .map((item) => Step.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  factory InstructionalDesign.empty() => InstructionalDesign();
}
