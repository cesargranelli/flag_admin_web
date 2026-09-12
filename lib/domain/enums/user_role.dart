enum UserRole {
  admin,
  organizer,
  commissioner,
  manager,
  adminInstitution,
  referee,
  clubManager,
  fan;

  static UserRole fromJson(String value) => switch (value) {
        'ADMIN' => UserRole.admin,
        'ADMIN_INSTITUTION' => UserRole.adminInstitution,
        'ORGANIZER' => UserRole.organizer,
        'COMMISSIONER' => UserRole.commissioner,
        'MANAGER' => UserRole.manager,
        'REFEREE' => UserRole.referee,
        'CLUB_MANAGER' => UserRole.clubManager,
        'FAN' => UserRole.fan,
        _ => UserRole.fan,
      };

  String toJson() => switch (this) {
        UserRole.admin => 'ADMIN',
        UserRole.adminInstitution => 'ADMIN_INSTITUTION',
        UserRole.organizer => 'ORGANIZER',
        UserRole.commissioner => 'COMMISSIONER',
        UserRole.manager => 'MANAGER',
        UserRole.referee => 'REFEREE',
        UserRole.clubManager => 'CLUB_MANAGER',
        UserRole.fan => 'FAN',
      };

  /// Rótulo amigável em pt-BR.
  String get label => switch (this) {
        UserRole.admin => 'Administrador',
        UserRole.adminInstitution => 'Admin Instituição',
        UserRole.organizer => 'Organizador',
        UserRole.commissioner => 'Comissário',
        UserRole.manager => 'Manager',
        UserRole.referee => 'Árbitro',
        UserRole.clubManager => 'Gestor de Clube',
        UserRole.fan => 'Torcedor',
      };
}
