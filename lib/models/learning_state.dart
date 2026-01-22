import 'learner_profile.dart';
import 'instructional_design.dart';

class LearningState {
  final LearnerProfile learnerProfile;
  final InstructionalDesign instructionalDesign;
  final bool isDesigning;
  final bool showDesignReady;
  final bool isCourseCompleted;
  final DateTime updatedAt;

  LearningState({
    required this.learnerProfile,
    required this.instructionalDesign,
    this.isDesigning = false,
    this.showDesignReady = false,
    this.isCourseCompleted = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  LearningState copyWith({
    LearnerProfile? learnerProfile,
    InstructionalDesign? instructionalDesign,
    bool? isDesigning,
    bool? showDesignReady,
    bool? isCourseCompleted,
    DateTime? updatedAt,
  }) {
    return LearningState(
      learnerProfile: learnerProfile ?? this.learnerProfile,
      instructionalDesign: instructionalDesign ?? this.instructionalDesign,
      isDesigning: isDesigning ?? this.isDesigning,
      showDesignReady: showDesignReady ?? this.showDesignReady,
      isCourseCompleted: isCourseCompleted ?? this.isCourseCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learnerProfile': learnerProfile.toJson(),
      'instructionalDesign': instructionalDesign.toJson(),
      'isDesigning': isDesigning,
      'showDesignReady': showDesignReady,
      'isCourseCompleted': isCourseCompleted,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LearningState.fromJson(Map<String, dynamic> json) {
    return LearningState(
      learnerProfile:
          LearnerProfile.fromJson(json['learnerProfile'] as Map<String, dynamic>),
      instructionalDesign: InstructionalDesign.fromJson(
        json['instructionalDesign'] as Map<String, dynamic>,
      ),
      isDesigning: json['isDesigning'] as bool? ?? false,
      showDesignReady: json['showDesignReady'] as bool? ?? false,
      isCourseCompleted: json['isCourseCompleted'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  factory LearningState.initial() {
    return LearningState(
      learnerProfile: LearnerProfile(),
      instructionalDesign: InstructionalDesign.empty(),
    );
  }
}
