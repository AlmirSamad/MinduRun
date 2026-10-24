import '../models/models.dart';
import 'domain_services.dart';

/// Short countdown for a competition ("Começa em 3 h", "Termina em 2 dias",
/// "Último dia! Termina em 5 h", "Encerrada"); null when cancelled.
String? competitionCountdown(
  Competition competition,
  DateTime now, {
  CompetitionStateService state = const CompetitionStateService(),
}) => switch (state.effectiveStatus(competition, now)) {
  CompetitionStatus.scheduled =>
    'Começa em ${_span(competition.startsAt.difference(now))}',
  CompetitionStatus.active =>
    competition.endsAt.difference(now) < const Duration(hours: 24)
        ? 'Último dia! Termina em ${_span(competition.endsAt.difference(now))}'
        : 'Termina em ${_span(competition.endsAt.difference(now))}',
  CompetitionStatus.finished => 'Encerrada',
  CompetitionStatus.cancelled => null,
};

/// Rounds up so "Termina em 1 min" never shows when time is already over.
String _span(Duration d) {
  final minutes = (d.inSeconds / 60).ceil();
  if (minutes < 60) return '$minutes min';
  final hours = (minutes / 60).ceil();
  if (hours < 24) return '$hours h';
  final days = (hours / 24).ceil();
  return days == 1 ? '1 dia' : '$days dias';
}
