import 'package:equatable/equatable.dart';

/// Payload kuesioner exit interview (`POST /resignations/my/exit-interview`).
///
/// Skala kepuasan 1–5. Bila [isSkipped] true, field lain diabaikan server.
class ExitInterviewRequestModel extends Equatable {
  final int? satisfactionCulture;
  final int? satisfactionManager;
  final int? satisfactionSalary;
  final int? satisfactionGrowth;
  final int? satisfactionWorkLifeBalance;
  final String reasonFeedback;
  final String? suggestions;
  final bool wouldRecommend;
  final bool isAnonymous;
  final bool isSkipped;

  const ExitInterviewRequestModel({
    this.satisfactionCulture,
    this.satisfactionManager,
    this.satisfactionSalary,
    this.satisfactionGrowth,
    this.satisfactionWorkLifeBalance,
    this.reasonFeedback = '',
    this.suggestions,
    this.wouldRecommend = true,
    this.isAnonymous = false,
    this.isSkipped = false,
  });

  /// Melewati kuesioner (jika diizinkan kebijakan perusahaan).
  const ExitInterviewRequestModel.skipped() : this(isSkipped: true);

  Map<String, dynamic> toJson() {
    final suggestionsText = suggestions?.trim();
    return {
      if (satisfactionCulture != null) 'satisfactionCulture': satisfactionCulture,
      if (satisfactionManager != null) 'satisfactionManager': satisfactionManager,
      if (satisfactionSalary != null) 'satisfactionSalary': satisfactionSalary,
      if (satisfactionGrowth != null) 'satisfactionGrowth': satisfactionGrowth,
      if (satisfactionWorkLifeBalance != null)
        'satisfactionWorkLifeBalance': satisfactionWorkLifeBalance,
      'reasonFeedback': reasonFeedback.trim(),
      if (suggestionsText != null && suggestionsText.isNotEmpty)
        'suggestions': suggestionsText,
      'wouldRecommend': wouldRecommend,
      'isAnonymous': isAnonymous,
      'isSkipped': isSkipped,
    };
  }

  @override
  List<Object?> get props => [
        satisfactionCulture,
        satisfactionManager,
        satisfactionSalary,
        satisfactionGrowth,
        satisfactionWorkLifeBalance,
        reasonFeedback,
        suggestions,
        wouldRecommend,
        isAnonymous,
        isSkipped,
      ];
}
