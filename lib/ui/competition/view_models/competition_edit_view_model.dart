import 'package:flutter/material.dart';
import 'package:flag_admin_web/data/repositories/competition_repository.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/domain/models/grouping_config.dart';
import 'package:flag_admin_web/src/api/repository_exception.dart';
import 'package:flag_admin_web/src/domain/enums/age_group.dart';
import 'package:flag_admin_web/src/domain/enums/competition_status.dart';
import 'package:flag_admin_web/src/domain/enums/gender.dart';
import 'package:flag_admin_web/src/domain/enums/grouping_type.dart';
import 'package:flag_admin_web/src/domain/enums/modality.dart';
import 'package:flag_admin_web/src/domain/enums/tournament_format.dart';

import 'competition_grouping_state.dart';

/// ViewModel dedicada exclusivamente à EDIÇÃO de Competição existente (ADR-001 / MVVM 1:1).
///
/// Responsabilidade única: carregar a entidade existente pelo ID e salvar as alterações.
class CompetitionEditViewModel extends ChangeNotifier implements CompetitionGroupingState {
  final CompetitionRepository _repository;
  final String competitionId;

  CompetitionEditViewModel({
    required CompetitionRepository repository,
    required this.competitionId,
    Competition? initialData,
  })  : _repository = repository {
    nameController.addListener(notifyListeners);
    if (initialData != null && initialData.organizationId != null && initialData.organizationId!.isNotEmpty) {
      _populate(initialData);
    }
  }

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final seasonController = TextEditingController(text: '2026');
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  String? selectedOrganizationId;
  String? organizationName;
  TournamentFormat tournamentFormat = TournamentFormat.roundRobin;
  @override
  GroupingType groupingType = GroupingType.none;

  /// Lista reativa de grupos customizados pelo usuário
  @override
  List<CompetitionGroupConfig> groups = [
    const CompetitionGroupConfig(id: 'grp_1', name: 'Grupo A'),
    const CompetitionGroupConfig(id: 'grp_2', name: 'Grupo B'),
  ];

  /// Lista reativa de conferências com suas respectivas divisões
  @override
  List<CompetitionConferenceConfig> conferences = [
    const CompetitionConferenceConfig(
      id: 'conf_1',
      name: 'Conferência Americana',
      divisions: [],
    ),
    const CompetitionConferenceConfig(
      id: 'conf_2',
      name: 'Conferência Nacional',
      divisions: [],
    ),
  ];

  Modality? selectedModality = Modality.flag5x5;
  Gender? selectedGender = Gender.male;
  AgeGroup? selectedAgeGroup = AgeGroup.adult;
  CompetitionStatus status = CompetitionStatus.draft;

  /// Exibição concatenada: Nome do campeonato + características (modalidade + gênero)
  String get displayNamePreview {
    final baseName = nameController.text.trim();
    if (baseName.isEmpty) return '';
    final parts = <String>[baseName];
    final details = <String>[
      if (selectedModality != null) selectedModality!.label,
      if (selectedGender != null) selectedGender!.label,
    ];
    if (details.isNotEmpty) {
      parts.add(details.join(' - '));
    }
    return parts.join(' • ');
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Inicializa e busca os dados da competição pelo ID.
  Future<void> load({bool forceRefresh = false}) async {
    if (selectedOrganizationId != null && !forceRefresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final comp = await _repository.getCompetition(competitionId);
      _populate(comp);
    } catch (e) {
      _errorMessage = 'Não foi possível carregar a competição.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _populate(Competition comp) {
    nameController.text = comp.name;
    descriptionController.text = comp.description ?? '';
    seasonController.text = comp.season;
    startDateController.text =
        comp.startDate != null ? comp.startDate!.toIso8601String().split('T').first : '';
    endDateController.text =
        comp.endDate != null ? comp.endDate!.toIso8601String().split('T').first : '';
    selectedOrganizationId = comp.organizationId;
    organizationName = comp.organizationName;
    tournamentFormat = comp.tournamentFormat;
    selectedModality = comp.modality;
    selectedGender =
        comp.gender != null ? Gender.tryFromJson(comp.gender!) : null;
    selectedAgeGroup =
        comp.ageGroup != null ? AgeGroup.tryFromJson(comp.ageGroup!) : null;
    groupingType = comp.groupingType ?? GroupingType.none;
    if (comp.groupingConfig != null) {
      if (comp.groupingConfig!.groups.isNotEmpty) {
        groups = List.from(comp.groupingConfig!.groups);
      }
      if (comp.groupingConfig!.conferences.isNotEmpty) {
        conferences = List.from(comp.groupingConfig!.conferences);
      }
    }
    status = comp.status;
    notifyListeners();
  }

  void setOrganization(String? id) {
    selectedOrganizationId = id;
    notifyListeners();
  }

  void setTournamentFormat(TournamentFormat format) {
    tournamentFormat = format;
    notifyListeners();
  }

  @override
  void setGroupingType(GroupingType type) {
    groupingType = type;
    notifyListeners();
  }

  // --- MÉTODOS DE MANIPULAÇÃO DE GRUPOS ---
  @override
  void addGroup() {
    final nextLetter = String.fromCharCode(65 + groups.length);
    final newId = 'grp_${DateTime.now().millisecondsSinceEpoch}';
    groups.add(CompetitionGroupConfig(id: newId, name: 'Grupo $nextLetter'));
    notifyListeners();
  }

  @override
  void updateGroupName(int index, String newName) {
    if (index >= 0 && index < groups.length) {
      groups[index] = CompetitionGroupConfig(id: groups[index].id, name: newName);
      notifyListeners();
    }
  }

  @override
  void removeGroup(int index) {
    if (groups.length > 2) {
      groups.removeAt(index);
      notifyListeners();
    }
  }

  // --- MÉTODOS DE MANIPULAÇÃO DE CONFERÊNCIAS E DIVISÕES ---
  @override
  void addConference() {
    final newId = 'conf_${DateTime.now().millisecondsSinceEpoch}';
    final count = conferences.length + 1;
    conferences.add(
      CompetitionConferenceConfig(
        id: newId,
        name: 'Conferência $count',
        divisions: [],
      ),
    );
    notifyListeners();
  }

  @override
  void updateConferenceName(int index, String newName) {
    if (index >= 0 && index < conferences.length) {
      conferences[index] = conferences[index].copyWith(name: newName);
      notifyListeners();
    }
  }

  @override
  void removeConference(int index) {
    if (conferences.length > 1) {
      conferences.removeAt(index);
      notifyListeners();
    }
  }

  @override
  void addDivision(int conferenceIndex, [String? initialName]) {
    if (conferenceIndex >= 0 && conferenceIndex < conferences.length) {
      final conf = conferences[conferenceIndex];
      final divCount = conf.divisions.length + 1;
      final newDivId = 'div_${DateTime.now().millisecondsSinceEpoch}';
      final name = (initialName != null && initialName.trim().isNotEmpty)
          ? initialName.trim()
          : 'Divisão $divCount';
      final updatedDivs = List<CompetitionDivisionConfig>.from(conf.divisions)
        ..add(CompetitionDivisionConfig(id: newDivId, name: name));
      conferences[conferenceIndex] = conf.copyWith(divisions: updatedDivs);
      notifyListeners();
    }
  }

  @override
  void updateDivisionName(int conferenceIndex, int divisionIndex, String newName) {
    if (conferenceIndex >= 0 && conferenceIndex < conferences.length) {
      final conf = conferences[conferenceIndex];
      if (divisionIndex >= 0 && divisionIndex < conf.divisions.length) {
        final updatedDivs = List<CompetitionDivisionConfig>.from(conf.divisions);
        updatedDivs[divisionIndex] = CompetitionDivisionConfig(
          id: updatedDivs[divisionIndex].id,
          name: newName,
        );
        conferences[conferenceIndex] = conf.copyWith(divisions: updatedDivs);
        notifyListeners();
      }
    }
  }

  @override
  void removeDivision(int conferenceIndex, int divisionIndex) {
    if (conferenceIndex >= 0 && conferenceIndex < conferences.length) {
      final conf = conferences[conferenceIndex];
      if (divisionIndex >= 0 && divisionIndex < conf.divisions.length) {
        final updatedDivs = List<CompetitionDivisionConfig>.from(conf.divisions)
          ..removeAt(divisionIndex);
        conferences[conferenceIndex] = conf.copyWith(divisions: updatedDivs);
        notifyListeners();
      }
    }
  }

  void setModality(Modality modality) {
    selectedModality = modality;
    notifyListeners();
  }

  void setGender(Gender gender) {
    selectedGender = gender;
    notifyListeners();
  }

  void setAgeGroup(AgeGroup ageGroup) {
    selectedAgeGroup = ageGroup;
    notifyListeners();
  }

  void setStatus(CompetitionStatus newStatus) {
    status = newStatus;
    notifyListeners();
  }

  /// Salva as alterações da competição.
  Future<Competition?> update() async {
    if (nameController.text.trim().isEmpty) {
      _errorMessage = 'Informe o nome da competição.';
      notifyListeners();
      return null;
    }
    if (selectedOrganizationId == null || selectedOrganizationId!.isEmpty) {
      _errorMessage = 'Selecione uma organização promotora.';
      notifyListeners();
      return null;
    }
    if (selectedModality == null) {
      _errorMessage = 'Selecione a modalidade.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final body = <String, dynamic>{
      'name': nameController.text.trim(),
      'organizationId': selectedOrganizationId,
      'season': seasonController.text.trim().isEmpty ? '2026' : seasonController.text.trim(),
      'tournamentFormat': tournamentFormat.toJson(),
      'groupingType': groupingType.toJson(),
      'groupingConfig': GroupingConfig(
        groups: groupingType == GroupingType.groups ? groups : const [],
        conferences: groupingType == GroupingType.conferences
            ? conferences
            : const [],
      ).toJson(),
      'status': status.toJson(),
      'modality': selectedModality!.toJson(),
      if (descriptionController.text.trim().isNotEmpty)
        'description': descriptionController.text.trim(),
      if (startDateController.text.isNotEmpty)
        'startDate': startDateController.text.trim(),
      if (endDateController.text.isNotEmpty)
        'endDate': endDateController.text.trim(),
      if (selectedGender != null) 'gender': selectedGender!.toJson(),
      if (selectedAgeGroup != null) 'ageGroup': selectedAgeGroup!.toJson(),
    };

    try {
      final result = await _repository.updateCompetition(competitionId, body);
      return result;
    } on RepositoryException catch (e) {
      if (e.statusCode == 403) {
        _errorMessage = 'Acesso não autorizado (403): você não possui permissão para gerenciar esta competição.';
      } else if (e.statusCode == 401) {
        _errorMessage = 'Sessão expirada (401). Faça login novamente.';
      } else {
        _errorMessage = e.message.isNotEmpty ? e.message : 'Erro ao salvar a competição ().';
      }
      return null;
    } catch (e) {
      _errorMessage = 'Erro ao salvar a competição: ';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    seasonController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }
}
