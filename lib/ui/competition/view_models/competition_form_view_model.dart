import 'package:flutter/material.dart';
import 'package:flag_admin_web/data/repositories/competition_repository.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/src/domain/enums/age_group.dart';
import 'package:flag_admin_web/src/domain/enums/competition_status.dart';
import 'package:flag_admin_web/src/domain/enums/gender.dart';
import 'package:flag_admin_web/src/domain/enums/grouping_type.dart';
import 'package:flag_admin_web/src/domain/enums/modality.dart';
import 'package:flag_admin_web/src/domain/enums/tournament_format.dart';

/// ViewModel para o formulário de cadastro/edição de Competições (ADR-001 / MVVM).
class CompetitionFormViewModel extends ChangeNotifier {
  final CompetitionRepository _repository;

  CompetitionFormViewModel({required CompetitionRepository repository})
      : _repository = repository {
    nameController.addListener(notifyListeners);
  }

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final seasonController = TextEditingController(text: '2026');
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  String? selectedOrganizationId;
  TournamentFormat tournamentFormat = TournamentFormat.roundRobin;
  GroupingType groupingType = GroupingType.none;
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

  String? competitionId;
  bool get isEditing => competitionId != null;

  /// Inicializa o formulário para edição ou novo registro.
  Future<void> init({String? id, Competition? initialData}) async {
    competitionId = id;
    if (initialData != null) {
      _populate(initialData);
      return;
    }
    if (id != null) {
      _isLoading = true;
      notifyListeners();
      try {
        final comp = await _repository.getCompetition(id);
        _populate(comp);
      } catch (e) {
        _errorMessage = 'Não foi possível carregar a competição.';
      } finally {
        _isLoading = false;
        notifyListeners();
      }
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
    tournamentFormat = comp.tournamentFormat;
    selectedModality = comp.modality;
    selectedGender =
        comp.gender != null ? Gender.tryFromJson(comp.gender!) : null;
    selectedAgeGroup =
        comp.ageGroup != null ? AgeGroup.tryFromJson(comp.ageGroup!) : null;
    groupingType = comp.groupingType ?? GroupingType.none;
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

  void setGroupingType(GroupingType type) {
    groupingType = type;
    notifyListeners();
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

  /// Salva ou atualiza a competição.
  Future<Competition?> save() async {
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
      final result = isEditing
          ? await _repository.updateCompetition(competitionId!, body)
          : await _repository.createCompetition(body);
      return result;
    } catch (e) {
      _errorMessage = 'Erro ao salvar a competição. Verifique os dados.';
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
