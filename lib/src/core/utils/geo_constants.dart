/// Opção de país para formulários de cadastro.
class CountryOption {
  final String code;
  final String name;

  const CountryOption(this.code, this.name);
}

/// Países comumente utilizados na plataforma.
const countryOptions = <CountryOption>[
  CountryOption('BR', 'Brasil'),
  CountryOption('US', 'Estados Unidos'),
  CountryOption('AR', 'Argentina'),
  CountryOption('UY', 'Uruguai'),
  CountryOption('CL', 'Chile'),
  CountryOption('CO', 'Colômbia'),
  CountryOption('MX', 'México'),
  CountryOption('PT', 'Portugal'),
  CountryOption('ES', 'Espanha'),
  CountryOption('OTHER', 'Outro'),
];

/// Lista das 27 Unidades Federativas do Brasil (sigla, nome).
const brazilUfs = <(String, String)>[
  ('AC', 'Acre'),
  ('AL', 'Alagoas'),
  ('AP', 'Amapá'),
  ('AM', 'Amazonas'),
  ('BA', 'Bahia'),
  ('CE', 'Ceará'),
  ('DF', 'Distrito Federal'),
  ('ES', 'Espírito Santo'),
  ('GO', 'Goiás'),
  ('MA', 'Maranhão'),
  ('MT', 'Mato Grosso'),
  ('MS', 'Mato Grosso do Sul'),
  ('MG', 'Minas Gerais'),
  ('PA', 'Pará'),
  ('PB', 'Paraíba'),
  ('PR', 'Paraná'),
  ('PE', 'Pernambuco'),
  ('PI', 'Piauí'),
  ('RJ', 'Rio de Janeiro'),
  ('RN', 'Rio Grande do Norte'),
  ('RS', 'Rio Grande do Sul'),
  ('RO', 'Rondônia'),
  ('RR', 'Roraima'),
  ('SC', 'Santa Catarina'),
  ('SP', 'São Paulo'),
  ('SE', 'Sergipe'),
  ('TO', 'Tocantins'),
];
