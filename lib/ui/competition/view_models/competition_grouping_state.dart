import 'package:flag_admin_web/domain/models/grouping_config.dart';
import 'package:flag_admin_web/src/domain/enums/grouping_type.dart';

/// Contrato comum de controle de agrupamento de times em competições.
abstract class CompetitionGroupingState {
  GroupingType get groupingType;
  List<CompetitionGroupConfig> get groups;
  List<CompetitionConferenceConfig> get conferences;

  void setGroupingType(GroupingType type);
  void addGroup();
  void updateGroupName(int index, String newName);
  void removeGroup(int index);
  void addConference();
  void updateConferenceName(int index, String newName);
  void removeConference(int index);
  void addDivision(int conferenceIndex, [String? initialName]);
  void updateDivisionName(int conferenceIndex, int divisionIndex, String newName);
  void removeDivision(int conferenceIndex, int divisionIndex);
}
