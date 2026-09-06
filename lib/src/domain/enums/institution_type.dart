enum InstitutionType { club, university;
  static InstitutionType fromJson(String v) => switch(v){'CLUB'=>club,'UNIVERSITY'=>university,_=>throw FormatException('InstitutionType $v')};
  String toJson()=> switch(this){club=>'CLUB',university=>'UNIVERSITY'};
  String get label=> switch(this){club=>'Clube',university=>'Universidade'};
}
