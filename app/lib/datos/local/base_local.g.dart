// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_local.dart';

// ignore_for_file: type=lint
class $UsuariosTable extends Usuarios with TableInfo<$UsuariosTable, Usuario> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsuariosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _celularMeta = const VerificationMeta(
    'celular',
  );
  @override
  late final GeneratedColumn<String> celular = GeneratedColumn<String>(
    'celular',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, celular, nombre, creadoEn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usuarios';
  @override
  VerificationContext validateIntegrity(
    Insertable<Usuario> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('celular')) {
      context.handle(
        _celularMeta,
        celular.isAcceptableOrUnknown(data['celular']!, _celularMeta),
      );
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Usuario map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Usuario(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      celular: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}celular'],
      ),
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $UsuariosTable createAlias(String alias) {
    return $UsuariosTable(attachedDatabase, alias);
  }
}

class Usuario extends DataClass implements Insertable<Usuario> {
  final String id;
  final String? celular;
  final String? nombre;
  final DateTime creadoEn;
  const Usuario({
    required this.id,
    this.celular,
    this.nombre,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || celular != null) {
      map['celular'] = Variable<String>(celular);
    }
    if (!nullToAbsent || nombre != null) {
      map['nombre'] = Variable<String>(nombre);
    }
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  UsuariosCompanion toCompanion(bool nullToAbsent) {
    return UsuariosCompanion(
      id: Value(id),
      celular: celular == null && nullToAbsent
          ? const Value.absent()
          : Value(celular),
      nombre: nombre == null && nullToAbsent
          ? const Value.absent()
          : Value(nombre),
      creadoEn: Value(creadoEn),
    );
  }

  factory Usuario.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Usuario(
      id: serializer.fromJson<String>(json['id']),
      celular: serializer.fromJson<String?>(json['celular']),
      nombre: serializer.fromJson<String?>(json['nombre']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'celular': serializer.toJson<String?>(celular),
      'nombre': serializer.toJson<String?>(nombre),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  Usuario copyWith({
    String? id,
    Value<String?> celular = const Value.absent(),
    Value<String?> nombre = const Value.absent(),
    DateTime? creadoEn,
  }) => Usuario(
    id: id ?? this.id,
    celular: celular.present ? celular.value : this.celular,
    nombre: nombre.present ? nombre.value : this.nombre,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  Usuario copyWithCompanion(UsuariosCompanion data) {
    return Usuario(
      id: data.id.present ? data.id.value : this.id,
      celular: data.celular.present ? data.celular.value : this.celular,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Usuario(')
          ..write('id: $id, ')
          ..write('celular: $celular, ')
          ..write('nombre: $nombre, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, celular, nombre, creadoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Usuario &&
          other.id == this.id &&
          other.celular == this.celular &&
          other.nombre == this.nombre &&
          other.creadoEn == this.creadoEn);
}

class UsuariosCompanion extends UpdateCompanion<Usuario> {
  final Value<String> id;
  final Value<String?> celular;
  final Value<String?> nombre;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const UsuariosCompanion({
    this.id = const Value.absent(),
    this.celular = const Value.absent(),
    this.nombre = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsuariosCompanion.insert({
    required String id,
    this.celular = const Value.absent(),
    this.nombre = const Value.absent(),
    required DateTime creadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       creadoEn = Value(creadoEn);
  static Insertable<Usuario> custom({
    Expression<String>? id,
    Expression<String>? celular,
    Expression<String>? nombre,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (celular != null) 'celular': celular,
      if (nombre != null) 'nombre': nombre,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsuariosCompanion copyWith({
    Value<String>? id,
    Value<String?>? celular,
    Value<String?>? nombre,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return UsuariosCompanion(
      id: id ?? this.id,
      celular: celular ?? this.celular,
      nombre: nombre ?? this.nombre,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (celular.present) {
      map['celular'] = Variable<String>(celular.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsuariosCompanion(')
          ..write('id: $id, ')
          ..write('celular: $celular, ')
          ..write('nombre: $nombre, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmpresasTable extends Empresas with TableInfo<$EmpresasTable, Empresa> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmpresasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TipoNegocio, String> tipoNegocio =
      GeneratedColumn<String>(
        'tipo_negocio',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TipoNegocio>($EmpresasTable.$convertertipoNegocio);
  @override
  late final GeneratedColumnWithTypeConverter<ModoEmpresa, String> modo =
      GeneratedColumn<String>(
        'modo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ModoEmpresa>($EmpresasTable.$convertermodo);
  static const VerificationMeta _paisMeta = const VerificationMeta('pais');
  @override
  late final GeneratedColumn<String> pais = GeneratedColumn<String>(
    'pais',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monedaMeta = const VerificationMeta('moneda');
  @override
  late final GeneratedColumn<String> moneda = GeneratedColumn<String>(
    'moneda',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regimenMeta = const VerificationMeta(
    'regimen',
  );
  @override
  late final GeneratedColumn<String> regimen = GeneratedColumn<String>(
    'regimen',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _horaCierreMinutosMeta = const VerificationMeta(
    'horaCierreMinutos',
  );
  @override
  late final GeneratedColumn<int> horaCierreMinutos = GeneratedColumn<int>(
    'hora_cierre_minutos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identificacionFiscalMeta =
      const VerificationMeta('identificacionFiscal');
  @override
  late final GeneratedColumn<String> identificacionFiscal =
      GeneratedColumn<String>(
        'identificacion_fiscal',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    tipoNegocio,
    modo,
    pais,
    moneda,
    regimen,
    horaCierreMinutos,
    identificacionFiscal,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'empresas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Empresa> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('pais')) {
      context.handle(
        _paisMeta,
        pais.isAcceptableOrUnknown(data['pais']!, _paisMeta),
      );
    } else if (isInserting) {
      context.missing(_paisMeta);
    }
    if (data.containsKey('moneda')) {
      context.handle(
        _monedaMeta,
        moneda.isAcceptableOrUnknown(data['moneda']!, _monedaMeta),
      );
    } else if (isInserting) {
      context.missing(_monedaMeta);
    }
    if (data.containsKey('regimen')) {
      context.handle(
        _regimenMeta,
        regimen.isAcceptableOrUnknown(data['regimen']!, _regimenMeta),
      );
    }
    if (data.containsKey('hora_cierre_minutos')) {
      context.handle(
        _horaCierreMinutosMeta,
        horaCierreMinutos.isAcceptableOrUnknown(
          data['hora_cierre_minutos']!,
          _horaCierreMinutosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_horaCierreMinutosMeta);
    }
    if (data.containsKey('identificacion_fiscal')) {
      context.handle(
        _identificacionFiscalMeta,
        identificacionFiscal.isAcceptableOrUnknown(
          data['identificacion_fiscal']!,
          _identificacionFiscalMeta,
        ),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Empresa map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Empresa(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      tipoNegocio: $EmpresasTable.$convertertipoNegocio.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo_negocio'],
        )!,
      ),
      modo: $EmpresasTable.$convertermodo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}modo'],
        )!,
      ),
      pais: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pais'],
      )!,
      moneda: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moneda'],
      )!,
      regimen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regimen'],
      ),
      horaCierreMinutos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hora_cierre_minutos'],
      )!,
      identificacionFiscal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identificacion_fiscal'],
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $EmpresasTable createAlias(String alias) {
    return $EmpresasTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TipoNegocio, String, String> $convertertipoNegocio =
      const EnumNameConverter<TipoNegocio>(TipoNegocio.values);
  static JsonTypeConverter2<ModoEmpresa, String, String> $convertermodo =
      const EnumNameConverter<ModoEmpresa>(ModoEmpresa.values);
}

class Empresa extends DataClass implements Insertable<Empresa> {
  final String id;
  final String nombre;
  final TipoNegocio tipoNegocio;
  final ModoEmpresa modo;
  final String pais;
  final String moneda;
  final String? regimen;

  /// Hora de cierre en minutos desde la medianoche (21:00 = 1260).
  final int horaCierreMinutos;
  final String? identificacionFiscal;
  final DateTime creadoEn;
  const Empresa({
    required this.id,
    required this.nombre,
    required this.tipoNegocio,
    required this.modo,
    required this.pais,
    required this.moneda,
    this.regimen,
    required this.horaCierreMinutos,
    this.identificacionFiscal,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    {
      map['tipo_negocio'] = Variable<String>(
        $EmpresasTable.$convertertipoNegocio.toSql(tipoNegocio),
      );
    }
    {
      map['modo'] = Variable<String>($EmpresasTable.$convertermodo.toSql(modo));
    }
    map['pais'] = Variable<String>(pais);
    map['moneda'] = Variable<String>(moneda);
    if (!nullToAbsent || regimen != null) {
      map['regimen'] = Variable<String>(regimen);
    }
    map['hora_cierre_minutos'] = Variable<int>(horaCierreMinutos);
    if (!nullToAbsent || identificacionFiscal != null) {
      map['identificacion_fiscal'] = Variable<String>(identificacionFiscal);
    }
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  EmpresasCompanion toCompanion(bool nullToAbsent) {
    return EmpresasCompanion(
      id: Value(id),
      nombre: Value(nombre),
      tipoNegocio: Value(tipoNegocio),
      modo: Value(modo),
      pais: Value(pais),
      moneda: Value(moneda),
      regimen: regimen == null && nullToAbsent
          ? const Value.absent()
          : Value(regimen),
      horaCierreMinutos: Value(horaCierreMinutos),
      identificacionFiscal: identificacionFiscal == null && nullToAbsent
          ? const Value.absent()
          : Value(identificacionFiscal),
      creadoEn: Value(creadoEn),
    );
  }

  factory Empresa.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Empresa(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      tipoNegocio: $EmpresasTable.$convertertipoNegocio.fromJson(
        serializer.fromJson<String>(json['tipoNegocio']),
      ),
      modo: $EmpresasTable.$convertermodo.fromJson(
        serializer.fromJson<String>(json['modo']),
      ),
      pais: serializer.fromJson<String>(json['pais']),
      moneda: serializer.fromJson<String>(json['moneda']),
      regimen: serializer.fromJson<String?>(json['regimen']),
      horaCierreMinutos: serializer.fromJson<int>(json['horaCierreMinutos']),
      identificacionFiscal: serializer.fromJson<String?>(
        json['identificacionFiscal'],
      ),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'tipoNegocio': serializer.toJson<String>(
        $EmpresasTable.$convertertipoNegocio.toJson(tipoNegocio),
      ),
      'modo': serializer.toJson<String>(
        $EmpresasTable.$convertermodo.toJson(modo),
      ),
      'pais': serializer.toJson<String>(pais),
      'moneda': serializer.toJson<String>(moneda),
      'regimen': serializer.toJson<String?>(regimen),
      'horaCierreMinutos': serializer.toJson<int>(horaCierreMinutos),
      'identificacionFiscal': serializer.toJson<String?>(identificacionFiscal),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  Empresa copyWith({
    String? id,
    String? nombre,
    TipoNegocio? tipoNegocio,
    ModoEmpresa? modo,
    String? pais,
    String? moneda,
    Value<String?> regimen = const Value.absent(),
    int? horaCierreMinutos,
    Value<String?> identificacionFiscal = const Value.absent(),
    DateTime? creadoEn,
  }) => Empresa(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    tipoNegocio: tipoNegocio ?? this.tipoNegocio,
    modo: modo ?? this.modo,
    pais: pais ?? this.pais,
    moneda: moneda ?? this.moneda,
    regimen: regimen.present ? regimen.value : this.regimen,
    horaCierreMinutos: horaCierreMinutos ?? this.horaCierreMinutos,
    identificacionFiscal: identificacionFiscal.present
        ? identificacionFiscal.value
        : this.identificacionFiscal,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  Empresa copyWithCompanion(EmpresasCompanion data) {
    return Empresa(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      tipoNegocio: data.tipoNegocio.present
          ? data.tipoNegocio.value
          : this.tipoNegocio,
      modo: data.modo.present ? data.modo.value : this.modo,
      pais: data.pais.present ? data.pais.value : this.pais,
      moneda: data.moneda.present ? data.moneda.value : this.moneda,
      regimen: data.regimen.present ? data.regimen.value : this.regimen,
      horaCierreMinutos: data.horaCierreMinutos.present
          ? data.horaCierreMinutos.value
          : this.horaCierreMinutos,
      identificacionFiscal: data.identificacionFiscal.present
          ? data.identificacionFiscal.value
          : this.identificacionFiscal,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Empresa(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('tipoNegocio: $tipoNegocio, ')
          ..write('modo: $modo, ')
          ..write('pais: $pais, ')
          ..write('moneda: $moneda, ')
          ..write('regimen: $regimen, ')
          ..write('horaCierreMinutos: $horaCierreMinutos, ')
          ..write('identificacionFiscal: $identificacionFiscal, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    tipoNegocio,
    modo,
    pais,
    moneda,
    regimen,
    horaCierreMinutos,
    identificacionFiscal,
    creadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Empresa &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.tipoNegocio == this.tipoNegocio &&
          other.modo == this.modo &&
          other.pais == this.pais &&
          other.moneda == this.moneda &&
          other.regimen == this.regimen &&
          other.horaCierreMinutos == this.horaCierreMinutos &&
          other.identificacionFiscal == this.identificacionFiscal &&
          other.creadoEn == this.creadoEn);
}

class EmpresasCompanion extends UpdateCompanion<Empresa> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<TipoNegocio> tipoNegocio;
  final Value<ModoEmpresa> modo;
  final Value<String> pais;
  final Value<String> moneda;
  final Value<String?> regimen;
  final Value<int> horaCierreMinutos;
  final Value<String?> identificacionFiscal;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const EmpresasCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.tipoNegocio = const Value.absent(),
    this.modo = const Value.absent(),
    this.pais = const Value.absent(),
    this.moneda = const Value.absent(),
    this.regimen = const Value.absent(),
    this.horaCierreMinutos = const Value.absent(),
    this.identificacionFiscal = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmpresasCompanion.insert({
    required String id,
    required String nombre,
    required TipoNegocio tipoNegocio,
    required ModoEmpresa modo,
    required String pais,
    required String moneda,
    this.regimen = const Value.absent(),
    required int horaCierreMinutos,
    this.identificacionFiscal = const Value.absent(),
    required DateTime creadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       tipoNegocio = Value(tipoNegocio),
       modo = Value(modo),
       pais = Value(pais),
       moneda = Value(moneda),
       horaCierreMinutos = Value(horaCierreMinutos),
       creadoEn = Value(creadoEn);
  static Insertable<Empresa> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? tipoNegocio,
    Expression<String>? modo,
    Expression<String>? pais,
    Expression<String>? moneda,
    Expression<String>? regimen,
    Expression<int>? horaCierreMinutos,
    Expression<String>? identificacionFiscal,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (tipoNegocio != null) 'tipo_negocio': tipoNegocio,
      if (modo != null) 'modo': modo,
      if (pais != null) 'pais': pais,
      if (moneda != null) 'moneda': moneda,
      if (regimen != null) 'regimen': regimen,
      if (horaCierreMinutos != null) 'hora_cierre_minutos': horaCierreMinutos,
      if (identificacionFiscal != null)
        'identificacion_fiscal': identificacionFiscal,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmpresasCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<TipoNegocio>? tipoNegocio,
    Value<ModoEmpresa>? modo,
    Value<String>? pais,
    Value<String>? moneda,
    Value<String?>? regimen,
    Value<int>? horaCierreMinutos,
    Value<String?>? identificacionFiscal,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return EmpresasCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoNegocio: tipoNegocio ?? this.tipoNegocio,
      modo: modo ?? this.modo,
      pais: pais ?? this.pais,
      moneda: moneda ?? this.moneda,
      regimen: regimen ?? this.regimen,
      horaCierreMinutos: horaCierreMinutos ?? this.horaCierreMinutos,
      identificacionFiscal: identificacionFiscal ?? this.identificacionFiscal,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (tipoNegocio.present) {
      map['tipo_negocio'] = Variable<String>(
        $EmpresasTable.$convertertipoNegocio.toSql(tipoNegocio.value),
      );
    }
    if (modo.present) {
      map['modo'] = Variable<String>(
        $EmpresasTable.$convertermodo.toSql(modo.value),
      );
    }
    if (pais.present) {
      map['pais'] = Variable<String>(pais.value);
    }
    if (moneda.present) {
      map['moneda'] = Variable<String>(moneda.value);
    }
    if (regimen.present) {
      map['regimen'] = Variable<String>(regimen.value);
    }
    if (horaCierreMinutos.present) {
      map['hora_cierre_minutos'] = Variable<int>(horaCierreMinutos.value);
    }
    if (identificacionFiscal.present) {
      map['identificacion_fiscal'] = Variable<String>(
        identificacionFiscal.value,
      );
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmpresasCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('tipoNegocio: $tipoNegocio, ')
          ..write('modo: $modo, ')
          ..write('pais: $pais, ')
          ..write('moneda: $moneda, ')
          ..write('regimen: $regimen, ')
          ..write('horaCierreMinutos: $horaCierreMinutos, ')
          ..write('identificacionFiscal: $identificacionFiscal, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembresiasTable extends Membresias
    with TableInfo<$MembresiasTable, Membresia> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembresiasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioIdMeta = const VerificationMeta(
    'usuarioId',
  );
  @override
  late final GeneratedColumn<String> usuarioId = GeneratedColumn<String>(
    'usuario_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES usuarios (id)',
    ),
  );
  static const VerificationMeta _empresaIdMeta = const VerificationMeta(
    'empresaId',
  );
  @override
  late final GeneratedColumn<String> empresaId = GeneratedColumn<String>(
    'empresa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES empresas (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Rol, String> rol =
      GeneratedColumn<String>(
        'rol',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Rol>($MembresiasTable.$converterrol);
  @override
  List<GeneratedColumn> get $columns => [id, usuarioId, empresaId, rol];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'membresias';
  @override
  VerificationContext validateIntegrity(
    Insertable<Membresia> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('usuario_id')) {
      context.handle(
        _usuarioIdMeta,
        usuarioId.isAcceptableOrUnknown(data['usuario_id']!, _usuarioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioIdMeta);
    }
    if (data.containsKey('empresa_id')) {
      context.handle(
        _empresaIdMeta,
        empresaId.isAcceptableOrUnknown(data['empresa_id']!, _empresaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empresaIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Membresia map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Membresia(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      usuarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_id'],
      )!,
      empresaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_id'],
      )!,
      rol: $MembresiasTable.$converterrol.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rol'],
        )!,
      ),
    );
  }

  @override
  $MembresiasTable createAlias(String alias) {
    return $MembresiasTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Rol, String, String> $converterrol =
      const EnumNameConverter<Rol>(Rol.values);
}

class Membresia extends DataClass implements Insertable<Membresia> {
  final String id;
  final String usuarioId;
  final String empresaId;
  final Rol rol;
  const Membresia({
    required this.id,
    required this.usuarioId,
    required this.empresaId,
    required this.rol,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['usuario_id'] = Variable<String>(usuarioId);
    map['empresa_id'] = Variable<String>(empresaId);
    {
      map['rol'] = Variable<String>($MembresiasTable.$converterrol.toSql(rol));
    }
    return map;
  }

  MembresiasCompanion toCompanion(bool nullToAbsent) {
    return MembresiasCompanion(
      id: Value(id),
      usuarioId: Value(usuarioId),
      empresaId: Value(empresaId),
      rol: Value(rol),
    );
  }

  factory Membresia.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Membresia(
      id: serializer.fromJson<String>(json['id']),
      usuarioId: serializer.fromJson<String>(json['usuarioId']),
      empresaId: serializer.fromJson<String>(json['empresaId']),
      rol: $MembresiasTable.$converterrol.fromJson(
        serializer.fromJson<String>(json['rol']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'usuarioId': serializer.toJson<String>(usuarioId),
      'empresaId': serializer.toJson<String>(empresaId),
      'rol': serializer.toJson<String>(
        $MembresiasTable.$converterrol.toJson(rol),
      ),
    };
  }

  Membresia copyWith({
    String? id,
    String? usuarioId,
    String? empresaId,
    Rol? rol,
  }) => Membresia(
    id: id ?? this.id,
    usuarioId: usuarioId ?? this.usuarioId,
    empresaId: empresaId ?? this.empresaId,
    rol: rol ?? this.rol,
  );
  Membresia copyWithCompanion(MembresiasCompanion data) {
    return Membresia(
      id: data.id.present ? data.id.value : this.id,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      empresaId: data.empresaId.present ? data.empresaId.value : this.empresaId,
      rol: data.rol.present ? data.rol.value : this.rol,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Membresia(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('empresaId: $empresaId, ')
          ..write('rol: $rol')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, usuarioId, empresaId, rol);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Membresia &&
          other.id == this.id &&
          other.usuarioId == this.usuarioId &&
          other.empresaId == this.empresaId &&
          other.rol == this.rol);
}

class MembresiasCompanion extends UpdateCompanion<Membresia> {
  final Value<String> id;
  final Value<String> usuarioId;
  final Value<String> empresaId;
  final Value<Rol> rol;
  final Value<int> rowid;
  const MembresiasCompanion({
    this.id = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.empresaId = const Value.absent(),
    this.rol = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembresiasCompanion.insert({
    required String id,
    required String usuarioId,
    required String empresaId,
    required Rol rol,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       usuarioId = Value(usuarioId),
       empresaId = Value(empresaId),
       rol = Value(rol);
  static Insertable<Membresia> custom({
    Expression<String>? id,
    Expression<String>? usuarioId,
    Expression<String>? empresaId,
    Expression<String>? rol,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (empresaId != null) 'empresa_id': empresaId,
      if (rol != null) 'rol': rol,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembresiasCompanion copyWith({
    Value<String>? id,
    Value<String>? usuarioId,
    Value<String>? empresaId,
    Value<Rol>? rol,
    Value<int>? rowid,
  }) {
    return MembresiasCompanion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      empresaId: empresaId ?? this.empresaId,
      rol: rol ?? this.rol,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (usuarioId.present) {
      map['usuario_id'] = Variable<String>(usuarioId.value);
    }
    if (empresaId.present) {
      map['empresa_id'] = Variable<String>(empresaId.value);
    }
    if (rol.present) {
      map['rol'] = Variable<String>(
        $MembresiasTable.$converterrol.toSql(rol.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembresiasCompanion(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('empresaId: $empresaId, ')
          ..write('rol: $rol, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CuentasTable extends Cuentas with TableInfo<$CuentasTable, Cuenta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CuentasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empresaIdMeta = const VerificationMeta(
    'empresaId',
  );
  @override
  late final GeneratedColumn<String> empresaId = GeneratedColumn<String>(
    'empresa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES empresas (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TipoCuenta, String> tipo =
      GeneratedColumn<String>(
        'tipo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TipoCuenta>($CuentasTable.$convertertipo);
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saldoInicialCentimosMeta =
      const VerificationMeta('saldoInicialCentimos');
  @override
  late final GeneratedColumn<int> saldoInicialCentimos = GeneratedColumn<int>(
    'saldo_inicial_centimos',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaSaldoInicialMeta = const VerificationMeta(
    'fechaSaldoInicial',
  );
  @override
  late final GeneratedColumn<DateTime> fechaSaldoInicial =
      GeneratedColumn<DateTime>(
        'fecha_saldo_inicial',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    empresaId,
    tipo,
    nombre,
    saldoInicialCentimos,
    fechaSaldoInicial,
    orden,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cuentas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cuenta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('empresa_id')) {
      context.handle(
        _empresaIdMeta,
        empresaId.isAcceptableOrUnknown(data['empresa_id']!, _empresaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empresaIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('saldo_inicial_centimos')) {
      context.handle(
        _saldoInicialCentimosMeta,
        saldoInicialCentimos.isAcceptableOrUnknown(
          data['saldo_inicial_centimos']!,
          _saldoInicialCentimosMeta,
        ),
      );
    }
    if (data.containsKey('fecha_saldo_inicial')) {
      context.handle(
        _fechaSaldoInicialMeta,
        fechaSaldoInicial.isAcceptableOrUnknown(
          data['fecha_saldo_inicial']!,
          _fechaSaldoInicialMeta,
        ),
      );
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    } else if (isInserting) {
      context.missing(_ordenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cuenta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cuenta(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      empresaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_id'],
      )!,
      tipo: $CuentasTable.$convertertipo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo'],
        )!,
      ),
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      saldoInicialCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saldo_inicial_centimos'],
      ),
      fechaSaldoInicial: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_saldo_inicial'],
      ),
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
    );
  }

  @override
  $CuentasTable createAlias(String alias) {
    return $CuentasTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TipoCuenta, String, String> $convertertipo =
      const EnumNameConverter<TipoCuenta>(TipoCuenta.values);
}

class Cuenta extends DataClass implements Insertable<Cuenta> {
  final String id;
  final String empresaId;
  final TipoCuenta tipo;
  final String nombre;

  /// Nulo mientras el dueño no declara su saldo inicial.
  final int? saldoInicialCentimos;
  final DateTime? fechaSaldoInicial;
  final int orden;
  const Cuenta({
    required this.id,
    required this.empresaId,
    required this.tipo,
    required this.nombre,
    this.saldoInicialCentimos,
    this.fechaSaldoInicial,
    required this.orden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['empresa_id'] = Variable<String>(empresaId);
    {
      map['tipo'] = Variable<String>($CuentasTable.$convertertipo.toSql(tipo));
    }
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || saldoInicialCentimos != null) {
      map['saldo_inicial_centimos'] = Variable<int>(saldoInicialCentimos);
    }
    if (!nullToAbsent || fechaSaldoInicial != null) {
      map['fecha_saldo_inicial'] = Variable<DateTime>(fechaSaldoInicial);
    }
    map['orden'] = Variable<int>(orden);
    return map;
  }

  CuentasCompanion toCompanion(bool nullToAbsent) {
    return CuentasCompanion(
      id: Value(id),
      empresaId: Value(empresaId),
      tipo: Value(tipo),
      nombre: Value(nombre),
      saldoInicialCentimos: saldoInicialCentimos == null && nullToAbsent
          ? const Value.absent()
          : Value(saldoInicialCentimos),
      fechaSaldoInicial: fechaSaldoInicial == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaSaldoInicial),
      orden: Value(orden),
    );
  }

  factory Cuenta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cuenta(
      id: serializer.fromJson<String>(json['id']),
      empresaId: serializer.fromJson<String>(json['empresaId']),
      tipo: $CuentasTable.$convertertipo.fromJson(
        serializer.fromJson<String>(json['tipo']),
      ),
      nombre: serializer.fromJson<String>(json['nombre']),
      saldoInicialCentimos: serializer.fromJson<int?>(
        json['saldoInicialCentimos'],
      ),
      fechaSaldoInicial: serializer.fromJson<DateTime?>(
        json['fechaSaldoInicial'],
      ),
      orden: serializer.fromJson<int>(json['orden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'empresaId': serializer.toJson<String>(empresaId),
      'tipo': serializer.toJson<String>(
        $CuentasTable.$convertertipo.toJson(tipo),
      ),
      'nombre': serializer.toJson<String>(nombre),
      'saldoInicialCentimos': serializer.toJson<int?>(saldoInicialCentimos),
      'fechaSaldoInicial': serializer.toJson<DateTime?>(fechaSaldoInicial),
      'orden': serializer.toJson<int>(orden),
    };
  }

  Cuenta copyWith({
    String? id,
    String? empresaId,
    TipoCuenta? tipo,
    String? nombre,
    Value<int?> saldoInicialCentimos = const Value.absent(),
    Value<DateTime?> fechaSaldoInicial = const Value.absent(),
    int? orden,
  }) => Cuenta(
    id: id ?? this.id,
    empresaId: empresaId ?? this.empresaId,
    tipo: tipo ?? this.tipo,
    nombre: nombre ?? this.nombre,
    saldoInicialCentimos: saldoInicialCentimos.present
        ? saldoInicialCentimos.value
        : this.saldoInicialCentimos,
    fechaSaldoInicial: fechaSaldoInicial.present
        ? fechaSaldoInicial.value
        : this.fechaSaldoInicial,
    orden: orden ?? this.orden,
  );
  Cuenta copyWithCompanion(CuentasCompanion data) {
    return Cuenta(
      id: data.id.present ? data.id.value : this.id,
      empresaId: data.empresaId.present ? data.empresaId.value : this.empresaId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      saldoInicialCentimos: data.saldoInicialCentimos.present
          ? data.saldoInicialCentimos.value
          : this.saldoInicialCentimos,
      fechaSaldoInicial: data.fechaSaldoInicial.present
          ? data.fechaSaldoInicial.value
          : this.fechaSaldoInicial,
      orden: data.orden.present ? data.orden.value : this.orden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cuenta(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('tipo: $tipo, ')
          ..write('nombre: $nombre, ')
          ..write('saldoInicialCentimos: $saldoInicialCentimos, ')
          ..write('fechaSaldoInicial: $fechaSaldoInicial, ')
          ..write('orden: $orden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    empresaId,
    tipo,
    nombre,
    saldoInicialCentimos,
    fechaSaldoInicial,
    orden,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cuenta &&
          other.id == this.id &&
          other.empresaId == this.empresaId &&
          other.tipo == this.tipo &&
          other.nombre == this.nombre &&
          other.saldoInicialCentimos == this.saldoInicialCentimos &&
          other.fechaSaldoInicial == this.fechaSaldoInicial &&
          other.orden == this.orden);
}

class CuentasCompanion extends UpdateCompanion<Cuenta> {
  final Value<String> id;
  final Value<String> empresaId;
  final Value<TipoCuenta> tipo;
  final Value<String> nombre;
  final Value<int?> saldoInicialCentimos;
  final Value<DateTime?> fechaSaldoInicial;
  final Value<int> orden;
  final Value<int> rowid;
  const CuentasCompanion({
    this.id = const Value.absent(),
    this.empresaId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.nombre = const Value.absent(),
    this.saldoInicialCentimos = const Value.absent(),
    this.fechaSaldoInicial = const Value.absent(),
    this.orden = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CuentasCompanion.insert({
    required String id,
    required String empresaId,
    required TipoCuenta tipo,
    required String nombre,
    this.saldoInicialCentimos = const Value.absent(),
    this.fechaSaldoInicial = const Value.absent(),
    required int orden,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       empresaId = Value(empresaId),
       tipo = Value(tipo),
       nombre = Value(nombre),
       orden = Value(orden);
  static Insertable<Cuenta> custom({
    Expression<String>? id,
    Expression<String>? empresaId,
    Expression<String>? tipo,
    Expression<String>? nombre,
    Expression<int>? saldoInicialCentimos,
    Expression<DateTime>? fechaSaldoInicial,
    Expression<int>? orden,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      if (tipo != null) 'tipo': tipo,
      if (nombre != null) 'nombre': nombre,
      if (saldoInicialCentimos != null)
        'saldo_inicial_centimos': saldoInicialCentimos,
      if (fechaSaldoInicial != null) 'fecha_saldo_inicial': fechaSaldoInicial,
      if (orden != null) 'orden': orden,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CuentasCompanion copyWith({
    Value<String>? id,
    Value<String>? empresaId,
    Value<TipoCuenta>? tipo,
    Value<String>? nombre,
    Value<int?>? saldoInicialCentimos,
    Value<DateTime?>? fechaSaldoInicial,
    Value<int>? orden,
    Value<int>? rowid,
  }) {
    return CuentasCompanion(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      tipo: tipo ?? this.tipo,
      nombre: nombre ?? this.nombre,
      saldoInicialCentimos: saldoInicialCentimos ?? this.saldoInicialCentimos,
      fechaSaldoInicial: fechaSaldoInicial ?? this.fechaSaldoInicial,
      orden: orden ?? this.orden,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (empresaId.present) {
      map['empresa_id'] = Variable<String>(empresaId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(
        $CuentasTable.$convertertipo.toSql(tipo.value),
      );
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (saldoInicialCentimos.present) {
      map['saldo_inicial_centimos'] = Variable<int>(saldoInicialCentimos.value);
    }
    if (fechaSaldoInicial.present) {
      map['fecha_saldo_inicial'] = Variable<DateTime>(fechaSaldoInicial.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CuentasCompanion(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('tipo: $tipo, ')
          ..write('nombre: $nombre, ')
          ..write('saldoInicialCentimos: $saldoInicialCentimos, ')
          ..write('fechaSaldoInicial: $fechaSaldoInicial, ')
          ..write('orden: $orden, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContrapartesTable extends Contrapartes
    with TableInfo<$ContrapartesTable, Contraparte> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContrapartesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empresaIdMeta = const VerificationMeta(
    'empresaId',
  );
  @override
  late final GeneratedColumn<String> empresaId = GeneratedColumn<String>(
    'empresa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES empresas (id)',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identificacionFiscalMeta =
      const VerificationMeta('identificacionFiscal');
  @override
  late final GeneratedColumn<String> identificacionFiscal =
      GeneratedColumn<String>(
        'identificacion_fiscal',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<TipoContraparte, String> tipo =
      GeneratedColumn<String>(
        'tipo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TipoContraparte>($ContrapartesTable.$convertertipo);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    empresaId,
    nombre,
    identificacionFiscal,
    tipo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contrapartes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contraparte> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('empresa_id')) {
      context.handle(
        _empresaIdMeta,
        empresaId.isAcceptableOrUnknown(data['empresa_id']!, _empresaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empresaIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('identificacion_fiscal')) {
      context.handle(
        _identificacionFiscalMeta,
        identificacionFiscal.isAcceptableOrUnknown(
          data['identificacion_fiscal']!,
          _identificacionFiscalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contraparte map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contraparte(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      empresaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      identificacionFiscal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identificacion_fiscal'],
      ),
      tipo: $ContrapartesTable.$convertertipo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo'],
        )!,
      ),
    );
  }

  @override
  $ContrapartesTable createAlias(String alias) {
    return $ContrapartesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TipoContraparte, String, String> $convertertipo =
      const EnumNameConverter<TipoContraparte>(TipoContraparte.values);
}

class Contraparte extends DataClass implements Insertable<Contraparte> {
  final String id;
  final String empresaId;
  final String nombre;
  final String? identificacionFiscal;
  final TipoContraparte tipo;
  const Contraparte({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.identificacionFiscal,
    required this.tipo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['empresa_id'] = Variable<String>(empresaId);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || identificacionFiscal != null) {
      map['identificacion_fiscal'] = Variable<String>(identificacionFiscal);
    }
    {
      map['tipo'] = Variable<String>(
        $ContrapartesTable.$convertertipo.toSql(tipo),
      );
    }
    return map;
  }

  ContrapartesCompanion toCompanion(bool nullToAbsent) {
    return ContrapartesCompanion(
      id: Value(id),
      empresaId: Value(empresaId),
      nombre: Value(nombre),
      identificacionFiscal: identificacionFiscal == null && nullToAbsent
          ? const Value.absent()
          : Value(identificacionFiscal),
      tipo: Value(tipo),
    );
  }

  factory Contraparte.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contraparte(
      id: serializer.fromJson<String>(json['id']),
      empresaId: serializer.fromJson<String>(json['empresaId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      identificacionFiscal: serializer.fromJson<String?>(
        json['identificacionFiscal'],
      ),
      tipo: $ContrapartesTable.$convertertipo.fromJson(
        serializer.fromJson<String>(json['tipo']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'empresaId': serializer.toJson<String>(empresaId),
      'nombre': serializer.toJson<String>(nombre),
      'identificacionFiscal': serializer.toJson<String?>(identificacionFiscal),
      'tipo': serializer.toJson<String>(
        $ContrapartesTable.$convertertipo.toJson(tipo),
      ),
    };
  }

  Contraparte copyWith({
    String? id,
    String? empresaId,
    String? nombre,
    Value<String?> identificacionFiscal = const Value.absent(),
    TipoContraparte? tipo,
  }) => Contraparte(
    id: id ?? this.id,
    empresaId: empresaId ?? this.empresaId,
    nombre: nombre ?? this.nombre,
    identificacionFiscal: identificacionFiscal.present
        ? identificacionFiscal.value
        : this.identificacionFiscal,
    tipo: tipo ?? this.tipo,
  );
  Contraparte copyWithCompanion(ContrapartesCompanion data) {
    return Contraparte(
      id: data.id.present ? data.id.value : this.id,
      empresaId: data.empresaId.present ? data.empresaId.value : this.empresaId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      identificacionFiscal: data.identificacionFiscal.present
          ? data.identificacionFiscal.value
          : this.identificacionFiscal,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contraparte(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('nombre: $nombre, ')
          ..write('identificacionFiscal: $identificacionFiscal, ')
          ..write('tipo: $tipo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, empresaId, nombre, identificacionFiscal, tipo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contraparte &&
          other.id == this.id &&
          other.empresaId == this.empresaId &&
          other.nombre == this.nombre &&
          other.identificacionFiscal == this.identificacionFiscal &&
          other.tipo == this.tipo);
}

class ContrapartesCompanion extends UpdateCompanion<Contraparte> {
  final Value<String> id;
  final Value<String> empresaId;
  final Value<String> nombre;
  final Value<String?> identificacionFiscal;
  final Value<TipoContraparte> tipo;
  final Value<int> rowid;
  const ContrapartesCompanion({
    this.id = const Value.absent(),
    this.empresaId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.identificacionFiscal = const Value.absent(),
    this.tipo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContrapartesCompanion.insert({
    required String id,
    required String empresaId,
    required String nombre,
    this.identificacionFiscal = const Value.absent(),
    required TipoContraparte tipo,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       empresaId = Value(empresaId),
       nombre = Value(nombre),
       tipo = Value(tipo);
  static Insertable<Contraparte> custom({
    Expression<String>? id,
    Expression<String>? empresaId,
    Expression<String>? nombre,
    Expression<String>? identificacionFiscal,
    Expression<String>? tipo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      if (nombre != null) 'nombre': nombre,
      if (identificacionFiscal != null)
        'identificacion_fiscal': identificacionFiscal,
      if (tipo != null) 'tipo': tipo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContrapartesCompanion copyWith({
    Value<String>? id,
    Value<String>? empresaId,
    Value<String>? nombre,
    Value<String?>? identificacionFiscal,
    Value<TipoContraparte>? tipo,
    Value<int>? rowid,
  }) {
    return ContrapartesCompanion(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      nombre: nombre ?? this.nombre,
      identificacionFiscal: identificacionFiscal ?? this.identificacionFiscal,
      tipo: tipo ?? this.tipo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (empresaId.present) {
      map['empresa_id'] = Variable<String>(empresaId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (identificacionFiscal.present) {
      map['identificacion_fiscal'] = Variable<String>(
        identificacionFiscal.value,
      );
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(
        $ContrapartesTable.$convertertipo.toSql(tipo.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContrapartesCompanion(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('nombre: $nombre, ')
          ..write('identificacionFiscal: $identificacionFiscal, ')
          ..write('tipo: $tipo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ComprobantesTable extends Comprobantes
    with TableInfo<$ComprobantesTable, Comprobante> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComprobantesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empresaIdMeta = const VerificationMeta(
    'empresaId',
  );
  @override
  late final GeneratedColumn<String> empresaId = GeneratedColumn<String>(
    'empresa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES empresas (id)',
    ),
  );
  static const VerificationMeta _emisorIdentificacionMeta =
      const VerificationMeta('emisorIdentificacion');
  @override
  late final GeneratedColumn<String> emisorIdentificacion =
      GeneratedColumn<String>(
        'emisor_identificacion',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _emisorNombreMeta = const VerificationMeta(
    'emisorNombre',
  );
  @override
  late final GeneratedColumn<String> emisorNombre = GeneratedColumn<String>(
    'emisor_nombre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serieMeta = const VerificationMeta('serie');
  @override
  late final GeneratedColumn<String> serie = GeneratedColumn<String>(
    'serie',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numeroMeta = const VerificationMeta('numero');
  @override
  late final GeneratedColumn<String> numero = GeneratedColumn<String>(
    'numero',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaEmisionMeta = const VerificationMeta(
    'fechaEmision',
  );
  @override
  late final GeneratedColumn<DateTime> fechaEmision = GeneratedColumn<DateTime>(
    'fecha_emision',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalCentimosMeta = const VerificationMeta(
    'subtotalCentimos',
  );
  @override
  late final GeneratedColumn<int> subtotalCentimos = GeneratedColumn<int>(
    'subtotal_centimos',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _impuestoCentimosMeta = const VerificationMeta(
    'impuestoCentimos',
  );
  @override
  late final GeneratedColumn<int> impuestoCentimos = GeneratedColumn<int>(
    'impuesto_centimos',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCentimosMeta = const VerificationMeta(
    'totalCentimos',
  );
  @override
  late final GeneratedColumn<int> totalCentimos = GeneratedColumn<int>(
    'total_centimos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rutaImagenMeta = const VerificationMeta(
    'rutaImagen',
  );
  @override
  late final GeneratedColumn<String> rutaImagen = GeneratedColumn<String>(
    'ruta_imagen',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OrigenLectura, String>
  origenLectura = GeneratedColumn<String>(
    'origen_lectura',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<OrigenLectura>($ComprobantesTable.$converterorigenLectura);
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    empresaId,
    emisorIdentificacion,
    emisorNombre,
    tipo,
    serie,
    numero,
    fechaEmision,
    subtotalCentimos,
    impuestoCentimos,
    totalCentimos,
    rutaImagen,
    origenLectura,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comprobantes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Comprobante> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('empresa_id')) {
      context.handle(
        _empresaIdMeta,
        empresaId.isAcceptableOrUnknown(data['empresa_id']!, _empresaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empresaIdMeta);
    }
    if (data.containsKey('emisor_identificacion')) {
      context.handle(
        _emisorIdentificacionMeta,
        emisorIdentificacion.isAcceptableOrUnknown(
          data['emisor_identificacion']!,
          _emisorIdentificacionMeta,
        ),
      );
    }
    if (data.containsKey('emisor_nombre')) {
      context.handle(
        _emisorNombreMeta,
        emisorNombre.isAcceptableOrUnknown(
          data['emisor_nombre']!,
          _emisorNombreMeta,
        ),
      );
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    if (data.containsKey('serie')) {
      context.handle(
        _serieMeta,
        serie.isAcceptableOrUnknown(data['serie']!, _serieMeta),
      );
    }
    if (data.containsKey('numero')) {
      context.handle(
        _numeroMeta,
        numero.isAcceptableOrUnknown(data['numero']!, _numeroMeta),
      );
    }
    if (data.containsKey('fecha_emision')) {
      context.handle(
        _fechaEmisionMeta,
        fechaEmision.isAcceptableOrUnknown(
          data['fecha_emision']!,
          _fechaEmisionMeta,
        ),
      );
    }
    if (data.containsKey('subtotal_centimos')) {
      context.handle(
        _subtotalCentimosMeta,
        subtotalCentimos.isAcceptableOrUnknown(
          data['subtotal_centimos']!,
          _subtotalCentimosMeta,
        ),
      );
    }
    if (data.containsKey('impuesto_centimos')) {
      context.handle(
        _impuestoCentimosMeta,
        impuestoCentimos.isAcceptableOrUnknown(
          data['impuesto_centimos']!,
          _impuestoCentimosMeta,
        ),
      );
    }
    if (data.containsKey('total_centimos')) {
      context.handle(
        _totalCentimosMeta,
        totalCentimos.isAcceptableOrUnknown(
          data['total_centimos']!,
          _totalCentimosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalCentimosMeta);
    }
    if (data.containsKey('ruta_imagen')) {
      context.handle(
        _rutaImagenMeta,
        rutaImagen.isAcceptableOrUnknown(data['ruta_imagen']!, _rutaImagenMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {empresaId, emisorIdentificacion, tipo, serie, numero},
  ];
  @override
  Comprobante map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Comprobante(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      empresaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_id'],
      )!,
      emisorIdentificacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emisor_identificacion'],
      ),
      emisorNombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emisor_nombre'],
      ),
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      ),
      serie: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serie'],
      ),
      numero: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero'],
      ),
      fechaEmision: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_emision'],
      ),
      subtotalCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_centimos'],
      ),
      impuestoCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}impuesto_centimos'],
      ),
      totalCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_centimos'],
      )!,
      rutaImagen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruta_imagen'],
      ),
      origenLectura: $ComprobantesTable.$converterorigenLectura.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origen_lectura'],
        )!,
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $ComprobantesTable createAlias(String alias) {
    return $ComprobantesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OrigenLectura, String, String>
  $converterorigenLectura = const EnumNameConverter<OrigenLectura>(
    OrigenLectura.values,
  );
}

class Comprobante extends DataClass implements Insertable<Comprobante> {
  final String id;
  final String empresaId;
  final String? emisorIdentificacion;
  final String? emisorNombre;
  final String? tipo;
  final String? serie;
  final String? numero;
  final DateTime? fechaEmision;
  final int? subtotalCentimos;
  final int? impuestoCentimos;
  final int totalCentimos;
  final String? rutaImagen;
  final OrigenLectura origenLectura;
  final DateTime creadoEn;
  const Comprobante({
    required this.id,
    required this.empresaId,
    this.emisorIdentificacion,
    this.emisorNombre,
    this.tipo,
    this.serie,
    this.numero,
    this.fechaEmision,
    this.subtotalCentimos,
    this.impuestoCentimos,
    required this.totalCentimos,
    this.rutaImagen,
    required this.origenLectura,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['empresa_id'] = Variable<String>(empresaId);
    if (!nullToAbsent || emisorIdentificacion != null) {
      map['emisor_identificacion'] = Variable<String>(emisorIdentificacion);
    }
    if (!nullToAbsent || emisorNombre != null) {
      map['emisor_nombre'] = Variable<String>(emisorNombre);
    }
    if (!nullToAbsent || tipo != null) {
      map['tipo'] = Variable<String>(tipo);
    }
    if (!nullToAbsent || serie != null) {
      map['serie'] = Variable<String>(serie);
    }
    if (!nullToAbsent || numero != null) {
      map['numero'] = Variable<String>(numero);
    }
    if (!nullToAbsent || fechaEmision != null) {
      map['fecha_emision'] = Variable<DateTime>(fechaEmision);
    }
    if (!nullToAbsent || subtotalCentimos != null) {
      map['subtotal_centimos'] = Variable<int>(subtotalCentimos);
    }
    if (!nullToAbsent || impuestoCentimos != null) {
      map['impuesto_centimos'] = Variable<int>(impuestoCentimos);
    }
    map['total_centimos'] = Variable<int>(totalCentimos);
    if (!nullToAbsent || rutaImagen != null) {
      map['ruta_imagen'] = Variable<String>(rutaImagen);
    }
    {
      map['origen_lectura'] = Variable<String>(
        $ComprobantesTable.$converterorigenLectura.toSql(origenLectura),
      );
    }
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  ComprobantesCompanion toCompanion(bool nullToAbsent) {
    return ComprobantesCompanion(
      id: Value(id),
      empresaId: Value(empresaId),
      emisorIdentificacion: emisorIdentificacion == null && nullToAbsent
          ? const Value.absent()
          : Value(emisorIdentificacion),
      emisorNombre: emisorNombre == null && nullToAbsent
          ? const Value.absent()
          : Value(emisorNombre),
      tipo: tipo == null && nullToAbsent ? const Value.absent() : Value(tipo),
      serie: serie == null && nullToAbsent
          ? const Value.absent()
          : Value(serie),
      numero: numero == null && nullToAbsent
          ? const Value.absent()
          : Value(numero),
      fechaEmision: fechaEmision == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaEmision),
      subtotalCentimos: subtotalCentimos == null && nullToAbsent
          ? const Value.absent()
          : Value(subtotalCentimos),
      impuestoCentimos: impuestoCentimos == null && nullToAbsent
          ? const Value.absent()
          : Value(impuestoCentimos),
      totalCentimos: Value(totalCentimos),
      rutaImagen: rutaImagen == null && nullToAbsent
          ? const Value.absent()
          : Value(rutaImagen),
      origenLectura: Value(origenLectura),
      creadoEn: Value(creadoEn),
    );
  }

  factory Comprobante.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Comprobante(
      id: serializer.fromJson<String>(json['id']),
      empresaId: serializer.fromJson<String>(json['empresaId']),
      emisorIdentificacion: serializer.fromJson<String?>(
        json['emisorIdentificacion'],
      ),
      emisorNombre: serializer.fromJson<String?>(json['emisorNombre']),
      tipo: serializer.fromJson<String?>(json['tipo']),
      serie: serializer.fromJson<String?>(json['serie']),
      numero: serializer.fromJson<String?>(json['numero']),
      fechaEmision: serializer.fromJson<DateTime?>(json['fechaEmision']),
      subtotalCentimos: serializer.fromJson<int?>(json['subtotalCentimos']),
      impuestoCentimos: serializer.fromJson<int?>(json['impuestoCentimos']),
      totalCentimos: serializer.fromJson<int>(json['totalCentimos']),
      rutaImagen: serializer.fromJson<String?>(json['rutaImagen']),
      origenLectura: $ComprobantesTable.$converterorigenLectura.fromJson(
        serializer.fromJson<String>(json['origenLectura']),
      ),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'empresaId': serializer.toJson<String>(empresaId),
      'emisorIdentificacion': serializer.toJson<String?>(emisorIdentificacion),
      'emisorNombre': serializer.toJson<String?>(emisorNombre),
      'tipo': serializer.toJson<String?>(tipo),
      'serie': serializer.toJson<String?>(serie),
      'numero': serializer.toJson<String?>(numero),
      'fechaEmision': serializer.toJson<DateTime?>(fechaEmision),
      'subtotalCentimos': serializer.toJson<int?>(subtotalCentimos),
      'impuestoCentimos': serializer.toJson<int?>(impuestoCentimos),
      'totalCentimos': serializer.toJson<int>(totalCentimos),
      'rutaImagen': serializer.toJson<String?>(rutaImagen),
      'origenLectura': serializer.toJson<String>(
        $ComprobantesTable.$converterorigenLectura.toJson(origenLectura),
      ),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  Comprobante copyWith({
    String? id,
    String? empresaId,
    Value<String?> emisorIdentificacion = const Value.absent(),
    Value<String?> emisorNombre = const Value.absent(),
    Value<String?> tipo = const Value.absent(),
    Value<String?> serie = const Value.absent(),
    Value<String?> numero = const Value.absent(),
    Value<DateTime?> fechaEmision = const Value.absent(),
    Value<int?> subtotalCentimos = const Value.absent(),
    Value<int?> impuestoCentimos = const Value.absent(),
    int? totalCentimos,
    Value<String?> rutaImagen = const Value.absent(),
    OrigenLectura? origenLectura,
    DateTime? creadoEn,
  }) => Comprobante(
    id: id ?? this.id,
    empresaId: empresaId ?? this.empresaId,
    emisorIdentificacion: emisorIdentificacion.present
        ? emisorIdentificacion.value
        : this.emisorIdentificacion,
    emisorNombre: emisorNombre.present ? emisorNombre.value : this.emisorNombre,
    tipo: tipo.present ? tipo.value : this.tipo,
    serie: serie.present ? serie.value : this.serie,
    numero: numero.present ? numero.value : this.numero,
    fechaEmision: fechaEmision.present ? fechaEmision.value : this.fechaEmision,
    subtotalCentimos: subtotalCentimos.present
        ? subtotalCentimos.value
        : this.subtotalCentimos,
    impuestoCentimos: impuestoCentimos.present
        ? impuestoCentimos.value
        : this.impuestoCentimos,
    totalCentimos: totalCentimos ?? this.totalCentimos,
    rutaImagen: rutaImagen.present ? rutaImagen.value : this.rutaImagen,
    origenLectura: origenLectura ?? this.origenLectura,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  Comprobante copyWithCompanion(ComprobantesCompanion data) {
    return Comprobante(
      id: data.id.present ? data.id.value : this.id,
      empresaId: data.empresaId.present ? data.empresaId.value : this.empresaId,
      emisorIdentificacion: data.emisorIdentificacion.present
          ? data.emisorIdentificacion.value
          : this.emisorIdentificacion,
      emisorNombre: data.emisorNombre.present
          ? data.emisorNombre.value
          : this.emisorNombre,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      serie: data.serie.present ? data.serie.value : this.serie,
      numero: data.numero.present ? data.numero.value : this.numero,
      fechaEmision: data.fechaEmision.present
          ? data.fechaEmision.value
          : this.fechaEmision,
      subtotalCentimos: data.subtotalCentimos.present
          ? data.subtotalCentimos.value
          : this.subtotalCentimos,
      impuestoCentimos: data.impuestoCentimos.present
          ? data.impuestoCentimos.value
          : this.impuestoCentimos,
      totalCentimos: data.totalCentimos.present
          ? data.totalCentimos.value
          : this.totalCentimos,
      rutaImagen: data.rutaImagen.present
          ? data.rutaImagen.value
          : this.rutaImagen,
      origenLectura: data.origenLectura.present
          ? data.origenLectura.value
          : this.origenLectura,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Comprobante(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('emisorIdentificacion: $emisorIdentificacion, ')
          ..write('emisorNombre: $emisorNombre, ')
          ..write('tipo: $tipo, ')
          ..write('serie: $serie, ')
          ..write('numero: $numero, ')
          ..write('fechaEmision: $fechaEmision, ')
          ..write('subtotalCentimos: $subtotalCentimos, ')
          ..write('impuestoCentimos: $impuestoCentimos, ')
          ..write('totalCentimos: $totalCentimos, ')
          ..write('rutaImagen: $rutaImagen, ')
          ..write('origenLectura: $origenLectura, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    empresaId,
    emisorIdentificacion,
    emisorNombre,
    tipo,
    serie,
    numero,
    fechaEmision,
    subtotalCentimos,
    impuestoCentimos,
    totalCentimos,
    rutaImagen,
    origenLectura,
    creadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Comprobante &&
          other.id == this.id &&
          other.empresaId == this.empresaId &&
          other.emisorIdentificacion == this.emisorIdentificacion &&
          other.emisorNombre == this.emisorNombre &&
          other.tipo == this.tipo &&
          other.serie == this.serie &&
          other.numero == this.numero &&
          other.fechaEmision == this.fechaEmision &&
          other.subtotalCentimos == this.subtotalCentimos &&
          other.impuestoCentimos == this.impuestoCentimos &&
          other.totalCentimos == this.totalCentimos &&
          other.rutaImagen == this.rutaImagen &&
          other.origenLectura == this.origenLectura &&
          other.creadoEn == this.creadoEn);
}

class ComprobantesCompanion extends UpdateCompanion<Comprobante> {
  final Value<String> id;
  final Value<String> empresaId;
  final Value<String?> emisorIdentificacion;
  final Value<String?> emisorNombre;
  final Value<String?> tipo;
  final Value<String?> serie;
  final Value<String?> numero;
  final Value<DateTime?> fechaEmision;
  final Value<int?> subtotalCentimos;
  final Value<int?> impuestoCentimos;
  final Value<int> totalCentimos;
  final Value<String?> rutaImagen;
  final Value<OrigenLectura> origenLectura;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const ComprobantesCompanion({
    this.id = const Value.absent(),
    this.empresaId = const Value.absent(),
    this.emisorIdentificacion = const Value.absent(),
    this.emisorNombre = const Value.absent(),
    this.tipo = const Value.absent(),
    this.serie = const Value.absent(),
    this.numero = const Value.absent(),
    this.fechaEmision = const Value.absent(),
    this.subtotalCentimos = const Value.absent(),
    this.impuestoCentimos = const Value.absent(),
    this.totalCentimos = const Value.absent(),
    this.rutaImagen = const Value.absent(),
    this.origenLectura = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComprobantesCompanion.insert({
    required String id,
    required String empresaId,
    this.emisorIdentificacion = const Value.absent(),
    this.emisorNombre = const Value.absent(),
    this.tipo = const Value.absent(),
    this.serie = const Value.absent(),
    this.numero = const Value.absent(),
    this.fechaEmision = const Value.absent(),
    this.subtotalCentimos = const Value.absent(),
    this.impuestoCentimos = const Value.absent(),
    required int totalCentimos,
    this.rutaImagen = const Value.absent(),
    required OrigenLectura origenLectura,
    required DateTime creadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       empresaId = Value(empresaId),
       totalCentimos = Value(totalCentimos),
       origenLectura = Value(origenLectura),
       creadoEn = Value(creadoEn);
  static Insertable<Comprobante> custom({
    Expression<String>? id,
    Expression<String>? empresaId,
    Expression<String>? emisorIdentificacion,
    Expression<String>? emisorNombre,
    Expression<String>? tipo,
    Expression<String>? serie,
    Expression<String>? numero,
    Expression<DateTime>? fechaEmision,
    Expression<int>? subtotalCentimos,
    Expression<int>? impuestoCentimos,
    Expression<int>? totalCentimos,
    Expression<String>? rutaImagen,
    Expression<String>? origenLectura,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      if (emisorIdentificacion != null)
        'emisor_identificacion': emisorIdentificacion,
      if (emisorNombre != null) 'emisor_nombre': emisorNombre,
      if (tipo != null) 'tipo': tipo,
      if (serie != null) 'serie': serie,
      if (numero != null) 'numero': numero,
      if (fechaEmision != null) 'fecha_emision': fechaEmision,
      if (subtotalCentimos != null) 'subtotal_centimos': subtotalCentimos,
      if (impuestoCentimos != null) 'impuesto_centimos': impuestoCentimos,
      if (totalCentimos != null) 'total_centimos': totalCentimos,
      if (rutaImagen != null) 'ruta_imagen': rutaImagen,
      if (origenLectura != null) 'origen_lectura': origenLectura,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComprobantesCompanion copyWith({
    Value<String>? id,
    Value<String>? empresaId,
    Value<String?>? emisorIdentificacion,
    Value<String?>? emisorNombre,
    Value<String?>? tipo,
    Value<String?>? serie,
    Value<String?>? numero,
    Value<DateTime?>? fechaEmision,
    Value<int?>? subtotalCentimos,
    Value<int?>? impuestoCentimos,
    Value<int>? totalCentimos,
    Value<String?>? rutaImagen,
    Value<OrigenLectura>? origenLectura,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return ComprobantesCompanion(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      emisorIdentificacion: emisorIdentificacion ?? this.emisorIdentificacion,
      emisorNombre: emisorNombre ?? this.emisorNombre,
      tipo: tipo ?? this.tipo,
      serie: serie ?? this.serie,
      numero: numero ?? this.numero,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      subtotalCentimos: subtotalCentimos ?? this.subtotalCentimos,
      impuestoCentimos: impuestoCentimos ?? this.impuestoCentimos,
      totalCentimos: totalCentimos ?? this.totalCentimos,
      rutaImagen: rutaImagen ?? this.rutaImagen,
      origenLectura: origenLectura ?? this.origenLectura,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (empresaId.present) {
      map['empresa_id'] = Variable<String>(empresaId.value);
    }
    if (emisorIdentificacion.present) {
      map['emisor_identificacion'] = Variable<String>(
        emisorIdentificacion.value,
      );
    }
    if (emisorNombre.present) {
      map['emisor_nombre'] = Variable<String>(emisorNombre.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (serie.present) {
      map['serie'] = Variable<String>(serie.value);
    }
    if (numero.present) {
      map['numero'] = Variable<String>(numero.value);
    }
    if (fechaEmision.present) {
      map['fecha_emision'] = Variable<DateTime>(fechaEmision.value);
    }
    if (subtotalCentimos.present) {
      map['subtotal_centimos'] = Variable<int>(subtotalCentimos.value);
    }
    if (impuestoCentimos.present) {
      map['impuesto_centimos'] = Variable<int>(impuestoCentimos.value);
    }
    if (totalCentimos.present) {
      map['total_centimos'] = Variable<int>(totalCentimos.value);
    }
    if (rutaImagen.present) {
      map['ruta_imagen'] = Variable<String>(rutaImagen.value);
    }
    if (origenLectura.present) {
      map['origen_lectura'] = Variable<String>(
        $ComprobantesTable.$converterorigenLectura.toSql(origenLectura.value),
      );
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComprobantesCompanion(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('emisorIdentificacion: $emisorIdentificacion, ')
          ..write('emisorNombre: $emisorNombre, ')
          ..write('tipo: $tipo, ')
          ..write('serie: $serie, ')
          ..write('numero: $numero, ')
          ..write('fechaEmision: $fechaEmision, ')
          ..write('subtotalCentimos: $subtotalCentimos, ')
          ..write('impuestoCentimos: $impuestoCentimos, ')
          ..write('totalCentimos: $totalCentimos, ')
          ..write('rutaImagen: $rutaImagen, ')
          ..write('origenLectura: $origenLectura, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsComprobanteTable extends ItemsComprobante
    with TableInfo<$ItemsComprobanteTable, ItemsComprobanteData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsComprobanteTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _comprobanteIdMeta = const VerificationMeta(
    'comprobanteId',
  );
  @override
  late final GeneratedColumn<String> comprobanteId = GeneratedColumn<String>(
    'comprobante_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES comprobantes (id)',
    ),
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<double> cantidad = GeneratedColumn<double>(
    'cantidad',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _precioUnitarioCentimosMeta =
      const VerificationMeta('precioUnitarioCentimos');
  @override
  late final GeneratedColumn<int> precioUnitarioCentimos = GeneratedColumn<int>(
    'precio_unitario_centimos',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importeCentimosMeta = const VerificationMeta(
    'importeCentimos',
  );
  @override
  late final GeneratedColumn<int> importeCentimos = GeneratedColumn<int>(
    'importe_centimos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    comprobanteId,
    descripcion,
    cantidad,
    precioUnitarioCentimos,
    importeCentimos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items_comprobante';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemsComprobanteData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('comprobante_id')) {
      context.handle(
        _comprobanteIdMeta,
        comprobanteId.isAcceptableOrUnknown(
          data['comprobante_id']!,
          _comprobanteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_comprobanteIdMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descripcionMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    }
    if (data.containsKey('precio_unitario_centimos')) {
      context.handle(
        _precioUnitarioCentimosMeta,
        precioUnitarioCentimos.isAcceptableOrUnknown(
          data['precio_unitario_centimos']!,
          _precioUnitarioCentimosMeta,
        ),
      );
    }
    if (data.containsKey('importe_centimos')) {
      context.handle(
        _importeCentimosMeta,
        importeCentimos.isAcceptableOrUnknown(
          data['importe_centimos']!,
          _importeCentimosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importeCentimosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemsComprobanteData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemsComprobanteData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      comprobanteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comprobante_id'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      )!,
      cantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cantidad'],
      ),
      precioUnitarioCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precio_unitario_centimos'],
      ),
      importeCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importe_centimos'],
      )!,
    );
  }

  @override
  $ItemsComprobanteTable createAlias(String alias) {
    return $ItemsComprobanteTable(attachedDatabase, alias);
  }
}

class ItemsComprobanteData extends DataClass
    implements Insertable<ItemsComprobanteData> {
  final String id;
  final String comprobanteId;
  final String descripcion;
  final double? cantidad;
  final int? precioUnitarioCentimos;
  final int importeCentimos;
  const ItemsComprobanteData({
    required this.id,
    required this.comprobanteId,
    required this.descripcion,
    this.cantidad,
    this.precioUnitarioCentimos,
    required this.importeCentimos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['comprobante_id'] = Variable<String>(comprobanteId);
    map['descripcion'] = Variable<String>(descripcion);
    if (!nullToAbsent || cantidad != null) {
      map['cantidad'] = Variable<double>(cantidad);
    }
    if (!nullToAbsent || precioUnitarioCentimos != null) {
      map['precio_unitario_centimos'] = Variable<int>(precioUnitarioCentimos);
    }
    map['importe_centimos'] = Variable<int>(importeCentimos);
    return map;
  }

  ItemsComprobanteCompanion toCompanion(bool nullToAbsent) {
    return ItemsComprobanteCompanion(
      id: Value(id),
      comprobanteId: Value(comprobanteId),
      descripcion: Value(descripcion),
      cantidad: cantidad == null && nullToAbsent
          ? const Value.absent()
          : Value(cantidad),
      precioUnitarioCentimos: precioUnitarioCentimos == null && nullToAbsent
          ? const Value.absent()
          : Value(precioUnitarioCentimos),
      importeCentimos: Value(importeCentimos),
    );
  }

  factory ItemsComprobanteData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemsComprobanteData(
      id: serializer.fromJson<String>(json['id']),
      comprobanteId: serializer.fromJson<String>(json['comprobanteId']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      cantidad: serializer.fromJson<double?>(json['cantidad']),
      precioUnitarioCentimos: serializer.fromJson<int?>(
        json['precioUnitarioCentimos'],
      ),
      importeCentimos: serializer.fromJson<int>(json['importeCentimos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'comprobanteId': serializer.toJson<String>(comprobanteId),
      'descripcion': serializer.toJson<String>(descripcion),
      'cantidad': serializer.toJson<double?>(cantidad),
      'precioUnitarioCentimos': serializer.toJson<int?>(precioUnitarioCentimos),
      'importeCentimos': serializer.toJson<int>(importeCentimos),
    };
  }

  ItemsComprobanteData copyWith({
    String? id,
    String? comprobanteId,
    String? descripcion,
    Value<double?> cantidad = const Value.absent(),
    Value<int?> precioUnitarioCentimos = const Value.absent(),
    int? importeCentimos,
  }) => ItemsComprobanteData(
    id: id ?? this.id,
    comprobanteId: comprobanteId ?? this.comprobanteId,
    descripcion: descripcion ?? this.descripcion,
    cantidad: cantidad.present ? cantidad.value : this.cantidad,
    precioUnitarioCentimos: precioUnitarioCentimos.present
        ? precioUnitarioCentimos.value
        : this.precioUnitarioCentimos,
    importeCentimos: importeCentimos ?? this.importeCentimos,
  );
  ItemsComprobanteData copyWithCompanion(ItemsComprobanteCompanion data) {
    return ItemsComprobanteData(
      id: data.id.present ? data.id.value : this.id,
      comprobanteId: data.comprobanteId.present
          ? data.comprobanteId.value
          : this.comprobanteId,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      precioUnitarioCentimos: data.precioUnitarioCentimos.present
          ? data.precioUnitarioCentimos.value
          : this.precioUnitarioCentimos,
      importeCentimos: data.importeCentimos.present
          ? data.importeCentimos.value
          : this.importeCentimos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemsComprobanteData(')
          ..write('id: $id, ')
          ..write('comprobanteId: $comprobanteId, ')
          ..write('descripcion: $descripcion, ')
          ..write('cantidad: $cantidad, ')
          ..write('precioUnitarioCentimos: $precioUnitarioCentimos, ')
          ..write('importeCentimos: $importeCentimos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    comprobanteId,
    descripcion,
    cantidad,
    precioUnitarioCentimos,
    importeCentimos,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemsComprobanteData &&
          other.id == this.id &&
          other.comprobanteId == this.comprobanteId &&
          other.descripcion == this.descripcion &&
          other.cantidad == this.cantidad &&
          other.precioUnitarioCentimos == this.precioUnitarioCentimos &&
          other.importeCentimos == this.importeCentimos);
}

class ItemsComprobanteCompanion extends UpdateCompanion<ItemsComprobanteData> {
  final Value<String> id;
  final Value<String> comprobanteId;
  final Value<String> descripcion;
  final Value<double?> cantidad;
  final Value<int?> precioUnitarioCentimos;
  final Value<int> importeCentimos;
  final Value<int> rowid;
  const ItemsComprobanteCompanion({
    this.id = const Value.absent(),
    this.comprobanteId = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.precioUnitarioCentimos = const Value.absent(),
    this.importeCentimos = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsComprobanteCompanion.insert({
    required String id,
    required String comprobanteId,
    required String descripcion,
    this.cantidad = const Value.absent(),
    this.precioUnitarioCentimos = const Value.absent(),
    required int importeCentimos,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       comprobanteId = Value(comprobanteId),
       descripcion = Value(descripcion),
       importeCentimos = Value(importeCentimos);
  static Insertable<ItemsComprobanteData> custom({
    Expression<String>? id,
    Expression<String>? comprobanteId,
    Expression<String>? descripcion,
    Expression<double>? cantidad,
    Expression<int>? precioUnitarioCentimos,
    Expression<int>? importeCentimos,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (comprobanteId != null) 'comprobante_id': comprobanteId,
      if (descripcion != null) 'descripcion': descripcion,
      if (cantidad != null) 'cantidad': cantidad,
      if (precioUnitarioCentimos != null)
        'precio_unitario_centimos': precioUnitarioCentimos,
      if (importeCentimos != null) 'importe_centimos': importeCentimos,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsComprobanteCompanion copyWith({
    Value<String>? id,
    Value<String>? comprobanteId,
    Value<String>? descripcion,
    Value<double?>? cantidad,
    Value<int?>? precioUnitarioCentimos,
    Value<int>? importeCentimos,
    Value<int>? rowid,
  }) {
    return ItemsComprobanteCompanion(
      id: id ?? this.id,
      comprobanteId: comprobanteId ?? this.comprobanteId,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      precioUnitarioCentimos:
          precioUnitarioCentimos ?? this.precioUnitarioCentimos,
      importeCentimos: importeCentimos ?? this.importeCentimos,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (comprobanteId.present) {
      map['comprobante_id'] = Variable<String>(comprobanteId.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<double>(cantidad.value);
    }
    if (precioUnitarioCentimos.present) {
      map['precio_unitario_centimos'] = Variable<int>(
        precioUnitarioCentimos.value,
      );
    }
    if (importeCentimos.present) {
      map['importe_centimos'] = Variable<int>(importeCentimos.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsComprobanteCompanion(')
          ..write('id: $id, ')
          ..write('comprobanteId: $comprobanteId, ')
          ..write('descripcion: $descripcion, ')
          ..write('cantidad: $cantidad, ')
          ..write('precioUnitarioCentimos: $precioUnitarioCentimos, ')
          ..write('importeCentimos: $importeCentimos, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriasTable extends Categorias
    with TableInfo<$CategoriasTable, Categoria> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empresaIdMeta = const VerificationMeta(
    'empresaId',
  );
  @override
  late final GeneratedColumn<String> empresaId = GeneratedColumn<String>(
    'empresa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES empresas (id)',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TipoMovimiento, String>
  tipoMovimiento = GeneratedColumn<String>(
    'tipo_movimiento',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<TipoMovimiento>($CategoriasTable.$convertertipoMovimiento);
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activaMeta = const VerificationMeta('activa');
  @override
  late final GeneratedColumn<bool> activa = GeneratedColumn<bool>(
    'activa',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activa" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    empresaId,
    nombre,
    tipoMovimiento,
    orden,
    activa,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categorias';
  @override
  VerificationContext validateIntegrity(
    Insertable<Categoria> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('empresa_id')) {
      context.handle(
        _empresaIdMeta,
        empresaId.isAcceptableOrUnknown(data['empresa_id']!, _empresaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empresaIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    } else if (isInserting) {
      context.missing(_ordenMeta);
    }
    if (data.containsKey('activa')) {
      context.handle(
        _activaMeta,
        activa.isAcceptableOrUnknown(data['activa']!, _activaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Categoria map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Categoria(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      empresaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      tipoMovimiento: $CategoriasTable.$convertertipoMovimiento.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo_movimiento'],
        )!,
      ),
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
      activa: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activa'],
      )!,
    );
  }

  @override
  $CategoriasTable createAlias(String alias) {
    return $CategoriasTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TipoMovimiento, String, String>
  $convertertipoMovimiento = const EnumNameConverter<TipoMovimiento>(
    TipoMovimiento.values,
  );
}

class Categoria extends DataClass implements Insertable<Categoria> {
  final String id;
  final String empresaId;
  final String nombre;
  final TipoMovimiento tipoMovimiento;
  final int orden;
  final bool activa;
  const Categoria({
    required this.id,
    required this.empresaId,
    required this.nombre,
    required this.tipoMovimiento,
    required this.orden,
    required this.activa,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['empresa_id'] = Variable<String>(empresaId);
    map['nombre'] = Variable<String>(nombre);
    {
      map['tipo_movimiento'] = Variable<String>(
        $CategoriasTable.$convertertipoMovimiento.toSql(tipoMovimiento),
      );
    }
    map['orden'] = Variable<int>(orden);
    map['activa'] = Variable<bool>(activa);
    return map;
  }

  CategoriasCompanion toCompanion(bool nullToAbsent) {
    return CategoriasCompanion(
      id: Value(id),
      empresaId: Value(empresaId),
      nombre: Value(nombre),
      tipoMovimiento: Value(tipoMovimiento),
      orden: Value(orden),
      activa: Value(activa),
    );
  }

  factory Categoria.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Categoria(
      id: serializer.fromJson<String>(json['id']),
      empresaId: serializer.fromJson<String>(json['empresaId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      tipoMovimiento: $CategoriasTable.$convertertipoMovimiento.fromJson(
        serializer.fromJson<String>(json['tipoMovimiento']),
      ),
      orden: serializer.fromJson<int>(json['orden']),
      activa: serializer.fromJson<bool>(json['activa']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'empresaId': serializer.toJson<String>(empresaId),
      'nombre': serializer.toJson<String>(nombre),
      'tipoMovimiento': serializer.toJson<String>(
        $CategoriasTable.$convertertipoMovimiento.toJson(tipoMovimiento),
      ),
      'orden': serializer.toJson<int>(orden),
      'activa': serializer.toJson<bool>(activa),
    };
  }

  Categoria copyWith({
    String? id,
    String? empresaId,
    String? nombre,
    TipoMovimiento? tipoMovimiento,
    int? orden,
    bool? activa,
  }) => Categoria(
    id: id ?? this.id,
    empresaId: empresaId ?? this.empresaId,
    nombre: nombre ?? this.nombre,
    tipoMovimiento: tipoMovimiento ?? this.tipoMovimiento,
    orden: orden ?? this.orden,
    activa: activa ?? this.activa,
  );
  Categoria copyWithCompanion(CategoriasCompanion data) {
    return Categoria(
      id: data.id.present ? data.id.value : this.id,
      empresaId: data.empresaId.present ? data.empresaId.value : this.empresaId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      tipoMovimiento: data.tipoMovimiento.present
          ? data.tipoMovimiento.value
          : this.tipoMovimiento,
      orden: data.orden.present ? data.orden.value : this.orden,
      activa: data.activa.present ? data.activa.value : this.activa,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Categoria(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('nombre: $nombre, ')
          ..write('tipoMovimiento: $tipoMovimiento, ')
          ..write('orden: $orden, ')
          ..write('activa: $activa')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, empresaId, nombre, tipoMovimiento, orden, activa);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Categoria &&
          other.id == this.id &&
          other.empresaId == this.empresaId &&
          other.nombre == this.nombre &&
          other.tipoMovimiento == this.tipoMovimiento &&
          other.orden == this.orden &&
          other.activa == this.activa);
}

class CategoriasCompanion extends UpdateCompanion<Categoria> {
  final Value<String> id;
  final Value<String> empresaId;
  final Value<String> nombre;
  final Value<TipoMovimiento> tipoMovimiento;
  final Value<int> orden;
  final Value<bool> activa;
  final Value<int> rowid;
  const CategoriasCompanion({
    this.id = const Value.absent(),
    this.empresaId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.tipoMovimiento = const Value.absent(),
    this.orden = const Value.absent(),
    this.activa = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriasCompanion.insert({
    required String id,
    required String empresaId,
    required String nombre,
    required TipoMovimiento tipoMovimiento,
    required int orden,
    this.activa = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       empresaId = Value(empresaId),
       nombre = Value(nombre),
       tipoMovimiento = Value(tipoMovimiento),
       orden = Value(orden);
  static Insertable<Categoria> custom({
    Expression<String>? id,
    Expression<String>? empresaId,
    Expression<String>? nombre,
    Expression<String>? tipoMovimiento,
    Expression<int>? orden,
    Expression<bool>? activa,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      if (nombre != null) 'nombre': nombre,
      if (tipoMovimiento != null) 'tipo_movimiento': tipoMovimiento,
      if (orden != null) 'orden': orden,
      if (activa != null) 'activa': activa,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriasCompanion copyWith({
    Value<String>? id,
    Value<String>? empresaId,
    Value<String>? nombre,
    Value<TipoMovimiento>? tipoMovimiento,
    Value<int>? orden,
    Value<bool>? activa,
    Value<int>? rowid,
  }) {
    return CategoriasCompanion(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      nombre: nombre ?? this.nombre,
      tipoMovimiento: tipoMovimiento ?? this.tipoMovimiento,
      orden: orden ?? this.orden,
      activa: activa ?? this.activa,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (empresaId.present) {
      map['empresa_id'] = Variable<String>(empresaId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (tipoMovimiento.present) {
      map['tipo_movimiento'] = Variable<String>(
        $CategoriasTable.$convertertipoMovimiento.toSql(tipoMovimiento.value),
      );
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (activa.present) {
      map['activa'] = Variable<bool>(activa.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriasCompanion(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('nombre: $nombre, ')
          ..write('tipoMovimiento: $tipoMovimiento, ')
          ..write('orden: $orden, ')
          ..write('activa: $activa, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovimientosTable extends Movimientos
    with TableInfo<$MovimientosTable, Movimiento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimientosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empresaIdMeta = const VerificationMeta(
    'empresaId',
  );
  @override
  late final GeneratedColumn<String> empresaId = GeneratedColumn<String>(
    'empresa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES empresas (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TipoMovimiento, String> tipo =
      GeneratedColumn<String>(
        'tipo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TipoMovimiento>($MovimientosTable.$convertertipo);
  static const VerificationMeta _cuentaIdMeta = const VerificationMeta(
    'cuentaId',
  );
  @override
  late final GeneratedColumn<String> cuentaId = GeneratedColumn<String>(
    'cuenta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuentas (id)',
    ),
  );
  static const VerificationMeta _cuentaDestinoIdMeta = const VerificationMeta(
    'cuentaDestinoId',
  );
  @override
  late final GeneratedColumn<String> cuentaDestinoId = GeneratedColumn<String>(
    'cuenta_destino_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuentas (id)',
    ),
  );
  static const VerificationMeta _montoCentimosMeta = const VerificationMeta(
    'montoCentimos',
  );
  @override
  late final GeneratedColumn<int> montoCentimos = GeneratedColumn<int>(
    'monto_centimos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMovimientoMeta = const VerificationMeta(
    'fechaMovimiento',
  );
  @override
  late final GeneratedColumn<DateTime> fechaMovimiento =
      GeneratedColumn<DateTime>(
        'fecha_movimiento',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fechaComprobanteMeta = const VerificationMeta(
    'fechaComprobante',
  );
  @override
  late final GeneratedColumn<DateTime> fechaComprobante =
      GeneratedColumn<DateTime>(
        'fecha_comprobante',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<EstadoPago, String> estadoPago =
      GeneratedColumn<String>(
        'estado_pago',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EstadoPago>($MovimientosTable.$converterestadoPago);
  static const VerificationMeta _montoPagadoCentimosMeta =
      const VerificationMeta('montoPagadoCentimos');
  @override
  late final GeneratedColumn<int> montoPagadoCentimos = GeneratedColumn<int>(
    'monto_pagado_centimos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaVencimientoMeta = const VerificationMeta(
    'fechaVencimiento',
  );
  @override
  late final GeneratedColumn<DateTime> fechaVencimiento =
      GeneratedColumn<DateTime>(
        'fecha_vencimiento',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fechaPagoMeta = const VerificationMeta(
    'fechaPago',
  );
  @override
  late final GeneratedColumn<DateTime> fechaPago = GeneratedColumn<DateTime>(
    'fecha_pago',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoriaIdMeta = const VerificationMeta(
    'categoriaId',
  );
  @override
  late final GeneratedColumn<String> categoriaId = GeneratedColumn<String>(
    'categoria_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categorias (id)',
    ),
  );
  static const VerificationMeta _contraparteIdMeta = const VerificationMeta(
    'contraparteId',
  );
  @override
  late final GeneratedColumn<String> contraparteId = GeneratedColumn<String>(
    'contraparte_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contrapartes (id)',
    ),
  );
  static const VerificationMeta _comprobanteIdMeta = const VerificationMeta(
    'comprobanteId',
  );
  @override
  late final GeneratedColumn<String> comprobanteId = GeneratedColumn<String>(
    'comprobante_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES comprobantes (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<NivelConfianza, String>
  nivelConfianza = GeneratedColumn<String>(
    'nivel_confianza',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<NivelConfianza>($MovimientosTable.$converternivelConfianza);
  @override
  late final GeneratedColumnWithTypeConverter<Fuente, String> fuente =
      GeneratedColumn<String>(
        'fuente',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Fuente>($MovimientosTable.$converterfuente);
  static const VerificationMeta _autorIdMeta = const VerificationMeta(
    'autorId',
  );
  @override
  late final GeneratedColumn<String> autorId = GeneratedColumn<String>(
    'autor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES usuarios (id)',
    ),
  );
  static const VerificationMeta _notaMeta = const VerificationMeta('nota');
  @override
  late final GeneratedColumn<String> nota = GeneratedColumn<String>(
    'nota',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EstadoRegistro, String> estado =
      GeneratedColumn<String>(
        'estado',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EstadoRegistro>($MovimientosTable.$converterestado);
  static const VerificationMeta _reemplazaAMeta = const VerificationMeta(
    'reemplazaA',
  );
  @override
  late final GeneratedColumn<String> reemplazaA = GeneratedColumn<String>(
    'reemplaza_a',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EstadoSincronizacion, String>
  estadoSincronizacion =
      GeneratedColumn<String>(
        'estado_sincronizacion',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EstadoSincronizacion>(
        $MovimientosTable.$converterestadoSincronizacion,
      );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    empresaId,
    tipo,
    cuentaId,
    cuentaDestinoId,
    montoCentimos,
    fechaMovimiento,
    fechaComprobante,
    estadoPago,
    montoPagadoCentimos,
    fechaVencimiento,
    fechaPago,
    categoriaId,
    contraparteId,
    comprobanteId,
    nivelConfianza,
    fuente,
    autorId,
    nota,
    estado,
    reemplazaA,
    estadoSincronizacion,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimientos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Movimiento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('empresa_id')) {
      context.handle(
        _empresaIdMeta,
        empresaId.isAcceptableOrUnknown(data['empresa_id']!, _empresaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empresaIdMeta);
    }
    if (data.containsKey('cuenta_id')) {
      context.handle(
        _cuentaIdMeta,
        cuentaId.isAcceptableOrUnknown(data['cuenta_id']!, _cuentaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cuentaIdMeta);
    }
    if (data.containsKey('cuenta_destino_id')) {
      context.handle(
        _cuentaDestinoIdMeta,
        cuentaDestinoId.isAcceptableOrUnknown(
          data['cuenta_destino_id']!,
          _cuentaDestinoIdMeta,
        ),
      );
    }
    if (data.containsKey('monto_centimos')) {
      context.handle(
        _montoCentimosMeta,
        montoCentimos.isAcceptableOrUnknown(
          data['monto_centimos']!,
          _montoCentimosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoCentimosMeta);
    }
    if (data.containsKey('fecha_movimiento')) {
      context.handle(
        _fechaMovimientoMeta,
        fechaMovimiento.isAcceptableOrUnknown(
          data['fecha_movimiento']!,
          _fechaMovimientoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaMovimientoMeta);
    }
    if (data.containsKey('fecha_comprobante')) {
      context.handle(
        _fechaComprobanteMeta,
        fechaComprobante.isAcceptableOrUnknown(
          data['fecha_comprobante']!,
          _fechaComprobanteMeta,
        ),
      );
    }
    if (data.containsKey('monto_pagado_centimos')) {
      context.handle(
        _montoPagadoCentimosMeta,
        montoPagadoCentimos.isAcceptableOrUnknown(
          data['monto_pagado_centimos']!,
          _montoPagadoCentimosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoPagadoCentimosMeta);
    }
    if (data.containsKey('fecha_vencimiento')) {
      context.handle(
        _fechaVencimientoMeta,
        fechaVencimiento.isAcceptableOrUnknown(
          data['fecha_vencimiento']!,
          _fechaVencimientoMeta,
        ),
      );
    }
    if (data.containsKey('fecha_pago')) {
      context.handle(
        _fechaPagoMeta,
        fechaPago.isAcceptableOrUnknown(data['fecha_pago']!, _fechaPagoMeta),
      );
    }
    if (data.containsKey('categoria_id')) {
      context.handle(
        _categoriaIdMeta,
        categoriaId.isAcceptableOrUnknown(
          data['categoria_id']!,
          _categoriaIdMeta,
        ),
      );
    }
    if (data.containsKey('contraparte_id')) {
      context.handle(
        _contraparteIdMeta,
        contraparteId.isAcceptableOrUnknown(
          data['contraparte_id']!,
          _contraparteIdMeta,
        ),
      );
    }
    if (data.containsKey('comprobante_id')) {
      context.handle(
        _comprobanteIdMeta,
        comprobanteId.isAcceptableOrUnknown(
          data['comprobante_id']!,
          _comprobanteIdMeta,
        ),
      );
    }
    if (data.containsKey('autor_id')) {
      context.handle(
        _autorIdMeta,
        autorId.isAcceptableOrUnknown(data['autor_id']!, _autorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_autorIdMeta);
    }
    if (data.containsKey('nota')) {
      context.handle(
        _notaMeta,
        nota.isAcceptableOrUnknown(data['nota']!, _notaMeta),
      );
    }
    if (data.containsKey('reemplaza_a')) {
      context.handle(
        _reemplazaAMeta,
        reemplazaA.isAcceptableOrUnknown(data['reemplaza_a']!, _reemplazaAMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Movimiento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movimiento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      empresaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_id'],
      )!,
      tipo: $MovimientosTable.$convertertipo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo'],
        )!,
      ),
      cuentaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuenta_id'],
      )!,
      cuentaDestinoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuenta_destino_id'],
      ),
      montoCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monto_centimos'],
      )!,
      fechaMovimiento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_movimiento'],
      )!,
      fechaComprobante: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_comprobante'],
      ),
      estadoPago: $MovimientosTable.$converterestadoPago.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}estado_pago'],
        )!,
      ),
      montoPagadoCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monto_pagado_centimos'],
      )!,
      fechaVencimiento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_vencimiento'],
      ),
      fechaPago: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_pago'],
      ),
      categoriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria_id'],
      ),
      contraparteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contraparte_id'],
      ),
      comprobanteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comprobante_id'],
      ),
      nivelConfianza: $MovimientosTable.$converternivelConfianza.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}nivel_confianza'],
        )!,
      ),
      fuente: $MovimientosTable.$converterfuente.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fuente'],
        )!,
      ),
      autorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}autor_id'],
      )!,
      nota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nota'],
      ),
      estado: $MovimientosTable.$converterestado.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}estado'],
        )!,
      ),
      reemplazaA: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reemplaza_a'],
      ),
      estadoSincronizacion: $MovimientosTable.$converterestadoSincronizacion
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}estado_sincronizacion'],
            )!,
          ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $MovimientosTable createAlias(String alias) {
    return $MovimientosTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TipoMovimiento, String, String> $convertertipo =
      const EnumNameConverter<TipoMovimiento>(TipoMovimiento.values);
  static JsonTypeConverter2<EstadoPago, String, String> $converterestadoPago =
      const EnumNameConverter<EstadoPago>(EstadoPago.values);
  static JsonTypeConverter2<NivelConfianza, String, String>
  $converternivelConfianza = const EnumNameConverter<NivelConfianza>(
    NivelConfianza.values,
  );
  static JsonTypeConverter2<Fuente, String, String> $converterfuente =
      const EnumNameConverter<Fuente>(Fuente.values);
  static JsonTypeConverter2<EstadoRegistro, String, String> $converterestado =
      const EnumNameConverter<EstadoRegistro>(EstadoRegistro.values);
  static JsonTypeConverter2<EstadoSincronizacion, String, String>
  $converterestadoSincronizacion =
      const EnumNameConverter<EstadoSincronizacion>(
        EstadoSincronizacion.values,
      );
}

class Movimiento extends DataClass implements Insertable<Movimiento> {
  final String id;
  final String empresaId;
  final TipoMovimiento tipo;
  final String cuentaId;

  /// A dónde fue la plata en un pase de una cuenta a otra (entrega 21.1).
  final String? cuentaDestinoId;
  final int montoCentimos;
  final DateTime fechaMovimiento;
  final DateTime? fechaComprobante;
  final EstadoPago estadoPago;
  final int montoPagadoCentimos;
  final DateTime? fechaVencimiento;

  /// Cuándo salió la plata de la cuenta; nulo mientras se debe.
  final DateTime? fechaPago;
  final String? categoriaId;
  final String? contraparteId;
  final String? comprobanteId;
  final NivelConfianza nivelConfianza;
  final Fuente fuente;
  final String autorId;
  final String? nota;
  final EstadoRegistro estado;

  /// En una edición, el movimiento anulado que este reemplaza.
  final String? reemplazaA;
  final EstadoSincronizacion estadoSincronizacion;
  final DateTime creadoEn;
  const Movimiento({
    required this.id,
    required this.empresaId,
    required this.tipo,
    required this.cuentaId,
    this.cuentaDestinoId,
    required this.montoCentimos,
    required this.fechaMovimiento,
    this.fechaComprobante,
    required this.estadoPago,
    required this.montoPagadoCentimos,
    this.fechaVencimiento,
    this.fechaPago,
    this.categoriaId,
    this.contraparteId,
    this.comprobanteId,
    required this.nivelConfianza,
    required this.fuente,
    required this.autorId,
    this.nota,
    required this.estado,
    this.reemplazaA,
    required this.estadoSincronizacion,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['empresa_id'] = Variable<String>(empresaId);
    {
      map['tipo'] = Variable<String>(
        $MovimientosTable.$convertertipo.toSql(tipo),
      );
    }
    map['cuenta_id'] = Variable<String>(cuentaId);
    if (!nullToAbsent || cuentaDestinoId != null) {
      map['cuenta_destino_id'] = Variable<String>(cuentaDestinoId);
    }
    map['monto_centimos'] = Variable<int>(montoCentimos);
    map['fecha_movimiento'] = Variable<DateTime>(fechaMovimiento);
    if (!nullToAbsent || fechaComprobante != null) {
      map['fecha_comprobante'] = Variable<DateTime>(fechaComprobante);
    }
    {
      map['estado_pago'] = Variable<String>(
        $MovimientosTable.$converterestadoPago.toSql(estadoPago),
      );
    }
    map['monto_pagado_centimos'] = Variable<int>(montoPagadoCentimos);
    if (!nullToAbsent || fechaVencimiento != null) {
      map['fecha_vencimiento'] = Variable<DateTime>(fechaVencimiento);
    }
    if (!nullToAbsent || fechaPago != null) {
      map['fecha_pago'] = Variable<DateTime>(fechaPago);
    }
    if (!nullToAbsent || categoriaId != null) {
      map['categoria_id'] = Variable<String>(categoriaId);
    }
    if (!nullToAbsent || contraparteId != null) {
      map['contraparte_id'] = Variable<String>(contraparteId);
    }
    if (!nullToAbsent || comprobanteId != null) {
      map['comprobante_id'] = Variable<String>(comprobanteId);
    }
    {
      map['nivel_confianza'] = Variable<String>(
        $MovimientosTable.$converternivelConfianza.toSql(nivelConfianza),
      );
    }
    {
      map['fuente'] = Variable<String>(
        $MovimientosTable.$converterfuente.toSql(fuente),
      );
    }
    map['autor_id'] = Variable<String>(autorId);
    if (!nullToAbsent || nota != null) {
      map['nota'] = Variable<String>(nota);
    }
    {
      map['estado'] = Variable<String>(
        $MovimientosTable.$converterestado.toSql(estado),
      );
    }
    if (!nullToAbsent || reemplazaA != null) {
      map['reemplaza_a'] = Variable<String>(reemplazaA);
    }
    {
      map['estado_sincronizacion'] = Variable<String>(
        $MovimientosTable.$converterestadoSincronizacion.toSql(
          estadoSincronizacion,
        ),
      );
    }
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  MovimientosCompanion toCompanion(bool nullToAbsent) {
    return MovimientosCompanion(
      id: Value(id),
      empresaId: Value(empresaId),
      tipo: Value(tipo),
      cuentaId: Value(cuentaId),
      cuentaDestinoId: cuentaDestinoId == null && nullToAbsent
          ? const Value.absent()
          : Value(cuentaDestinoId),
      montoCentimos: Value(montoCentimos),
      fechaMovimiento: Value(fechaMovimiento),
      fechaComprobante: fechaComprobante == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaComprobante),
      estadoPago: Value(estadoPago),
      montoPagadoCentimos: Value(montoPagadoCentimos),
      fechaVencimiento: fechaVencimiento == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaVencimiento),
      fechaPago: fechaPago == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaPago),
      categoriaId: categoriaId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoriaId),
      contraparteId: contraparteId == null && nullToAbsent
          ? const Value.absent()
          : Value(contraparteId),
      comprobanteId: comprobanteId == null && nullToAbsent
          ? const Value.absent()
          : Value(comprobanteId),
      nivelConfianza: Value(nivelConfianza),
      fuente: Value(fuente),
      autorId: Value(autorId),
      nota: nota == null && nullToAbsent ? const Value.absent() : Value(nota),
      estado: Value(estado),
      reemplazaA: reemplazaA == null && nullToAbsent
          ? const Value.absent()
          : Value(reemplazaA),
      estadoSincronizacion: Value(estadoSincronizacion),
      creadoEn: Value(creadoEn),
    );
  }

  factory Movimiento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Movimiento(
      id: serializer.fromJson<String>(json['id']),
      empresaId: serializer.fromJson<String>(json['empresaId']),
      tipo: $MovimientosTable.$convertertipo.fromJson(
        serializer.fromJson<String>(json['tipo']),
      ),
      cuentaId: serializer.fromJson<String>(json['cuentaId']),
      cuentaDestinoId: serializer.fromJson<String?>(json['cuentaDestinoId']),
      montoCentimos: serializer.fromJson<int>(json['montoCentimos']),
      fechaMovimiento: serializer.fromJson<DateTime>(json['fechaMovimiento']),
      fechaComprobante: serializer.fromJson<DateTime?>(
        json['fechaComprobante'],
      ),
      estadoPago: $MovimientosTable.$converterestadoPago.fromJson(
        serializer.fromJson<String>(json['estadoPago']),
      ),
      montoPagadoCentimos: serializer.fromJson<int>(
        json['montoPagadoCentimos'],
      ),
      fechaVencimiento: serializer.fromJson<DateTime?>(
        json['fechaVencimiento'],
      ),
      fechaPago: serializer.fromJson<DateTime?>(json['fechaPago']),
      categoriaId: serializer.fromJson<String?>(json['categoriaId']),
      contraparteId: serializer.fromJson<String?>(json['contraparteId']),
      comprobanteId: serializer.fromJson<String?>(json['comprobanteId']),
      nivelConfianza: $MovimientosTable.$converternivelConfianza.fromJson(
        serializer.fromJson<String>(json['nivelConfianza']),
      ),
      fuente: $MovimientosTable.$converterfuente.fromJson(
        serializer.fromJson<String>(json['fuente']),
      ),
      autorId: serializer.fromJson<String>(json['autorId']),
      nota: serializer.fromJson<String?>(json['nota']),
      estado: $MovimientosTable.$converterestado.fromJson(
        serializer.fromJson<String>(json['estado']),
      ),
      reemplazaA: serializer.fromJson<String?>(json['reemplazaA']),
      estadoSincronizacion: $MovimientosTable.$converterestadoSincronizacion
          .fromJson(serializer.fromJson<String>(json['estadoSincronizacion'])),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'empresaId': serializer.toJson<String>(empresaId),
      'tipo': serializer.toJson<String>(
        $MovimientosTable.$convertertipo.toJson(tipo),
      ),
      'cuentaId': serializer.toJson<String>(cuentaId),
      'cuentaDestinoId': serializer.toJson<String?>(cuentaDestinoId),
      'montoCentimos': serializer.toJson<int>(montoCentimos),
      'fechaMovimiento': serializer.toJson<DateTime>(fechaMovimiento),
      'fechaComprobante': serializer.toJson<DateTime?>(fechaComprobante),
      'estadoPago': serializer.toJson<String>(
        $MovimientosTable.$converterestadoPago.toJson(estadoPago),
      ),
      'montoPagadoCentimos': serializer.toJson<int>(montoPagadoCentimos),
      'fechaVencimiento': serializer.toJson<DateTime?>(fechaVencimiento),
      'fechaPago': serializer.toJson<DateTime?>(fechaPago),
      'categoriaId': serializer.toJson<String?>(categoriaId),
      'contraparteId': serializer.toJson<String?>(contraparteId),
      'comprobanteId': serializer.toJson<String?>(comprobanteId),
      'nivelConfianza': serializer.toJson<String>(
        $MovimientosTable.$converternivelConfianza.toJson(nivelConfianza),
      ),
      'fuente': serializer.toJson<String>(
        $MovimientosTable.$converterfuente.toJson(fuente),
      ),
      'autorId': serializer.toJson<String>(autorId),
      'nota': serializer.toJson<String?>(nota),
      'estado': serializer.toJson<String>(
        $MovimientosTable.$converterestado.toJson(estado),
      ),
      'reemplazaA': serializer.toJson<String?>(reemplazaA),
      'estadoSincronizacion': serializer.toJson<String>(
        $MovimientosTable.$converterestadoSincronizacion.toJson(
          estadoSincronizacion,
        ),
      ),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  Movimiento copyWith({
    String? id,
    String? empresaId,
    TipoMovimiento? tipo,
    String? cuentaId,
    Value<String?> cuentaDestinoId = const Value.absent(),
    int? montoCentimos,
    DateTime? fechaMovimiento,
    Value<DateTime?> fechaComprobante = const Value.absent(),
    EstadoPago? estadoPago,
    int? montoPagadoCentimos,
    Value<DateTime?> fechaVencimiento = const Value.absent(),
    Value<DateTime?> fechaPago = const Value.absent(),
    Value<String?> categoriaId = const Value.absent(),
    Value<String?> contraparteId = const Value.absent(),
    Value<String?> comprobanteId = const Value.absent(),
    NivelConfianza? nivelConfianza,
    Fuente? fuente,
    String? autorId,
    Value<String?> nota = const Value.absent(),
    EstadoRegistro? estado,
    Value<String?> reemplazaA = const Value.absent(),
    EstadoSincronizacion? estadoSincronizacion,
    DateTime? creadoEn,
  }) => Movimiento(
    id: id ?? this.id,
    empresaId: empresaId ?? this.empresaId,
    tipo: tipo ?? this.tipo,
    cuentaId: cuentaId ?? this.cuentaId,
    cuentaDestinoId: cuentaDestinoId.present
        ? cuentaDestinoId.value
        : this.cuentaDestinoId,
    montoCentimos: montoCentimos ?? this.montoCentimos,
    fechaMovimiento: fechaMovimiento ?? this.fechaMovimiento,
    fechaComprobante: fechaComprobante.present
        ? fechaComprobante.value
        : this.fechaComprobante,
    estadoPago: estadoPago ?? this.estadoPago,
    montoPagadoCentimos: montoPagadoCentimos ?? this.montoPagadoCentimos,
    fechaVencimiento: fechaVencimiento.present
        ? fechaVencimiento.value
        : this.fechaVencimiento,
    fechaPago: fechaPago.present ? fechaPago.value : this.fechaPago,
    categoriaId: categoriaId.present ? categoriaId.value : this.categoriaId,
    contraparteId: contraparteId.present
        ? contraparteId.value
        : this.contraparteId,
    comprobanteId: comprobanteId.present
        ? comprobanteId.value
        : this.comprobanteId,
    nivelConfianza: nivelConfianza ?? this.nivelConfianza,
    fuente: fuente ?? this.fuente,
    autorId: autorId ?? this.autorId,
    nota: nota.present ? nota.value : this.nota,
    estado: estado ?? this.estado,
    reemplazaA: reemplazaA.present ? reemplazaA.value : this.reemplazaA,
    estadoSincronizacion: estadoSincronizacion ?? this.estadoSincronizacion,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  Movimiento copyWithCompanion(MovimientosCompanion data) {
    return Movimiento(
      id: data.id.present ? data.id.value : this.id,
      empresaId: data.empresaId.present ? data.empresaId.value : this.empresaId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      cuentaId: data.cuentaId.present ? data.cuentaId.value : this.cuentaId,
      cuentaDestinoId: data.cuentaDestinoId.present
          ? data.cuentaDestinoId.value
          : this.cuentaDestinoId,
      montoCentimos: data.montoCentimos.present
          ? data.montoCentimos.value
          : this.montoCentimos,
      fechaMovimiento: data.fechaMovimiento.present
          ? data.fechaMovimiento.value
          : this.fechaMovimiento,
      fechaComprobante: data.fechaComprobante.present
          ? data.fechaComprobante.value
          : this.fechaComprobante,
      estadoPago: data.estadoPago.present
          ? data.estadoPago.value
          : this.estadoPago,
      montoPagadoCentimos: data.montoPagadoCentimos.present
          ? data.montoPagadoCentimos.value
          : this.montoPagadoCentimos,
      fechaVencimiento: data.fechaVencimiento.present
          ? data.fechaVencimiento.value
          : this.fechaVencimiento,
      fechaPago: data.fechaPago.present ? data.fechaPago.value : this.fechaPago,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      contraparteId: data.contraparteId.present
          ? data.contraparteId.value
          : this.contraparteId,
      comprobanteId: data.comprobanteId.present
          ? data.comprobanteId.value
          : this.comprobanteId,
      nivelConfianza: data.nivelConfianza.present
          ? data.nivelConfianza.value
          : this.nivelConfianza,
      fuente: data.fuente.present ? data.fuente.value : this.fuente,
      autorId: data.autorId.present ? data.autorId.value : this.autorId,
      nota: data.nota.present ? data.nota.value : this.nota,
      estado: data.estado.present ? data.estado.value : this.estado,
      reemplazaA: data.reemplazaA.present
          ? data.reemplazaA.value
          : this.reemplazaA,
      estadoSincronizacion: data.estadoSincronizacion.present
          ? data.estadoSincronizacion.value
          : this.estadoSincronizacion,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Movimiento(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('tipo: $tipo, ')
          ..write('cuentaId: $cuentaId, ')
          ..write('cuentaDestinoId: $cuentaDestinoId, ')
          ..write('montoCentimos: $montoCentimos, ')
          ..write('fechaMovimiento: $fechaMovimiento, ')
          ..write('fechaComprobante: $fechaComprobante, ')
          ..write('estadoPago: $estadoPago, ')
          ..write('montoPagadoCentimos: $montoPagadoCentimos, ')
          ..write('fechaVencimiento: $fechaVencimiento, ')
          ..write('fechaPago: $fechaPago, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('contraparteId: $contraparteId, ')
          ..write('comprobanteId: $comprobanteId, ')
          ..write('nivelConfianza: $nivelConfianza, ')
          ..write('fuente: $fuente, ')
          ..write('autorId: $autorId, ')
          ..write('nota: $nota, ')
          ..write('estado: $estado, ')
          ..write('reemplazaA: $reemplazaA, ')
          ..write('estadoSincronizacion: $estadoSincronizacion, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    empresaId,
    tipo,
    cuentaId,
    cuentaDestinoId,
    montoCentimos,
    fechaMovimiento,
    fechaComprobante,
    estadoPago,
    montoPagadoCentimos,
    fechaVencimiento,
    fechaPago,
    categoriaId,
    contraparteId,
    comprobanteId,
    nivelConfianza,
    fuente,
    autorId,
    nota,
    estado,
    reemplazaA,
    estadoSincronizacion,
    creadoEn,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Movimiento &&
          other.id == this.id &&
          other.empresaId == this.empresaId &&
          other.tipo == this.tipo &&
          other.cuentaId == this.cuentaId &&
          other.cuentaDestinoId == this.cuentaDestinoId &&
          other.montoCentimos == this.montoCentimos &&
          other.fechaMovimiento == this.fechaMovimiento &&
          other.fechaComprobante == this.fechaComprobante &&
          other.estadoPago == this.estadoPago &&
          other.montoPagadoCentimos == this.montoPagadoCentimos &&
          other.fechaVencimiento == this.fechaVencimiento &&
          other.fechaPago == this.fechaPago &&
          other.categoriaId == this.categoriaId &&
          other.contraparteId == this.contraparteId &&
          other.comprobanteId == this.comprobanteId &&
          other.nivelConfianza == this.nivelConfianza &&
          other.fuente == this.fuente &&
          other.autorId == this.autorId &&
          other.nota == this.nota &&
          other.estado == this.estado &&
          other.reemplazaA == this.reemplazaA &&
          other.estadoSincronizacion == this.estadoSincronizacion &&
          other.creadoEn == this.creadoEn);
}

class MovimientosCompanion extends UpdateCompanion<Movimiento> {
  final Value<String> id;
  final Value<String> empresaId;
  final Value<TipoMovimiento> tipo;
  final Value<String> cuentaId;
  final Value<String?> cuentaDestinoId;
  final Value<int> montoCentimos;
  final Value<DateTime> fechaMovimiento;
  final Value<DateTime?> fechaComprobante;
  final Value<EstadoPago> estadoPago;
  final Value<int> montoPagadoCentimos;
  final Value<DateTime?> fechaVencimiento;
  final Value<DateTime?> fechaPago;
  final Value<String?> categoriaId;
  final Value<String?> contraparteId;
  final Value<String?> comprobanteId;
  final Value<NivelConfianza> nivelConfianza;
  final Value<Fuente> fuente;
  final Value<String> autorId;
  final Value<String?> nota;
  final Value<EstadoRegistro> estado;
  final Value<String?> reemplazaA;
  final Value<EstadoSincronizacion> estadoSincronizacion;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const MovimientosCompanion({
    this.id = const Value.absent(),
    this.empresaId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.cuentaId = const Value.absent(),
    this.cuentaDestinoId = const Value.absent(),
    this.montoCentimos = const Value.absent(),
    this.fechaMovimiento = const Value.absent(),
    this.fechaComprobante = const Value.absent(),
    this.estadoPago = const Value.absent(),
    this.montoPagadoCentimos = const Value.absent(),
    this.fechaVencimiento = const Value.absent(),
    this.fechaPago = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.contraparteId = const Value.absent(),
    this.comprobanteId = const Value.absent(),
    this.nivelConfianza = const Value.absent(),
    this.fuente = const Value.absent(),
    this.autorId = const Value.absent(),
    this.nota = const Value.absent(),
    this.estado = const Value.absent(),
    this.reemplazaA = const Value.absent(),
    this.estadoSincronizacion = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovimientosCompanion.insert({
    required String id,
    required String empresaId,
    required TipoMovimiento tipo,
    required String cuentaId,
    this.cuentaDestinoId = const Value.absent(),
    required int montoCentimos,
    required DateTime fechaMovimiento,
    this.fechaComprobante = const Value.absent(),
    required EstadoPago estadoPago,
    required int montoPagadoCentimos,
    this.fechaVencimiento = const Value.absent(),
    this.fechaPago = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.contraparteId = const Value.absent(),
    this.comprobanteId = const Value.absent(),
    required NivelConfianza nivelConfianza,
    required Fuente fuente,
    required String autorId,
    this.nota = const Value.absent(),
    required EstadoRegistro estado,
    this.reemplazaA = const Value.absent(),
    required EstadoSincronizacion estadoSincronizacion,
    required DateTime creadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       empresaId = Value(empresaId),
       tipo = Value(tipo),
       cuentaId = Value(cuentaId),
       montoCentimos = Value(montoCentimos),
       fechaMovimiento = Value(fechaMovimiento),
       estadoPago = Value(estadoPago),
       montoPagadoCentimos = Value(montoPagadoCentimos),
       nivelConfianza = Value(nivelConfianza),
       fuente = Value(fuente),
       autorId = Value(autorId),
       estado = Value(estado),
       estadoSincronizacion = Value(estadoSincronizacion),
       creadoEn = Value(creadoEn);
  static Insertable<Movimiento> custom({
    Expression<String>? id,
    Expression<String>? empresaId,
    Expression<String>? tipo,
    Expression<String>? cuentaId,
    Expression<String>? cuentaDestinoId,
    Expression<int>? montoCentimos,
    Expression<DateTime>? fechaMovimiento,
    Expression<DateTime>? fechaComprobante,
    Expression<String>? estadoPago,
    Expression<int>? montoPagadoCentimos,
    Expression<DateTime>? fechaVencimiento,
    Expression<DateTime>? fechaPago,
    Expression<String>? categoriaId,
    Expression<String>? contraparteId,
    Expression<String>? comprobanteId,
    Expression<String>? nivelConfianza,
    Expression<String>? fuente,
    Expression<String>? autorId,
    Expression<String>? nota,
    Expression<String>? estado,
    Expression<String>? reemplazaA,
    Expression<String>? estadoSincronizacion,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      if (tipo != null) 'tipo': tipo,
      if (cuentaId != null) 'cuenta_id': cuentaId,
      if (cuentaDestinoId != null) 'cuenta_destino_id': cuentaDestinoId,
      if (montoCentimos != null) 'monto_centimos': montoCentimos,
      if (fechaMovimiento != null) 'fecha_movimiento': fechaMovimiento,
      if (fechaComprobante != null) 'fecha_comprobante': fechaComprobante,
      if (estadoPago != null) 'estado_pago': estadoPago,
      if (montoPagadoCentimos != null)
        'monto_pagado_centimos': montoPagadoCentimos,
      if (fechaVencimiento != null) 'fecha_vencimiento': fechaVencimiento,
      if (fechaPago != null) 'fecha_pago': fechaPago,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (contraparteId != null) 'contraparte_id': contraparteId,
      if (comprobanteId != null) 'comprobante_id': comprobanteId,
      if (nivelConfianza != null) 'nivel_confianza': nivelConfianza,
      if (fuente != null) 'fuente': fuente,
      if (autorId != null) 'autor_id': autorId,
      if (nota != null) 'nota': nota,
      if (estado != null) 'estado': estado,
      if (reemplazaA != null) 'reemplaza_a': reemplazaA,
      if (estadoSincronizacion != null)
        'estado_sincronizacion': estadoSincronizacion,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovimientosCompanion copyWith({
    Value<String>? id,
    Value<String>? empresaId,
    Value<TipoMovimiento>? tipo,
    Value<String>? cuentaId,
    Value<String?>? cuentaDestinoId,
    Value<int>? montoCentimos,
    Value<DateTime>? fechaMovimiento,
    Value<DateTime?>? fechaComprobante,
    Value<EstadoPago>? estadoPago,
    Value<int>? montoPagadoCentimos,
    Value<DateTime?>? fechaVencimiento,
    Value<DateTime?>? fechaPago,
    Value<String?>? categoriaId,
    Value<String?>? contraparteId,
    Value<String?>? comprobanteId,
    Value<NivelConfianza>? nivelConfianza,
    Value<Fuente>? fuente,
    Value<String>? autorId,
    Value<String?>? nota,
    Value<EstadoRegistro>? estado,
    Value<String?>? reemplazaA,
    Value<EstadoSincronizacion>? estadoSincronizacion,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return MovimientosCompanion(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      tipo: tipo ?? this.tipo,
      cuentaId: cuentaId ?? this.cuentaId,
      cuentaDestinoId: cuentaDestinoId ?? this.cuentaDestinoId,
      montoCentimos: montoCentimos ?? this.montoCentimos,
      fechaMovimiento: fechaMovimiento ?? this.fechaMovimiento,
      fechaComprobante: fechaComprobante ?? this.fechaComprobante,
      estadoPago: estadoPago ?? this.estadoPago,
      montoPagadoCentimos: montoPagadoCentimos ?? this.montoPagadoCentimos,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaPago: fechaPago ?? this.fechaPago,
      categoriaId: categoriaId ?? this.categoriaId,
      contraparteId: contraparteId ?? this.contraparteId,
      comprobanteId: comprobanteId ?? this.comprobanteId,
      nivelConfianza: nivelConfianza ?? this.nivelConfianza,
      fuente: fuente ?? this.fuente,
      autorId: autorId ?? this.autorId,
      nota: nota ?? this.nota,
      estado: estado ?? this.estado,
      reemplazaA: reemplazaA ?? this.reemplazaA,
      estadoSincronizacion: estadoSincronizacion ?? this.estadoSincronizacion,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (empresaId.present) {
      map['empresa_id'] = Variable<String>(empresaId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(
        $MovimientosTable.$convertertipo.toSql(tipo.value),
      );
    }
    if (cuentaId.present) {
      map['cuenta_id'] = Variable<String>(cuentaId.value);
    }
    if (cuentaDestinoId.present) {
      map['cuenta_destino_id'] = Variable<String>(cuentaDestinoId.value);
    }
    if (montoCentimos.present) {
      map['monto_centimos'] = Variable<int>(montoCentimos.value);
    }
    if (fechaMovimiento.present) {
      map['fecha_movimiento'] = Variable<DateTime>(fechaMovimiento.value);
    }
    if (fechaComprobante.present) {
      map['fecha_comprobante'] = Variable<DateTime>(fechaComprobante.value);
    }
    if (estadoPago.present) {
      map['estado_pago'] = Variable<String>(
        $MovimientosTable.$converterestadoPago.toSql(estadoPago.value),
      );
    }
    if (montoPagadoCentimos.present) {
      map['monto_pagado_centimos'] = Variable<int>(montoPagadoCentimos.value);
    }
    if (fechaVencimiento.present) {
      map['fecha_vencimiento'] = Variable<DateTime>(fechaVencimiento.value);
    }
    if (fechaPago.present) {
      map['fecha_pago'] = Variable<DateTime>(fechaPago.value);
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<String>(categoriaId.value);
    }
    if (contraparteId.present) {
      map['contraparte_id'] = Variable<String>(contraparteId.value);
    }
    if (comprobanteId.present) {
      map['comprobante_id'] = Variable<String>(comprobanteId.value);
    }
    if (nivelConfianza.present) {
      map['nivel_confianza'] = Variable<String>(
        $MovimientosTable.$converternivelConfianza.toSql(nivelConfianza.value),
      );
    }
    if (fuente.present) {
      map['fuente'] = Variable<String>(
        $MovimientosTable.$converterfuente.toSql(fuente.value),
      );
    }
    if (autorId.present) {
      map['autor_id'] = Variable<String>(autorId.value);
    }
    if (nota.present) {
      map['nota'] = Variable<String>(nota.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(
        $MovimientosTable.$converterestado.toSql(estado.value),
      );
    }
    if (reemplazaA.present) {
      map['reemplaza_a'] = Variable<String>(reemplazaA.value);
    }
    if (estadoSincronizacion.present) {
      map['estado_sincronizacion'] = Variable<String>(
        $MovimientosTable.$converterestadoSincronizacion.toSql(
          estadoSincronizacion.value,
        ),
      );
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosCompanion(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('tipo: $tipo, ')
          ..write('cuentaId: $cuentaId, ')
          ..write('cuentaDestinoId: $cuentaDestinoId, ')
          ..write('montoCentimos: $montoCentimos, ')
          ..write('fechaMovimiento: $fechaMovimiento, ')
          ..write('fechaComprobante: $fechaComprobante, ')
          ..write('estadoPago: $estadoPago, ')
          ..write('montoPagadoCentimos: $montoPagadoCentimos, ')
          ..write('fechaVencimiento: $fechaVencimiento, ')
          ..write('fechaPago: $fechaPago, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('contraparteId: $contraparteId, ')
          ..write('comprobanteId: $comprobanteId, ')
          ..write('nivelConfianza: $nivelConfianza, ')
          ..write('fuente: $fuente, ')
          ..write('autorId: $autorId, ')
          ..write('nota: $nota, ')
          ..write('estado: $estado, ')
          ..write('reemplazaA: $reemplazaA, ')
          ..write('estadoSincronizacion: $estadoSincronizacion, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArqueosTable extends Arqueos with TableInfo<$ArqueosTable, Arqueo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArqueosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empresaIdMeta = const VerificationMeta(
    'empresaId',
  );
  @override
  late final GeneratedColumn<String> empresaId = GeneratedColumn<String>(
    'empresa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES empresas (id)',
    ),
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autorIdMeta = const VerificationMeta(
    'autorId',
  );
  @override
  late final GeneratedColumn<String> autorId = GeneratedColumn<String>(
    'autor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES usuarios (id)',
    ),
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    empresaId,
    fecha,
    autorId,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'arqueos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Arqueo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('empresa_id')) {
      context.handle(
        _empresaIdMeta,
        empresaId.isAcceptableOrUnknown(data['empresa_id']!, _empresaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empresaIdMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('autor_id')) {
      context.handle(
        _autorIdMeta,
        autorId.isAcceptableOrUnknown(data['autor_id']!, _autorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_autorIdMeta);
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Arqueo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Arqueo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      empresaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      autorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}autor_id'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $ArqueosTable createAlias(String alias) {
    return $ArqueosTable(attachedDatabase, alias);
  }
}

class Arqueo extends DataClass implements Insertable<Arqueo> {
  final String id;
  final String empresaId;
  final DateTime fecha;
  final String autorId;
  final DateTime creadoEn;
  const Arqueo({
    required this.id,
    required this.empresaId,
    required this.fecha,
    required this.autorId,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['empresa_id'] = Variable<String>(empresaId);
    map['fecha'] = Variable<DateTime>(fecha);
    map['autor_id'] = Variable<String>(autorId);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  ArqueosCompanion toCompanion(bool nullToAbsent) {
    return ArqueosCompanion(
      id: Value(id),
      empresaId: Value(empresaId),
      fecha: Value(fecha),
      autorId: Value(autorId),
      creadoEn: Value(creadoEn),
    );
  }

  factory Arqueo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Arqueo(
      id: serializer.fromJson<String>(json['id']),
      empresaId: serializer.fromJson<String>(json['empresaId']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      autorId: serializer.fromJson<String>(json['autorId']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'empresaId': serializer.toJson<String>(empresaId),
      'fecha': serializer.toJson<DateTime>(fecha),
      'autorId': serializer.toJson<String>(autorId),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  Arqueo copyWith({
    String? id,
    String? empresaId,
    DateTime? fecha,
    String? autorId,
    DateTime? creadoEn,
  }) => Arqueo(
    id: id ?? this.id,
    empresaId: empresaId ?? this.empresaId,
    fecha: fecha ?? this.fecha,
    autorId: autorId ?? this.autorId,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  Arqueo copyWithCompanion(ArqueosCompanion data) {
    return Arqueo(
      id: data.id.present ? data.id.value : this.id,
      empresaId: data.empresaId.present ? data.empresaId.value : this.empresaId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      autorId: data.autorId.present ? data.autorId.value : this.autorId,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Arqueo(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('fecha: $fecha, ')
          ..write('autorId: $autorId, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, empresaId, fecha, autorId, creadoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Arqueo &&
          other.id == this.id &&
          other.empresaId == this.empresaId &&
          other.fecha == this.fecha &&
          other.autorId == this.autorId &&
          other.creadoEn == this.creadoEn);
}

class ArqueosCompanion extends UpdateCompanion<Arqueo> {
  final Value<String> id;
  final Value<String> empresaId;
  final Value<DateTime> fecha;
  final Value<String> autorId;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const ArqueosCompanion({
    this.id = const Value.absent(),
    this.empresaId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.autorId = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArqueosCompanion.insert({
    required String id,
    required String empresaId,
    required DateTime fecha,
    required String autorId,
    required DateTime creadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       empresaId = Value(empresaId),
       fecha = Value(fecha),
       autorId = Value(autorId),
       creadoEn = Value(creadoEn);
  static Insertable<Arqueo> custom({
    Expression<String>? id,
    Expression<String>? empresaId,
    Expression<DateTime>? fecha,
    Expression<String>? autorId,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      if (fecha != null) 'fecha': fecha,
      if (autorId != null) 'autor_id': autorId,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArqueosCompanion copyWith({
    Value<String>? id,
    Value<String>? empresaId,
    Value<DateTime>? fecha,
    Value<String>? autorId,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return ArqueosCompanion(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      fecha: fecha ?? this.fecha,
      autorId: autorId ?? this.autorId,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (empresaId.present) {
      map['empresa_id'] = Variable<String>(empresaId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (autorId.present) {
      map['autor_id'] = Variable<String>(autorId.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArqueosCompanion(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('fecha: $fecha, ')
          ..write('autorId: $autorId, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArqueoCuentasTable extends ArqueoCuentas
    with TableInfo<$ArqueoCuentasTable, ArqueoCuenta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArqueoCuentasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arqueoIdMeta = const VerificationMeta(
    'arqueoId',
  );
  @override
  late final GeneratedColumn<String> arqueoId = GeneratedColumn<String>(
    'arqueo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES arqueos (id)',
    ),
  );
  static const VerificationMeta _cuentaIdMeta = const VerificationMeta(
    'cuentaId',
  );
  @override
  late final GeneratedColumn<String> cuentaId = GeneratedColumn<String>(
    'cuenta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuentas (id)',
    ),
  );
  static const VerificationMeta _saldoCalculadoCentimosMeta =
      const VerificationMeta('saldoCalculadoCentimos');
  @override
  late final GeneratedColumn<int> saldoCalculadoCentimos = GeneratedColumn<int>(
    'saldo_calculado_centimos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saldoRealCentimosMeta = const VerificationMeta(
    'saldoRealCentimos',
  );
  @override
  late final GeneratedColumn<int> saldoRealCentimos = GeneratedColumn<int>(
    'saldo_real_centimos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diferenciaCentimosMeta =
      const VerificationMeta('diferenciaCentimos');
  @override
  late final GeneratedColumn<int> diferenciaCentimos = GeneratedColumn<int>(
    'diferencia_centimos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MotivoArqueo?, String> motivo =
      GeneratedColumn<String>(
        'motivo',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MotivoArqueo?>($ArqueoCuentasTable.$convertermotivon);
  static const VerificationMeta _movimientoIdMeta = const VerificationMeta(
    'movimientoId',
  );
  @override
  late final GeneratedColumn<String> movimientoId = GeneratedColumn<String>(
    'movimiento_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES movimientos (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    arqueoId,
    cuentaId,
    saldoCalculadoCentimos,
    saldoRealCentimos,
    diferenciaCentimos,
    motivo,
    movimientoId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'arqueo_cuentas';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArqueoCuenta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('arqueo_id')) {
      context.handle(
        _arqueoIdMeta,
        arqueoId.isAcceptableOrUnknown(data['arqueo_id']!, _arqueoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_arqueoIdMeta);
    }
    if (data.containsKey('cuenta_id')) {
      context.handle(
        _cuentaIdMeta,
        cuentaId.isAcceptableOrUnknown(data['cuenta_id']!, _cuentaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cuentaIdMeta);
    }
    if (data.containsKey('saldo_calculado_centimos')) {
      context.handle(
        _saldoCalculadoCentimosMeta,
        saldoCalculadoCentimos.isAcceptableOrUnknown(
          data['saldo_calculado_centimos']!,
          _saldoCalculadoCentimosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saldoCalculadoCentimosMeta);
    }
    if (data.containsKey('saldo_real_centimos')) {
      context.handle(
        _saldoRealCentimosMeta,
        saldoRealCentimos.isAcceptableOrUnknown(
          data['saldo_real_centimos']!,
          _saldoRealCentimosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saldoRealCentimosMeta);
    }
    if (data.containsKey('diferencia_centimos')) {
      context.handle(
        _diferenciaCentimosMeta,
        diferenciaCentimos.isAcceptableOrUnknown(
          data['diferencia_centimos']!,
          _diferenciaCentimosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_diferenciaCentimosMeta);
    }
    if (data.containsKey('movimiento_id')) {
      context.handle(
        _movimientoIdMeta,
        movimientoId.isAcceptableOrUnknown(
          data['movimiento_id']!,
          _movimientoIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArqueoCuenta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArqueoCuenta(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      arqueoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arqueo_id'],
      )!,
      cuentaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuenta_id'],
      )!,
      saldoCalculadoCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saldo_calculado_centimos'],
      )!,
      saldoRealCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saldo_real_centimos'],
      )!,
      diferenciaCentimos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}diferencia_centimos'],
      )!,
      motivo: $ArqueoCuentasTable.$convertermotivon.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}motivo'],
        ),
      ),
      movimientoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movimiento_id'],
      ),
    );
  }

  @override
  $ArqueoCuentasTable createAlias(String alias) {
    return $ArqueoCuentasTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MotivoArqueo, String, String> $convertermotivo =
      const EnumNameConverter<MotivoArqueo>(MotivoArqueo.values);
  static JsonTypeConverter2<MotivoArqueo?, String?, String?> $convertermotivon =
      JsonTypeConverter2.asNullable($convertermotivo);
}

class ArqueoCuenta extends DataClass implements Insertable<ArqueoCuenta> {
  final String id;
  final String arqueoId;
  final String cuentaId;
  final int saldoCalculadoCentimos;
  final int saldoRealCentimos;
  final int diferenciaCentimos;
  final MotivoArqueo? motivo;

  /// El movimiento que generó el motivo, si generó uno.
  final String? movimientoId;
  const ArqueoCuenta({
    required this.id,
    required this.arqueoId,
    required this.cuentaId,
    required this.saldoCalculadoCentimos,
    required this.saldoRealCentimos,
    required this.diferenciaCentimos,
    this.motivo,
    this.movimientoId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['arqueo_id'] = Variable<String>(arqueoId);
    map['cuenta_id'] = Variable<String>(cuentaId);
    map['saldo_calculado_centimos'] = Variable<int>(saldoCalculadoCentimos);
    map['saldo_real_centimos'] = Variable<int>(saldoRealCentimos);
    map['diferencia_centimos'] = Variable<int>(diferenciaCentimos);
    if (!nullToAbsent || motivo != null) {
      map['motivo'] = Variable<String>(
        $ArqueoCuentasTable.$convertermotivon.toSql(motivo),
      );
    }
    if (!nullToAbsent || movimientoId != null) {
      map['movimiento_id'] = Variable<String>(movimientoId);
    }
    return map;
  }

  ArqueoCuentasCompanion toCompanion(bool nullToAbsent) {
    return ArqueoCuentasCompanion(
      id: Value(id),
      arqueoId: Value(arqueoId),
      cuentaId: Value(cuentaId),
      saldoCalculadoCentimos: Value(saldoCalculadoCentimos),
      saldoRealCentimos: Value(saldoRealCentimos),
      diferenciaCentimos: Value(diferenciaCentimos),
      motivo: motivo == null && nullToAbsent
          ? const Value.absent()
          : Value(motivo),
      movimientoId: movimientoId == null && nullToAbsent
          ? const Value.absent()
          : Value(movimientoId),
    );
  }

  factory ArqueoCuenta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArqueoCuenta(
      id: serializer.fromJson<String>(json['id']),
      arqueoId: serializer.fromJson<String>(json['arqueoId']),
      cuentaId: serializer.fromJson<String>(json['cuentaId']),
      saldoCalculadoCentimos: serializer.fromJson<int>(
        json['saldoCalculadoCentimos'],
      ),
      saldoRealCentimos: serializer.fromJson<int>(json['saldoRealCentimos']),
      diferenciaCentimos: serializer.fromJson<int>(json['diferenciaCentimos']),
      motivo: $ArqueoCuentasTable.$convertermotivon.fromJson(
        serializer.fromJson<String?>(json['motivo']),
      ),
      movimientoId: serializer.fromJson<String?>(json['movimientoId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'arqueoId': serializer.toJson<String>(arqueoId),
      'cuentaId': serializer.toJson<String>(cuentaId),
      'saldoCalculadoCentimos': serializer.toJson<int>(saldoCalculadoCentimos),
      'saldoRealCentimos': serializer.toJson<int>(saldoRealCentimos),
      'diferenciaCentimos': serializer.toJson<int>(diferenciaCentimos),
      'motivo': serializer.toJson<String?>(
        $ArqueoCuentasTable.$convertermotivon.toJson(motivo),
      ),
      'movimientoId': serializer.toJson<String?>(movimientoId),
    };
  }

  ArqueoCuenta copyWith({
    String? id,
    String? arqueoId,
    String? cuentaId,
    int? saldoCalculadoCentimos,
    int? saldoRealCentimos,
    int? diferenciaCentimos,
    Value<MotivoArqueo?> motivo = const Value.absent(),
    Value<String?> movimientoId = const Value.absent(),
  }) => ArqueoCuenta(
    id: id ?? this.id,
    arqueoId: arqueoId ?? this.arqueoId,
    cuentaId: cuentaId ?? this.cuentaId,
    saldoCalculadoCentimos:
        saldoCalculadoCentimos ?? this.saldoCalculadoCentimos,
    saldoRealCentimos: saldoRealCentimos ?? this.saldoRealCentimos,
    diferenciaCentimos: diferenciaCentimos ?? this.diferenciaCentimos,
    motivo: motivo.present ? motivo.value : this.motivo,
    movimientoId: movimientoId.present ? movimientoId.value : this.movimientoId,
  );
  ArqueoCuenta copyWithCompanion(ArqueoCuentasCompanion data) {
    return ArqueoCuenta(
      id: data.id.present ? data.id.value : this.id,
      arqueoId: data.arqueoId.present ? data.arqueoId.value : this.arqueoId,
      cuentaId: data.cuentaId.present ? data.cuentaId.value : this.cuentaId,
      saldoCalculadoCentimos: data.saldoCalculadoCentimos.present
          ? data.saldoCalculadoCentimos.value
          : this.saldoCalculadoCentimos,
      saldoRealCentimos: data.saldoRealCentimos.present
          ? data.saldoRealCentimos.value
          : this.saldoRealCentimos,
      diferenciaCentimos: data.diferenciaCentimos.present
          ? data.diferenciaCentimos.value
          : this.diferenciaCentimos,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      movimientoId: data.movimientoId.present
          ? data.movimientoId.value
          : this.movimientoId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArqueoCuenta(')
          ..write('id: $id, ')
          ..write('arqueoId: $arqueoId, ')
          ..write('cuentaId: $cuentaId, ')
          ..write('saldoCalculadoCentimos: $saldoCalculadoCentimos, ')
          ..write('saldoRealCentimos: $saldoRealCentimos, ')
          ..write('diferenciaCentimos: $diferenciaCentimos, ')
          ..write('motivo: $motivo, ')
          ..write('movimientoId: $movimientoId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    arqueoId,
    cuentaId,
    saldoCalculadoCentimos,
    saldoRealCentimos,
    diferenciaCentimos,
    motivo,
    movimientoId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArqueoCuenta &&
          other.id == this.id &&
          other.arqueoId == this.arqueoId &&
          other.cuentaId == this.cuentaId &&
          other.saldoCalculadoCentimos == this.saldoCalculadoCentimos &&
          other.saldoRealCentimos == this.saldoRealCentimos &&
          other.diferenciaCentimos == this.diferenciaCentimos &&
          other.motivo == this.motivo &&
          other.movimientoId == this.movimientoId);
}

class ArqueoCuentasCompanion extends UpdateCompanion<ArqueoCuenta> {
  final Value<String> id;
  final Value<String> arqueoId;
  final Value<String> cuentaId;
  final Value<int> saldoCalculadoCentimos;
  final Value<int> saldoRealCentimos;
  final Value<int> diferenciaCentimos;
  final Value<MotivoArqueo?> motivo;
  final Value<String?> movimientoId;
  final Value<int> rowid;
  const ArqueoCuentasCompanion({
    this.id = const Value.absent(),
    this.arqueoId = const Value.absent(),
    this.cuentaId = const Value.absent(),
    this.saldoCalculadoCentimos = const Value.absent(),
    this.saldoRealCentimos = const Value.absent(),
    this.diferenciaCentimos = const Value.absent(),
    this.motivo = const Value.absent(),
    this.movimientoId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArqueoCuentasCompanion.insert({
    required String id,
    required String arqueoId,
    required String cuentaId,
    required int saldoCalculadoCentimos,
    required int saldoRealCentimos,
    required int diferenciaCentimos,
    this.motivo = const Value.absent(),
    this.movimientoId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       arqueoId = Value(arqueoId),
       cuentaId = Value(cuentaId),
       saldoCalculadoCentimos = Value(saldoCalculadoCentimos),
       saldoRealCentimos = Value(saldoRealCentimos),
       diferenciaCentimos = Value(diferenciaCentimos);
  static Insertable<ArqueoCuenta> custom({
    Expression<String>? id,
    Expression<String>? arqueoId,
    Expression<String>? cuentaId,
    Expression<int>? saldoCalculadoCentimos,
    Expression<int>? saldoRealCentimos,
    Expression<int>? diferenciaCentimos,
    Expression<String>? motivo,
    Expression<String>? movimientoId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (arqueoId != null) 'arqueo_id': arqueoId,
      if (cuentaId != null) 'cuenta_id': cuentaId,
      if (saldoCalculadoCentimos != null)
        'saldo_calculado_centimos': saldoCalculadoCentimos,
      if (saldoRealCentimos != null) 'saldo_real_centimos': saldoRealCentimos,
      if (diferenciaCentimos != null) 'diferencia_centimos': diferenciaCentimos,
      if (motivo != null) 'motivo': motivo,
      if (movimientoId != null) 'movimiento_id': movimientoId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArqueoCuentasCompanion copyWith({
    Value<String>? id,
    Value<String>? arqueoId,
    Value<String>? cuentaId,
    Value<int>? saldoCalculadoCentimos,
    Value<int>? saldoRealCentimos,
    Value<int>? diferenciaCentimos,
    Value<MotivoArqueo?>? motivo,
    Value<String?>? movimientoId,
    Value<int>? rowid,
  }) {
    return ArqueoCuentasCompanion(
      id: id ?? this.id,
      arqueoId: arqueoId ?? this.arqueoId,
      cuentaId: cuentaId ?? this.cuentaId,
      saldoCalculadoCentimos:
          saldoCalculadoCentimos ?? this.saldoCalculadoCentimos,
      saldoRealCentimos: saldoRealCentimos ?? this.saldoRealCentimos,
      diferenciaCentimos: diferenciaCentimos ?? this.diferenciaCentimos,
      motivo: motivo ?? this.motivo,
      movimientoId: movimientoId ?? this.movimientoId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (arqueoId.present) {
      map['arqueo_id'] = Variable<String>(arqueoId.value);
    }
    if (cuentaId.present) {
      map['cuenta_id'] = Variable<String>(cuentaId.value);
    }
    if (saldoCalculadoCentimos.present) {
      map['saldo_calculado_centimos'] = Variable<int>(
        saldoCalculadoCentimos.value,
      );
    }
    if (saldoRealCentimos.present) {
      map['saldo_real_centimos'] = Variable<int>(saldoRealCentimos.value);
    }
    if (diferenciaCentimos.present) {
      map['diferencia_centimos'] = Variable<int>(diferenciaCentimos.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(
        $ArqueoCuentasTable.$convertermotivon.toSql(motivo.value),
      );
    }
    if (movimientoId.present) {
      map['movimiento_id'] = Variable<String>(movimientoId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArqueoCuentasCompanion(')
          ..write('id: $id, ')
          ..write('arqueoId: $arqueoId, ')
          ..write('cuentaId: $cuentaId, ')
          ..write('saldoCalculadoCentimos: $saldoCalculadoCentimos, ')
          ..write('saldoRealCentimos: $saldoRealCentimos, ')
          ..write('diferenciaCentimos: $diferenciaCentimos, ')
          ..write('motivo: $motivo, ')
          ..write('movimientoId: $movimientoId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertasTable extends Alertas with TableInfo<$AlertasTable, Alerta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empresaIdMeta = const VerificationMeta(
    'empresaId',
  );
  @override
  late final GeneratedColumn<String> empresaId = GeneratedColumn<String>(
    'empresa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES empresas (id)',
    ),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PrioridadAlerta, String>
  prioridad = GeneratedColumn<String>(
    'prioridad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PrioridadAlerta>($AlertasTable.$converterprioridad);
  @override
  late final GeneratedColumnWithTypeConverter<EstadoAlerta, String> estado =
      GeneratedColumn<String>(
        'estado',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EstadoAlerta>($AlertasTable.$converterestado);
  static const VerificationMeta _textoMeta = const VerificationMeta('texto');
  @override
  late final GeneratedColumn<String> texto = GeneratedColumn<String>(
    'texto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _datosMeta = const VerificationMeta('datos');
  @override
  late final GeneratedColumn<String> datos = GeneratedColumn<String>(
    'datos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    empresaId,
    tipo,
    prioridad,
    estado,
    texto,
    datos,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alertas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Alerta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('empresa_id')) {
      context.handle(
        _empresaIdMeta,
        empresaId.isAcceptableOrUnknown(data['empresa_id']!, _empresaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empresaIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('texto')) {
      context.handle(
        _textoMeta,
        texto.isAcceptableOrUnknown(data['texto']!, _textoMeta),
      );
    } else if (isInserting) {
      context.missing(_textoMeta);
    }
    if (data.containsKey('datos')) {
      context.handle(
        _datosMeta,
        datos.isAcceptableOrUnknown(data['datos']!, _datosMeta),
      );
    } else if (isInserting) {
      context.missing(_datosMeta);
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alerta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alerta(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      empresaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      prioridad: $AlertasTable.$converterprioridad.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}prioridad'],
        )!,
      ),
      estado: $AlertasTable.$converterestado.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}estado'],
        )!,
      ),
      texto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}texto'],
      )!,
      datos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}datos'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $AlertasTable createAlias(String alias) {
    return $AlertasTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PrioridadAlerta, String, String>
  $converterprioridad = const EnumNameConverter<PrioridadAlerta>(
    PrioridadAlerta.values,
  );
  static JsonTypeConverter2<EstadoAlerta, String, String> $converterestado =
      const EnumNameConverter<EstadoAlerta>(EstadoAlerta.values);
}

class Alerta extends DataClass implements Insertable<Alerta> {
  final String id;
  final String empresaId;
  final String tipo;
  final PrioridadAlerta prioridad;
  final EstadoAlerta estado;
  final String texto;

  /// Los datos que dispararon la alerta, en JSON.
  final String datos;
  final DateTime creadoEn;
  const Alerta({
    required this.id,
    required this.empresaId,
    required this.tipo,
    required this.prioridad,
    required this.estado,
    required this.texto,
    required this.datos,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['empresa_id'] = Variable<String>(empresaId);
    map['tipo'] = Variable<String>(tipo);
    {
      map['prioridad'] = Variable<String>(
        $AlertasTable.$converterprioridad.toSql(prioridad),
      );
    }
    {
      map['estado'] = Variable<String>(
        $AlertasTable.$converterestado.toSql(estado),
      );
    }
    map['texto'] = Variable<String>(texto);
    map['datos'] = Variable<String>(datos);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  AlertasCompanion toCompanion(bool nullToAbsent) {
    return AlertasCompanion(
      id: Value(id),
      empresaId: Value(empresaId),
      tipo: Value(tipo),
      prioridad: Value(prioridad),
      estado: Value(estado),
      texto: Value(texto),
      datos: Value(datos),
      creadoEn: Value(creadoEn),
    );
  }

  factory Alerta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alerta(
      id: serializer.fromJson<String>(json['id']),
      empresaId: serializer.fromJson<String>(json['empresaId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      prioridad: $AlertasTable.$converterprioridad.fromJson(
        serializer.fromJson<String>(json['prioridad']),
      ),
      estado: $AlertasTable.$converterestado.fromJson(
        serializer.fromJson<String>(json['estado']),
      ),
      texto: serializer.fromJson<String>(json['texto']),
      datos: serializer.fromJson<String>(json['datos']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'empresaId': serializer.toJson<String>(empresaId),
      'tipo': serializer.toJson<String>(tipo),
      'prioridad': serializer.toJson<String>(
        $AlertasTable.$converterprioridad.toJson(prioridad),
      ),
      'estado': serializer.toJson<String>(
        $AlertasTable.$converterestado.toJson(estado),
      ),
      'texto': serializer.toJson<String>(texto),
      'datos': serializer.toJson<String>(datos),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  Alerta copyWith({
    String? id,
    String? empresaId,
    String? tipo,
    PrioridadAlerta? prioridad,
    EstadoAlerta? estado,
    String? texto,
    String? datos,
    DateTime? creadoEn,
  }) => Alerta(
    id: id ?? this.id,
    empresaId: empresaId ?? this.empresaId,
    tipo: tipo ?? this.tipo,
    prioridad: prioridad ?? this.prioridad,
    estado: estado ?? this.estado,
    texto: texto ?? this.texto,
    datos: datos ?? this.datos,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  Alerta copyWithCompanion(AlertasCompanion data) {
    return Alerta(
      id: data.id.present ? data.id.value : this.id,
      empresaId: data.empresaId.present ? data.empresaId.value : this.empresaId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      prioridad: data.prioridad.present ? data.prioridad.value : this.prioridad,
      estado: data.estado.present ? data.estado.value : this.estado,
      texto: data.texto.present ? data.texto.value : this.texto,
      datos: data.datos.present ? data.datos.value : this.datos,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alerta(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('tipo: $tipo, ')
          ..write('prioridad: $prioridad, ')
          ..write('estado: $estado, ')
          ..write('texto: $texto, ')
          ..write('datos: $datos, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    empresaId,
    tipo,
    prioridad,
    estado,
    texto,
    datos,
    creadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alerta &&
          other.id == this.id &&
          other.empresaId == this.empresaId &&
          other.tipo == this.tipo &&
          other.prioridad == this.prioridad &&
          other.estado == this.estado &&
          other.texto == this.texto &&
          other.datos == this.datos &&
          other.creadoEn == this.creadoEn);
}

class AlertasCompanion extends UpdateCompanion<Alerta> {
  final Value<String> id;
  final Value<String> empresaId;
  final Value<String> tipo;
  final Value<PrioridadAlerta> prioridad;
  final Value<EstadoAlerta> estado;
  final Value<String> texto;
  final Value<String> datos;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const AlertasCompanion({
    this.id = const Value.absent(),
    this.empresaId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.prioridad = const Value.absent(),
    this.estado = const Value.absent(),
    this.texto = const Value.absent(),
    this.datos = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertasCompanion.insert({
    required String id,
    required String empresaId,
    required String tipo,
    required PrioridadAlerta prioridad,
    required EstadoAlerta estado,
    required String texto,
    required String datos,
    required DateTime creadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       empresaId = Value(empresaId),
       tipo = Value(tipo),
       prioridad = Value(prioridad),
       estado = Value(estado),
       texto = Value(texto),
       datos = Value(datos),
       creadoEn = Value(creadoEn);
  static Insertable<Alerta> custom({
    Expression<String>? id,
    Expression<String>? empresaId,
    Expression<String>? tipo,
    Expression<String>? prioridad,
    Expression<String>? estado,
    Expression<String>? texto,
    Expression<String>? datos,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      if (tipo != null) 'tipo': tipo,
      if (prioridad != null) 'prioridad': prioridad,
      if (estado != null) 'estado': estado,
      if (texto != null) 'texto': texto,
      if (datos != null) 'datos': datos,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertasCompanion copyWith({
    Value<String>? id,
    Value<String>? empresaId,
    Value<String>? tipo,
    Value<PrioridadAlerta>? prioridad,
    Value<EstadoAlerta>? estado,
    Value<String>? texto,
    Value<String>? datos,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return AlertasCompanion(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      tipo: tipo ?? this.tipo,
      prioridad: prioridad ?? this.prioridad,
      estado: estado ?? this.estado,
      texto: texto ?? this.texto,
      datos: datos ?? this.datos,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (empresaId.present) {
      map['empresa_id'] = Variable<String>(empresaId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (prioridad.present) {
      map['prioridad'] = Variable<String>(
        $AlertasTable.$converterprioridad.toSql(prioridad.value),
      );
    }
    if (estado.present) {
      map['estado'] = Variable<String>(
        $AlertasTable.$converterestado.toSql(estado.value),
      );
    }
    if (texto.present) {
      map['texto'] = Variable<String>(texto.value);
    }
    if (datos.present) {
      map['datos'] = Variable<String>(datos.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertasCompanion(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('tipo: $tipo, ')
          ..write('prioridad: $prioridad, ')
          ..write('estado: $estado, ')
          ..write('texto: $texto, ')
          ..write('datos: $datos, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BitacoraTable extends Bitacora
    with TableInfo<$BitacoraTable, BitacoraData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BitacoraTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empresaIdMeta = const VerificationMeta(
    'empresaId',
  );
  @override
  late final GeneratedColumn<String> empresaId = GeneratedColumn<String>(
    'empresa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES empresas (id)',
    ),
  );
  static const VerificationMeta _autorIdMeta = const VerificationMeta(
    'autorId',
  );
  @override
  late final GeneratedColumn<String> autorId = GeneratedColumn<String>(
    'autor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES usuarios (id)',
    ),
  );
  static const VerificationMeta _entidadMeta = const VerificationMeta(
    'entidad',
  );
  @override
  late final GeneratedColumn<String> entidad = GeneratedColumn<String>(
    'entidad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadIdMeta = const VerificationMeta(
    'entidadId',
  );
  @override
  late final GeneratedColumn<String> entidadId = GeneratedColumn<String>(
    'entidad_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccionBitacora, String> accion =
      GeneratedColumn<String>(
        'accion',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccionBitacora>($BitacoraTable.$converteraccion);
  static const VerificationMeta _valorAnteriorMeta = const VerificationMeta(
    'valorAnterior',
  );
  @override
  late final GeneratedColumn<String> valorAnterior = GeneratedColumn<String>(
    'valor_anterior',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valorNuevoMeta = const VerificationMeta(
    'valorNuevo',
  );
  @override
  late final GeneratedColumn<String> valorNuevo = GeneratedColumn<String>(
    'valor_nuevo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    empresaId,
    autorId,
    entidad,
    entidadId,
    accion,
    valorAnterior,
    valorNuevo,
    fecha,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bitacora';
  @override
  VerificationContext validateIntegrity(
    Insertable<BitacoraData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('empresa_id')) {
      context.handle(
        _empresaIdMeta,
        empresaId.isAcceptableOrUnknown(data['empresa_id']!, _empresaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empresaIdMeta);
    }
    if (data.containsKey('autor_id')) {
      context.handle(
        _autorIdMeta,
        autorId.isAcceptableOrUnknown(data['autor_id']!, _autorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_autorIdMeta);
    }
    if (data.containsKey('entidad')) {
      context.handle(
        _entidadMeta,
        entidad.isAcceptableOrUnknown(data['entidad']!, _entidadMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadMeta);
    }
    if (data.containsKey('entidad_id')) {
      context.handle(
        _entidadIdMeta,
        entidadId.isAcceptableOrUnknown(data['entidad_id']!, _entidadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadIdMeta);
    }
    if (data.containsKey('valor_anterior')) {
      context.handle(
        _valorAnteriorMeta,
        valorAnterior.isAcceptableOrUnknown(
          data['valor_anterior']!,
          _valorAnteriorMeta,
        ),
      );
    }
    if (data.containsKey('valor_nuevo')) {
      context.handle(
        _valorNuevoMeta,
        valorNuevo.isAcceptableOrUnknown(data['valor_nuevo']!, _valorNuevoMeta),
      );
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BitacoraData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BitacoraData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      empresaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_id'],
      )!,
      autorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}autor_id'],
      )!,
      entidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidad'],
      )!,
      entidadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidad_id'],
      )!,
      accion: $BitacoraTable.$converteraccion.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}accion'],
        )!,
      ),
      valorAnterior: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor_anterior'],
      ),
      valorNuevo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor_nuevo'],
      ),
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
    );
  }

  @override
  $BitacoraTable createAlias(String alias) {
    return $BitacoraTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccionBitacora, String, String> $converteraccion =
      const EnumNameConverter<AccionBitacora>(AccionBitacora.values);
}

class BitacoraData extends DataClass implements Insertable<BitacoraData> {
  final String id;
  final String empresaId;
  final String autorId;
  final String entidad;
  final String entidadId;
  final AccionBitacora accion;

  /// Valores en JSON; nulos cuando no aplican (al crear no hay anterior).
  final String? valorAnterior;
  final String? valorNuevo;
  final DateTime fecha;
  const BitacoraData({
    required this.id,
    required this.empresaId,
    required this.autorId,
    required this.entidad,
    required this.entidadId,
    required this.accion,
    this.valorAnterior,
    this.valorNuevo,
    required this.fecha,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['empresa_id'] = Variable<String>(empresaId);
    map['autor_id'] = Variable<String>(autorId);
    map['entidad'] = Variable<String>(entidad);
    map['entidad_id'] = Variable<String>(entidadId);
    {
      map['accion'] = Variable<String>(
        $BitacoraTable.$converteraccion.toSql(accion),
      );
    }
    if (!nullToAbsent || valorAnterior != null) {
      map['valor_anterior'] = Variable<String>(valorAnterior);
    }
    if (!nullToAbsent || valorNuevo != null) {
      map['valor_nuevo'] = Variable<String>(valorNuevo);
    }
    map['fecha'] = Variable<DateTime>(fecha);
    return map;
  }

  BitacoraCompanion toCompanion(bool nullToAbsent) {
    return BitacoraCompanion(
      id: Value(id),
      empresaId: Value(empresaId),
      autorId: Value(autorId),
      entidad: Value(entidad),
      entidadId: Value(entidadId),
      accion: Value(accion),
      valorAnterior: valorAnterior == null && nullToAbsent
          ? const Value.absent()
          : Value(valorAnterior),
      valorNuevo: valorNuevo == null && nullToAbsent
          ? const Value.absent()
          : Value(valorNuevo),
      fecha: Value(fecha),
    );
  }

  factory BitacoraData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BitacoraData(
      id: serializer.fromJson<String>(json['id']),
      empresaId: serializer.fromJson<String>(json['empresaId']),
      autorId: serializer.fromJson<String>(json['autorId']),
      entidad: serializer.fromJson<String>(json['entidad']),
      entidadId: serializer.fromJson<String>(json['entidadId']),
      accion: $BitacoraTable.$converteraccion.fromJson(
        serializer.fromJson<String>(json['accion']),
      ),
      valorAnterior: serializer.fromJson<String?>(json['valorAnterior']),
      valorNuevo: serializer.fromJson<String?>(json['valorNuevo']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'empresaId': serializer.toJson<String>(empresaId),
      'autorId': serializer.toJson<String>(autorId),
      'entidad': serializer.toJson<String>(entidad),
      'entidadId': serializer.toJson<String>(entidadId),
      'accion': serializer.toJson<String>(
        $BitacoraTable.$converteraccion.toJson(accion),
      ),
      'valorAnterior': serializer.toJson<String?>(valorAnterior),
      'valorNuevo': serializer.toJson<String?>(valorNuevo),
      'fecha': serializer.toJson<DateTime>(fecha),
    };
  }

  BitacoraData copyWith({
    String? id,
    String? empresaId,
    String? autorId,
    String? entidad,
    String? entidadId,
    AccionBitacora? accion,
    Value<String?> valorAnterior = const Value.absent(),
    Value<String?> valorNuevo = const Value.absent(),
    DateTime? fecha,
  }) => BitacoraData(
    id: id ?? this.id,
    empresaId: empresaId ?? this.empresaId,
    autorId: autorId ?? this.autorId,
    entidad: entidad ?? this.entidad,
    entidadId: entidadId ?? this.entidadId,
    accion: accion ?? this.accion,
    valorAnterior: valorAnterior.present
        ? valorAnterior.value
        : this.valorAnterior,
    valorNuevo: valorNuevo.present ? valorNuevo.value : this.valorNuevo,
    fecha: fecha ?? this.fecha,
  );
  BitacoraData copyWithCompanion(BitacoraCompanion data) {
    return BitacoraData(
      id: data.id.present ? data.id.value : this.id,
      empresaId: data.empresaId.present ? data.empresaId.value : this.empresaId,
      autorId: data.autorId.present ? data.autorId.value : this.autorId,
      entidad: data.entidad.present ? data.entidad.value : this.entidad,
      entidadId: data.entidadId.present ? data.entidadId.value : this.entidadId,
      accion: data.accion.present ? data.accion.value : this.accion,
      valorAnterior: data.valorAnterior.present
          ? data.valorAnterior.value
          : this.valorAnterior,
      valorNuevo: data.valorNuevo.present
          ? data.valorNuevo.value
          : this.valorNuevo,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BitacoraData(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('autorId: $autorId, ')
          ..write('entidad: $entidad, ')
          ..write('entidadId: $entidadId, ')
          ..write('accion: $accion, ')
          ..write('valorAnterior: $valorAnterior, ')
          ..write('valorNuevo: $valorNuevo, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    empresaId,
    autorId,
    entidad,
    entidadId,
    accion,
    valorAnterior,
    valorNuevo,
    fecha,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BitacoraData &&
          other.id == this.id &&
          other.empresaId == this.empresaId &&
          other.autorId == this.autorId &&
          other.entidad == this.entidad &&
          other.entidadId == this.entidadId &&
          other.accion == this.accion &&
          other.valorAnterior == this.valorAnterior &&
          other.valorNuevo == this.valorNuevo &&
          other.fecha == this.fecha);
}

class BitacoraCompanion extends UpdateCompanion<BitacoraData> {
  final Value<String> id;
  final Value<String> empresaId;
  final Value<String> autorId;
  final Value<String> entidad;
  final Value<String> entidadId;
  final Value<AccionBitacora> accion;
  final Value<String?> valorAnterior;
  final Value<String?> valorNuevo;
  final Value<DateTime> fecha;
  final Value<int> rowid;
  const BitacoraCompanion({
    this.id = const Value.absent(),
    this.empresaId = const Value.absent(),
    this.autorId = const Value.absent(),
    this.entidad = const Value.absent(),
    this.entidadId = const Value.absent(),
    this.accion = const Value.absent(),
    this.valorAnterior = const Value.absent(),
    this.valorNuevo = const Value.absent(),
    this.fecha = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BitacoraCompanion.insert({
    required String id,
    required String empresaId,
    required String autorId,
    required String entidad,
    required String entidadId,
    required AccionBitacora accion,
    this.valorAnterior = const Value.absent(),
    this.valorNuevo = const Value.absent(),
    required DateTime fecha,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       empresaId = Value(empresaId),
       autorId = Value(autorId),
       entidad = Value(entidad),
       entidadId = Value(entidadId),
       accion = Value(accion),
       fecha = Value(fecha);
  static Insertable<BitacoraData> custom({
    Expression<String>? id,
    Expression<String>? empresaId,
    Expression<String>? autorId,
    Expression<String>? entidad,
    Expression<String>? entidadId,
    Expression<String>? accion,
    Expression<String>? valorAnterior,
    Expression<String>? valorNuevo,
    Expression<DateTime>? fecha,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      if (autorId != null) 'autor_id': autorId,
      if (entidad != null) 'entidad': entidad,
      if (entidadId != null) 'entidad_id': entidadId,
      if (accion != null) 'accion': accion,
      if (valorAnterior != null) 'valor_anterior': valorAnterior,
      if (valorNuevo != null) 'valor_nuevo': valorNuevo,
      if (fecha != null) 'fecha': fecha,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BitacoraCompanion copyWith({
    Value<String>? id,
    Value<String>? empresaId,
    Value<String>? autorId,
    Value<String>? entidad,
    Value<String>? entidadId,
    Value<AccionBitacora>? accion,
    Value<String?>? valorAnterior,
    Value<String?>? valorNuevo,
    Value<DateTime>? fecha,
    Value<int>? rowid,
  }) {
    return BitacoraCompanion(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      autorId: autorId ?? this.autorId,
      entidad: entidad ?? this.entidad,
      entidadId: entidadId ?? this.entidadId,
      accion: accion ?? this.accion,
      valorAnterior: valorAnterior ?? this.valorAnterior,
      valorNuevo: valorNuevo ?? this.valorNuevo,
      fecha: fecha ?? this.fecha,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (empresaId.present) {
      map['empresa_id'] = Variable<String>(empresaId.value);
    }
    if (autorId.present) {
      map['autor_id'] = Variable<String>(autorId.value);
    }
    if (entidad.present) {
      map['entidad'] = Variable<String>(entidad.value);
    }
    if (entidadId.present) {
      map['entidad_id'] = Variable<String>(entidadId.value);
    }
    if (accion.present) {
      map['accion'] = Variable<String>(
        $BitacoraTable.$converteraccion.toSql(accion.value),
      );
    }
    if (valorAnterior.present) {
      map['valor_anterior'] = Variable<String>(valorAnterior.value);
    }
    if (valorNuevo.present) {
      map['valor_nuevo'] = Variable<String>(valorNuevo.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BitacoraCompanion(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('autorId: $autorId, ')
          ..write('entidad: $entidad, ')
          ..write('entidadId: $entidadId, ')
          ..write('accion: $accion, ')
          ..write('valorAnterior: $valorAnterior, ')
          ..write('valorNuevo: $valorNuevo, ')
          ..write('fecha: $fecha, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiasCerradosTable extends DiasCerrados
    with TableInfo<$DiasCerradosTable, DiasCerrado> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiasCerradosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empresaIdMeta = const VerificationMeta(
    'empresaId',
  );
  @override
  late final GeneratedColumn<String> empresaId = GeneratedColumn<String>(
    'empresa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES empresas (id)',
    ),
  );
  static const VerificationMeta _diaMeta = const VerificationMeta('dia');
  @override
  late final GeneratedColumn<DateTime> dia = GeneratedColumn<DateTime>(
    'dia',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, empresaId, dia];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dias_cerrados';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiasCerrado> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('empresa_id')) {
      context.handle(
        _empresaIdMeta,
        empresaId.isAcceptableOrUnknown(data['empresa_id']!, _empresaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empresaIdMeta);
    }
    if (data.containsKey('dia')) {
      context.handle(
        _diaMeta,
        dia.isAcceptableOrUnknown(data['dia']!, _diaMeta),
      );
    } else if (isInserting) {
      context.missing(_diaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiasCerrado map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiasCerrado(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      empresaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empresa_id'],
      )!,
      dia: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dia'],
      )!,
    );
  }

  @override
  $DiasCerradosTable createAlias(String alias) {
    return $DiasCerradosTable(attachedDatabase, alias);
  }
}

class DiasCerrado extends DataClass implements Insertable<DiasCerrado> {
  final String id;
  final String empresaId;
  final DateTime dia;
  const DiasCerrado({
    required this.id,
    required this.empresaId,
    required this.dia,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['empresa_id'] = Variable<String>(empresaId);
    map['dia'] = Variable<DateTime>(dia);
    return map;
  }

  DiasCerradosCompanion toCompanion(bool nullToAbsent) {
    return DiasCerradosCompanion(
      id: Value(id),
      empresaId: Value(empresaId),
      dia: Value(dia),
    );
  }

  factory DiasCerrado.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiasCerrado(
      id: serializer.fromJson<String>(json['id']),
      empresaId: serializer.fromJson<String>(json['empresaId']),
      dia: serializer.fromJson<DateTime>(json['dia']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'empresaId': serializer.toJson<String>(empresaId),
      'dia': serializer.toJson<DateTime>(dia),
    };
  }

  DiasCerrado copyWith({String? id, String? empresaId, DateTime? dia}) =>
      DiasCerrado(
        id: id ?? this.id,
        empresaId: empresaId ?? this.empresaId,
        dia: dia ?? this.dia,
      );
  DiasCerrado copyWithCompanion(DiasCerradosCompanion data) {
    return DiasCerrado(
      id: data.id.present ? data.id.value : this.id,
      empresaId: data.empresaId.present ? data.empresaId.value : this.empresaId,
      dia: data.dia.present ? data.dia.value : this.dia,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiasCerrado(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('dia: $dia')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, empresaId, dia);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiasCerrado &&
          other.id == this.id &&
          other.empresaId == this.empresaId &&
          other.dia == this.dia);
}

class DiasCerradosCompanion extends UpdateCompanion<DiasCerrado> {
  final Value<String> id;
  final Value<String> empresaId;
  final Value<DateTime> dia;
  final Value<int> rowid;
  const DiasCerradosCompanion({
    this.id = const Value.absent(),
    this.empresaId = const Value.absent(),
    this.dia = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiasCerradosCompanion.insert({
    required String id,
    required String empresaId,
    required DateTime dia,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       empresaId = Value(empresaId),
       dia = Value(dia);
  static Insertable<DiasCerrado> custom({
    Expression<String>? id,
    Expression<String>? empresaId,
    Expression<DateTime>? dia,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      if (dia != null) 'dia': dia,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiasCerradosCompanion copyWith({
    Value<String>? id,
    Value<String>? empresaId,
    Value<DateTime>? dia,
    Value<int>? rowid,
  }) {
    return DiasCerradosCompanion(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      dia: dia ?? this.dia,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (empresaId.present) {
      map['empresa_id'] = Variable<String>(empresaId.value);
    }
    if (dia.present) {
      map['dia'] = Variable<DateTime>(dia.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiasCerradosCompanion(')
          ..write('id: $id, ')
          ..write('empresaId: $empresaId, ')
          ..write('dia: $dia, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventosMedicionTable extends EventosMedicion
    with TableInfo<$EventosMedicionTable, EventosMedicionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventosMedicionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _datosMeta = const VerificationMeta('datos');
  @override
  late final GeneratedColumn<String> datos = GeneratedColumn<String>(
    'datos',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nombre, fecha, datos];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eventos_medicion';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventosMedicionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('datos')) {
      context.handle(
        _datosMeta,
        datos.isAcceptableOrUnknown(data['datos']!, _datosMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventosMedicionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventosMedicionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      datos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}datos'],
      ),
    );
  }

  @override
  $EventosMedicionTable createAlias(String alias) {
    return $EventosMedicionTable(attachedDatabase, alias);
  }
}

class EventosMedicionData extends DataClass
    implements Insertable<EventosMedicionData> {
  final String id;
  final String nombre;
  final DateTime fecha;
  final String? datos;
  const EventosMedicionData({
    required this.id,
    required this.nombre,
    required this.fecha,
    this.datos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['fecha'] = Variable<DateTime>(fecha);
    if (!nullToAbsent || datos != null) {
      map['datos'] = Variable<String>(datos);
    }
    return map;
  }

  EventosMedicionCompanion toCompanion(bool nullToAbsent) {
    return EventosMedicionCompanion(
      id: Value(id),
      nombre: Value(nombre),
      fecha: Value(fecha),
      datos: datos == null && nullToAbsent
          ? const Value.absent()
          : Value(datos),
    );
  }

  factory EventosMedicionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventosMedicionData(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      datos: serializer.fromJson<String?>(json['datos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'fecha': serializer.toJson<DateTime>(fecha),
      'datos': serializer.toJson<String?>(datos),
    };
  }

  EventosMedicionData copyWith({
    String? id,
    String? nombre,
    DateTime? fecha,
    Value<String?> datos = const Value.absent(),
  }) => EventosMedicionData(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    fecha: fecha ?? this.fecha,
    datos: datos.present ? datos.value : this.datos,
  );
  EventosMedicionData copyWithCompanion(EventosMedicionCompanion data) {
    return EventosMedicionData(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      datos: data.datos.present ? data.datos.value : this.datos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventosMedicionData(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('fecha: $fecha, ')
          ..write('datos: $datos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, fecha, datos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventosMedicionData &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.fecha == this.fecha &&
          other.datos == this.datos);
}

class EventosMedicionCompanion extends UpdateCompanion<EventosMedicionData> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<DateTime> fecha;
  final Value<String?> datos;
  final Value<int> rowid;
  const EventosMedicionCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.fecha = const Value.absent(),
    this.datos = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventosMedicionCompanion.insert({
    required String id,
    required String nombre,
    required DateTime fecha,
    this.datos = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       fecha = Value(fecha);
  static Insertable<EventosMedicionData> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<DateTime>? fecha,
    Expression<String>? datos,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (fecha != null) 'fecha': fecha,
      if (datos != null) 'datos': datos,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventosMedicionCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<DateTime>? fecha,
    Value<String?>? datos,
    Value<int>? rowid,
  }) {
    return EventosMedicionCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      fecha: fecha ?? this.fecha,
      datos: datos ?? this.datos,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (datos.present) {
      map['datos'] = Variable<String>(datos.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventosMedicionCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('fecha: $fecha, ')
          ..write('datos: $datos, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AjustesTable extends Ajustes with TableInfo<$AjustesTable, Ajuste> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AjustesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claveMeta = const VerificationMeta('clave');
  @override
  late final GeneratedColumn<String> clave = GeneratedColumn<String>(
    'clave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<String> valor = GeneratedColumn<String>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [clave, valor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ajustes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ajuste> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clave')) {
      context.handle(
        _claveMeta,
        clave.isAcceptableOrUnknown(data['clave']!, _claveMeta),
      );
    } else if (isInserting) {
      context.missing(_claveMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clave};
  @override
  Ajuste map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ajuste(
      clave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor'],
      )!,
    );
  }

  @override
  $AjustesTable createAlias(String alias) {
    return $AjustesTable(attachedDatabase, alias);
  }
}

class Ajuste extends DataClass implements Insertable<Ajuste> {
  final String clave;
  final String valor;
  const Ajuste({required this.clave, required this.valor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clave'] = Variable<String>(clave);
    map['valor'] = Variable<String>(valor);
    return map;
  }

  AjustesCompanion toCompanion(bool nullToAbsent) {
    return AjustesCompanion(clave: Value(clave), valor: Value(valor));
  }

  factory Ajuste.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ajuste(
      clave: serializer.fromJson<String>(json['clave']),
      valor: serializer.fromJson<String>(json['valor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clave': serializer.toJson<String>(clave),
      'valor': serializer.toJson<String>(valor),
    };
  }

  Ajuste copyWith({String? clave, String? valor}) =>
      Ajuste(clave: clave ?? this.clave, valor: valor ?? this.valor);
  Ajuste copyWithCompanion(AjustesCompanion data) {
    return Ajuste(
      clave: data.clave.present ? data.clave.value : this.clave,
      valor: data.valor.present ? data.valor.value : this.valor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ajuste(')
          ..write('clave: $clave, ')
          ..write('valor: $valor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clave, valor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ajuste &&
          other.clave == this.clave &&
          other.valor == this.valor);
}

class AjustesCompanion extends UpdateCompanion<Ajuste> {
  final Value<String> clave;
  final Value<String> valor;
  final Value<int> rowid;
  const AjustesCompanion({
    this.clave = const Value.absent(),
    this.valor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AjustesCompanion.insert({
    required String clave,
    required String valor,
    this.rowid = const Value.absent(),
  }) : clave = Value(clave),
       valor = Value(valor);
  static Insertable<Ajuste> custom({
    Expression<String>? clave,
    Expression<String>? valor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clave != null) 'clave': clave,
      if (valor != null) 'valor': valor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AjustesCompanion copyWith({
    Value<String>? clave,
    Value<String>? valor,
    Value<int>? rowid,
  }) {
    return AjustesCompanion(
      clave: clave ?? this.clave,
      valor: valor ?? this.valor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clave.present) {
      map['clave'] = Variable<String>(clave.value);
    }
    if (valor.present) {
      map['valor'] = Variable<String>(valor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AjustesCompanion(')
          ..write('clave: $clave, ')
          ..write('valor: $valor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubidasTable extends Subidas with TableInfo<$SubidasTable, Subida> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubidasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tablaMeta = const VerificationMeta('tabla');
  @override
  late final GeneratedColumn<String> tabla = GeneratedColumn<String>(
    'tabla',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filaIdMeta = const VerificationMeta('filaId');
  @override
  late final GeneratedColumn<String> filaId = GeneratedColumn<String>(
    'fila_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _huellaMeta = const VerificationMeta('huella');
  @override
  late final GeneratedColumn<String> huella = GeneratedColumn<String>(
    'huella',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tabla, filaId, huella];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subidas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subida> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tabla')) {
      context.handle(
        _tablaMeta,
        tabla.isAcceptableOrUnknown(data['tabla']!, _tablaMeta),
      );
    } else if (isInserting) {
      context.missing(_tablaMeta);
    }
    if (data.containsKey('fila_id')) {
      context.handle(
        _filaIdMeta,
        filaId.isAcceptableOrUnknown(data['fila_id']!, _filaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_filaIdMeta);
    }
    if (data.containsKey('huella')) {
      context.handle(
        _huellaMeta,
        huella.isAcceptableOrUnknown(data['huella']!, _huellaMeta),
      );
    } else if (isInserting) {
      context.missing(_huellaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tabla, filaId};
  @override
  Subida map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subida(
      tabla: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tabla'],
      )!,
      filaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fila_id'],
      )!,
      huella: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}huella'],
      )!,
    );
  }

  @override
  $SubidasTable createAlias(String alias) {
    return $SubidasTable(attachedDatabase, alias);
  }
}

class Subida extends DataClass implements Insertable<Subida> {
  final String tabla;
  final String filaId;
  final String huella;
  const Subida({
    required this.tabla,
    required this.filaId,
    required this.huella,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tabla'] = Variable<String>(tabla);
    map['fila_id'] = Variable<String>(filaId);
    map['huella'] = Variable<String>(huella);
    return map;
  }

  SubidasCompanion toCompanion(bool nullToAbsent) {
    return SubidasCompanion(
      tabla: Value(tabla),
      filaId: Value(filaId),
      huella: Value(huella),
    );
  }

  factory Subida.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subida(
      tabla: serializer.fromJson<String>(json['tabla']),
      filaId: serializer.fromJson<String>(json['filaId']),
      huella: serializer.fromJson<String>(json['huella']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tabla': serializer.toJson<String>(tabla),
      'filaId': serializer.toJson<String>(filaId),
      'huella': serializer.toJson<String>(huella),
    };
  }

  Subida copyWith({String? tabla, String? filaId, String? huella}) => Subida(
    tabla: tabla ?? this.tabla,
    filaId: filaId ?? this.filaId,
    huella: huella ?? this.huella,
  );
  Subida copyWithCompanion(SubidasCompanion data) {
    return Subida(
      tabla: data.tabla.present ? data.tabla.value : this.tabla,
      filaId: data.filaId.present ? data.filaId.value : this.filaId,
      huella: data.huella.present ? data.huella.value : this.huella,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subida(')
          ..write('tabla: $tabla, ')
          ..write('filaId: $filaId, ')
          ..write('huella: $huella')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tabla, filaId, huella);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subida &&
          other.tabla == this.tabla &&
          other.filaId == this.filaId &&
          other.huella == this.huella);
}

class SubidasCompanion extends UpdateCompanion<Subida> {
  final Value<String> tabla;
  final Value<String> filaId;
  final Value<String> huella;
  final Value<int> rowid;
  const SubidasCompanion({
    this.tabla = const Value.absent(),
    this.filaId = const Value.absent(),
    this.huella = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubidasCompanion.insert({
    required String tabla,
    required String filaId,
    required String huella,
    this.rowid = const Value.absent(),
  }) : tabla = Value(tabla),
       filaId = Value(filaId),
       huella = Value(huella);
  static Insertable<Subida> custom({
    Expression<String>? tabla,
    Expression<String>? filaId,
    Expression<String>? huella,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tabla != null) 'tabla': tabla,
      if (filaId != null) 'fila_id': filaId,
      if (huella != null) 'huella': huella,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubidasCompanion copyWith({
    Value<String>? tabla,
    Value<String>? filaId,
    Value<String>? huella,
    Value<int>? rowid,
  }) {
    return SubidasCompanion(
      tabla: tabla ?? this.tabla,
      filaId: filaId ?? this.filaId,
      huella: huella ?? this.huella,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tabla.present) {
      map['tabla'] = Variable<String>(tabla.value);
    }
    if (filaId.present) {
      map['fila_id'] = Variable<String>(filaId.value);
    }
    if (huella.present) {
      map['huella'] = Variable<String>(huella.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubidasCompanion(')
          ..write('tabla: $tabla, ')
          ..write('filaId: $filaId, ')
          ..write('huella: $huella, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BaseLocal extends GeneratedDatabase {
  _$BaseLocal(QueryExecutor e) : super(e);
  $BaseLocalManager get managers => $BaseLocalManager(this);
  late final $UsuariosTable usuarios = $UsuariosTable(this);
  late final $EmpresasTable empresas = $EmpresasTable(this);
  late final $MembresiasTable membresias = $MembresiasTable(this);
  late final $CuentasTable cuentas = $CuentasTable(this);
  late final $ContrapartesTable contrapartes = $ContrapartesTable(this);
  late final $ComprobantesTable comprobantes = $ComprobantesTable(this);
  late final $ItemsComprobanteTable itemsComprobante = $ItemsComprobanteTable(
    this,
  );
  late final $CategoriasTable categorias = $CategoriasTable(this);
  late final $MovimientosTable movimientos = $MovimientosTable(this);
  late final $ArqueosTable arqueos = $ArqueosTable(this);
  late final $ArqueoCuentasTable arqueoCuentas = $ArqueoCuentasTable(this);
  late final $AlertasTable alertas = $AlertasTable(this);
  late final $BitacoraTable bitacora = $BitacoraTable(this);
  late final $DiasCerradosTable diasCerrados = $DiasCerradosTable(this);
  late final $EventosMedicionTable eventosMedicion = $EventosMedicionTable(
    this,
  );
  late final $AjustesTable ajustes = $AjustesTable(this);
  late final $SubidasTable subidas = $SubidasTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usuarios,
    empresas,
    membresias,
    cuentas,
    contrapartes,
    comprobantes,
    itemsComprobante,
    categorias,
    movimientos,
    arqueos,
    arqueoCuentas,
    alertas,
    bitacora,
    diasCerrados,
    eventosMedicion,
    ajustes,
    subidas,
  ];
}

typedef $$UsuariosTableCreateCompanionBuilder = UsuariosCompanion Function({
  required String id,
  Value<String?> celular,
  Value<String?> nombre,
  required DateTime creadoEn,
  Value<int> rowid,
});
typedef $$UsuariosTableUpdateCompanionBuilder = UsuariosCompanion Function({
  Value<String> id,
  Value<String?> celular,
  Value<String?> nombre,
  Value<DateTime> creadoEn,
  Value<int> rowid,
});

final class $$UsuariosTableReferences
    extends BaseReferences<_$BaseLocal, $UsuariosTable, Usuario> {
  $$UsuariosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MembresiasTable, List<Membresia>>
  _membresiasRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.membresias,
    aliasName: 'usuarios__id__membresias__usuario_id',
  );

  $$MembresiasTableProcessedTableManager get membresiasRefs {
    final manager = $$MembresiasTableTableManager(
      $_db,
      $_db.membresias,
    ).filter((f) => f.usuarioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_membresiasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MovimientosTable, List<Movimiento>>
  _movimientosRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.movimientos,
    aliasName: 'usuarios__id__movimientos__autor_id',
  );

  $$MovimientosTableProcessedTableManager get movimientosRefs {
    final manager = $$MovimientosTableTableManager(
      $_db,
      $_db.movimientos,
    ).filter((f) => f.autorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movimientosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ArqueosTable, List<Arqueo>> _arqueosRefsTable(
    _$BaseLocal db,
  ) => MultiTypedResultKey.fromTable(
    db.arqueos,
    aliasName: 'usuarios__id__arqueos__autor_id',
  );

  $$ArqueosTableProcessedTableManager get arqueosRefs {
    final manager = $$ArqueosTableTableManager(
      $_db,
      $_db.arqueos,
    ).filter((f) => f.autorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_arqueosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BitacoraTable, List<BitacoraData>>
  _bitacoraRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.bitacora,
    aliasName: 'usuarios__id__bitacora__autor_id',
  );

  $$BitacoraTableProcessedTableManager get bitacoraRefs {
    final manager = $$BitacoraTableTableManager(
      $_db,
      $_db.bitacora,
    ).filter((f) => f.autorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bitacoraRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsuariosTableFilterComposer
    extends Composer<_$BaseLocal, $UsuariosTable> {
  $$UsuariosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get celular => $composableBuilder(
    column: $table.celular,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> membresiasRefs(
    Expression<bool> Function($$MembresiasTableFilterComposer f) f,
  ) {
    final $$MembresiasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.membresias,
      getReferencedColumn: (t) => t.usuarioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembresiasTableFilterComposer(
            $db: $db,
            $table: $db.membresias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> movimientosRefs(
    Expression<bool> Function($$MovimientosTableFilterComposer f) f,
  ) {
    final $$MovimientosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.autorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableFilterComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> arqueosRefs(
    Expression<bool> Function($$ArqueosTableFilterComposer f) f,
  ) {
    final $$ArqueosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arqueos,
      getReferencedColumn: (t) => t.autorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueosTableFilterComposer(
            $db: $db,
            $table: $db.arqueos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bitacoraRefs(
    Expression<bool> Function($$BitacoraTableFilterComposer f) f,
  ) {
    final $$BitacoraTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bitacora,
      getReferencedColumn: (t) => t.autorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BitacoraTableFilterComposer(
            $db: $db,
            $table: $db.bitacora,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsuariosTableOrderingComposer
    extends Composer<_$BaseLocal, $UsuariosTable> {
  $$UsuariosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get celular => $composableBuilder(
    column: $table.celular,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsuariosTableAnnotationComposer
    extends Composer<_$BaseLocal, $UsuariosTable> {
  $$UsuariosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get celular =>
      $composableBuilder(column: $table.celular, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  Expression<T> membresiasRefs<T extends Object>(
    Expression<T> Function($$MembresiasTableAnnotationComposer a) f,
  ) {
    final $$MembresiasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.membresias,
      getReferencedColumn: (t) => t.usuarioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembresiasTableAnnotationComposer(
            $db: $db,
            $table: $db.membresias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> movimientosRefs<T extends Object>(
    Expression<T> Function($$MovimientosTableAnnotationComposer a) f,
  ) {
    final $$MovimientosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.autorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableAnnotationComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> arqueosRefs<T extends Object>(
    Expression<T> Function($$ArqueosTableAnnotationComposer a) f,
  ) {
    final $$ArqueosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arqueos,
      getReferencedColumn: (t) => t.autorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueosTableAnnotationComposer(
            $db: $db,
            $table: $db.arqueos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bitacoraRefs<T extends Object>(
    Expression<T> Function($$BitacoraTableAnnotationComposer a) f,
  ) {
    final $$BitacoraTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bitacora,
      getReferencedColumn: (t) => t.autorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BitacoraTableAnnotationComposer(
            $db: $db,
            $table: $db.bitacora,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsuariosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $UsuariosTable,
          Usuario,
          $$UsuariosTableFilterComposer,
          $$UsuariosTableOrderingComposer,
          $$UsuariosTableAnnotationComposer,
          $$UsuariosTableCreateCompanionBuilder,
          $$UsuariosTableUpdateCompanionBuilder,
          (Usuario, $$UsuariosTableReferences),
          Usuario,
          PrefetchHooks Function({
            bool membresiasRefs,
            bool movimientosRefs,
            bool arqueosRefs,
            bool bitacoraRefs,
          })
        > {
  $$UsuariosTableTableManager(_$BaseLocal db, $UsuariosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsuariosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsuariosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsuariosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> celular = const Value.absent(),
                Value<String?> nombre = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion(
                id: id,
                celular: celular,
                nombre: nombre,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> celular = const Value.absent(),
                Value<String?> nombre = const Value.absent(),
                required DateTime creadoEn,
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion.insert(
                id: id,
                celular: celular,
                nombre: nombre,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsuariosTable, Usuario>(table),
                  $$UsuariosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                membresiasRefs = false,
                movimientosRefs = false,
                arqueosRefs = false,
                bitacoraRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (membresiasRefs) db.membresias,
                    if (movimientosRefs) db.movimientos,
                    if (arqueosRefs) db.arqueos,
                    if (bitacoraRefs) db.bitacora,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (membresiasRefs)
                        await $_getPrefetchedData<
                          Usuario,
                          $UsuariosTable,
                          Membresia
                        >(
                          currentTable: table,
                          referencedTable: $$UsuariosTableReferences
                              ._membresiasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsuariosTableReferences(
                                db,
                                table,
                                p0,
                              ).membresiasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.usuarioId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (movimientosRefs)
                        await $_getPrefetchedData<
                          Usuario,
                          $UsuariosTable,
                          Movimiento
                        >(
                          currentTable: table,
                          referencedTable: $$UsuariosTableReferences
                              ._movimientosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsuariosTableReferences(
                                db,
                                table,
                                p0,
                              ).movimientosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.autorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (arqueosRefs)
                        await $_getPrefetchedData<
                          Usuario,
                          $UsuariosTable,
                          Arqueo
                        >(
                          currentTable: table,
                          referencedTable: $$UsuariosTableReferences
                              ._arqueosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsuariosTableReferences(
                                db,
                                table,
                                p0,
                              ).arqueosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.autorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bitacoraRefs)
                        await $_getPrefetchedData<
                          Usuario,
                          $UsuariosTable,
                          BitacoraData
                        >(
                          currentTable: table,
                          referencedTable: $$UsuariosTableReferences
                              ._bitacoraRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsuariosTableReferences(
                                db,
                                table,
                                p0,
                              ).bitacoraRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.autorId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UsuariosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $UsuariosTable,
      Usuario,
      $$UsuariosTableFilterComposer,
      $$UsuariosTableOrderingComposer,
      $$UsuariosTableAnnotationComposer,
      $$UsuariosTableCreateCompanionBuilder,
      $$UsuariosTableUpdateCompanionBuilder,
      (Usuario, $$UsuariosTableReferences),
      Usuario,
      PrefetchHooks Function({
        bool membresiasRefs,
        bool movimientosRefs,
        bool arqueosRefs,
        bool bitacoraRefs,
      })
    >;
typedef $$EmpresasTableCreateCompanionBuilder = EmpresasCompanion Function({
  required String id,
  required String nombre,
  required TipoNegocio tipoNegocio,
  required ModoEmpresa modo,
  required String pais,
  required String moneda,
  Value<String?> regimen,
  required int horaCierreMinutos,
  Value<String?> identificacionFiscal,
  required DateTime creadoEn,
  Value<int> rowid,
});
typedef $$EmpresasTableUpdateCompanionBuilder = EmpresasCompanion Function({
  Value<String> id,
  Value<String> nombre,
  Value<TipoNegocio> tipoNegocio,
  Value<ModoEmpresa> modo,
  Value<String> pais,
  Value<String> moneda,
  Value<String?> regimen,
  Value<int> horaCierreMinutos,
  Value<String?> identificacionFiscal,
  Value<DateTime> creadoEn,
  Value<int> rowid,
});

final class $$EmpresasTableReferences
    extends BaseReferences<_$BaseLocal, $EmpresasTable, Empresa> {
  $$EmpresasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MembresiasTable, List<Membresia>>
  _membresiasRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.membresias,
    aliasName: 'empresas__id__membresias__empresa_id',
  );

  $$MembresiasTableProcessedTableManager get membresiasRefs {
    final manager = $$MembresiasTableTableManager(
      $_db,
      $_db.membresias,
    ).filter((f) => f.empresaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_membresiasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CuentasTable, List<Cuenta>> _cuentasRefsTable(
    _$BaseLocal db,
  ) => MultiTypedResultKey.fromTable(
    db.cuentas,
    aliasName: 'empresas__id__cuentas__empresa_id',
  );

  $$CuentasTableProcessedTableManager get cuentasRefs {
    final manager = $$CuentasTableTableManager(
      $_db,
      $_db.cuentas,
    ).filter((f) => f.empresaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cuentasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ContrapartesTable, List<Contraparte>>
  _contrapartesRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.contrapartes,
    aliasName: 'empresas__id__contrapartes__empresa_id',
  );

  $$ContrapartesTableProcessedTableManager get contrapartesRefs {
    final manager = $$ContrapartesTableTableManager(
      $_db,
      $_db.contrapartes,
    ).filter((f) => f.empresaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_contrapartesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ComprobantesTable, List<Comprobante>>
  _comprobantesRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.comprobantes,
    aliasName: 'empresas__id__comprobantes__empresa_id',
  );

  $$ComprobantesTableProcessedTableManager get comprobantesRefs {
    final manager = $$ComprobantesTableTableManager(
      $_db,
      $_db.comprobantes,
    ).filter((f) => f.empresaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_comprobantesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CategoriasTable, List<Categoria>>
  _categoriasRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.categorias,
    aliasName: 'empresas__id__categorias__empresa_id',
  );

  $$CategoriasTableProcessedTableManager get categoriasRefs {
    final manager = $$CategoriasTableTableManager(
      $_db,
      $_db.categorias,
    ).filter((f) => f.empresaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MovimientosTable, List<Movimiento>>
  _movimientosRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.movimientos,
    aliasName: 'empresas__id__movimientos__empresa_id',
  );

  $$MovimientosTableProcessedTableManager get movimientosRefs {
    final manager = $$MovimientosTableTableManager(
      $_db,
      $_db.movimientos,
    ).filter((f) => f.empresaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movimientosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ArqueosTable, List<Arqueo>> _arqueosRefsTable(
    _$BaseLocal db,
  ) => MultiTypedResultKey.fromTable(
    db.arqueos,
    aliasName: 'empresas__id__arqueos__empresa_id',
  );

  $$ArqueosTableProcessedTableManager get arqueosRefs {
    final manager = $$ArqueosTableTableManager(
      $_db,
      $_db.arqueos,
    ).filter((f) => f.empresaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_arqueosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AlertasTable, List<Alerta>> _alertasRefsTable(
    _$BaseLocal db,
  ) => MultiTypedResultKey.fromTable(
    db.alertas,
    aliasName: 'empresas__id__alertas__empresa_id',
  );

  $$AlertasTableProcessedTableManager get alertasRefs {
    final manager = $$AlertasTableTableManager(
      $_db,
      $_db.alertas,
    ).filter((f) => f.empresaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_alertasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BitacoraTable, List<BitacoraData>>
  _bitacoraRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.bitacora,
    aliasName: 'empresas__id__bitacora__empresa_id',
  );

  $$BitacoraTableProcessedTableManager get bitacoraRefs {
    final manager = $$BitacoraTableTableManager(
      $_db,
      $_db.bitacora,
    ).filter((f) => f.empresaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bitacoraRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DiasCerradosTable, List<DiasCerrado>>
  _diasCerradosRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.diasCerrados,
    aliasName: 'empresas__id__dias_cerrados__empresa_id',
  );

  $$DiasCerradosTableProcessedTableManager get diasCerradosRefs {
    final manager = $$DiasCerradosTableTableManager(
      $_db,
      $_db.diasCerrados,
    ).filter((f) => f.empresaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_diasCerradosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EmpresasTableFilterComposer
    extends Composer<_$BaseLocal, $EmpresasTable> {
  $$EmpresasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TipoNegocio, TipoNegocio, String>
  get tipoNegocio => $composableBuilder(
    column: $table.tipoNegocio,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ModoEmpresa, ModoEmpresa, String> get modo =>
      $composableBuilder(
        column: $table.modo,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get pais => $composableBuilder(
    column: $table.pais,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moneda => $composableBuilder(
    column: $table.moneda,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regimen => $composableBuilder(
    column: $table.regimen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get horaCierreMinutos => $composableBuilder(
    column: $table.horaCierreMinutos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identificacionFiscal => $composableBuilder(
    column: $table.identificacionFiscal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> membresiasRefs(
    Expression<bool> Function($$MembresiasTableFilterComposer f) f,
  ) {
    final $$MembresiasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.membresias,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembresiasTableFilterComposer(
            $db: $db,
            $table: $db.membresias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cuentasRefs(
    Expression<bool> Function($$CuentasTableFilterComposer f) f,
  ) {
    final $$CuentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableFilterComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> contrapartesRefs(
    Expression<bool> Function($$ContrapartesTableFilterComposer f) f,
  ) {
    final $$ContrapartesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contrapartes,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContrapartesTableFilterComposer(
            $db: $db,
            $table: $db.contrapartes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> comprobantesRefs(
    Expression<bool> Function($$ComprobantesTableFilterComposer f) f,
  ) {
    final $$ComprobantesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.comprobantes,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprobantesTableFilterComposer(
            $db: $db,
            $table: $db.comprobantes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> categoriasRefs(
    Expression<bool> Function($$CategoriasTableFilterComposer f) f,
  ) {
    final $$CategoriasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableFilterComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> movimientosRefs(
    Expression<bool> Function($$MovimientosTableFilterComposer f) f,
  ) {
    final $$MovimientosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableFilterComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> arqueosRefs(
    Expression<bool> Function($$ArqueosTableFilterComposer f) f,
  ) {
    final $$ArqueosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arqueos,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueosTableFilterComposer(
            $db: $db,
            $table: $db.arqueos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> alertasRefs(
    Expression<bool> Function($$AlertasTableFilterComposer f) f,
  ) {
    final $$AlertasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alertas,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertasTableFilterComposer(
            $db: $db,
            $table: $db.alertas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bitacoraRefs(
    Expression<bool> Function($$BitacoraTableFilterComposer f) f,
  ) {
    final $$BitacoraTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bitacora,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BitacoraTableFilterComposer(
            $db: $db,
            $table: $db.bitacora,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> diasCerradosRefs(
    Expression<bool> Function($$DiasCerradosTableFilterComposer f) f,
  ) {
    final $$DiasCerradosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diasCerrados,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiasCerradosTableFilterComposer(
            $db: $db,
            $table: $db.diasCerrados,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EmpresasTableOrderingComposer
    extends Composer<_$BaseLocal, $EmpresasTable> {
  $$EmpresasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoNegocio => $composableBuilder(
    column: $table.tipoNegocio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modo => $composableBuilder(
    column: $table.modo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pais => $composableBuilder(
    column: $table.pais,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moneda => $composableBuilder(
    column: $table.moneda,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regimen => $composableBuilder(
    column: $table.regimen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get horaCierreMinutos => $composableBuilder(
    column: $table.horaCierreMinutos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identificacionFiscal => $composableBuilder(
    column: $table.identificacionFiscal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmpresasTableAnnotationComposer
    extends Composer<_$BaseLocal, $EmpresasTable> {
  $$EmpresasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TipoNegocio, String> get tipoNegocio =>
      $composableBuilder(
        column: $table.tipoNegocio,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<ModoEmpresa, String> get modo =>
      $composableBuilder(column: $table.modo, builder: (column) => column);

  GeneratedColumn<String> get pais =>
      $composableBuilder(column: $table.pais, builder: (column) => column);

  GeneratedColumn<String> get moneda =>
      $composableBuilder(column: $table.moneda, builder: (column) => column);

  GeneratedColumn<String> get regimen =>
      $composableBuilder(column: $table.regimen, builder: (column) => column);

  GeneratedColumn<int> get horaCierreMinutos => $composableBuilder(
    column: $table.horaCierreMinutos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identificacionFiscal => $composableBuilder(
    column: $table.identificacionFiscal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  Expression<T> membresiasRefs<T extends Object>(
    Expression<T> Function($$MembresiasTableAnnotationComposer a) f,
  ) {
    final $$MembresiasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.membresias,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembresiasTableAnnotationComposer(
            $db: $db,
            $table: $db.membresias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cuentasRefs<T extends Object>(
    Expression<T> Function($$CuentasTableAnnotationComposer a) f,
  ) {
    final $$CuentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> contrapartesRefs<T extends Object>(
    Expression<T> Function($$ContrapartesTableAnnotationComposer a) f,
  ) {
    final $$ContrapartesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contrapartes,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContrapartesTableAnnotationComposer(
            $db: $db,
            $table: $db.contrapartes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> comprobantesRefs<T extends Object>(
    Expression<T> Function($$ComprobantesTableAnnotationComposer a) f,
  ) {
    final $$ComprobantesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.comprobantes,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprobantesTableAnnotationComposer(
            $db: $db,
            $table: $db.comprobantes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> categoriasRefs<T extends Object>(
    Expression<T> Function($$CategoriasTableAnnotationComposer a) f,
  ) {
    final $$CategoriasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableAnnotationComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> movimientosRefs<T extends Object>(
    Expression<T> Function($$MovimientosTableAnnotationComposer a) f,
  ) {
    final $$MovimientosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableAnnotationComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> arqueosRefs<T extends Object>(
    Expression<T> Function($$ArqueosTableAnnotationComposer a) f,
  ) {
    final $$ArqueosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arqueos,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueosTableAnnotationComposer(
            $db: $db,
            $table: $db.arqueos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> alertasRefs<T extends Object>(
    Expression<T> Function($$AlertasTableAnnotationComposer a) f,
  ) {
    final $$AlertasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alertas,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertasTableAnnotationComposer(
            $db: $db,
            $table: $db.alertas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bitacoraRefs<T extends Object>(
    Expression<T> Function($$BitacoraTableAnnotationComposer a) f,
  ) {
    final $$BitacoraTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bitacora,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BitacoraTableAnnotationComposer(
            $db: $db,
            $table: $db.bitacora,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> diasCerradosRefs<T extends Object>(
    Expression<T> Function($$DiasCerradosTableAnnotationComposer a) f,
  ) {
    final $$DiasCerradosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diasCerrados,
      getReferencedColumn: (t) => t.empresaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiasCerradosTableAnnotationComposer(
            $db: $db,
            $table: $db.diasCerrados,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EmpresasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $EmpresasTable,
          Empresa,
          $$EmpresasTableFilterComposer,
          $$EmpresasTableOrderingComposer,
          $$EmpresasTableAnnotationComposer,
          $$EmpresasTableCreateCompanionBuilder,
          $$EmpresasTableUpdateCompanionBuilder,
          (Empresa, $$EmpresasTableReferences),
          Empresa,
          PrefetchHooks Function({
            bool membresiasRefs,
            bool cuentasRefs,
            bool contrapartesRefs,
            bool comprobantesRefs,
            bool categoriasRefs,
            bool movimientosRefs,
            bool arqueosRefs,
            bool alertasRefs,
            bool bitacoraRefs,
            bool diasCerradosRefs,
          })
        > {
  $$EmpresasTableTableManager(_$BaseLocal db, $EmpresasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmpresasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmpresasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmpresasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<TipoNegocio> tipoNegocio = const Value.absent(),
                Value<ModoEmpresa> modo = const Value.absent(),
                Value<String> pais = const Value.absent(),
                Value<String> moneda = const Value.absent(),
                Value<String?> regimen = const Value.absent(),
                Value<int> horaCierreMinutos = const Value.absent(),
                Value<String?> identificacionFiscal = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmpresasCompanion(
                id: id,
                nombre: nombre,
                tipoNegocio: tipoNegocio,
                modo: modo,
                pais: pais,
                moneda: moneda,
                regimen: regimen,
                horaCierreMinutos: horaCierreMinutos,
                identificacionFiscal: identificacionFiscal,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required TipoNegocio tipoNegocio,
                required ModoEmpresa modo,
                required String pais,
                required String moneda,
                Value<String?> regimen = const Value.absent(),
                required int horaCierreMinutos,
                Value<String?> identificacionFiscal = const Value.absent(),
                required DateTime creadoEn,
                Value<int> rowid = const Value.absent(),
              }) => EmpresasCompanion.insert(
                id: id,
                nombre: nombre,
                tipoNegocio: tipoNegocio,
                modo: modo,
                pais: pais,
                moneda: moneda,
                regimen: regimen,
                horaCierreMinutos: horaCierreMinutos,
                identificacionFiscal: identificacionFiscal,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EmpresasTable, Empresa>(table),
                  $$EmpresasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                membresiasRefs = false,
                cuentasRefs = false,
                contrapartesRefs = false,
                comprobantesRefs = false,
                categoriasRefs = false,
                movimientosRefs = false,
                arqueosRefs = false,
                alertasRefs = false,
                bitacoraRefs = false,
                diasCerradosRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (membresiasRefs) db.membresias,
                    if (cuentasRefs) db.cuentas,
                    if (contrapartesRefs) db.contrapartes,
                    if (comprobantesRefs) db.comprobantes,
                    if (categoriasRefs) db.categorias,
                    if (movimientosRefs) db.movimientos,
                    if (arqueosRefs) db.arqueos,
                    if (alertasRefs) db.alertas,
                    if (bitacoraRefs) db.bitacora,
                    if (diasCerradosRefs) db.diasCerrados,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (membresiasRefs)
                        await $_getPrefetchedData<
                          Empresa,
                          $EmpresasTable,
                          Membresia
                        >(
                          currentTable: table,
                          referencedTable: $$EmpresasTableReferences
                              ._membresiasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmpresasTableReferences(
                                db,
                                table,
                                p0,
                              ).membresiasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.empresaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cuentasRefs)
                        await $_getPrefetchedData<
                          Empresa,
                          $EmpresasTable,
                          Cuenta
                        >(
                          currentTable: table,
                          referencedTable: $$EmpresasTableReferences
                              ._cuentasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmpresasTableReferences(
                                db,
                                table,
                                p0,
                              ).cuentasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.empresaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contrapartesRefs)
                        await $_getPrefetchedData<
                          Empresa,
                          $EmpresasTable,
                          Contraparte
                        >(
                          currentTable: table,
                          referencedTable: $$EmpresasTableReferences
                              ._contrapartesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmpresasTableReferences(
                                db,
                                table,
                                p0,
                              ).contrapartesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.empresaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (comprobantesRefs)
                        await $_getPrefetchedData<
                          Empresa,
                          $EmpresasTable,
                          Comprobante
                        >(
                          currentTable: table,
                          referencedTable: $$EmpresasTableReferences
                              ._comprobantesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmpresasTableReferences(
                                db,
                                table,
                                p0,
                              ).comprobantesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.empresaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (categoriasRefs)
                        await $_getPrefetchedData<
                          Empresa,
                          $EmpresasTable,
                          Categoria
                        >(
                          currentTable: table,
                          referencedTable: $$EmpresasTableReferences
                              ._categoriasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmpresasTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.empresaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (movimientosRefs)
                        await $_getPrefetchedData<
                          Empresa,
                          $EmpresasTable,
                          Movimiento
                        >(
                          currentTable: table,
                          referencedTable: $$EmpresasTableReferences
                              ._movimientosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmpresasTableReferences(
                                db,
                                table,
                                p0,
                              ).movimientosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.empresaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (arqueosRefs)
                        await $_getPrefetchedData<
                          Empresa,
                          $EmpresasTable,
                          Arqueo
                        >(
                          currentTable: table,
                          referencedTable: $$EmpresasTableReferences
                              ._arqueosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmpresasTableReferences(
                                db,
                                table,
                                p0,
                              ).arqueosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.empresaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (alertasRefs)
                        await $_getPrefetchedData<
                          Empresa,
                          $EmpresasTable,
                          Alerta
                        >(
                          currentTable: table,
                          referencedTable: $$EmpresasTableReferences
                              ._alertasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmpresasTableReferences(
                                db,
                                table,
                                p0,
                              ).alertasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.empresaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bitacoraRefs)
                        await $_getPrefetchedData<
                          Empresa,
                          $EmpresasTable,
                          BitacoraData
                        >(
                          currentTable: table,
                          referencedTable: $$EmpresasTableReferences
                              ._bitacoraRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmpresasTableReferences(
                                db,
                                table,
                                p0,
                              ).bitacoraRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.empresaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (diasCerradosRefs)
                        await $_getPrefetchedData<
                          Empresa,
                          $EmpresasTable,
                          DiasCerrado
                        >(
                          currentTable: table,
                          referencedTable: $$EmpresasTableReferences
                              ._diasCerradosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmpresasTableReferences(
                                db,
                                table,
                                p0,
                              ).diasCerradosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.empresaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EmpresasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $EmpresasTable,
      Empresa,
      $$EmpresasTableFilterComposer,
      $$EmpresasTableOrderingComposer,
      $$EmpresasTableAnnotationComposer,
      $$EmpresasTableCreateCompanionBuilder,
      $$EmpresasTableUpdateCompanionBuilder,
      (Empresa, $$EmpresasTableReferences),
      Empresa,
      PrefetchHooks Function({
        bool membresiasRefs,
        bool cuentasRefs,
        bool contrapartesRefs,
        bool comprobantesRefs,
        bool categoriasRefs,
        bool movimientosRefs,
        bool arqueosRefs,
        bool alertasRefs,
        bool bitacoraRefs,
        bool diasCerradosRefs,
      })
    >;
typedef $$MembresiasTableCreateCompanionBuilder = MembresiasCompanion Function({
  required String id,
  required String usuarioId,
  required String empresaId,
  required Rol rol,
  Value<int> rowid,
});
typedef $$MembresiasTableUpdateCompanionBuilder = MembresiasCompanion Function({
  Value<String> id,
  Value<String> usuarioId,
  Value<String> empresaId,
  Value<Rol> rol,
  Value<int> rowid,
});

final class $$MembresiasTableReferences
    extends BaseReferences<_$BaseLocal, $MembresiasTable, Membresia> {
  $$MembresiasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsuariosTable _usuarioIdTable(_$BaseLocal db) =>
      db.usuarios.createAlias('membresias__usuario_id__usuarios__id');

  $$UsuariosTableProcessedTableManager get usuarioId {
    final $_column = $_itemColumn<String>('usuario_id')!;

    final manager = $$UsuariosTableTableManager(
      $_db,
      $_db.usuarios,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_usuarioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EmpresasTable _empresaIdTable(_$BaseLocal db) =>
      db.empresas.createAlias('membresias__empresa_id__empresas__id');

  $$EmpresasTableProcessedTableManager get empresaId {
    final $_column = $_itemColumn<String>('empresa_id')!;

    final manager = $$EmpresasTableTableManager(
      $_db,
      $_db.empresas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_empresaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MembresiasTableFilterComposer
    extends Composer<_$BaseLocal, $MembresiasTable> {
  $$MembresiasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Rol, Rol, String> get rol =>
      $composableBuilder(
        column: $table.rol,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$UsuariosTableFilterComposer get usuarioId {
    final $$UsuariosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.usuarioId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableFilterComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EmpresasTableFilterComposer get empresaId {
    final $$EmpresasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableFilterComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembresiasTableOrderingComposer
    extends Composer<_$BaseLocal, $MembresiasTable> {
  $$MembresiasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsuariosTableOrderingComposer get usuarioId {
    final $$UsuariosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.usuarioId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableOrderingComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EmpresasTableOrderingComposer get empresaId {
    final $$EmpresasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableOrderingComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembresiasTableAnnotationComposer
    extends Composer<_$BaseLocal, $MembresiasTable> {
  $$MembresiasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Rol, String> get rol =>
      $composableBuilder(column: $table.rol, builder: (column) => column);

  $$UsuariosTableAnnotationComposer get usuarioId {
    final $$UsuariosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.usuarioId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableAnnotationComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EmpresasTableAnnotationComposer get empresaId {
    final $$EmpresasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableAnnotationComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembresiasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $MembresiasTable,
          Membresia,
          $$MembresiasTableFilterComposer,
          $$MembresiasTableOrderingComposer,
          $$MembresiasTableAnnotationComposer,
          $$MembresiasTableCreateCompanionBuilder,
          $$MembresiasTableUpdateCompanionBuilder,
          (Membresia, $$MembresiasTableReferences),
          Membresia,
          PrefetchHooks Function({bool usuarioId, bool empresaId})
        > {
  $$MembresiasTableTableManager(_$BaseLocal db, $MembresiasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembresiasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembresiasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembresiasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> usuarioId = const Value.absent(),
                Value<String> empresaId = const Value.absent(),
                Value<Rol> rol = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembresiasCompanion(
                id: id,
                usuarioId: usuarioId,
                empresaId: empresaId,
                rol: rol,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String usuarioId,
                required String empresaId,
                required Rol rol,
                Value<int> rowid = const Value.absent(),
              }) => MembresiasCompanion.insert(
                id: id,
                usuarioId: usuarioId,
                empresaId: empresaId,
                rol: rol,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MembresiasTable, Membresia>(table),
                  $$MembresiasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({usuarioId = false, empresaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (usuarioId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.usuarioId,
                        referencedTable: $$MembresiasTableReferences
                            ._usuarioIdTable(db),
                        referencedColumn: $$MembresiasTableReferences
                            ._usuarioIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (empresaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.empresaId,
                        referencedTable: $$MembresiasTableReferences
                            ._empresaIdTable(db),
                        referencedColumn: $$MembresiasTableReferences
                            ._empresaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MembresiasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $MembresiasTable,
      Membresia,
      $$MembresiasTableFilterComposer,
      $$MembresiasTableOrderingComposer,
      $$MembresiasTableAnnotationComposer,
      $$MembresiasTableCreateCompanionBuilder,
      $$MembresiasTableUpdateCompanionBuilder,
      (Membresia, $$MembresiasTableReferences),
      Membresia,
      PrefetchHooks Function({bool usuarioId, bool empresaId})
    >;
typedef $$CuentasTableCreateCompanionBuilder = CuentasCompanion Function({
  required String id,
  required String empresaId,
  required TipoCuenta tipo,
  required String nombre,
  Value<int?> saldoInicialCentimos,
  Value<DateTime?> fechaSaldoInicial,
  required int orden,
  Value<int> rowid,
});
typedef $$CuentasTableUpdateCompanionBuilder = CuentasCompanion Function({
  Value<String> id,
  Value<String> empresaId,
  Value<TipoCuenta> tipo,
  Value<String> nombre,
  Value<int?> saldoInicialCentimos,
  Value<DateTime?> fechaSaldoInicial,
  Value<int> orden,
  Value<int> rowid,
});

final class $$CuentasTableReferences
    extends BaseReferences<_$BaseLocal, $CuentasTable, Cuenta> {
  $$CuentasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmpresasTable _empresaIdTable(_$BaseLocal db) =>
      db.empresas.createAlias('cuentas__empresa_id__empresas__id');

  $$EmpresasTableProcessedTableManager get empresaId {
    final $_column = $_itemColumn<String>('empresa_id')!;

    final manager = $$EmpresasTableTableManager(
      $_db,
      $_db.empresas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_empresaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ArqueoCuentasTable, List<ArqueoCuenta>>
  _arqueoCuentasRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.arqueoCuentas,
    aliasName: 'cuentas__id__arqueo_cuentas__cuenta_id',
  );

  $$ArqueoCuentasTableProcessedTableManager get arqueoCuentasRefs {
    final manager = $$ArqueoCuentasTableTableManager(
      $_db,
      $_db.arqueoCuentas,
    ).filter((f) => f.cuentaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_arqueoCuentasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CuentasTableFilterComposer
    extends Composer<_$BaseLocal, $CuentasTable> {
  $$CuentasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TipoCuenta, TipoCuenta, String> get tipo =>
      $composableBuilder(
        column: $table.tipo,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saldoInicialCentimos => $composableBuilder(
    column: $table.saldoInicialCentimos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaSaldoInicial => $composableBuilder(
    column: $table.fechaSaldoInicial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  $$EmpresasTableFilterComposer get empresaId {
    final $$EmpresasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableFilterComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> arqueoCuentasRefs(
    Expression<bool> Function($$ArqueoCuentasTableFilterComposer f) f,
  ) {
    final $$ArqueoCuentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arqueoCuentas,
      getReferencedColumn: (t) => t.cuentaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueoCuentasTableFilterComposer(
            $db: $db,
            $table: $db.arqueoCuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CuentasTableOrderingComposer
    extends Composer<_$BaseLocal, $CuentasTable> {
  $$CuentasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saldoInicialCentimos => $composableBuilder(
    column: $table.saldoInicialCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaSaldoInicial => $composableBuilder(
    column: $table.fechaSaldoInicial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmpresasTableOrderingComposer get empresaId {
    final $$EmpresasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableOrderingComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CuentasTableAnnotationComposer
    extends Composer<_$BaseLocal, $CuentasTable> {
  $$CuentasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TipoCuenta, String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<int> get saldoInicialCentimos => $composableBuilder(
    column: $table.saldoInicialCentimos,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaSaldoInicial => $composableBuilder(
    column: $table.fechaSaldoInicial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  $$EmpresasTableAnnotationComposer get empresaId {
    final $$EmpresasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableAnnotationComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> arqueoCuentasRefs<T extends Object>(
    Expression<T> Function($$ArqueoCuentasTableAnnotationComposer a) f,
  ) {
    final $$ArqueoCuentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arqueoCuentas,
      getReferencedColumn: (t) => t.cuentaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueoCuentasTableAnnotationComposer(
            $db: $db,
            $table: $db.arqueoCuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CuentasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $CuentasTable,
          Cuenta,
          $$CuentasTableFilterComposer,
          $$CuentasTableOrderingComposer,
          $$CuentasTableAnnotationComposer,
          $$CuentasTableCreateCompanionBuilder,
          $$CuentasTableUpdateCompanionBuilder,
          (Cuenta, $$CuentasTableReferences),
          Cuenta,
          PrefetchHooks Function({bool empresaId, bool arqueoCuentasRefs})
        > {
  $$CuentasTableTableManager(_$BaseLocal db, $CuentasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CuentasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CuentasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CuentasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> empresaId = const Value.absent(),
                Value<TipoCuenta> tipo = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<int?> saldoInicialCentimos = const Value.absent(),
                Value<DateTime?> fechaSaldoInicial = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CuentasCompanion(
                id: id,
                empresaId: empresaId,
                tipo: tipo,
                nombre: nombre,
                saldoInicialCentimos: saldoInicialCentimos,
                fechaSaldoInicial: fechaSaldoInicial,
                orden: orden,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String empresaId,
                required TipoCuenta tipo,
                required String nombre,
                Value<int?> saldoInicialCentimos = const Value.absent(),
                Value<DateTime?> fechaSaldoInicial = const Value.absent(),
                required int orden,
                Value<int> rowid = const Value.absent(),
              }) => CuentasCompanion.insert(
                id: id,
                empresaId: empresaId,
                tipo: tipo,
                nombre: nombre,
                saldoInicialCentimos: saldoInicialCentimos,
                fechaSaldoInicial: fechaSaldoInicial,
                orden: orden,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CuentasTable, Cuenta>(table),
                  $$CuentasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({empresaId = false, arqueoCuentasRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (arqueoCuentasRefs) db.arqueoCuentas,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (empresaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.empresaId,
                            referencedTable: $$CuentasTableReferences
                                ._empresaIdTable(db),
                            referencedColumn: $$CuentasTableReferences
                                ._empresaIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (arqueoCuentasRefs)
                        await $_getPrefetchedData<
                          Cuenta,
                          $CuentasTable,
                          ArqueoCuenta
                        >(
                          currentTable: table,
                          referencedTable: $$CuentasTableReferences
                              ._arqueoCuentasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CuentasTableReferences(
                                db,
                                table,
                                p0,
                              ).arqueoCuentasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cuentaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CuentasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $CuentasTable,
      Cuenta,
      $$CuentasTableFilterComposer,
      $$CuentasTableOrderingComposer,
      $$CuentasTableAnnotationComposer,
      $$CuentasTableCreateCompanionBuilder,
      $$CuentasTableUpdateCompanionBuilder,
      (Cuenta, $$CuentasTableReferences),
      Cuenta,
      PrefetchHooks Function({bool empresaId, bool arqueoCuentasRefs})
    >;
typedef $$ContrapartesTableCreateCompanionBuilder =
    ContrapartesCompanion Function({
      required String id,
      required String empresaId,
      required String nombre,
      Value<String?> identificacionFiscal,
      required TipoContraparte tipo,
      Value<int> rowid,
    });
typedef $$ContrapartesTableUpdateCompanionBuilder =
    ContrapartesCompanion Function({
      Value<String> id,
      Value<String> empresaId,
      Value<String> nombre,
      Value<String?> identificacionFiscal,
      Value<TipoContraparte> tipo,
      Value<int> rowid,
    });

final class $$ContrapartesTableReferences
    extends BaseReferences<_$BaseLocal, $ContrapartesTable, Contraparte> {
  $$ContrapartesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmpresasTable _empresaIdTable(_$BaseLocal db) =>
      db.empresas.createAlias('contrapartes__empresa_id__empresas__id');

  $$EmpresasTableProcessedTableManager get empresaId {
    final $_column = $_itemColumn<String>('empresa_id')!;

    final manager = $$EmpresasTableTableManager(
      $_db,
      $_db.empresas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_empresaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MovimientosTable, List<Movimiento>>
  _movimientosRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.movimientos,
    aliasName: 'contrapartes__id__movimientos__contraparte_id',
  );

  $$MovimientosTableProcessedTableManager get movimientosRefs {
    final manager = $$MovimientosTableTableManager(
      $_db,
      $_db.movimientos,
    ).filter((f) => f.contraparteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movimientosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContrapartesTableFilterComposer
    extends Composer<_$BaseLocal, $ContrapartesTable> {
  $$ContrapartesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identificacionFiscal => $composableBuilder(
    column: $table.identificacionFiscal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TipoContraparte, TipoContraparte, String>
  get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$EmpresasTableFilterComposer get empresaId {
    final $$EmpresasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableFilterComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> movimientosRefs(
    Expression<bool> Function($$MovimientosTableFilterComposer f) f,
  ) {
    final $$MovimientosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.contraparteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableFilterComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContrapartesTableOrderingComposer
    extends Composer<_$BaseLocal, $ContrapartesTable> {
  $$ContrapartesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identificacionFiscal => $composableBuilder(
    column: $table.identificacionFiscal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmpresasTableOrderingComposer get empresaId {
    final $$EmpresasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableOrderingComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContrapartesTableAnnotationComposer
    extends Composer<_$BaseLocal, $ContrapartesTable> {
  $$ContrapartesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get identificacionFiscal => $composableBuilder(
    column: $table.identificacionFiscal,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TipoContraparte, String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  $$EmpresasTableAnnotationComposer get empresaId {
    final $$EmpresasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableAnnotationComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> movimientosRefs<T extends Object>(
    Expression<T> Function($$MovimientosTableAnnotationComposer a) f,
  ) {
    final $$MovimientosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.contraparteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableAnnotationComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContrapartesTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $ContrapartesTable,
          Contraparte,
          $$ContrapartesTableFilterComposer,
          $$ContrapartesTableOrderingComposer,
          $$ContrapartesTableAnnotationComposer,
          $$ContrapartesTableCreateCompanionBuilder,
          $$ContrapartesTableUpdateCompanionBuilder,
          (Contraparte, $$ContrapartesTableReferences),
          Contraparte,
          PrefetchHooks Function({bool empresaId, bool movimientosRefs})
        > {
  $$ContrapartesTableTableManager(_$BaseLocal db, $ContrapartesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContrapartesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContrapartesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContrapartesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> empresaId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> identificacionFiscal = const Value.absent(),
                Value<TipoContraparte> tipo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContrapartesCompanion(
                id: id,
                empresaId: empresaId,
                nombre: nombre,
                identificacionFiscal: identificacionFiscal,
                tipo: tipo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String empresaId,
                required String nombre,
                Value<String?> identificacionFiscal = const Value.absent(),
                required TipoContraparte tipo,
                Value<int> rowid = const Value.absent(),
              }) => ContrapartesCompanion.insert(
                id: id,
                empresaId: empresaId,
                nombre: nombre,
                identificacionFiscal: identificacionFiscal,
                tipo: tipo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContrapartesTable, Contraparte>(table),
                  $$ContrapartesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({empresaId = false, movimientosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movimientosRefs) db.movimientos,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (empresaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.empresaId,
                            referencedTable: $$ContrapartesTableReferences
                                ._empresaIdTable(db),
                            referencedColumn: $$ContrapartesTableReferences
                                ._empresaIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movimientosRefs)
                        await $_getPrefetchedData<
                          Contraparte,
                          $ContrapartesTable,
                          Movimiento
                        >(
                          currentTable: table,
                          referencedTable: $$ContrapartesTableReferences
                              ._movimientosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContrapartesTableReferences(
                                db,
                                table,
                                p0,
                              ).movimientosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contraparteId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ContrapartesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $ContrapartesTable,
      Contraparte,
      $$ContrapartesTableFilterComposer,
      $$ContrapartesTableOrderingComposer,
      $$ContrapartesTableAnnotationComposer,
      $$ContrapartesTableCreateCompanionBuilder,
      $$ContrapartesTableUpdateCompanionBuilder,
      (Contraparte, $$ContrapartesTableReferences),
      Contraparte,
      PrefetchHooks Function({bool empresaId, bool movimientosRefs})
    >;
typedef $$ComprobantesTableCreateCompanionBuilder =
    ComprobantesCompanion Function({
      required String id,
      required String empresaId,
      Value<String?> emisorIdentificacion,
      Value<String?> emisorNombre,
      Value<String?> tipo,
      Value<String?> serie,
      Value<String?> numero,
      Value<DateTime?> fechaEmision,
      Value<int?> subtotalCentimos,
      Value<int?> impuestoCentimos,
      required int totalCentimos,
      Value<String?> rutaImagen,
      required OrigenLectura origenLectura,
      required DateTime creadoEn,
      Value<int> rowid,
    });
typedef $$ComprobantesTableUpdateCompanionBuilder =
    ComprobantesCompanion Function({
      Value<String> id,
      Value<String> empresaId,
      Value<String?> emisorIdentificacion,
      Value<String?> emisorNombre,
      Value<String?> tipo,
      Value<String?> serie,
      Value<String?> numero,
      Value<DateTime?> fechaEmision,
      Value<int?> subtotalCentimos,
      Value<int?> impuestoCentimos,
      Value<int> totalCentimos,
      Value<String?> rutaImagen,
      Value<OrigenLectura> origenLectura,
      Value<DateTime> creadoEn,
      Value<int> rowid,
    });

final class $$ComprobantesTableReferences
    extends BaseReferences<_$BaseLocal, $ComprobantesTable, Comprobante> {
  $$ComprobantesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmpresasTable _empresaIdTable(_$BaseLocal db) =>
      db.empresas.createAlias('comprobantes__empresa_id__empresas__id');

  $$EmpresasTableProcessedTableManager get empresaId {
    final $_column = $_itemColumn<String>('empresa_id')!;

    final manager = $$EmpresasTableTableManager(
      $_db,
      $_db.empresas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_empresaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemsComprobanteTable, List<ItemsComprobanteData>>
  _itemsComprobanteRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.itemsComprobante,
    aliasName: 'comprobantes__id__items_comprobante__comprobante_id',
  );

  $$ItemsComprobanteTableProcessedTableManager get itemsComprobanteRefs {
    final manager = $$ItemsComprobanteTableTableManager(
      $_db,
      $_db.itemsComprobante,
    ).filter((f) => f.comprobanteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _itemsComprobanteRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MovimientosTable, List<Movimiento>>
  _movimientosRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.movimientos,
    aliasName: 'comprobantes__id__movimientos__comprobante_id',
  );

  $$MovimientosTableProcessedTableManager get movimientosRefs {
    final manager = $$MovimientosTableTableManager(
      $_db,
      $_db.movimientos,
    ).filter((f) => f.comprobanteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movimientosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ComprobantesTableFilterComposer
    extends Composer<_$BaseLocal, $ComprobantesTable> {
  $$ComprobantesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emisorIdentificacion => $composableBuilder(
    column: $table.emisorIdentificacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emisorNombre => $composableBuilder(
    column: $table.emisorNombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serie => $composableBuilder(
    column: $table.serie,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numero => $composableBuilder(
    column: $table.numero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaEmision => $composableBuilder(
    column: $table.fechaEmision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalCentimos => $composableBuilder(
    column: $table.subtotalCentimos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get impuestoCentimos => $composableBuilder(
    column: $table.impuestoCentimos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCentimos => $composableBuilder(
    column: $table.totalCentimos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rutaImagen => $composableBuilder(
    column: $table.rutaImagen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OrigenLectura, OrigenLectura, String>
  get origenLectura => $composableBuilder(
    column: $table.origenLectura,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  $$EmpresasTableFilterComposer get empresaId {
    final $$EmpresasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableFilterComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemsComprobanteRefs(
    Expression<bool> Function($$ItemsComprobanteTableFilterComposer f) f,
  ) {
    final $$ItemsComprobanteTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsComprobante,
      getReferencedColumn: (t) => t.comprobanteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsComprobanteTableFilterComposer(
            $db: $db,
            $table: $db.itemsComprobante,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> movimientosRefs(
    Expression<bool> Function($$MovimientosTableFilterComposer f) f,
  ) {
    final $$MovimientosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.comprobanteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableFilterComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComprobantesTableOrderingComposer
    extends Composer<_$BaseLocal, $ComprobantesTable> {
  $$ComprobantesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emisorIdentificacion => $composableBuilder(
    column: $table.emisorIdentificacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emisorNombre => $composableBuilder(
    column: $table.emisorNombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serie => $composableBuilder(
    column: $table.serie,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numero => $composableBuilder(
    column: $table.numero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaEmision => $composableBuilder(
    column: $table.fechaEmision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalCentimos => $composableBuilder(
    column: $table.subtotalCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get impuestoCentimos => $composableBuilder(
    column: $table.impuestoCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCentimos => $composableBuilder(
    column: $table.totalCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rutaImagen => $composableBuilder(
    column: $table.rutaImagen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origenLectura => $composableBuilder(
    column: $table.origenLectura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmpresasTableOrderingComposer get empresaId {
    final $$EmpresasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableOrderingComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ComprobantesTableAnnotationComposer
    extends Composer<_$BaseLocal, $ComprobantesTable> {
  $$ComprobantesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get emisorIdentificacion => $composableBuilder(
    column: $table.emisorIdentificacion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emisorNombre => $composableBuilder(
    column: $table.emisorNombre,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get serie =>
      $composableBuilder(column: $table.serie, builder: (column) => column);

  GeneratedColumn<String> get numero =>
      $composableBuilder(column: $table.numero, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaEmision => $composableBuilder(
    column: $table.fechaEmision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotalCentimos => $composableBuilder(
    column: $table.subtotalCentimos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get impuestoCentimos => $composableBuilder(
    column: $table.impuestoCentimos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCentimos => $composableBuilder(
    column: $table.totalCentimos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rutaImagen => $composableBuilder(
    column: $table.rutaImagen,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<OrigenLectura, String> get origenLectura =>
      $composableBuilder(
        column: $table.origenLectura,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  $$EmpresasTableAnnotationComposer get empresaId {
    final $$EmpresasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableAnnotationComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemsComprobanteRefs<T extends Object>(
    Expression<T> Function($$ItemsComprobanteTableAnnotationComposer a) f,
  ) {
    final $$ItemsComprobanteTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsComprobante,
      getReferencedColumn: (t) => t.comprobanteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsComprobanteTableAnnotationComposer(
            $db: $db,
            $table: $db.itemsComprobante,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> movimientosRefs<T extends Object>(
    Expression<T> Function($$MovimientosTableAnnotationComposer a) f,
  ) {
    final $$MovimientosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.comprobanteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableAnnotationComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComprobantesTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $ComprobantesTable,
          Comprobante,
          $$ComprobantesTableFilterComposer,
          $$ComprobantesTableOrderingComposer,
          $$ComprobantesTableAnnotationComposer,
          $$ComprobantesTableCreateCompanionBuilder,
          $$ComprobantesTableUpdateCompanionBuilder,
          (Comprobante, $$ComprobantesTableReferences),
          Comprobante,
          PrefetchHooks Function({
            bool empresaId,
            bool itemsComprobanteRefs,
            bool movimientosRefs,
          })
        > {
  $$ComprobantesTableTableManager(_$BaseLocal db, $ComprobantesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComprobantesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComprobantesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComprobantesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> empresaId = const Value.absent(),
                Value<String?> emisorIdentificacion = const Value.absent(),
                Value<String?> emisorNombre = const Value.absent(),
                Value<String?> tipo = const Value.absent(),
                Value<String?> serie = const Value.absent(),
                Value<String?> numero = const Value.absent(),
                Value<DateTime?> fechaEmision = const Value.absent(),
                Value<int?> subtotalCentimos = const Value.absent(),
                Value<int?> impuestoCentimos = const Value.absent(),
                Value<int> totalCentimos = const Value.absent(),
                Value<String?> rutaImagen = const Value.absent(),
                Value<OrigenLectura> origenLectura = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComprobantesCompanion(
                id: id,
                empresaId: empresaId,
                emisorIdentificacion: emisorIdentificacion,
                emisorNombre: emisorNombre,
                tipo: tipo,
                serie: serie,
                numero: numero,
                fechaEmision: fechaEmision,
                subtotalCentimos: subtotalCentimos,
                impuestoCentimos: impuestoCentimos,
                totalCentimos: totalCentimos,
                rutaImagen: rutaImagen,
                origenLectura: origenLectura,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String empresaId,
                Value<String?> emisorIdentificacion = const Value.absent(),
                Value<String?> emisorNombre = const Value.absent(),
                Value<String?> tipo = const Value.absent(),
                Value<String?> serie = const Value.absent(),
                Value<String?> numero = const Value.absent(),
                Value<DateTime?> fechaEmision = const Value.absent(),
                Value<int?> subtotalCentimos = const Value.absent(),
                Value<int?> impuestoCentimos = const Value.absent(),
                required int totalCentimos,
                Value<String?> rutaImagen = const Value.absent(),
                required OrigenLectura origenLectura,
                required DateTime creadoEn,
                Value<int> rowid = const Value.absent(),
              }) => ComprobantesCompanion.insert(
                id: id,
                empresaId: empresaId,
                emisorIdentificacion: emisorIdentificacion,
                emisorNombre: emisorNombre,
                tipo: tipo,
                serie: serie,
                numero: numero,
                fechaEmision: fechaEmision,
                subtotalCentimos: subtotalCentimos,
                impuestoCentimos: impuestoCentimos,
                totalCentimos: totalCentimos,
                rutaImagen: rutaImagen,
                origenLectura: origenLectura,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ComprobantesTable, Comprobante>(table),
                  $$ComprobantesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                empresaId = false,
                itemsComprobanteRefs = false,
                movimientosRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemsComprobanteRefs) db.itemsComprobante,
                    if (movimientosRefs) db.movimientos,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (empresaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.empresaId,
                            referencedTable: $$ComprobantesTableReferences
                                ._empresaIdTable(db),
                            referencedColumn: $$ComprobantesTableReferences
                                ._empresaIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemsComprobanteRefs)
                        await $_getPrefetchedData<
                          Comprobante,
                          $ComprobantesTable,
                          ItemsComprobanteData
                        >(
                          currentTable: table,
                          referencedTable: $$ComprobantesTableReferences
                              ._itemsComprobanteRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ComprobantesTableReferences(
                                db,
                                table,
                                p0,
                              ).itemsComprobanteRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.comprobanteId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (movimientosRefs)
                        await $_getPrefetchedData<
                          Comprobante,
                          $ComprobantesTable,
                          Movimiento
                        >(
                          currentTable: table,
                          referencedTable: $$ComprobantesTableReferences
                              ._movimientosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ComprobantesTableReferences(
                                db,
                                table,
                                p0,
                              ).movimientosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.comprobanteId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ComprobantesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $ComprobantesTable,
      Comprobante,
      $$ComprobantesTableFilterComposer,
      $$ComprobantesTableOrderingComposer,
      $$ComprobantesTableAnnotationComposer,
      $$ComprobantesTableCreateCompanionBuilder,
      $$ComprobantesTableUpdateCompanionBuilder,
      (Comprobante, $$ComprobantesTableReferences),
      Comprobante,
      PrefetchHooks Function({
        bool empresaId,
        bool itemsComprobanteRefs,
        bool movimientosRefs,
      })
    >;
typedef $$ItemsComprobanteTableCreateCompanionBuilder =
    ItemsComprobanteCompanion Function({
      required String id,
      required String comprobanteId,
      required String descripcion,
      Value<double?> cantidad,
      Value<int?> precioUnitarioCentimos,
      required int importeCentimos,
      Value<int> rowid,
    });
typedef $$ItemsComprobanteTableUpdateCompanionBuilder =
    ItemsComprobanteCompanion Function({
      Value<String> id,
      Value<String> comprobanteId,
      Value<String> descripcion,
      Value<double?> cantidad,
      Value<int?> precioUnitarioCentimos,
      Value<int> importeCentimos,
      Value<int> rowid,
    });

final class $$ItemsComprobanteTableReferences
    extends
        BaseReferences<
          _$BaseLocal,
          $ItemsComprobanteTable,
          ItemsComprobanteData
        > {
  $$ItemsComprobanteTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ComprobantesTable _comprobanteIdTable(_$BaseLocal db) => db
      .comprobantes
      .createAlias('items_comprobante__comprobante_id__comprobantes__id');

  $$ComprobantesTableProcessedTableManager get comprobanteId {
    final $_column = $_itemColumn<String>('comprobante_id')!;

    final manager = $$ComprobantesTableTableManager(
      $_db,
      $_db.comprobantes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_comprobanteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemsComprobanteTableFilterComposer
    extends Composer<_$BaseLocal, $ItemsComprobanteTable> {
  $$ItemsComprobanteTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get precioUnitarioCentimos => $composableBuilder(
    column: $table.precioUnitarioCentimos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importeCentimos => $composableBuilder(
    column: $table.importeCentimos,
    builder: (column) => ColumnFilters(column),
  );

  $$ComprobantesTableFilterComposer get comprobanteId {
    final $$ComprobantesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comprobanteId,
      referencedTable: $db.comprobantes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprobantesTableFilterComposer(
            $db: $db,
            $table: $db.comprobantes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsComprobanteTableOrderingComposer
    extends Composer<_$BaseLocal, $ItemsComprobanteTable> {
  $$ItemsComprobanteTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get precioUnitarioCentimos => $composableBuilder(
    column: $table.precioUnitarioCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importeCentimos => $composableBuilder(
    column: $table.importeCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  $$ComprobantesTableOrderingComposer get comprobanteId {
    final $$ComprobantesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comprobanteId,
      referencedTable: $db.comprobantes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprobantesTableOrderingComposer(
            $db: $db,
            $table: $db.comprobantes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsComprobanteTableAnnotationComposer
    extends Composer<_$BaseLocal, $ItemsComprobanteTable> {
  $$ItemsComprobanteTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<int> get precioUnitarioCentimos => $composableBuilder(
    column: $table.precioUnitarioCentimos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get importeCentimos => $composableBuilder(
    column: $table.importeCentimos,
    builder: (column) => column,
  );

  $$ComprobantesTableAnnotationComposer get comprobanteId {
    final $$ComprobantesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comprobanteId,
      referencedTable: $db.comprobantes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprobantesTableAnnotationComposer(
            $db: $db,
            $table: $db.comprobantes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsComprobanteTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $ItemsComprobanteTable,
          ItemsComprobanteData,
          $$ItemsComprobanteTableFilterComposer,
          $$ItemsComprobanteTableOrderingComposer,
          $$ItemsComprobanteTableAnnotationComposer,
          $$ItemsComprobanteTableCreateCompanionBuilder,
          $$ItemsComprobanteTableUpdateCompanionBuilder,
          (ItemsComprobanteData, $$ItemsComprobanteTableReferences),
          ItemsComprobanteData,
          PrefetchHooks Function({bool comprobanteId})
        > {
  $$ItemsComprobanteTableTableManager(
    _$BaseLocal db,
    $ItemsComprobanteTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsComprobanteTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsComprobanteTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsComprobanteTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> comprobanteId = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<double?> cantidad = const Value.absent(),
                Value<int?> precioUnitarioCentimos = const Value.absent(),
                Value<int> importeCentimos = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsComprobanteCompanion(
                id: id,
                comprobanteId: comprobanteId,
                descripcion: descripcion,
                cantidad: cantidad,
                precioUnitarioCentimos: precioUnitarioCentimos,
                importeCentimos: importeCentimos,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String comprobanteId,
                required String descripcion,
                Value<double?> cantidad = const Value.absent(),
                Value<int?> precioUnitarioCentimos = const Value.absent(),
                required int importeCentimos,
                Value<int> rowid = const Value.absent(),
              }) => ItemsComprobanteCompanion.insert(
                id: id,
                comprobanteId: comprobanteId,
                descripcion: descripcion,
                cantidad: cantidad,
                precioUnitarioCentimos: precioUnitarioCentimos,
                importeCentimos: importeCentimos,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsComprobanteTable, ItemsComprobanteData>(
                    table,
                  ),
                  $$ItemsComprobanteTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({comprobanteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (comprobanteId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.comprobanteId,
                        referencedTable: $$ItemsComprobanteTableReferences
                            ._comprobanteIdTable(db),
                        referencedColumn: $$ItemsComprobanteTableReferences
                            ._comprobanteIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ItemsComprobanteTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $ItemsComprobanteTable,
      ItemsComprobanteData,
      $$ItemsComprobanteTableFilterComposer,
      $$ItemsComprobanteTableOrderingComposer,
      $$ItemsComprobanteTableAnnotationComposer,
      $$ItemsComprobanteTableCreateCompanionBuilder,
      $$ItemsComprobanteTableUpdateCompanionBuilder,
      (ItemsComprobanteData, $$ItemsComprobanteTableReferences),
      ItemsComprobanteData,
      PrefetchHooks Function({bool comprobanteId})
    >;
typedef $$CategoriasTableCreateCompanionBuilder = CategoriasCompanion Function({
  required String id,
  required String empresaId,
  required String nombre,
  required TipoMovimiento tipoMovimiento,
  required int orden,
  Value<bool> activa,
  Value<int> rowid,
});
typedef $$CategoriasTableUpdateCompanionBuilder = CategoriasCompanion Function({
  Value<String> id,
  Value<String> empresaId,
  Value<String> nombre,
  Value<TipoMovimiento> tipoMovimiento,
  Value<int> orden,
  Value<bool> activa,
  Value<int> rowid,
});

final class $$CategoriasTableReferences
    extends BaseReferences<_$BaseLocal, $CategoriasTable, Categoria> {
  $$CategoriasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmpresasTable _empresaIdTable(_$BaseLocal db) =>
      db.empresas.createAlias('categorias__empresa_id__empresas__id');

  $$EmpresasTableProcessedTableManager get empresaId {
    final $_column = $_itemColumn<String>('empresa_id')!;

    final manager = $$EmpresasTableTableManager(
      $_db,
      $_db.empresas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_empresaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MovimientosTable, List<Movimiento>>
  _movimientosRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.movimientos,
    aliasName: 'categorias__id__movimientos__categoria_id',
  );

  $$MovimientosTableProcessedTableManager get movimientosRefs {
    final manager = $$MovimientosTableTableManager(
      $_db,
      $_db.movimientos,
    ).filter((f) => f.categoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movimientosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriasTableFilterComposer
    extends Composer<_$BaseLocal, $CategoriasTable> {
  $$CategoriasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TipoMovimiento, TipoMovimiento, String>
  get tipoMovimiento => $composableBuilder(
    column: $table.tipoMovimiento,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activa => $composableBuilder(
    column: $table.activa,
    builder: (column) => ColumnFilters(column),
  );

  $$EmpresasTableFilterComposer get empresaId {
    final $$EmpresasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableFilterComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> movimientosRefs(
    Expression<bool> Function($$MovimientosTableFilterComposer f) f,
  ) {
    final $$MovimientosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableFilterComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriasTableOrderingComposer
    extends Composer<_$BaseLocal, $CategoriasTable> {
  $$CategoriasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoMovimiento => $composableBuilder(
    column: $table.tipoMovimiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activa => $composableBuilder(
    column: $table.activa,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmpresasTableOrderingComposer get empresaId {
    final $$EmpresasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableOrderingComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriasTableAnnotationComposer
    extends Composer<_$BaseLocal, $CategoriasTable> {
  $$CategoriasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TipoMovimiento, String> get tipoMovimiento =>
      $composableBuilder(
        column: $table.tipoMovimiento,
        builder: (column) => column,
      );

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<bool> get activa =>
      $composableBuilder(column: $table.activa, builder: (column) => column);

  $$EmpresasTableAnnotationComposer get empresaId {
    final $$EmpresasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableAnnotationComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> movimientosRefs<T extends Object>(
    Expression<T> Function($$MovimientosTableAnnotationComposer a) f,
  ) {
    final $$MovimientosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableAnnotationComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $CategoriasTable,
          Categoria,
          $$CategoriasTableFilterComposer,
          $$CategoriasTableOrderingComposer,
          $$CategoriasTableAnnotationComposer,
          $$CategoriasTableCreateCompanionBuilder,
          $$CategoriasTableUpdateCompanionBuilder,
          (Categoria, $$CategoriasTableReferences),
          Categoria,
          PrefetchHooks Function({bool empresaId, bool movimientosRefs})
        > {
  $$CategoriasTableTableManager(_$BaseLocal db, $CategoriasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> empresaId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<TipoMovimiento> tipoMovimiento = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<bool> activa = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriasCompanion(
                id: id,
                empresaId: empresaId,
                nombre: nombre,
                tipoMovimiento: tipoMovimiento,
                orden: orden,
                activa: activa,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String empresaId,
                required String nombre,
                required TipoMovimiento tipoMovimiento,
                required int orden,
                Value<bool> activa = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriasCompanion.insert(
                id: id,
                empresaId: empresaId,
                nombre: nombre,
                tipoMovimiento: tipoMovimiento,
                orden: orden,
                activa: activa,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriasTable, Categoria>(table),
                  $$CategoriasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({empresaId = false, movimientosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movimientosRefs) db.movimientos,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (empresaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.empresaId,
                            referencedTable: $$CategoriasTableReferences
                                ._empresaIdTable(db),
                            referencedColumn: $$CategoriasTableReferences
                                ._empresaIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movimientosRefs)
                        await $_getPrefetchedData<
                          Categoria,
                          $CategoriasTable,
                          Movimiento
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriasTableReferences
                              ._movimientosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriasTableReferences(
                                db,
                                table,
                                p0,
                              ).movimientosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoriaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $CategoriasTable,
      Categoria,
      $$CategoriasTableFilterComposer,
      $$CategoriasTableOrderingComposer,
      $$CategoriasTableAnnotationComposer,
      $$CategoriasTableCreateCompanionBuilder,
      $$CategoriasTableUpdateCompanionBuilder,
      (Categoria, $$CategoriasTableReferences),
      Categoria,
      PrefetchHooks Function({bool empresaId, bool movimientosRefs})
    >;
typedef $$MovimientosTableCreateCompanionBuilder =
    MovimientosCompanion Function({
      required String id,
      required String empresaId,
      required TipoMovimiento tipo,
      required String cuentaId,
      Value<String?> cuentaDestinoId,
      required int montoCentimos,
      required DateTime fechaMovimiento,
      Value<DateTime?> fechaComprobante,
      required EstadoPago estadoPago,
      required int montoPagadoCentimos,
      Value<DateTime?> fechaVencimiento,
      Value<DateTime?> fechaPago,
      Value<String?> categoriaId,
      Value<String?> contraparteId,
      Value<String?> comprobanteId,
      required NivelConfianza nivelConfianza,
      required Fuente fuente,
      required String autorId,
      Value<String?> nota,
      required EstadoRegistro estado,
      Value<String?> reemplazaA,
      required EstadoSincronizacion estadoSincronizacion,
      required DateTime creadoEn,
      Value<int> rowid,
    });
typedef $$MovimientosTableUpdateCompanionBuilder =
    MovimientosCompanion Function({
      Value<String> id,
      Value<String> empresaId,
      Value<TipoMovimiento> tipo,
      Value<String> cuentaId,
      Value<String?> cuentaDestinoId,
      Value<int> montoCentimos,
      Value<DateTime> fechaMovimiento,
      Value<DateTime?> fechaComprobante,
      Value<EstadoPago> estadoPago,
      Value<int> montoPagadoCentimos,
      Value<DateTime?> fechaVencimiento,
      Value<DateTime?> fechaPago,
      Value<String?> categoriaId,
      Value<String?> contraparteId,
      Value<String?> comprobanteId,
      Value<NivelConfianza> nivelConfianza,
      Value<Fuente> fuente,
      Value<String> autorId,
      Value<String?> nota,
      Value<EstadoRegistro> estado,
      Value<String?> reemplazaA,
      Value<EstadoSincronizacion> estadoSincronizacion,
      Value<DateTime> creadoEn,
      Value<int> rowid,
    });

final class $$MovimientosTableReferences
    extends BaseReferences<_$BaseLocal, $MovimientosTable, Movimiento> {
  $$MovimientosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmpresasTable _empresaIdTable(_$BaseLocal db) =>
      db.empresas.createAlias('movimientos__empresa_id__empresas__id');

  $$EmpresasTableProcessedTableManager get empresaId {
    final $_column = $_itemColumn<String>('empresa_id')!;

    final manager = $$EmpresasTableTableManager(
      $_db,
      $_db.empresas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_empresaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CuentasTable _cuentaIdTable(_$BaseLocal db) =>
      db.cuentas.createAlias('movimientos__cuenta_id__cuentas__id');

  $$CuentasTableProcessedTableManager get cuentaId {
    final $_column = $_itemColumn<String>('cuenta_id')!;

    final manager = $$CuentasTableTableManager(
      $_db,
      $_db.cuentas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuentaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CuentasTable _cuentaDestinoIdTable(_$BaseLocal db) =>
      db.cuentas.createAlias('movimientos__cuenta_destino_id__cuentas__id');

  $$CuentasTableProcessedTableManager? get cuentaDestinoId {
    final $_column = $_itemColumn<String>('cuenta_destino_id');
    if ($_column == null) return null;
    final manager = $$CuentasTableTableManager(
      $_db,
      $_db.cuentas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuentaDestinoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriasTable _categoriaIdTable(_$BaseLocal db) =>
      db.categorias.createAlias('movimientos__categoria_id__categorias__id');

  $$CategoriasTableProcessedTableManager? get categoriaId {
    final $_column = $_itemColumn<String>('categoria_id');
    if ($_column == null) return null;
    final manager = $$CategoriasTableTableManager(
      $_db,
      $_db.categorias,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContrapartesTable _contraparteIdTable(_$BaseLocal db) => db
      .contrapartes
      .createAlias('movimientos__contraparte_id__contrapartes__id');

  $$ContrapartesTableProcessedTableManager? get contraparteId {
    final $_column = $_itemColumn<String>('contraparte_id');
    if ($_column == null) return null;
    final manager = $$ContrapartesTableTableManager(
      $_db,
      $_db.contrapartes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contraparteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ComprobantesTable _comprobanteIdTable(_$BaseLocal db) => db
      .comprobantes
      .createAlias('movimientos__comprobante_id__comprobantes__id');

  $$ComprobantesTableProcessedTableManager? get comprobanteId {
    final $_column = $_itemColumn<String>('comprobante_id');
    if ($_column == null) return null;
    final manager = $$ComprobantesTableTableManager(
      $_db,
      $_db.comprobantes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_comprobanteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsuariosTable _autorIdTable(_$BaseLocal db) =>
      db.usuarios.createAlias('movimientos__autor_id__usuarios__id');

  $$UsuariosTableProcessedTableManager get autorId {
    final $_column = $_itemColumn<String>('autor_id')!;

    final manager = $$UsuariosTableTableManager(
      $_db,
      $_db.usuarios,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_autorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ArqueoCuentasTable, List<ArqueoCuenta>>
  _arqueoCuentasRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.arqueoCuentas,
    aliasName: 'movimientos__id__arqueo_cuentas__movimiento_id',
  );

  $$ArqueoCuentasTableProcessedTableManager get arqueoCuentasRefs {
    final manager = $$ArqueoCuentasTableTableManager(
      $_db,
      $_db.arqueoCuentas,
    ).filter((f) => f.movimientoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_arqueoCuentasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MovimientosTableFilterComposer
    extends Composer<_$BaseLocal, $MovimientosTable> {
  $$MovimientosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TipoMovimiento, TipoMovimiento, String>
  get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get montoCentimos => $composableBuilder(
    column: $table.montoCentimos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaMovimiento => $composableBuilder(
    column: $table.fechaMovimiento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaComprobante => $composableBuilder(
    column: $table.fechaComprobante,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EstadoPago, EstadoPago, String>
  get estadoPago => $composableBuilder(
    column: $table.estadoPago,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get montoPagadoCentimos => $composableBuilder(
    column: $table.montoPagadoCentimos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaVencimiento => $composableBuilder(
    column: $table.fechaVencimiento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaPago => $composableBuilder(
    column: $table.fechaPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NivelConfianza, NivelConfianza, String>
  get nivelConfianza => $composableBuilder(
    column: $table.nivelConfianza,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Fuente, Fuente, String> get fuente =>
      $composableBuilder(
        column: $table.fuente,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EstadoRegistro, EstadoRegistro, String>
  get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get reemplazaA => $composableBuilder(
    column: $table.reemplazaA,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    EstadoSincronizacion,
    EstadoSincronizacion,
    String
  >
  get estadoSincronizacion => $composableBuilder(
    column: $table.estadoSincronizacion,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  $$EmpresasTableFilterComposer get empresaId {
    final $$EmpresasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableFilterComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasTableFilterComposer get cuentaId {
    final $$CuentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaId,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableFilterComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasTableFilterComposer get cuentaDestinoId {
    final $$CuentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDestinoId,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableFilterComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriasTableFilterComposer get categoriaId {
    final $$CategoriasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableFilterComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContrapartesTableFilterComposer get contraparteId {
    final $$ContrapartesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contraparteId,
      referencedTable: $db.contrapartes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContrapartesTableFilterComposer(
            $db: $db,
            $table: $db.contrapartes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComprobantesTableFilterComposer get comprobanteId {
    final $$ComprobantesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comprobanteId,
      referencedTable: $db.comprobantes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprobantesTableFilterComposer(
            $db: $db,
            $table: $db.comprobantes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsuariosTableFilterComposer get autorId {
    final $$UsuariosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.autorId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableFilterComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> arqueoCuentasRefs(
    Expression<bool> Function($$ArqueoCuentasTableFilterComposer f) f,
  ) {
    final $$ArqueoCuentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arqueoCuentas,
      getReferencedColumn: (t) => t.movimientoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueoCuentasTableFilterComposer(
            $db: $db,
            $table: $db.arqueoCuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MovimientosTableOrderingComposer
    extends Composer<_$BaseLocal, $MovimientosTable> {
  $$MovimientosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montoCentimos => $composableBuilder(
    column: $table.montoCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaMovimiento => $composableBuilder(
    column: $table.fechaMovimiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaComprobante => $composableBuilder(
    column: $table.fechaComprobante,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estadoPago => $composableBuilder(
    column: $table.estadoPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montoPagadoCentimos => $composableBuilder(
    column: $table.montoPagadoCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaVencimiento => $composableBuilder(
    column: $table.fechaVencimiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaPago => $composableBuilder(
    column: $table.fechaPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nivelConfianza => $composableBuilder(
    column: $table.nivelConfianza,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuente => $composableBuilder(
    column: $table.fuente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reemplazaA => $composableBuilder(
    column: $table.reemplazaA,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estadoSincronizacion => $composableBuilder(
    column: $table.estadoSincronizacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmpresasTableOrderingComposer get empresaId {
    final $$EmpresasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableOrderingComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasTableOrderingComposer get cuentaId {
    final $$CuentasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaId,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableOrderingComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasTableOrderingComposer get cuentaDestinoId {
    final $$CuentasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDestinoId,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableOrderingComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriasTableOrderingComposer get categoriaId {
    final $$CategoriasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableOrderingComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContrapartesTableOrderingComposer get contraparteId {
    final $$ContrapartesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contraparteId,
      referencedTable: $db.contrapartes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContrapartesTableOrderingComposer(
            $db: $db,
            $table: $db.contrapartes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComprobantesTableOrderingComposer get comprobanteId {
    final $$ComprobantesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comprobanteId,
      referencedTable: $db.comprobantes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprobantesTableOrderingComposer(
            $db: $db,
            $table: $db.comprobantes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsuariosTableOrderingComposer get autorId {
    final $$UsuariosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.autorId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableOrderingComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosTableAnnotationComposer
    extends Composer<_$BaseLocal, $MovimientosTable> {
  $$MovimientosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TipoMovimiento, String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<int> get montoCentimos => $composableBuilder(
    column: $table.montoCentimos,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaMovimiento => $composableBuilder(
    column: $table.fechaMovimiento,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaComprobante => $composableBuilder(
    column: $table.fechaComprobante,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EstadoPago, String> get estadoPago =>
      $composableBuilder(
        column: $table.estadoPago,
        builder: (column) => column,
      );

  GeneratedColumn<int> get montoPagadoCentimos => $composableBuilder(
    column: $table.montoPagadoCentimos,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaVencimiento => $composableBuilder(
    column: $table.fechaVencimiento,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaPago =>
      $composableBuilder(column: $table.fechaPago, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NivelConfianza, String> get nivelConfianza =>
      $composableBuilder(
        column: $table.nivelConfianza,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Fuente, String> get fuente =>
      $composableBuilder(column: $table.fuente, builder: (column) => column);

  GeneratedColumn<String> get nota =>
      $composableBuilder(column: $table.nota, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EstadoRegistro, String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get reemplazaA => $composableBuilder(
    column: $table.reemplazaA,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EstadoSincronizacion, String>
  get estadoSincronizacion => $composableBuilder(
    column: $table.estadoSincronizacion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  $$EmpresasTableAnnotationComposer get empresaId {
    final $$EmpresasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableAnnotationComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasTableAnnotationComposer get cuentaId {
    final $$CuentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaId,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasTableAnnotationComposer get cuentaDestinoId {
    final $$CuentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDestinoId,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriasTableAnnotationComposer get categoriaId {
    final $$CategoriasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableAnnotationComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContrapartesTableAnnotationComposer get contraparteId {
    final $$ContrapartesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contraparteId,
      referencedTable: $db.contrapartes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContrapartesTableAnnotationComposer(
            $db: $db,
            $table: $db.contrapartes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComprobantesTableAnnotationComposer get comprobanteId {
    final $$ComprobantesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comprobanteId,
      referencedTable: $db.comprobantes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprobantesTableAnnotationComposer(
            $db: $db,
            $table: $db.comprobantes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsuariosTableAnnotationComposer get autorId {
    final $$UsuariosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.autorId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableAnnotationComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> arqueoCuentasRefs<T extends Object>(
    Expression<T> Function($$ArqueoCuentasTableAnnotationComposer a) f,
  ) {
    final $$ArqueoCuentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arqueoCuentas,
      getReferencedColumn: (t) => t.movimientoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueoCuentasTableAnnotationComposer(
            $db: $db,
            $table: $db.arqueoCuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MovimientosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $MovimientosTable,
          Movimiento,
          $$MovimientosTableFilterComposer,
          $$MovimientosTableOrderingComposer,
          $$MovimientosTableAnnotationComposer,
          $$MovimientosTableCreateCompanionBuilder,
          $$MovimientosTableUpdateCompanionBuilder,
          (Movimiento, $$MovimientosTableReferences),
          Movimiento,
          PrefetchHooks Function({
            bool empresaId,
            bool cuentaId,
            bool cuentaDestinoId,
            bool categoriaId,
            bool contraparteId,
            bool comprobanteId,
            bool autorId,
            bool arqueoCuentasRefs,
          })
        > {
  $$MovimientosTableTableManager(_$BaseLocal db, $MovimientosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimientosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovimientosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovimientosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> empresaId = const Value.absent(),
                Value<TipoMovimiento> tipo = const Value.absent(),
                Value<String> cuentaId = const Value.absent(),
                Value<String?> cuentaDestinoId = const Value.absent(),
                Value<int> montoCentimos = const Value.absent(),
                Value<DateTime> fechaMovimiento = const Value.absent(),
                Value<DateTime?> fechaComprobante = const Value.absent(),
                Value<EstadoPago> estadoPago = const Value.absent(),
                Value<int> montoPagadoCentimos = const Value.absent(),
                Value<DateTime?> fechaVencimiento = const Value.absent(),
                Value<DateTime?> fechaPago = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                Value<String?> contraparteId = const Value.absent(),
                Value<String?> comprobanteId = const Value.absent(),
                Value<NivelConfianza> nivelConfianza = const Value.absent(),
                Value<Fuente> fuente = const Value.absent(),
                Value<String> autorId = const Value.absent(),
                Value<String?> nota = const Value.absent(),
                Value<EstadoRegistro> estado = const Value.absent(),
                Value<String?> reemplazaA = const Value.absent(),
                Value<EstadoSincronizacion> estadoSincronizacion =
                    const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosCompanion(
                id: id,
                empresaId: empresaId,
                tipo: tipo,
                cuentaId: cuentaId,
                cuentaDestinoId: cuentaDestinoId,
                montoCentimos: montoCentimos,
                fechaMovimiento: fechaMovimiento,
                fechaComprobante: fechaComprobante,
                estadoPago: estadoPago,
                montoPagadoCentimos: montoPagadoCentimos,
                fechaVencimiento: fechaVencimiento,
                fechaPago: fechaPago,
                categoriaId: categoriaId,
                contraparteId: contraparteId,
                comprobanteId: comprobanteId,
                nivelConfianza: nivelConfianza,
                fuente: fuente,
                autorId: autorId,
                nota: nota,
                estado: estado,
                reemplazaA: reemplazaA,
                estadoSincronizacion: estadoSincronizacion,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String empresaId,
                required TipoMovimiento tipo,
                required String cuentaId,
                Value<String?> cuentaDestinoId = const Value.absent(),
                required int montoCentimos,
                required DateTime fechaMovimiento,
                Value<DateTime?> fechaComprobante = const Value.absent(),
                required EstadoPago estadoPago,
                required int montoPagadoCentimos,
                Value<DateTime?> fechaVencimiento = const Value.absent(),
                Value<DateTime?> fechaPago = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                Value<String?> contraparteId = const Value.absent(),
                Value<String?> comprobanteId = const Value.absent(),
                required NivelConfianza nivelConfianza,
                required Fuente fuente,
                required String autorId,
                Value<String?> nota = const Value.absent(),
                required EstadoRegistro estado,
                Value<String?> reemplazaA = const Value.absent(),
                required EstadoSincronizacion estadoSincronizacion,
                required DateTime creadoEn,
                Value<int> rowid = const Value.absent(),
              }) => MovimientosCompanion.insert(
                id: id,
                empresaId: empresaId,
                tipo: tipo,
                cuentaId: cuentaId,
                cuentaDestinoId: cuentaDestinoId,
                montoCentimos: montoCentimos,
                fechaMovimiento: fechaMovimiento,
                fechaComprobante: fechaComprobante,
                estadoPago: estadoPago,
                montoPagadoCentimos: montoPagadoCentimos,
                fechaVencimiento: fechaVencimiento,
                fechaPago: fechaPago,
                categoriaId: categoriaId,
                contraparteId: contraparteId,
                comprobanteId: comprobanteId,
                nivelConfianza: nivelConfianza,
                fuente: fuente,
                autorId: autorId,
                nota: nota,
                estado: estado,
                reemplazaA: reemplazaA,
                estadoSincronizacion: estadoSincronizacion,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MovimientosTable, Movimiento>(table),
                  $$MovimientosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                empresaId = false,
                cuentaId = false,
                cuentaDestinoId = false,
                categoriaId = false,
                contraparteId = false,
                comprobanteId = false,
                autorId = false,
                arqueoCuentasRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (arqueoCuentasRefs) db.arqueoCuentas,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (empresaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.empresaId,
                            referencedTable: $$MovimientosTableReferences
                                ._empresaIdTable(db),
                            referencedColumn: $$MovimientosTableReferences
                                ._empresaIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (cuentaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.cuentaId,
                            referencedTable: $$MovimientosTableReferences
                                ._cuentaIdTable(db),
                            referencedColumn: $$MovimientosTableReferences
                                ._cuentaIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (cuentaDestinoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.cuentaDestinoId,
                            referencedTable: $$MovimientosTableReferences
                                ._cuentaDestinoIdTable(db),
                            referencedColumn: $$MovimientosTableReferences
                                ._cuentaDestinoIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (categoriaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoriaId,
                            referencedTable: $$MovimientosTableReferences
                                ._categoriaIdTable(db),
                            referencedColumn: $$MovimientosTableReferences
                                ._categoriaIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (contraparteId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contraparteId,
                            referencedTable: $$MovimientosTableReferences
                                ._contraparteIdTable(db),
                            referencedColumn: $$MovimientosTableReferences
                                ._contraparteIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (comprobanteId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.comprobanteId,
                            referencedTable: $$MovimientosTableReferences
                                ._comprobanteIdTable(db),
                            referencedColumn: $$MovimientosTableReferences
                                ._comprobanteIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (autorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.autorId,
                            referencedTable: $$MovimientosTableReferences
                                ._autorIdTable(db),
                            referencedColumn: $$MovimientosTableReferences
                                ._autorIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (arqueoCuentasRefs)
                        await $_getPrefetchedData<
                          Movimiento,
                          $MovimientosTable,
                          ArqueoCuenta
                        >(
                          currentTable: table,
                          referencedTable: $$MovimientosTableReferences
                              ._arqueoCuentasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovimientosTableReferences(
                                db,
                                table,
                                p0,
                              ).arqueoCuentasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.movimientoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MovimientosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $MovimientosTable,
      Movimiento,
      $$MovimientosTableFilterComposer,
      $$MovimientosTableOrderingComposer,
      $$MovimientosTableAnnotationComposer,
      $$MovimientosTableCreateCompanionBuilder,
      $$MovimientosTableUpdateCompanionBuilder,
      (Movimiento, $$MovimientosTableReferences),
      Movimiento,
      PrefetchHooks Function({
        bool empresaId,
        bool cuentaId,
        bool cuentaDestinoId,
        bool categoriaId,
        bool contraparteId,
        bool comprobanteId,
        bool autorId,
        bool arqueoCuentasRefs,
      })
    >;
typedef $$ArqueosTableCreateCompanionBuilder = ArqueosCompanion Function({
  required String id,
  required String empresaId,
  required DateTime fecha,
  required String autorId,
  required DateTime creadoEn,
  Value<int> rowid,
});
typedef $$ArqueosTableUpdateCompanionBuilder = ArqueosCompanion Function({
  Value<String> id,
  Value<String> empresaId,
  Value<DateTime> fecha,
  Value<String> autorId,
  Value<DateTime> creadoEn,
  Value<int> rowid,
});

final class $$ArqueosTableReferences
    extends BaseReferences<_$BaseLocal, $ArqueosTable, Arqueo> {
  $$ArqueosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmpresasTable _empresaIdTable(_$BaseLocal db) =>
      db.empresas.createAlias('arqueos__empresa_id__empresas__id');

  $$EmpresasTableProcessedTableManager get empresaId {
    final $_column = $_itemColumn<String>('empresa_id')!;

    final manager = $$EmpresasTableTableManager(
      $_db,
      $_db.empresas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_empresaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsuariosTable _autorIdTable(_$BaseLocal db) =>
      db.usuarios.createAlias('arqueos__autor_id__usuarios__id');

  $$UsuariosTableProcessedTableManager get autorId {
    final $_column = $_itemColumn<String>('autor_id')!;

    final manager = $$UsuariosTableTableManager(
      $_db,
      $_db.usuarios,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_autorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ArqueoCuentasTable, List<ArqueoCuenta>>
  _arqueoCuentasRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.arqueoCuentas,
    aliasName: 'arqueos__id__arqueo_cuentas__arqueo_id',
  );

  $$ArqueoCuentasTableProcessedTableManager get arqueoCuentasRefs {
    final manager = $$ArqueoCuentasTableTableManager(
      $_db,
      $_db.arqueoCuentas,
    ).filter((f) => f.arqueoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_arqueoCuentasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ArqueosTableFilterComposer
    extends Composer<_$BaseLocal, $ArqueosTable> {
  $$ArqueosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  $$EmpresasTableFilterComposer get empresaId {
    final $$EmpresasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableFilterComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsuariosTableFilterComposer get autorId {
    final $$UsuariosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.autorId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableFilterComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> arqueoCuentasRefs(
    Expression<bool> Function($$ArqueoCuentasTableFilterComposer f) f,
  ) {
    final $$ArqueoCuentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arqueoCuentas,
      getReferencedColumn: (t) => t.arqueoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueoCuentasTableFilterComposer(
            $db: $db,
            $table: $db.arqueoCuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArqueosTableOrderingComposer
    extends Composer<_$BaseLocal, $ArqueosTable> {
  $$ArqueosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmpresasTableOrderingComposer get empresaId {
    final $$EmpresasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableOrderingComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsuariosTableOrderingComposer get autorId {
    final $$UsuariosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.autorId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableOrderingComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArqueosTableAnnotationComposer
    extends Composer<_$BaseLocal, $ArqueosTable> {
  $$ArqueosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  $$EmpresasTableAnnotationComposer get empresaId {
    final $$EmpresasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableAnnotationComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsuariosTableAnnotationComposer get autorId {
    final $$UsuariosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.autorId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableAnnotationComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> arqueoCuentasRefs<T extends Object>(
    Expression<T> Function($$ArqueoCuentasTableAnnotationComposer a) f,
  ) {
    final $$ArqueoCuentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.arqueoCuentas,
      getReferencedColumn: (t) => t.arqueoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueoCuentasTableAnnotationComposer(
            $db: $db,
            $table: $db.arqueoCuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArqueosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $ArqueosTable,
          Arqueo,
          $$ArqueosTableFilterComposer,
          $$ArqueosTableOrderingComposer,
          $$ArqueosTableAnnotationComposer,
          $$ArqueosTableCreateCompanionBuilder,
          $$ArqueosTableUpdateCompanionBuilder,
          (Arqueo, $$ArqueosTableReferences),
          Arqueo,
          PrefetchHooks Function({
            bool empresaId,
            bool autorId,
            bool arqueoCuentasRefs,
          })
        > {
  $$ArqueosTableTableManager(_$BaseLocal db, $ArqueosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArqueosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArqueosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArqueosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> empresaId = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> autorId = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArqueosCompanion(
                id: id,
                empresaId: empresaId,
                fecha: fecha,
                autorId: autorId,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String empresaId,
                required DateTime fecha,
                required String autorId,
                required DateTime creadoEn,
                Value<int> rowid = const Value.absent(),
              }) => ArqueosCompanion.insert(
                id: id,
                empresaId: empresaId,
                fecha: fecha,
                autorId: autorId,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArqueosTable, Arqueo>(table),
                  $$ArqueosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                empresaId = false,
                autorId = false,
                arqueoCuentasRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (arqueoCuentasRefs) db.arqueoCuentas,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (empresaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.empresaId,
                            referencedTable: $$ArqueosTableReferences
                                ._empresaIdTable(db),
                            referencedColumn: $$ArqueosTableReferences
                                ._empresaIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (autorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.autorId,
                            referencedTable: $$ArqueosTableReferences
                                ._autorIdTable(db),
                            referencedColumn: $$ArqueosTableReferences
                                ._autorIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (arqueoCuentasRefs)
                        await $_getPrefetchedData<
                          Arqueo,
                          $ArqueosTable,
                          ArqueoCuenta
                        >(
                          currentTable: table,
                          referencedTable: $$ArqueosTableReferences
                              ._arqueoCuentasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArqueosTableReferences(
                                db,
                                table,
                                p0,
                              ).arqueoCuentasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.arqueoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ArqueosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $ArqueosTable,
      Arqueo,
      $$ArqueosTableFilterComposer,
      $$ArqueosTableOrderingComposer,
      $$ArqueosTableAnnotationComposer,
      $$ArqueosTableCreateCompanionBuilder,
      $$ArqueosTableUpdateCompanionBuilder,
      (Arqueo, $$ArqueosTableReferences),
      Arqueo,
      PrefetchHooks Function({
        bool empresaId,
        bool autorId,
        bool arqueoCuentasRefs,
      })
    >;
typedef $$ArqueoCuentasTableCreateCompanionBuilder =
    ArqueoCuentasCompanion Function({
      required String id,
      required String arqueoId,
      required String cuentaId,
      required int saldoCalculadoCentimos,
      required int saldoRealCentimos,
      required int diferenciaCentimos,
      Value<MotivoArqueo?> motivo,
      Value<String?> movimientoId,
      Value<int> rowid,
    });
typedef $$ArqueoCuentasTableUpdateCompanionBuilder =
    ArqueoCuentasCompanion Function({
      Value<String> id,
      Value<String> arqueoId,
      Value<String> cuentaId,
      Value<int> saldoCalculadoCentimos,
      Value<int> saldoRealCentimos,
      Value<int> diferenciaCentimos,
      Value<MotivoArqueo?> motivo,
      Value<String?> movimientoId,
      Value<int> rowid,
    });

final class $$ArqueoCuentasTableReferences
    extends BaseReferences<_$BaseLocal, $ArqueoCuentasTable, ArqueoCuenta> {
  $$ArqueoCuentasTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ArqueosTable _arqueoIdTable(_$BaseLocal db) =>
      db.arqueos.createAlias('arqueo_cuentas__arqueo_id__arqueos__id');

  $$ArqueosTableProcessedTableManager get arqueoId {
    final $_column = $_itemColumn<String>('arqueo_id')!;

    final manager = $$ArqueosTableTableManager(
      $_db,
      $_db.arqueos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_arqueoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CuentasTable _cuentaIdTable(_$BaseLocal db) =>
      db.cuentas.createAlias('arqueo_cuentas__cuenta_id__cuentas__id');

  $$CuentasTableProcessedTableManager get cuentaId {
    final $_column = $_itemColumn<String>('cuenta_id')!;

    final manager = $$CuentasTableTableManager(
      $_db,
      $_db.cuentas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuentaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MovimientosTable _movimientoIdTable(_$BaseLocal db) => db.movimientos
      .createAlias('arqueo_cuentas__movimiento_id__movimientos__id');

  $$MovimientosTableProcessedTableManager? get movimientoId {
    final $_column = $_itemColumn<String>('movimiento_id');
    if ($_column == null) return null;
    final manager = $$MovimientosTableTableManager(
      $_db,
      $_db.movimientos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_movimientoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ArqueoCuentasTableFilterComposer
    extends Composer<_$BaseLocal, $ArqueoCuentasTable> {
  $$ArqueoCuentasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saldoCalculadoCentimos => $composableBuilder(
    column: $table.saldoCalculadoCentimos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saldoRealCentimos => $composableBuilder(
    column: $table.saldoRealCentimos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diferenciaCentimos => $composableBuilder(
    column: $table.diferenciaCentimos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MotivoArqueo?, MotivoArqueo, String>
  get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$ArqueosTableFilterComposer get arqueoId {
    final $$ArqueosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.arqueoId,
      referencedTable: $db.arqueos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueosTableFilterComposer(
            $db: $db,
            $table: $db.arqueos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasTableFilterComposer get cuentaId {
    final $$CuentasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaId,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableFilterComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovimientosTableFilterComposer get movimientoId {
    final $$MovimientosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movimientoId,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableFilterComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArqueoCuentasTableOrderingComposer
    extends Composer<_$BaseLocal, $ArqueoCuentasTable> {
  $$ArqueoCuentasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saldoCalculadoCentimos => $composableBuilder(
    column: $table.saldoCalculadoCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saldoRealCentimos => $composableBuilder(
    column: $table.saldoRealCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diferenciaCentimos => $composableBuilder(
    column: $table.diferenciaCentimos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnOrderings(column),
  );

  $$ArqueosTableOrderingComposer get arqueoId {
    final $$ArqueosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.arqueoId,
      referencedTable: $db.arqueos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueosTableOrderingComposer(
            $db: $db,
            $table: $db.arqueos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasTableOrderingComposer get cuentaId {
    final $$CuentasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaId,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableOrderingComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovimientosTableOrderingComposer get movimientoId {
    final $$MovimientosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movimientoId,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableOrderingComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArqueoCuentasTableAnnotationComposer
    extends Composer<_$BaseLocal, $ArqueoCuentasTable> {
  $$ArqueoCuentasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get saldoCalculadoCentimos => $composableBuilder(
    column: $table.saldoCalculadoCentimos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get saldoRealCentimos => $composableBuilder(
    column: $table.saldoRealCentimos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diferenciaCentimos => $composableBuilder(
    column: $table.diferenciaCentimos,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MotivoArqueo?, String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  $$ArqueosTableAnnotationComposer get arqueoId {
    final $$ArqueosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.arqueoId,
      referencedTable: $db.arqueos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArqueosTableAnnotationComposer(
            $db: $db,
            $table: $db.arqueos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasTableAnnotationComposer get cuentaId {
    final $$CuentasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaId,
      referencedTable: $db.cuentas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovimientosTableAnnotationComposer get movimientoId {
    final $$MovimientosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movimientoId,
      referencedTable: $db.movimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosTableAnnotationComposer(
            $db: $db,
            $table: $db.movimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArqueoCuentasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $ArqueoCuentasTable,
          ArqueoCuenta,
          $$ArqueoCuentasTableFilterComposer,
          $$ArqueoCuentasTableOrderingComposer,
          $$ArqueoCuentasTableAnnotationComposer,
          $$ArqueoCuentasTableCreateCompanionBuilder,
          $$ArqueoCuentasTableUpdateCompanionBuilder,
          (ArqueoCuenta, $$ArqueoCuentasTableReferences),
          ArqueoCuenta,
          PrefetchHooks Function({
            bool arqueoId,
            bool cuentaId,
            bool movimientoId,
          })
        > {
  $$ArqueoCuentasTableTableManager(_$BaseLocal db, $ArqueoCuentasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArqueoCuentasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArqueoCuentasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArqueoCuentasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> arqueoId = const Value.absent(),
                Value<String> cuentaId = const Value.absent(),
                Value<int> saldoCalculadoCentimos = const Value.absent(),
                Value<int> saldoRealCentimos = const Value.absent(),
                Value<int> diferenciaCentimos = const Value.absent(),
                Value<MotivoArqueo?> motivo = const Value.absent(),
                Value<String?> movimientoId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArqueoCuentasCompanion(
                id: id,
                arqueoId: arqueoId,
                cuentaId: cuentaId,
                saldoCalculadoCentimos: saldoCalculadoCentimos,
                saldoRealCentimos: saldoRealCentimos,
                diferenciaCentimos: diferenciaCentimos,
                motivo: motivo,
                movimientoId: movimientoId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String arqueoId,
                required String cuentaId,
                required int saldoCalculadoCentimos,
                required int saldoRealCentimos,
                required int diferenciaCentimos,
                Value<MotivoArqueo?> motivo = const Value.absent(),
                Value<String?> movimientoId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArqueoCuentasCompanion.insert(
                id: id,
                arqueoId: arqueoId,
                cuentaId: cuentaId,
                saldoCalculadoCentimos: saldoCalculadoCentimos,
                saldoRealCentimos: saldoRealCentimos,
                diferenciaCentimos: diferenciaCentimos,
                motivo: motivo,
                movimientoId: movimientoId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArqueoCuentasTable, ArqueoCuenta>(table),
                  $$ArqueoCuentasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({arqueoId = false, cuentaId = false, movimientoId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (arqueoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.arqueoId,
                            referencedTable: $$ArqueoCuentasTableReferences
                                ._arqueoIdTable(db),
                            referencedColumn: $$ArqueoCuentasTableReferences
                                ._arqueoIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (cuentaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.cuentaId,
                            referencedTable: $$ArqueoCuentasTableReferences
                                ._cuentaIdTable(db),
                            referencedColumn: $$ArqueoCuentasTableReferences
                                ._cuentaIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (movimientoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.movimientoId,
                            referencedTable: $$ArqueoCuentasTableReferences
                                ._movimientoIdTable(db),
                            referencedColumn: $$ArqueoCuentasTableReferences
                                ._movimientoIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ArqueoCuentasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $ArqueoCuentasTable,
      ArqueoCuenta,
      $$ArqueoCuentasTableFilterComposer,
      $$ArqueoCuentasTableOrderingComposer,
      $$ArqueoCuentasTableAnnotationComposer,
      $$ArqueoCuentasTableCreateCompanionBuilder,
      $$ArqueoCuentasTableUpdateCompanionBuilder,
      (ArqueoCuenta, $$ArqueoCuentasTableReferences),
      ArqueoCuenta,
      PrefetchHooks Function({bool arqueoId, bool cuentaId, bool movimientoId})
    >;
typedef $$AlertasTableCreateCompanionBuilder = AlertasCompanion Function({
  required String id,
  required String empresaId,
  required String tipo,
  required PrioridadAlerta prioridad,
  required EstadoAlerta estado,
  required String texto,
  required String datos,
  required DateTime creadoEn,
  Value<int> rowid,
});
typedef $$AlertasTableUpdateCompanionBuilder = AlertasCompanion Function({
  Value<String> id,
  Value<String> empresaId,
  Value<String> tipo,
  Value<PrioridadAlerta> prioridad,
  Value<EstadoAlerta> estado,
  Value<String> texto,
  Value<String> datos,
  Value<DateTime> creadoEn,
  Value<int> rowid,
});

final class $$AlertasTableReferences
    extends BaseReferences<_$BaseLocal, $AlertasTable, Alerta> {
  $$AlertasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmpresasTable _empresaIdTable(_$BaseLocal db) =>
      db.empresas.createAlias('alertas__empresa_id__empresas__id');

  $$EmpresasTableProcessedTableManager get empresaId {
    final $_column = $_itemColumn<String>('empresa_id')!;

    final manager = $$EmpresasTableTableManager(
      $_db,
      $_db.empresas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_empresaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AlertasTableFilterComposer
    extends Composer<_$BaseLocal, $AlertasTable> {
  $$AlertasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PrioridadAlerta, PrioridadAlerta, String>
  get prioridad => $composableBuilder(
    column: $table.prioridad,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<EstadoAlerta, EstadoAlerta, String>
  get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get texto => $composableBuilder(
    column: $table.texto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datos => $composableBuilder(
    column: $table.datos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  $$EmpresasTableFilterComposer get empresaId {
    final $$EmpresasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableFilterComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertasTableOrderingComposer
    extends Composer<_$BaseLocal, $AlertasTable> {
  $$AlertasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prioridad => $composableBuilder(
    column: $table.prioridad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get texto => $composableBuilder(
    column: $table.texto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datos => $composableBuilder(
    column: $table.datos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmpresasTableOrderingComposer get empresaId {
    final $$EmpresasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableOrderingComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertasTableAnnotationComposer
    extends Composer<_$BaseLocal, $AlertasTable> {
  $$AlertasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrioridadAlerta, String> get prioridad =>
      $composableBuilder(column: $table.prioridad, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EstadoAlerta, String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get texto =>
      $composableBuilder(column: $table.texto, builder: (column) => column);

  GeneratedColumn<String> get datos =>
      $composableBuilder(column: $table.datos, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  $$EmpresasTableAnnotationComposer get empresaId {
    final $$EmpresasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableAnnotationComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $AlertasTable,
          Alerta,
          $$AlertasTableFilterComposer,
          $$AlertasTableOrderingComposer,
          $$AlertasTableAnnotationComposer,
          $$AlertasTableCreateCompanionBuilder,
          $$AlertasTableUpdateCompanionBuilder,
          (Alerta, $$AlertasTableReferences),
          Alerta,
          PrefetchHooks Function({bool empresaId})
        > {
  $$AlertasTableTableManager(_$BaseLocal db, $AlertasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> empresaId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<PrioridadAlerta> prioridad = const Value.absent(),
                Value<EstadoAlerta> estado = const Value.absent(),
                Value<String> texto = const Value.absent(),
                Value<String> datos = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertasCompanion(
                id: id,
                empresaId: empresaId,
                tipo: tipo,
                prioridad: prioridad,
                estado: estado,
                texto: texto,
                datos: datos,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String empresaId,
                required String tipo,
                required PrioridadAlerta prioridad,
                required EstadoAlerta estado,
                required String texto,
                required String datos,
                required DateTime creadoEn,
                Value<int> rowid = const Value.absent(),
              }) => AlertasCompanion.insert(
                id: id,
                empresaId: empresaId,
                tipo: tipo,
                prioridad: prioridad,
                estado: estado,
                texto: texto,
                datos: datos,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlertasTable, Alerta>(table),
                  $$AlertasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({empresaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (empresaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.empresaId,
                        referencedTable: $$AlertasTableReferences
                            ._empresaIdTable(db),
                        referencedColumn: $$AlertasTableReferences
                            ._empresaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AlertasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $AlertasTable,
      Alerta,
      $$AlertasTableFilterComposer,
      $$AlertasTableOrderingComposer,
      $$AlertasTableAnnotationComposer,
      $$AlertasTableCreateCompanionBuilder,
      $$AlertasTableUpdateCompanionBuilder,
      (Alerta, $$AlertasTableReferences),
      Alerta,
      PrefetchHooks Function({bool empresaId})
    >;
typedef $$BitacoraTableCreateCompanionBuilder = BitacoraCompanion Function({
  required String id,
  required String empresaId,
  required String autorId,
  required String entidad,
  required String entidadId,
  required AccionBitacora accion,
  Value<String?> valorAnterior,
  Value<String?> valorNuevo,
  required DateTime fecha,
  Value<int> rowid,
});
typedef $$BitacoraTableUpdateCompanionBuilder = BitacoraCompanion Function({
  Value<String> id,
  Value<String> empresaId,
  Value<String> autorId,
  Value<String> entidad,
  Value<String> entidadId,
  Value<AccionBitacora> accion,
  Value<String?> valorAnterior,
  Value<String?> valorNuevo,
  Value<DateTime> fecha,
  Value<int> rowid,
});

final class $$BitacoraTableReferences
    extends BaseReferences<_$BaseLocal, $BitacoraTable, BitacoraData> {
  $$BitacoraTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmpresasTable _empresaIdTable(_$BaseLocal db) =>
      db.empresas.createAlias('bitacora__empresa_id__empresas__id');

  $$EmpresasTableProcessedTableManager get empresaId {
    final $_column = $_itemColumn<String>('empresa_id')!;

    final manager = $$EmpresasTableTableManager(
      $_db,
      $_db.empresas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_empresaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsuariosTable _autorIdTable(_$BaseLocal db) =>
      db.usuarios.createAlias('bitacora__autor_id__usuarios__id');

  $$UsuariosTableProcessedTableManager get autorId {
    final $_column = $_itemColumn<String>('autor_id')!;

    final manager = $$UsuariosTableTableManager(
      $_db,
      $_db.usuarios,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_autorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BitacoraTableFilterComposer
    extends Composer<_$BaseLocal, $BitacoraTable> {
  $$BitacoraTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidad => $composableBuilder(
    column: $table.entidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidadId => $composableBuilder(
    column: $table.entidadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccionBitacora, AccionBitacora, String>
  get accion => $composableBuilder(
    column: $table.accion,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get valorAnterior => $composableBuilder(
    column: $table.valorAnterior,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valorNuevo => $composableBuilder(
    column: $table.valorNuevo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  $$EmpresasTableFilterComposer get empresaId {
    final $$EmpresasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableFilterComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsuariosTableFilterComposer get autorId {
    final $$UsuariosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.autorId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableFilterComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BitacoraTableOrderingComposer
    extends Composer<_$BaseLocal, $BitacoraTable> {
  $$BitacoraTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidad => $composableBuilder(
    column: $table.entidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidadId => $composableBuilder(
    column: $table.entidadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accion => $composableBuilder(
    column: $table.accion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valorAnterior => $composableBuilder(
    column: $table.valorAnterior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valorNuevo => $composableBuilder(
    column: $table.valorNuevo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmpresasTableOrderingComposer get empresaId {
    final $$EmpresasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableOrderingComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsuariosTableOrderingComposer get autorId {
    final $$UsuariosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.autorId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableOrderingComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BitacoraTableAnnotationComposer
    extends Composer<_$BaseLocal, $BitacoraTable> {
  $$BitacoraTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entidad =>
      $composableBuilder(column: $table.entidad, builder: (column) => column);

  GeneratedColumn<String> get entidadId =>
      $composableBuilder(column: $table.entidadId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccionBitacora, String> get accion =>
      $composableBuilder(column: $table.accion, builder: (column) => column);

  GeneratedColumn<String> get valorAnterior => $composableBuilder(
    column: $table.valorAnterior,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valorNuevo => $composableBuilder(
    column: $table.valorNuevo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  $$EmpresasTableAnnotationComposer get empresaId {
    final $$EmpresasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableAnnotationComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsuariosTableAnnotationComposer get autorId {
    final $$UsuariosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.autorId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableAnnotationComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BitacoraTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $BitacoraTable,
          BitacoraData,
          $$BitacoraTableFilterComposer,
          $$BitacoraTableOrderingComposer,
          $$BitacoraTableAnnotationComposer,
          $$BitacoraTableCreateCompanionBuilder,
          $$BitacoraTableUpdateCompanionBuilder,
          (BitacoraData, $$BitacoraTableReferences),
          BitacoraData,
          PrefetchHooks Function({bool empresaId, bool autorId})
        > {
  $$BitacoraTableTableManager(_$BaseLocal db, $BitacoraTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BitacoraTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BitacoraTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BitacoraTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> empresaId = const Value.absent(),
                Value<String> autorId = const Value.absent(),
                Value<String> entidad = const Value.absent(),
                Value<String> entidadId = const Value.absent(),
                Value<AccionBitacora> accion = const Value.absent(),
                Value<String?> valorAnterior = const Value.absent(),
                Value<String?> valorNuevo = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BitacoraCompanion(
                id: id,
                empresaId: empresaId,
                autorId: autorId,
                entidad: entidad,
                entidadId: entidadId,
                accion: accion,
                valorAnterior: valorAnterior,
                valorNuevo: valorNuevo,
                fecha: fecha,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String empresaId,
                required String autorId,
                required String entidad,
                required String entidadId,
                required AccionBitacora accion,
                Value<String?> valorAnterior = const Value.absent(),
                Value<String?> valorNuevo = const Value.absent(),
                required DateTime fecha,
                Value<int> rowid = const Value.absent(),
              }) => BitacoraCompanion.insert(
                id: id,
                empresaId: empresaId,
                autorId: autorId,
                entidad: entidad,
                entidadId: entidadId,
                accion: accion,
                valorAnterior: valorAnterior,
                valorNuevo: valorNuevo,
                fecha: fecha,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BitacoraTable, BitacoraData>(table),
                  $$BitacoraTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({empresaId = false, autorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (empresaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.empresaId,
                        referencedTable: $$BitacoraTableReferences
                            ._empresaIdTable(db),
                        referencedColumn: $$BitacoraTableReferences
                            ._empresaIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (autorId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.autorId,
                        referencedTable: $$BitacoraTableReferences
                            ._autorIdTable(db),
                        referencedColumn: $$BitacoraTableReferences
                            ._autorIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BitacoraTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $BitacoraTable,
      BitacoraData,
      $$BitacoraTableFilterComposer,
      $$BitacoraTableOrderingComposer,
      $$BitacoraTableAnnotationComposer,
      $$BitacoraTableCreateCompanionBuilder,
      $$BitacoraTableUpdateCompanionBuilder,
      (BitacoraData, $$BitacoraTableReferences),
      BitacoraData,
      PrefetchHooks Function({bool empresaId, bool autorId})
    >;
typedef $$DiasCerradosTableCreateCompanionBuilder =
    DiasCerradosCompanion Function({
      required String id,
      required String empresaId,
      required DateTime dia,
      Value<int> rowid,
    });
typedef $$DiasCerradosTableUpdateCompanionBuilder =
    DiasCerradosCompanion Function({
      Value<String> id,
      Value<String> empresaId,
      Value<DateTime> dia,
      Value<int> rowid,
    });

final class $$DiasCerradosTableReferences
    extends BaseReferences<_$BaseLocal, $DiasCerradosTable, DiasCerrado> {
  $$DiasCerradosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmpresasTable _empresaIdTable(_$BaseLocal db) =>
      db.empresas.createAlias('dias_cerrados__empresa_id__empresas__id');

  $$EmpresasTableProcessedTableManager get empresaId {
    final $_column = $_itemColumn<String>('empresa_id')!;

    final manager = $$EmpresasTableTableManager(
      $_db,
      $_db.empresas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_empresaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiasCerradosTableFilterComposer
    extends Composer<_$BaseLocal, $DiasCerradosTable> {
  $$DiasCerradosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dia => $composableBuilder(
    column: $table.dia,
    builder: (column) => ColumnFilters(column),
  );

  $$EmpresasTableFilterComposer get empresaId {
    final $$EmpresasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableFilterComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiasCerradosTableOrderingComposer
    extends Composer<_$BaseLocal, $DiasCerradosTable> {
  $$DiasCerradosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dia => $composableBuilder(
    column: $table.dia,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmpresasTableOrderingComposer get empresaId {
    final $$EmpresasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableOrderingComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiasCerradosTableAnnotationComposer
    extends Composer<_$BaseLocal, $DiasCerradosTable> {
  $$DiasCerradosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get dia =>
      $composableBuilder(column: $table.dia, builder: (column) => column);

  $$EmpresasTableAnnotationComposer get empresaId {
    final $$EmpresasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.empresaId,
      referencedTable: $db.empresas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpresasTableAnnotationComposer(
            $db: $db,
            $table: $db.empresas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiasCerradosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $DiasCerradosTable,
          DiasCerrado,
          $$DiasCerradosTableFilterComposer,
          $$DiasCerradosTableOrderingComposer,
          $$DiasCerradosTableAnnotationComposer,
          $$DiasCerradosTableCreateCompanionBuilder,
          $$DiasCerradosTableUpdateCompanionBuilder,
          (DiasCerrado, $$DiasCerradosTableReferences),
          DiasCerrado,
          PrefetchHooks Function({bool empresaId})
        > {
  $$DiasCerradosTableTableManager(_$BaseLocal db, $DiasCerradosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiasCerradosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiasCerradosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiasCerradosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> empresaId = const Value.absent(),
                Value<DateTime> dia = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiasCerradosCompanion(
                id: id,
                empresaId: empresaId,
                dia: dia,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String empresaId,
                required DateTime dia,
                Value<int> rowid = const Value.absent(),
              }) => DiasCerradosCompanion.insert(
                id: id,
                empresaId: empresaId,
                dia: dia,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiasCerradosTable, DiasCerrado>(table),
                  $$DiasCerradosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({empresaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (empresaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.empresaId,
                        referencedTable: $$DiasCerradosTableReferences
                            ._empresaIdTable(db),
                        referencedColumn: $$DiasCerradosTableReferences
                            ._empresaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DiasCerradosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $DiasCerradosTable,
      DiasCerrado,
      $$DiasCerradosTableFilterComposer,
      $$DiasCerradosTableOrderingComposer,
      $$DiasCerradosTableAnnotationComposer,
      $$DiasCerradosTableCreateCompanionBuilder,
      $$DiasCerradosTableUpdateCompanionBuilder,
      (DiasCerrado, $$DiasCerradosTableReferences),
      DiasCerrado,
      PrefetchHooks Function({bool empresaId})
    >;
typedef $$EventosMedicionTableCreateCompanionBuilder =
    EventosMedicionCompanion Function({
      required String id,
      required String nombre,
      required DateTime fecha,
      Value<String?> datos,
      Value<int> rowid,
    });
typedef $$EventosMedicionTableUpdateCompanionBuilder =
    EventosMedicionCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<DateTime> fecha,
      Value<String?> datos,
      Value<int> rowid,
    });

class $$EventosMedicionTableFilterComposer
    extends Composer<_$BaseLocal, $EventosMedicionTable> {
  $$EventosMedicionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datos => $composableBuilder(
    column: $table.datos,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventosMedicionTableOrderingComposer
    extends Composer<_$BaseLocal, $EventosMedicionTable> {
  $$EventosMedicionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datos => $composableBuilder(
    column: $table.datos,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventosMedicionTableAnnotationComposer
    extends Composer<_$BaseLocal, $EventosMedicionTable> {
  $$EventosMedicionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get datos =>
      $composableBuilder(column: $table.datos, builder: (column) => column);
}

class $$EventosMedicionTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $EventosMedicionTable,
          EventosMedicionData,
          $$EventosMedicionTableFilterComposer,
          $$EventosMedicionTableOrderingComposer,
          $$EventosMedicionTableAnnotationComposer,
          $$EventosMedicionTableCreateCompanionBuilder,
          $$EventosMedicionTableUpdateCompanionBuilder,
          (
            EventosMedicionData,
            BaseReferences<
              _$BaseLocal,
              $EventosMedicionTable,
              EventosMedicionData
            >,
          ),
          EventosMedicionData,
          PrefetchHooks Function()
        > {
  $$EventosMedicionTableTableManager(
    _$BaseLocal db,
    $EventosMedicionTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventosMedicionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventosMedicionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventosMedicionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String?> datos = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventosMedicionCompanion(
                id: id,
                nombre: nombre,
                fecha: fecha,
                datos: datos,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required DateTime fecha,
                Value<String?> datos = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventosMedicionCompanion.insert(
                id: id,
                nombre: nombre,
                fecha: fecha,
                datos: datos,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventosMedicionTable, EventosMedicionData>(
                    table,
                  ),
                  BaseReferences<
                    _$BaseLocal,
                    $EventosMedicionTable,
                    EventosMedicionData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventosMedicionTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $EventosMedicionTable,
      EventosMedicionData,
      $$EventosMedicionTableFilterComposer,
      $$EventosMedicionTableOrderingComposer,
      $$EventosMedicionTableAnnotationComposer,
      $$EventosMedicionTableCreateCompanionBuilder,
      $$EventosMedicionTableUpdateCompanionBuilder,
      (
        EventosMedicionData,
        BaseReferences<_$BaseLocal, $EventosMedicionTable, EventosMedicionData>,
      ),
      EventosMedicionData,
      PrefetchHooks Function()
    >;
typedef $$AjustesTableCreateCompanionBuilder = AjustesCompanion Function({
  required String clave,
  required String valor,
  Value<int> rowid,
});
typedef $$AjustesTableUpdateCompanionBuilder = AjustesCompanion Function({
  Value<String> clave,
  Value<String> valor,
  Value<int> rowid,
});

class $$AjustesTableFilterComposer
    extends Composer<_$BaseLocal, $AjustesTable> {
  $$AjustesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AjustesTableOrderingComposer
    extends Composer<_$BaseLocal, $AjustesTable> {
  $$AjustesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AjustesTableAnnotationComposer
    extends Composer<_$BaseLocal, $AjustesTable> {
  $$AjustesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => column);

  GeneratedColumn<String> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);
}

class $$AjustesTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $AjustesTable,
          Ajuste,
          $$AjustesTableFilterComposer,
          $$AjustesTableOrderingComposer,
          $$AjustesTableAnnotationComposer,
          $$AjustesTableCreateCompanionBuilder,
          $$AjustesTableUpdateCompanionBuilder,
          (Ajuste, BaseReferences<_$BaseLocal, $AjustesTable, Ajuste>),
          Ajuste,
          PrefetchHooks Function()
        > {
  $$AjustesTableTableManager(_$BaseLocal db, $AjustesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AjustesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AjustesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AjustesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> clave = const Value.absent(),
            Value<String> valor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AjustesCompanion(clave: clave, valor: valor, rowid: rowid),
          createCompanionCallback:
              ({
                required String clave,
                required String valor,
                Value<int> rowid = const Value.absent(),
              }) => AjustesCompanion.insert(
                clave: clave,
                valor: valor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AjustesTable, Ajuste>(table),
                  BaseReferences<_$BaseLocal, $AjustesTable, Ajuste>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AjustesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $AjustesTable,
      Ajuste,
      $$AjustesTableFilterComposer,
      $$AjustesTableOrderingComposer,
      $$AjustesTableAnnotationComposer,
      $$AjustesTableCreateCompanionBuilder,
      $$AjustesTableUpdateCompanionBuilder,
      (Ajuste, BaseReferences<_$BaseLocal, $AjustesTable, Ajuste>),
      Ajuste,
      PrefetchHooks Function()
    >;
typedef $$SubidasTableCreateCompanionBuilder = SubidasCompanion Function({
  required String tabla,
  required String filaId,
  required String huella,
  Value<int> rowid,
});
typedef $$SubidasTableUpdateCompanionBuilder = SubidasCompanion Function({
  Value<String> tabla,
  Value<String> filaId,
  Value<String> huella,
  Value<int> rowid,
});

class $$SubidasTableFilterComposer
    extends Composer<_$BaseLocal, $SubidasTable> {
  $$SubidasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filaId => $composableBuilder(
    column: $table.filaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get huella => $composableBuilder(
    column: $table.huella,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubidasTableOrderingComposer
    extends Composer<_$BaseLocal, $SubidasTable> {
  $$SubidasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filaId => $composableBuilder(
    column: $table.filaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get huella => $composableBuilder(
    column: $table.huella,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubidasTableAnnotationComposer
    extends Composer<_$BaseLocal, $SubidasTable> {
  $$SubidasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tabla =>
      $composableBuilder(column: $table.tabla, builder: (column) => column);

  GeneratedColumn<String> get filaId =>
      $composableBuilder(column: $table.filaId, builder: (column) => column);

  GeneratedColumn<String> get huella =>
      $composableBuilder(column: $table.huella, builder: (column) => column);
}

class $$SubidasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $SubidasTable,
          Subida,
          $$SubidasTableFilterComposer,
          $$SubidasTableOrderingComposer,
          $$SubidasTableAnnotationComposer,
          $$SubidasTableCreateCompanionBuilder,
          $$SubidasTableUpdateCompanionBuilder,
          (Subida, BaseReferences<_$BaseLocal, $SubidasTable, Subida>),
          Subida,
          PrefetchHooks Function()
        > {
  $$SubidasTableTableManager(_$BaseLocal db, $SubidasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubidasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubidasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubidasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tabla = const Value.absent(),
                Value<String> filaId = const Value.absent(),
                Value<String> huella = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubidasCompanion(
                tabla: tabla,
                filaId: filaId,
                huella: huella,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tabla,
                required String filaId,
                required String huella,
                Value<int> rowid = const Value.absent(),
              }) => SubidasCompanion.insert(
                tabla: tabla,
                filaId: filaId,
                huella: huella,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubidasTable, Subida>(table),
                  BaseReferences<_$BaseLocal, $SubidasTable, Subida>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubidasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $SubidasTable,
      Subida,
      $$SubidasTableFilterComposer,
      $$SubidasTableOrderingComposer,
      $$SubidasTableAnnotationComposer,
      $$SubidasTableCreateCompanionBuilder,
      $$SubidasTableUpdateCompanionBuilder,
      (Subida, BaseReferences<_$BaseLocal, $SubidasTable, Subida>),
      Subida,
      PrefetchHooks Function()
    >;

class $BaseLocalManager {
  final _$BaseLocal _db;
  $BaseLocalManager(this._db);
  $$UsuariosTableTableManager get usuarios =>
      $$UsuariosTableTableManager(_db, _db.usuarios);
  $$EmpresasTableTableManager get empresas =>
      $$EmpresasTableTableManager(_db, _db.empresas);
  $$MembresiasTableTableManager get membresias =>
      $$MembresiasTableTableManager(_db, _db.membresias);
  $$CuentasTableTableManager get cuentas =>
      $$CuentasTableTableManager(_db, _db.cuentas);
  $$ContrapartesTableTableManager get contrapartes =>
      $$ContrapartesTableTableManager(_db, _db.contrapartes);
  $$ComprobantesTableTableManager get comprobantes =>
      $$ComprobantesTableTableManager(_db, _db.comprobantes);
  $$ItemsComprobanteTableTableManager get itemsComprobante =>
      $$ItemsComprobanteTableTableManager(_db, _db.itemsComprobante);
  $$CategoriasTableTableManager get categorias =>
      $$CategoriasTableTableManager(_db, _db.categorias);
  $$MovimientosTableTableManager get movimientos =>
      $$MovimientosTableTableManager(_db, _db.movimientos);
  $$ArqueosTableTableManager get arqueos =>
      $$ArqueosTableTableManager(_db, _db.arqueos);
  $$ArqueoCuentasTableTableManager get arqueoCuentas =>
      $$ArqueoCuentasTableTableManager(_db, _db.arqueoCuentas);
  $$AlertasTableTableManager get alertas =>
      $$AlertasTableTableManager(_db, _db.alertas);
  $$BitacoraTableTableManager get bitacora =>
      $$BitacoraTableTableManager(_db, _db.bitacora);
  $$DiasCerradosTableTableManager get diasCerrados =>
      $$DiasCerradosTableTableManager(_db, _db.diasCerrados);
  $$EventosMedicionTableTableManager get eventosMedicion =>
      $$EventosMedicionTableTableManager(_db, _db.eventosMedicion);
  $$AjustesTableTableManager get ajustes =>
      $$AjustesTableTableManager(_db, _db.ajustes);
  $$SubidasTableTableManager get subidas =>
      $$SubidasTableTableManager(_db, _db.subidas);
}
