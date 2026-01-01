// Location data models for hierarchical location selection
// Used by DRM form for District → County → Sub-county → Parish → Polling Station

class District {
  final String code;
  final String name;

  const District({required this.code, required this.name});

  @override
  String toString() => 'District($code: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is District && code == other.code && name == other.name;

  @override
  int get hashCode => code.hashCode ^ name.hashCode;
}

class County {
  final String code;
  final String name;
  final String districtCode;

  const County({
    required this.code,
    required this.name,
    required this.districtCode,
  });

  @override
  String toString() => 'County($code: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is County && code == other.code && name == other.name;

  @override
  int get hashCode => code.hashCode ^ name.hashCode;
}

class SubCounty {
  final String code;
  final String name;
  final String districtCode;
  final String countyCode;

  const SubCounty({
    required this.code,
    required this.name,
    required this.districtCode,
    required this.countyCode,
  });

  @override
  String toString() => 'SubCounty($code: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubCounty && code == other.code && name == other.name;

  @override
  int get hashCode => code.hashCode ^ name.hashCode;
}

class Parish {
  final String code;
  final String name;
  final String districtCode;
  final String countyCode;
  final String subCountyCode;

  const Parish({
    required this.code,
    required this.name,
    required this.districtCode,
    required this.countyCode,
    required this.subCountyCode,
  });

  @override
  String toString() => 'Parish($code: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parish && code == other.code && name == other.name;

  @override
  int get hashCode => code.hashCode ^ name.hashCode;
}

class PollingStation {
  final String code;
  final String name;
  final String districtCode;
  final String countyCode;
  final String subCountyCode;
  final String parishCode;
  final int voterCount;

  const PollingStation({
    required this.code,
    required this.name,
    required this.districtCode,
    required this.countyCode,
    required this.subCountyCode,
    required this.parishCode,
    required this.voterCount,
  });

  @override
  String toString() => 'PollingStation($code: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PollingStation && code == other.code && name == other.name;

  @override
  int get hashCode => code.hashCode ^ name.hashCode;
}
