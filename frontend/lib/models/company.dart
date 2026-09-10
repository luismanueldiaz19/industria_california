class Company {
  final String name;
  final String rnc;
  final String address;
  final String phone;
  final String mobile;
  final String logo;
  final String developer;

  const Company({
    required this.name,
    required this.rnc,
    required this.address,
    required this.phone,
    required this.mobile,
    required this.logo,
    this.developer = '',
  });

  // Instancia con los datos reales para usar en la aplicación
  static const Company current = Company(
    name: 'Industria California S.R.L',
    rnc: '132839935',
    address:
        'Calle 16 Agosto , # 91, Moca, Dom R Moca 09 56000 Dominican Republic.',
    phone: '829-477-8000',
    mobile: '+1 (809) xxx-xxxx',
    logo: 'assets/logos/logo_california.png',
    developer: 'Lwader Soft',
  );

  // Puedes agregar factory de JSON si en el futuro los datos vienen del backend
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'] ?? '',
      rnc: json['rnc'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      mobile: json['mobile'] ?? '',
      logo: json['logo'] ?? 'assets/logos/logo_california.png',
      developer: json['developer'] ?? 'Lwader Soft',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rnc': rnc,
      'address': address,
      'phone': phone,
      'mobile': mobile,
    };
  }
}
