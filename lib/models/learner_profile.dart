enum LearnerLevel {
  beginner,
  intermediate,
  expert;

  String toJson() => name;
  static LearnerLevel fromJson(String value) =>
      LearnerLevel.values.byName(value);
}

enum TonePreference {
  kind,
  formal,
  casual;

  String toJson() => name;
  static TonePreference fromJson(String value) =>
      TonePreference.values.byName(value);
}

class LearnerProfile {
  final String? subject;
  final String? goal;
  final LearnerLevel? level;
  final TonePreference? tonePreference;

  LearnerProfile({
    this.subject,
    this.goal,
    this.level,
    this.tonePreference,
  });

  bool get isMandatoryFilled {
    return _isFilled(subject) && _isFilled(goal);
  }

  bool _isFilled(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.toLowerCase() != 'null';
  }

  LearnerProfile copyWith({
    String? subject,
    String? goal,
    LearnerLevel? level,
    TonePreference? tonePreference,
  }) {
    return LearnerProfile(
      subject: subject ?? this.subject,
      goal: goal ?? this.goal,
      level: level ?? this.level,
      tonePreference: tonePreference ?? this.tonePreference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'goal': goal,
      'level': level?.toJson(),
      'tonePreference': tonePreference?.toJson(),
    };
  }

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    return LearnerProfile(
      subject: json['subject'] as String?,
      goal: json['goal'] as String?,
      level: json['level'] != null
          ? LearnerLevel.fromJson(json['level'] as String)
          : null,
      tonePreference: json['tonePreference'] != null
          ? TonePreference.fromJson(json['tonePreference'] as String)
          : null,
    );
  }
}
