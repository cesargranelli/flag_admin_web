enum UserRole {
  admin,
  organizer,
  mesa,
  manager,
  adminLiga,
  referee,
  clubManager,
  fan;

  static UserRole fromJson(String value) => switch (value) {
        'ADMIN' => UserRole.admin,
        'ADMIN_LIGA' => UserRole.adminLiga,
        'ORGANIZER' => UserRole.organizer,
        'MESA' => UserRole.mesa,
        'MANAGER' => UserRole.manager,
        'REFEREE' => UserRole.referee,
        'CLUB_MANAGER' => UserRole.clubManager,
        'FAN' => UserRole.fan,
        _ => UserRole.fan,
      };

  String toJson() => switch (this) {
        UserRole.admin => 'ADMIN',
        UserRole.adminLiga => 'ADMIN_LIGA',
        UserRole.organizer => 'ORGANIZER',
        UserRole.mesa => 'MESA',
        UserRole.manager => 'MANAGER',
        UserRole.referee => 'REFEREE',
        UserRole.clubManager => 'CLUB_MANAGER',
        UserRole.fan => 'FAN',
      };

  /// Rótulo amigável em pt-BR.
  String get label => switch (this) {
        UserRole.admin => 'Administrador',
        UserRole.adminLiga => 'Admin Liga',
        UserRole.organizer => 'Organizador',
        UserRole.mesa => 'Mesa',
        UserRole.manager => 'Manager',
        UserRole.referee => 'Árbitro',
        UserRole.clubManager => 'Gestor de Clube',
        UserRole.fan => 'Torcedor',
      };
}
