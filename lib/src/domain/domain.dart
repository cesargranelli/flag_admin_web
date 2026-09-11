/// Domain package do Flag Admin Web.
///
/// Exporta todos os models e enums.
library;

// Enums
export 'package:flag_admin_web/domain/enums/age_group.dart';
export 'package:flag_admin_web/domain/enums/athlete_position.dart';
export 'package:flag_admin_web/domain/enums/check_in_status.dart';
export 'package:flag_admin_web/domain/enums/competition_status.dart';
export 'package:flag_admin_web/domain/enums/document_type.dart';
export 'package:flag_admin_web/domain/enums/game_status.dart';
export 'package:flag_admin_web/domain/enums/gender.dart';
export 'package:flag_admin_web/domain/enums/grouping_type.dart';
export 'package:flag_admin_web/domain/enums/modality.dart';
export 'package:flag_admin_web/domain/enums/organization_status.dart';
export 'package:flag_admin_web/domain/enums/organization_type.dart';
export 'package:flag_admin_web/domain/enums/round_type.dart';
export 'package:flag_admin_web/domain/enums/tournament_format.dart';
export 'package:flag_admin_web/domain/enums/user_role.dart';
export 'package:flag_admin_web/domain/models/affiliation_window.dart';
export 'package:flag_admin_web/domain/models/competition.dart';
export 'package:flag_admin_web/domain/models/institution.dart';
export 'package:flag_admin_web/domain/models/organization.dart';

// Models
export 'package:flag_admin_web/domain/models/person.dart';
export 'package:flag_admin_web/domain/models/person_batch.dart';
export 'package:flag_admin_web/domain/models/roster_batch.dart';
export 'package:flag_admin_web/domain/models/roster_entry.dart';
export 'package:flag_admin_web/domain/models/team.dart';

export '../../domain/models/category.dart';
export '../../domain/models/check_in.dart';
export '../../domain/models/conference.dart';
export '../../domain/models/division.dart';
export '../../domain/models/game.dart';
export '../../domain/models/game_batch.dart';
export '../../domain/models/round.dart';
export '../../domain/models/score_event.dart';
export '../../domain/models/standing.dart';
export '../../domain/models/team_roster.dart';
export '../../domain/models/user.dart';
export '../../domain/models/venue.dart';
