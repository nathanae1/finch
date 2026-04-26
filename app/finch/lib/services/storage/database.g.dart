// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $IdentityEntriesTable extends IdentityEntries
    with TableInfo<$IdentityEntriesTable, IdentityEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdentityEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
    'pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedKeyMeta = const VerificationMeta(
    'feedKey',
  );
  @override
  late final GeneratedColumn<Uint8List> feedKey = GeneratedColumn<Uint8List>(
    'feed_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedKeyEpochMeta = const VerificationMeta(
    'feedKeyEpoch',
  );
  @override
  late final GeneratedColumn<int> feedKeyEpoch = GeneratedColumn<int>(
    'feed_key_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recoveryPhraseMeta = const VerificationMeta(
    'recoveryPhrase',
  );
  @override
  late final GeneratedColumn<String> recoveryPhrase = GeneratedColumn<String>(
    'recovery_phrase',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    pubkey,
    feedKey,
    feedKeyEpoch,
    recoveryPhrase,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'identity_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<IdentityEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pubkey')) {
      context.handle(
        _pubkeyMeta,
        pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubkeyMeta);
    }
    if (data.containsKey('feed_key')) {
      context.handle(
        _feedKeyMeta,
        feedKey.isAcceptableOrUnknown(data['feed_key']!, _feedKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_feedKeyMeta);
    }
    if (data.containsKey('feed_key_epoch')) {
      context.handle(
        _feedKeyEpochMeta,
        feedKeyEpoch.isAcceptableOrUnknown(
          data['feed_key_epoch']!,
          _feedKeyEpochMeta,
        ),
      );
    }
    if (data.containsKey('recovery_phrase')) {
      context.handle(
        _recoveryPhraseMeta,
        recoveryPhrase.isAcceptableOrUnknown(
          data['recovery_phrase']!,
          _recoveryPhraseMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pubkey};
  @override
  IdentityEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdentityEntry(
      pubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pubkey'],
      )!,
      feedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}feed_key'],
      )!,
      feedKeyEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feed_key_epoch'],
      )!,
      recoveryPhrase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recovery_phrase'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IdentityEntriesTable createAlias(String alias) {
    return $IdentityEntriesTable(attachedDatabase, alias);
  }
}

class IdentityEntry extends DataClass implements Insertable<IdentityEntry> {
  final String pubkey;
  final Uint8List feedKey;
  final int feedKeyEpoch;
  final String? recoveryPhrase;
  final int createdAt;
  const IdentityEntry({
    required this.pubkey,
    required this.feedKey,
    required this.feedKeyEpoch,
    this.recoveryPhrase,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pubkey'] = Variable<String>(pubkey);
    map['feed_key'] = Variable<Uint8List>(feedKey);
    map['feed_key_epoch'] = Variable<int>(feedKeyEpoch);
    if (!nullToAbsent || recoveryPhrase != null) {
      map['recovery_phrase'] = Variable<String>(recoveryPhrase);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  IdentityEntriesCompanion toCompanion(bool nullToAbsent) {
    return IdentityEntriesCompanion(
      pubkey: Value(pubkey),
      feedKey: Value(feedKey),
      feedKeyEpoch: Value(feedKeyEpoch),
      recoveryPhrase: recoveryPhrase == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryPhrase),
      createdAt: Value(createdAt),
    );
  }

  factory IdentityEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdentityEntry(
      pubkey: serializer.fromJson<String>(json['pubkey']),
      feedKey: serializer.fromJson<Uint8List>(json['feedKey']),
      feedKeyEpoch: serializer.fromJson<int>(json['feedKeyEpoch']),
      recoveryPhrase: serializer.fromJson<String?>(json['recoveryPhrase']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pubkey': serializer.toJson<String>(pubkey),
      'feedKey': serializer.toJson<Uint8List>(feedKey),
      'feedKeyEpoch': serializer.toJson<int>(feedKeyEpoch),
      'recoveryPhrase': serializer.toJson<String?>(recoveryPhrase),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  IdentityEntry copyWith({
    String? pubkey,
    Uint8List? feedKey,
    int? feedKeyEpoch,
    Value<String?> recoveryPhrase = const Value.absent(),
    int? createdAt,
  }) => IdentityEntry(
    pubkey: pubkey ?? this.pubkey,
    feedKey: feedKey ?? this.feedKey,
    feedKeyEpoch: feedKeyEpoch ?? this.feedKeyEpoch,
    recoveryPhrase: recoveryPhrase.present
        ? recoveryPhrase.value
        : this.recoveryPhrase,
    createdAt: createdAt ?? this.createdAt,
  );
  IdentityEntry copyWithCompanion(IdentityEntriesCompanion data) {
    return IdentityEntry(
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
      feedKey: data.feedKey.present ? data.feedKey.value : this.feedKey,
      feedKeyEpoch: data.feedKeyEpoch.present
          ? data.feedKeyEpoch.value
          : this.feedKeyEpoch,
      recoveryPhrase: data.recoveryPhrase.present
          ? data.recoveryPhrase.value
          : this.recoveryPhrase,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdentityEntry(')
          ..write('pubkey: $pubkey, ')
          ..write('feedKey: $feedKey, ')
          ..write('feedKeyEpoch: $feedKeyEpoch, ')
          ..write('recoveryPhrase: $recoveryPhrase, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    pubkey,
    $driftBlobEquality.hash(feedKey),
    feedKeyEpoch,
    recoveryPhrase,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdentityEntry &&
          other.pubkey == this.pubkey &&
          $driftBlobEquality.equals(other.feedKey, this.feedKey) &&
          other.feedKeyEpoch == this.feedKeyEpoch &&
          other.recoveryPhrase == this.recoveryPhrase &&
          other.createdAt == this.createdAt);
}

class IdentityEntriesCompanion extends UpdateCompanion<IdentityEntry> {
  final Value<String> pubkey;
  final Value<Uint8List> feedKey;
  final Value<int> feedKeyEpoch;
  final Value<String?> recoveryPhrase;
  final Value<int> createdAt;
  final Value<int> rowid;
  const IdentityEntriesCompanion({
    this.pubkey = const Value.absent(),
    this.feedKey = const Value.absent(),
    this.feedKeyEpoch = const Value.absent(),
    this.recoveryPhrase = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdentityEntriesCompanion.insert({
    required String pubkey,
    required Uint8List feedKey,
    this.feedKeyEpoch = const Value.absent(),
    this.recoveryPhrase = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : pubkey = Value(pubkey),
       feedKey = Value(feedKey),
       createdAt = Value(createdAt);
  static Insertable<IdentityEntry> custom({
    Expression<String>? pubkey,
    Expression<Uint8List>? feedKey,
    Expression<int>? feedKeyEpoch,
    Expression<String>? recoveryPhrase,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pubkey != null) 'pubkey': pubkey,
      if (feedKey != null) 'feed_key': feedKey,
      if (feedKeyEpoch != null) 'feed_key_epoch': feedKeyEpoch,
      if (recoveryPhrase != null) 'recovery_phrase': recoveryPhrase,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdentityEntriesCompanion copyWith({
    Value<String>? pubkey,
    Value<Uint8List>? feedKey,
    Value<int>? feedKeyEpoch,
    Value<String?>? recoveryPhrase,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return IdentityEntriesCompanion(
      pubkey: pubkey ?? this.pubkey,
      feedKey: feedKey ?? this.feedKey,
      feedKeyEpoch: feedKeyEpoch ?? this.feedKeyEpoch,
      recoveryPhrase: recoveryPhrase ?? this.recoveryPhrase,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (feedKey.present) {
      map['feed_key'] = Variable<Uint8List>(feedKey.value);
    }
    if (feedKeyEpoch.present) {
      map['feed_key_epoch'] = Variable<int>(feedKeyEpoch.value);
    }
    if (recoveryPhrase.present) {
      map['recovery_phrase'] = Variable<String>(recoveryPhrase.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdentityEntriesCompanion(')
          ..write('pubkey: $pubkey, ')
          ..write('feedKey: $feedKey, ')
          ..write('feedKeyEpoch: $feedKeyEpoch, ')
          ..write('recoveryPhrase: $recoveryPhrase, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FollowEntriesTable extends FollowEntries
    with TableInfo<$FollowEntriesTable, FollowEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
    'pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarHashMeta = const VerificationMeta(
    'avatarHash',
  );
  @override
  late final GeneratedColumn<String> avatarHash = GeneratedColumn<String>(
    'avatar_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _connectionCardMeta = const VerificationMeta(
    'connectionCard',
  );
  @override
  late final GeneratedColumn<String> connectionCard = GeneratedColumn<String>(
    'connection_card',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedKeyMeta = const VerificationMeta(
    'feedKey',
  );
  @override
  late final GeneratedColumn<Uint8List> feedKey = GeneratedColumn<Uint8List>(
    'feed_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedKeyEpochMeta = const VerificationMeta(
    'feedKeyEpoch',
  );
  @override
  late final GeneratedColumn<int> feedKeyEpoch = GeneratedColumn<int>(
    'feed_key_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    pubkey,
    displayName,
    avatarHash,
    connectionCard,
    feedKey,
    feedKeyEpoch,
    lastSyncedAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'follow_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FollowEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pubkey')) {
      context.handle(
        _pubkeyMeta,
        pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubkeyMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('avatar_hash')) {
      context.handle(
        _avatarHashMeta,
        avatarHash.isAcceptableOrUnknown(data['avatar_hash']!, _avatarHashMeta),
      );
    }
    if (data.containsKey('connection_card')) {
      context.handle(
        _connectionCardMeta,
        connectionCard.isAcceptableOrUnknown(
          data['connection_card']!,
          _connectionCardMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionCardMeta);
    }
    if (data.containsKey('feed_key')) {
      context.handle(
        _feedKeyMeta,
        feedKey.isAcceptableOrUnknown(data['feed_key']!, _feedKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_feedKeyMeta);
    }
    if (data.containsKey('feed_key_epoch')) {
      context.handle(
        _feedKeyEpochMeta,
        feedKeyEpoch.isAcceptableOrUnknown(
          data['feed_key_epoch']!,
          _feedKeyEpochMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pubkey};
  @override
  FollowEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowEntry(
      pubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pubkey'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      avatarHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_hash'],
      ),
      connectionCard: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_card'],
      )!,
      feedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}feed_key'],
      )!,
      feedKeyEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feed_key_epoch'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $FollowEntriesTable createAlias(String alias) {
    return $FollowEntriesTable(attachedDatabase, alias);
  }
}

class FollowEntry extends DataClass implements Insertable<FollowEntry> {
  final String pubkey;
  final String? displayName;
  final String? avatarHash;
  final String connectionCard;
  final Uint8List feedKey;
  final int feedKeyEpoch;
  final int lastSyncedAt;
  final String status;
  const FollowEntry({
    required this.pubkey,
    this.displayName,
    this.avatarHash,
    required this.connectionCard,
    required this.feedKey,
    required this.feedKeyEpoch,
    required this.lastSyncedAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pubkey'] = Variable<String>(pubkey);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || avatarHash != null) {
      map['avatar_hash'] = Variable<String>(avatarHash);
    }
    map['connection_card'] = Variable<String>(connectionCard);
    map['feed_key'] = Variable<Uint8List>(feedKey);
    map['feed_key_epoch'] = Variable<int>(feedKeyEpoch);
    map['last_synced_at'] = Variable<int>(lastSyncedAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  FollowEntriesCompanion toCompanion(bool nullToAbsent) {
    return FollowEntriesCompanion(
      pubkey: Value(pubkey),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      avatarHash: avatarHash == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarHash),
      connectionCard: Value(connectionCard),
      feedKey: Value(feedKey),
      feedKeyEpoch: Value(feedKeyEpoch),
      lastSyncedAt: Value(lastSyncedAt),
      status: Value(status),
    );
  }

  factory FollowEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowEntry(
      pubkey: serializer.fromJson<String>(json['pubkey']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      avatarHash: serializer.fromJson<String?>(json['avatarHash']),
      connectionCard: serializer.fromJson<String>(json['connectionCard']),
      feedKey: serializer.fromJson<Uint8List>(json['feedKey']),
      feedKeyEpoch: serializer.fromJson<int>(json['feedKeyEpoch']),
      lastSyncedAt: serializer.fromJson<int>(json['lastSyncedAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pubkey': serializer.toJson<String>(pubkey),
      'displayName': serializer.toJson<String?>(displayName),
      'avatarHash': serializer.toJson<String?>(avatarHash),
      'connectionCard': serializer.toJson<String>(connectionCard),
      'feedKey': serializer.toJson<Uint8List>(feedKey),
      'feedKeyEpoch': serializer.toJson<int>(feedKeyEpoch),
      'lastSyncedAt': serializer.toJson<int>(lastSyncedAt),
      'status': serializer.toJson<String>(status),
    };
  }

  FollowEntry copyWith({
    String? pubkey,
    Value<String?> displayName = const Value.absent(),
    Value<String?> avatarHash = const Value.absent(),
    String? connectionCard,
    Uint8List? feedKey,
    int? feedKeyEpoch,
    int? lastSyncedAt,
    String? status,
  }) => FollowEntry(
    pubkey: pubkey ?? this.pubkey,
    displayName: displayName.present ? displayName.value : this.displayName,
    avatarHash: avatarHash.present ? avatarHash.value : this.avatarHash,
    connectionCard: connectionCard ?? this.connectionCard,
    feedKey: feedKey ?? this.feedKey,
    feedKeyEpoch: feedKeyEpoch ?? this.feedKeyEpoch,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    status: status ?? this.status,
  );
  FollowEntry copyWithCompanion(FollowEntriesCompanion data) {
    return FollowEntry(
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarHash: data.avatarHash.present
          ? data.avatarHash.value
          : this.avatarHash,
      connectionCard: data.connectionCard.present
          ? data.connectionCard.value
          : this.connectionCard,
      feedKey: data.feedKey.present ? data.feedKey.value : this.feedKey,
      feedKeyEpoch: data.feedKeyEpoch.present
          ? data.feedKeyEpoch.value
          : this.feedKeyEpoch,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowEntry(')
          ..write('pubkey: $pubkey, ')
          ..write('displayName: $displayName, ')
          ..write('avatarHash: $avatarHash, ')
          ..write('connectionCard: $connectionCard, ')
          ..write('feedKey: $feedKey, ')
          ..write('feedKeyEpoch: $feedKeyEpoch, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    pubkey,
    displayName,
    avatarHash,
    connectionCard,
    $driftBlobEquality.hash(feedKey),
    feedKeyEpoch,
    lastSyncedAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowEntry &&
          other.pubkey == this.pubkey &&
          other.displayName == this.displayName &&
          other.avatarHash == this.avatarHash &&
          other.connectionCard == this.connectionCard &&
          $driftBlobEquality.equals(other.feedKey, this.feedKey) &&
          other.feedKeyEpoch == this.feedKeyEpoch &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.status == this.status);
}

class FollowEntriesCompanion extends UpdateCompanion<FollowEntry> {
  final Value<String> pubkey;
  final Value<String?> displayName;
  final Value<String?> avatarHash;
  final Value<String> connectionCard;
  final Value<Uint8List> feedKey;
  final Value<int> feedKeyEpoch;
  final Value<int> lastSyncedAt;
  final Value<String> status;
  final Value<int> rowid;
  const FollowEntriesCompanion({
    this.pubkey = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarHash = const Value.absent(),
    this.connectionCard = const Value.absent(),
    this.feedKey = const Value.absent(),
    this.feedKeyEpoch = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FollowEntriesCompanion.insert({
    required String pubkey,
    this.displayName = const Value.absent(),
    this.avatarHash = const Value.absent(),
    required String connectionCard,
    required Uint8List feedKey,
    this.feedKeyEpoch = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : pubkey = Value(pubkey),
       connectionCard = Value(connectionCard),
       feedKey = Value(feedKey);
  static Insertable<FollowEntry> custom({
    Expression<String>? pubkey,
    Expression<String>? displayName,
    Expression<String>? avatarHash,
    Expression<String>? connectionCard,
    Expression<Uint8List>? feedKey,
    Expression<int>? feedKeyEpoch,
    Expression<int>? lastSyncedAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pubkey != null) 'pubkey': pubkey,
      if (displayName != null) 'display_name': displayName,
      if (avatarHash != null) 'avatar_hash': avatarHash,
      if (connectionCard != null) 'connection_card': connectionCard,
      if (feedKey != null) 'feed_key': feedKey,
      if (feedKeyEpoch != null) 'feed_key_epoch': feedKeyEpoch,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FollowEntriesCompanion copyWith({
    Value<String>? pubkey,
    Value<String?>? displayName,
    Value<String?>? avatarHash,
    Value<String>? connectionCard,
    Value<Uint8List>? feedKey,
    Value<int>? feedKeyEpoch,
    Value<int>? lastSyncedAt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return FollowEntriesCompanion(
      pubkey: pubkey ?? this.pubkey,
      displayName: displayName ?? this.displayName,
      avatarHash: avatarHash ?? this.avatarHash,
      connectionCard: connectionCard ?? this.connectionCard,
      feedKey: feedKey ?? this.feedKey,
      feedKeyEpoch: feedKeyEpoch ?? this.feedKeyEpoch,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarHash.present) {
      map['avatar_hash'] = Variable<String>(avatarHash.value);
    }
    if (connectionCard.present) {
      map['connection_card'] = Variable<String>(connectionCard.value);
    }
    if (feedKey.present) {
      map['feed_key'] = Variable<Uint8List>(feedKey.value);
    }
    if (feedKeyEpoch.present) {
      map['feed_key_epoch'] = Variable<int>(feedKeyEpoch.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowEntriesCompanion(')
          ..write('pubkey: $pubkey, ')
          ..write('displayName: $displayName, ')
          ..write('avatarHash: $avatarHash, ')
          ..write('connectionCard: $connectionCard, ')
          ..write('feedKey: $feedKey, ')
          ..write('feedKeyEpoch: $feedKeyEpoch, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventEntriesTable extends EventEntries
    with TableInfo<$EventEntriesTable, EventEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
    'pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<Uint8List> content = GeneratedColumn<Uint8List>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaRefsMeta = const VerificationMeta(
    'mediaRefs',
  );
  @override
  late final GeneratedColumn<String> mediaRefs = GeneratedColumn<String>(
    'media_refs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sigMeta = const VerificationMeta('sig');
  @override
  late final GeneratedColumn<Uint8List> sig = GeneratedColumn<Uint8List>(
    'sig',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isOwnMeta = const VerificationMeta('isOwn');
  @override
  late final GeneratedColumn<int> isOwn = GeneratedColumn<int>(
    'is_own',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSavedMeta = const VerificationMeta(
    'isSaved',
  );
  @override
  late final GeneratedColumn<int> isSaved = GeneratedColumn<int>(
    'is_saved',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastViewedMeta = const VerificationMeta(
    'lastViewed',
  );
  @override
  late final GeneratedColumn<int> lastViewed = GeneratedColumn<int>(
    'last_viewed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('2026-03-24'),
  );
  static const VerificationMeta _extensionsMeta = const VerificationMeta(
    'extensions',
  );
  @override
  late final GeneratedColumn<Uint8List> extensions = GeneratedColumn<Uint8List>(
    'extensions',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pubkey,
    createdAt,
    kind,
    refId,
    content,
    mediaRefs,
    sig,
    isOwn,
    isSaved,
    fetchedAt,
    lastViewed,
    version,
    extensions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pubkey')) {
      context.handle(
        _pubkeyMeta,
        pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubkeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('media_refs')) {
      context.handle(
        _mediaRefsMeta,
        mediaRefs.isAcceptableOrUnknown(data['media_refs']!, _mediaRefsMeta),
      );
    }
    if (data.containsKey('sig')) {
      context.handle(
        _sigMeta,
        sig.isAcceptableOrUnknown(data['sig']!, _sigMeta),
      );
    } else if (isInserting) {
      context.missing(_sigMeta);
    }
    if (data.containsKey('is_own')) {
      context.handle(
        _isOwnMeta,
        isOwn.isAcceptableOrUnknown(data['is_own']!, _isOwnMeta),
      );
    }
    if (data.containsKey('is_saved')) {
      context.handle(
        _isSavedMeta,
        isSaved.isAcceptableOrUnknown(data['is_saved']!, _isSavedMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('last_viewed')) {
      context.handle(
        _lastViewedMeta,
        lastViewed.isAcceptableOrUnknown(data['last_viewed']!, _lastViewedMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('extensions')) {
      context.handle(
        _extensionsMeta,
        extensions.isAcceptableOrUnknown(data['extensions']!, _extensionsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pubkey'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}content'],
      )!,
      mediaRefs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_refs'],
      ),
      sig: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}sig'],
      )!,
      isOwn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_own'],
      )!,
      isSaved: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_saved'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
      lastViewed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_viewed'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      extensions: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}extensions'],
      ),
    );
  }

  @override
  $EventEntriesTable createAlias(String alias) {
    return $EventEntriesTable(attachedDatabase, alias);
  }
}

class EventEntry extends DataClass implements Insertable<EventEntry> {
  final String id;
  final String pubkey;
  final int createdAt;
  final int kind;
  final String? refId;
  final Uint8List content;
  final String? mediaRefs;
  final Uint8List sig;
  final int isOwn;
  final int isSaved;
  final int fetchedAt;
  final int? lastViewed;
  final String version;
  final Uint8List? extensions;
  const EventEntry({
    required this.id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    this.refId,
    required this.content,
    this.mediaRefs,
    required this.sig,
    required this.isOwn,
    required this.isSaved,
    required this.fetchedAt,
    this.lastViewed,
    required this.version,
    this.extensions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pubkey'] = Variable<String>(pubkey);
    map['created_at'] = Variable<int>(createdAt);
    map['kind'] = Variable<int>(kind);
    if (!nullToAbsent || refId != null) {
      map['ref_id'] = Variable<String>(refId);
    }
    map['content'] = Variable<Uint8List>(content);
    if (!nullToAbsent || mediaRefs != null) {
      map['media_refs'] = Variable<String>(mediaRefs);
    }
    map['sig'] = Variable<Uint8List>(sig);
    map['is_own'] = Variable<int>(isOwn);
    map['is_saved'] = Variable<int>(isSaved);
    map['fetched_at'] = Variable<int>(fetchedAt);
    if (!nullToAbsent || lastViewed != null) {
      map['last_viewed'] = Variable<int>(lastViewed);
    }
    map['version'] = Variable<String>(version);
    if (!nullToAbsent || extensions != null) {
      map['extensions'] = Variable<Uint8List>(extensions);
    }
    return map;
  }

  EventEntriesCompanion toCompanion(bool nullToAbsent) {
    return EventEntriesCompanion(
      id: Value(id),
      pubkey: Value(pubkey),
      createdAt: Value(createdAt),
      kind: Value(kind),
      refId: refId == null && nullToAbsent
          ? const Value.absent()
          : Value(refId),
      content: Value(content),
      mediaRefs: mediaRefs == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaRefs),
      sig: Value(sig),
      isOwn: Value(isOwn),
      isSaved: Value(isSaved),
      fetchedAt: Value(fetchedAt),
      lastViewed: lastViewed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastViewed),
      version: Value(version),
      extensions: extensions == null && nullToAbsent
          ? const Value.absent()
          : Value(extensions),
    );
  }

  factory EventEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventEntry(
      id: serializer.fromJson<String>(json['id']),
      pubkey: serializer.fromJson<String>(json['pubkey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      kind: serializer.fromJson<int>(json['kind']),
      refId: serializer.fromJson<String?>(json['refId']),
      content: serializer.fromJson<Uint8List>(json['content']),
      mediaRefs: serializer.fromJson<String?>(json['mediaRefs']),
      sig: serializer.fromJson<Uint8List>(json['sig']),
      isOwn: serializer.fromJson<int>(json['isOwn']),
      isSaved: serializer.fromJson<int>(json['isSaved']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
      lastViewed: serializer.fromJson<int?>(json['lastViewed']),
      version: serializer.fromJson<String>(json['version']),
      extensions: serializer.fromJson<Uint8List?>(json['extensions']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pubkey': serializer.toJson<String>(pubkey),
      'createdAt': serializer.toJson<int>(createdAt),
      'kind': serializer.toJson<int>(kind),
      'refId': serializer.toJson<String?>(refId),
      'content': serializer.toJson<Uint8List>(content),
      'mediaRefs': serializer.toJson<String?>(mediaRefs),
      'sig': serializer.toJson<Uint8List>(sig),
      'isOwn': serializer.toJson<int>(isOwn),
      'isSaved': serializer.toJson<int>(isSaved),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
      'lastViewed': serializer.toJson<int?>(lastViewed),
      'version': serializer.toJson<String>(version),
      'extensions': serializer.toJson<Uint8List?>(extensions),
    };
  }

  EventEntry copyWith({
    String? id,
    String? pubkey,
    int? createdAt,
    int? kind,
    Value<String?> refId = const Value.absent(),
    Uint8List? content,
    Value<String?> mediaRefs = const Value.absent(),
    Uint8List? sig,
    int? isOwn,
    int? isSaved,
    int? fetchedAt,
    Value<int?> lastViewed = const Value.absent(),
    String? version,
    Value<Uint8List?> extensions = const Value.absent(),
  }) => EventEntry(
    id: id ?? this.id,
    pubkey: pubkey ?? this.pubkey,
    createdAt: createdAt ?? this.createdAt,
    kind: kind ?? this.kind,
    refId: refId.present ? refId.value : this.refId,
    content: content ?? this.content,
    mediaRefs: mediaRefs.present ? mediaRefs.value : this.mediaRefs,
    sig: sig ?? this.sig,
    isOwn: isOwn ?? this.isOwn,
    isSaved: isSaved ?? this.isSaved,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    lastViewed: lastViewed.present ? lastViewed.value : this.lastViewed,
    version: version ?? this.version,
    extensions: extensions.present ? extensions.value : this.extensions,
  );
  EventEntry copyWithCompanion(EventEntriesCompanion data) {
    return EventEntry(
      id: data.id.present ? data.id.value : this.id,
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      refId: data.refId.present ? data.refId.value : this.refId,
      content: data.content.present ? data.content.value : this.content,
      mediaRefs: data.mediaRefs.present ? data.mediaRefs.value : this.mediaRefs,
      sig: data.sig.present ? data.sig.value : this.sig,
      isOwn: data.isOwn.present ? data.isOwn.value : this.isOwn,
      isSaved: data.isSaved.present ? data.isSaved.value : this.isSaved,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      lastViewed: data.lastViewed.present
          ? data.lastViewed.value
          : this.lastViewed,
      version: data.version.present ? data.version.value : this.version,
      extensions: data.extensions.present
          ? data.extensions.value
          : this.extensions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventEntry(')
          ..write('id: $id, ')
          ..write('pubkey: $pubkey, ')
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('content: $content, ')
          ..write('mediaRefs: $mediaRefs, ')
          ..write('sig: $sig, ')
          ..write('isOwn: $isOwn, ')
          ..write('isSaved: $isSaved, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('lastViewed: $lastViewed, ')
          ..write('version: $version, ')
          ..write('extensions: $extensions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pubkey,
    createdAt,
    kind,
    refId,
    $driftBlobEquality.hash(content),
    mediaRefs,
    $driftBlobEquality.hash(sig),
    isOwn,
    isSaved,
    fetchedAt,
    lastViewed,
    version,
    $driftBlobEquality.hash(extensions),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventEntry &&
          other.id == this.id &&
          other.pubkey == this.pubkey &&
          other.createdAt == this.createdAt &&
          other.kind == this.kind &&
          other.refId == this.refId &&
          $driftBlobEquality.equals(other.content, this.content) &&
          other.mediaRefs == this.mediaRefs &&
          $driftBlobEquality.equals(other.sig, this.sig) &&
          other.isOwn == this.isOwn &&
          other.isSaved == this.isSaved &&
          other.fetchedAt == this.fetchedAt &&
          other.lastViewed == this.lastViewed &&
          other.version == this.version &&
          $driftBlobEquality.equals(other.extensions, this.extensions));
}

class EventEntriesCompanion extends UpdateCompanion<EventEntry> {
  final Value<String> id;
  final Value<String> pubkey;
  final Value<int> createdAt;
  final Value<int> kind;
  final Value<String?> refId;
  final Value<Uint8List> content;
  final Value<String?> mediaRefs;
  final Value<Uint8List> sig;
  final Value<int> isOwn;
  final Value<int> isSaved;
  final Value<int> fetchedAt;
  final Value<int?> lastViewed;
  final Value<String> version;
  final Value<Uint8List?> extensions;
  final Value<int> rowid;
  const EventEntriesCompanion({
    this.id = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.refId = const Value.absent(),
    this.content = const Value.absent(),
    this.mediaRefs = const Value.absent(),
    this.sig = const Value.absent(),
    this.isOwn = const Value.absent(),
    this.isSaved = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.lastViewed = const Value.absent(),
    this.version = const Value.absent(),
    this.extensions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventEntriesCompanion.insert({
    required String id,
    required String pubkey,
    required int createdAt,
    required int kind,
    this.refId = const Value.absent(),
    required Uint8List content,
    this.mediaRefs = const Value.absent(),
    required Uint8List sig,
    this.isOwn = const Value.absent(),
    this.isSaved = const Value.absent(),
    required int fetchedAt,
    this.lastViewed = const Value.absent(),
    this.version = const Value.absent(),
    this.extensions = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pubkey = Value(pubkey),
       createdAt = Value(createdAt),
       kind = Value(kind),
       content = Value(content),
       sig = Value(sig),
       fetchedAt = Value(fetchedAt);
  static Insertable<EventEntry> custom({
    Expression<String>? id,
    Expression<String>? pubkey,
    Expression<int>? createdAt,
    Expression<int>? kind,
    Expression<String>? refId,
    Expression<Uint8List>? content,
    Expression<String>? mediaRefs,
    Expression<Uint8List>? sig,
    Expression<int>? isOwn,
    Expression<int>? isSaved,
    Expression<int>? fetchedAt,
    Expression<int>? lastViewed,
    Expression<String>? version,
    Expression<Uint8List>? extensions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pubkey != null) 'pubkey': pubkey,
      if (createdAt != null) 'created_at': createdAt,
      if (kind != null) 'kind': kind,
      if (refId != null) 'ref_id': refId,
      if (content != null) 'content': content,
      if (mediaRefs != null) 'media_refs': mediaRefs,
      if (sig != null) 'sig': sig,
      if (isOwn != null) 'is_own': isOwn,
      if (isSaved != null) 'is_saved': isSaved,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (lastViewed != null) 'last_viewed': lastViewed,
      if (version != null) 'version': version,
      if (extensions != null) 'extensions': extensions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? pubkey,
    Value<int>? createdAt,
    Value<int>? kind,
    Value<String?>? refId,
    Value<Uint8List>? content,
    Value<String?>? mediaRefs,
    Value<Uint8List>? sig,
    Value<int>? isOwn,
    Value<int>? isSaved,
    Value<int>? fetchedAt,
    Value<int?>? lastViewed,
    Value<String>? version,
    Value<Uint8List?>? extensions,
    Value<int>? rowid,
  }) {
    return EventEntriesCompanion(
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
      refId: refId ?? this.refId,
      content: content ?? this.content,
      mediaRefs: mediaRefs ?? this.mediaRefs,
      sig: sig ?? this.sig,
      isOwn: isOwn ?? this.isOwn,
      isSaved: isSaved ?? this.isSaved,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      lastViewed: lastViewed ?? this.lastViewed,
      version: version ?? this.version,
      extensions: extensions ?? this.extensions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (content.present) {
      map['content'] = Variable<Uint8List>(content.value);
    }
    if (mediaRefs.present) {
      map['media_refs'] = Variable<String>(mediaRefs.value);
    }
    if (sig.present) {
      map['sig'] = Variable<Uint8List>(sig.value);
    }
    if (isOwn.present) {
      map['is_own'] = Variable<int>(isOwn.value);
    }
    if (isSaved.present) {
      map['is_saved'] = Variable<int>(isSaved.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (lastViewed.present) {
      map['last_viewed'] = Variable<int>(lastViewed.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (extensions.present) {
      map['extensions'] = Variable<Uint8List>(extensions.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventEntriesCompanion(')
          ..write('id: $id, ')
          ..write('pubkey: $pubkey, ')
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('content: $content, ')
          ..write('mediaRefs: $mediaRefs, ')
          ..write('sig: $sig, ')
          ..write('isOwn: $isOwn, ')
          ..write('isSaved: $isSaved, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('lastViewed: $lastViewed, ')
          ..write('version: $version, ')
          ..write('extensions: $extensions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaCacheEntriesTable extends MediaCacheEntries
    with TableInfo<$MediaCacheEntriesTable, MediaCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedMeta = const VerificationMeta(
    'lastAccessed',
  );
  @override
  late final GeneratedColumn<int> lastAccessed = GeneratedColumn<int>(
    'last_accessed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [hash, path, size, lastAccessed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('last_accessed')) {
      context.handle(
        _lastAccessedMeta,
        lastAccessed.isAcceptableOrUnknown(
          data['last_accessed']!,
          _lastAccessedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hash};
  @override
  MediaCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaCacheEntry(
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      lastAccessed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_accessed'],
      )!,
    );
  }

  @override
  $MediaCacheEntriesTable createAlias(String alias) {
    return $MediaCacheEntriesTable(attachedDatabase, alias);
  }
}

class MediaCacheEntry extends DataClass implements Insertable<MediaCacheEntry> {
  final String hash;
  final String path;
  final int size;
  final int lastAccessed;
  const MediaCacheEntry({
    required this.hash,
    required this.path,
    required this.size,
    required this.lastAccessed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hash'] = Variable<String>(hash);
    map['path'] = Variable<String>(path);
    map['size'] = Variable<int>(size);
    map['last_accessed'] = Variable<int>(lastAccessed);
    return map;
  }

  MediaCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return MediaCacheEntriesCompanion(
      hash: Value(hash),
      path: Value(path),
      size: Value(size),
      lastAccessed: Value(lastAccessed),
    );
  }

  factory MediaCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaCacheEntry(
      hash: serializer.fromJson<String>(json['hash']),
      path: serializer.fromJson<String>(json['path']),
      size: serializer.fromJson<int>(json['size']),
      lastAccessed: serializer.fromJson<int>(json['lastAccessed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hash': serializer.toJson<String>(hash),
      'path': serializer.toJson<String>(path),
      'size': serializer.toJson<int>(size),
      'lastAccessed': serializer.toJson<int>(lastAccessed),
    };
  }

  MediaCacheEntry copyWith({
    String? hash,
    String? path,
    int? size,
    int? lastAccessed,
  }) => MediaCacheEntry(
    hash: hash ?? this.hash,
    path: path ?? this.path,
    size: size ?? this.size,
    lastAccessed: lastAccessed ?? this.lastAccessed,
  );
  MediaCacheEntry copyWithCompanion(MediaCacheEntriesCompanion data) {
    return MediaCacheEntry(
      hash: data.hash.present ? data.hash.value : this.hash,
      path: data.path.present ? data.path.value : this.path,
      size: data.size.present ? data.size.value : this.size,
      lastAccessed: data.lastAccessed.present
          ? data.lastAccessed.value
          : this.lastAccessed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaCacheEntry(')
          ..write('hash: $hash, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('lastAccessed: $lastAccessed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(hash, path, size, lastAccessed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaCacheEntry &&
          other.hash == this.hash &&
          other.path == this.path &&
          other.size == this.size &&
          other.lastAccessed == this.lastAccessed);
}

class MediaCacheEntriesCompanion extends UpdateCompanion<MediaCacheEntry> {
  final Value<String> hash;
  final Value<String> path;
  final Value<int> size;
  final Value<int> lastAccessed;
  final Value<int> rowid;
  const MediaCacheEntriesCompanion({
    this.hash = const Value.absent(),
    this.path = const Value.absent(),
    this.size = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaCacheEntriesCompanion.insert({
    required String hash,
    required String path,
    required int size,
    required int lastAccessed,
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       path = Value(path),
       size = Value(size),
       lastAccessed = Value(lastAccessed);
  static Insertable<MediaCacheEntry> custom({
    Expression<String>? hash,
    Expression<String>? path,
    Expression<int>? size,
    Expression<int>? lastAccessed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hash != null) 'hash': hash,
      if (path != null) 'path': path,
      if (size != null) 'size': size,
      if (lastAccessed != null) 'last_accessed': lastAccessed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaCacheEntriesCompanion copyWith({
    Value<String>? hash,
    Value<String>? path,
    Value<int>? size,
    Value<int>? lastAccessed,
    Value<int>? rowid,
  }) {
    return MediaCacheEntriesCompanion(
      hash: hash ?? this.hash,
      path: path ?? this.path,
      size: size ?? this.size,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (lastAccessed.present) {
      map['last_accessed'] = Variable<int>(lastAccessed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaCacheEntriesCompanion(')
          ..write('hash: $hash, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InboundFollowRequestEntriesTable extends InboundFollowRequestEntries
    with
        TableInfo<
          $InboundFollowRequestEntriesTable,
          InboundFollowRequestEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InboundFollowRequestEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
    'pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedEndpointsMeta =
      const VerificationMeta('encryptedEndpoints');
  @override
  late final GeneratedColumn<Uint8List> encryptedEndpoints =
      GeneratedColumn<Uint8List>(
        'encrypted_endpoints',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestTimestampMeta = const VerificationMeta(
    'requestTimestamp',
  );
  @override
  late final GeneratedColumn<int> requestTimestamp = GeneratedColumn<int>(
    'request_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    pubkey,
    encryptedEndpoints,
    createdAt,
    requestTimestamp,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inbound_follow_request_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<InboundFollowRequestEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pubkey')) {
      context.handle(
        _pubkeyMeta,
        pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubkeyMeta);
    }
    if (data.containsKey('encrypted_endpoints')) {
      context.handle(
        _encryptedEndpointsMeta,
        encryptedEndpoints.isAcceptableOrUnknown(
          data['encrypted_endpoints']!,
          _encryptedEndpointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedEndpointsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('request_timestamp')) {
      context.handle(
        _requestTimestampMeta,
        requestTimestamp.isAcceptableOrUnknown(
          data['request_timestamp']!,
          _requestTimestampMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pubkey};
  @override
  InboundFollowRequestEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InboundFollowRequestEntry(
      pubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pubkey'],
      )!,
      encryptedEndpoints: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_endpoints'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      requestTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}request_timestamp'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $InboundFollowRequestEntriesTable createAlias(String alias) {
    return $InboundFollowRequestEntriesTable(attachedDatabase, alias);
  }
}

class InboundFollowRequestEntry extends DataClass
    implements Insertable<InboundFollowRequestEntry> {
  final String pubkey;
  final Uint8List encryptedEndpoints;
  final int createdAt;
  final int requestTimestamp;
  final String status;
  const InboundFollowRequestEntry({
    required this.pubkey,
    required this.encryptedEndpoints,
    required this.createdAt,
    required this.requestTimestamp,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pubkey'] = Variable<String>(pubkey);
    map['encrypted_endpoints'] = Variable<Uint8List>(encryptedEndpoints);
    map['created_at'] = Variable<int>(createdAt);
    map['request_timestamp'] = Variable<int>(requestTimestamp);
    map['status'] = Variable<String>(status);
    return map;
  }

  InboundFollowRequestEntriesCompanion toCompanion(bool nullToAbsent) {
    return InboundFollowRequestEntriesCompanion(
      pubkey: Value(pubkey),
      encryptedEndpoints: Value(encryptedEndpoints),
      createdAt: Value(createdAt),
      requestTimestamp: Value(requestTimestamp),
      status: Value(status),
    );
  }

  factory InboundFollowRequestEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InboundFollowRequestEntry(
      pubkey: serializer.fromJson<String>(json['pubkey']),
      encryptedEndpoints: serializer.fromJson<Uint8List>(
        json['encryptedEndpoints'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      requestTimestamp: serializer.fromJson<int>(json['requestTimestamp']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pubkey': serializer.toJson<String>(pubkey),
      'encryptedEndpoints': serializer.toJson<Uint8List>(encryptedEndpoints),
      'createdAt': serializer.toJson<int>(createdAt),
      'requestTimestamp': serializer.toJson<int>(requestTimestamp),
      'status': serializer.toJson<String>(status),
    };
  }

  InboundFollowRequestEntry copyWith({
    String? pubkey,
    Uint8List? encryptedEndpoints,
    int? createdAt,
    int? requestTimestamp,
    String? status,
  }) => InboundFollowRequestEntry(
    pubkey: pubkey ?? this.pubkey,
    encryptedEndpoints: encryptedEndpoints ?? this.encryptedEndpoints,
    createdAt: createdAt ?? this.createdAt,
    requestTimestamp: requestTimestamp ?? this.requestTimestamp,
    status: status ?? this.status,
  );
  InboundFollowRequestEntry copyWithCompanion(
    InboundFollowRequestEntriesCompanion data,
  ) {
    return InboundFollowRequestEntry(
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
      encryptedEndpoints: data.encryptedEndpoints.present
          ? data.encryptedEndpoints.value
          : this.encryptedEndpoints,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      requestTimestamp: data.requestTimestamp.present
          ? data.requestTimestamp.value
          : this.requestTimestamp,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InboundFollowRequestEntry(')
          ..write('pubkey: $pubkey, ')
          ..write('encryptedEndpoints: $encryptedEndpoints, ')
          ..write('createdAt: $createdAt, ')
          ..write('requestTimestamp: $requestTimestamp, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    pubkey,
    $driftBlobEquality.hash(encryptedEndpoints),
    createdAt,
    requestTimestamp,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InboundFollowRequestEntry &&
          other.pubkey == this.pubkey &&
          $driftBlobEquality.equals(
            other.encryptedEndpoints,
            this.encryptedEndpoints,
          ) &&
          other.createdAt == this.createdAt &&
          other.requestTimestamp == this.requestTimestamp &&
          other.status == this.status);
}

class InboundFollowRequestEntriesCompanion
    extends UpdateCompanion<InboundFollowRequestEntry> {
  final Value<String> pubkey;
  final Value<Uint8List> encryptedEndpoints;
  final Value<int> createdAt;
  final Value<int> requestTimestamp;
  final Value<String> status;
  final Value<int> rowid;
  const InboundFollowRequestEntriesCompanion({
    this.pubkey = const Value.absent(),
    this.encryptedEndpoints = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.requestTimestamp = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InboundFollowRequestEntriesCompanion.insert({
    required String pubkey,
    required Uint8List encryptedEndpoints,
    required int createdAt,
    this.requestTimestamp = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : pubkey = Value(pubkey),
       encryptedEndpoints = Value(encryptedEndpoints),
       createdAt = Value(createdAt);
  static Insertable<InboundFollowRequestEntry> custom({
    Expression<String>? pubkey,
    Expression<Uint8List>? encryptedEndpoints,
    Expression<int>? createdAt,
    Expression<int>? requestTimestamp,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pubkey != null) 'pubkey': pubkey,
      if (encryptedEndpoints != null) 'encrypted_endpoints': encryptedEndpoints,
      if (createdAt != null) 'created_at': createdAt,
      if (requestTimestamp != null) 'request_timestamp': requestTimestamp,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InboundFollowRequestEntriesCompanion copyWith({
    Value<String>? pubkey,
    Value<Uint8List>? encryptedEndpoints,
    Value<int>? createdAt,
    Value<int>? requestTimestamp,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return InboundFollowRequestEntriesCompanion(
      pubkey: pubkey ?? this.pubkey,
      encryptedEndpoints: encryptedEndpoints ?? this.encryptedEndpoints,
      createdAt: createdAt ?? this.createdAt,
      requestTimestamp: requestTimestamp ?? this.requestTimestamp,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (encryptedEndpoints.present) {
      map['encrypted_endpoints'] = Variable<Uint8List>(
        encryptedEndpoints.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (requestTimestamp.present) {
      map['request_timestamp'] = Variable<int>(requestTimestamp.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InboundFollowRequestEntriesCompanion(')
          ..write('pubkey: $pubkey, ')
          ..write('encryptedEndpoints: $encryptedEndpoints, ')
          ..write('createdAt: $createdAt, ')
          ..write('requestTimestamp: $requestTimestamp, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboundFollowRequestEntriesTable extends OutboundFollowRequestEntries
    with
        TableInfo<
          $OutboundFollowRequestEntriesTable,
          OutboundFollowRequestEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboundFollowRequestEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
    'pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionCardMeta = const VerificationMeta(
    'connectionCard',
  );
  @override
  late final GeneratedColumn<String> connectionCard = GeneratedColumn<String>(
    'connection_card',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    pubkey,
    connectionCard,
    createdAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbound_follow_request_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboundFollowRequestEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pubkey')) {
      context.handle(
        _pubkeyMeta,
        pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubkeyMeta);
    }
    if (data.containsKey('connection_card')) {
      context.handle(
        _connectionCardMeta,
        connectionCard.isAcceptableOrUnknown(
          data['connection_card']!,
          _connectionCardMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionCardMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pubkey};
  @override
  OutboundFollowRequestEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboundFollowRequestEntry(
      pubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pubkey'],
      )!,
      connectionCard: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_card'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $OutboundFollowRequestEntriesTable createAlias(String alias) {
    return $OutboundFollowRequestEntriesTable(attachedDatabase, alias);
  }
}

class OutboundFollowRequestEntry extends DataClass
    implements Insertable<OutboundFollowRequestEntry> {
  final String pubkey;
  final String connectionCard;
  final int createdAt;
  final String status;
  const OutboundFollowRequestEntry({
    required this.pubkey,
    required this.connectionCard,
    required this.createdAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pubkey'] = Variable<String>(pubkey);
    map['connection_card'] = Variable<String>(connectionCard);
    map['created_at'] = Variable<int>(createdAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  OutboundFollowRequestEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboundFollowRequestEntriesCompanion(
      pubkey: Value(pubkey),
      connectionCard: Value(connectionCard),
      createdAt: Value(createdAt),
      status: Value(status),
    );
  }

  factory OutboundFollowRequestEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboundFollowRequestEntry(
      pubkey: serializer.fromJson<String>(json['pubkey']),
      connectionCard: serializer.fromJson<String>(json['connectionCard']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pubkey': serializer.toJson<String>(pubkey),
      'connectionCard': serializer.toJson<String>(connectionCard),
      'createdAt': serializer.toJson<int>(createdAt),
      'status': serializer.toJson<String>(status),
    };
  }

  OutboundFollowRequestEntry copyWith({
    String? pubkey,
    String? connectionCard,
    int? createdAt,
    String? status,
  }) => OutboundFollowRequestEntry(
    pubkey: pubkey ?? this.pubkey,
    connectionCard: connectionCard ?? this.connectionCard,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
  );
  OutboundFollowRequestEntry copyWithCompanion(
    OutboundFollowRequestEntriesCompanion data,
  ) {
    return OutboundFollowRequestEntry(
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
      connectionCard: data.connectionCard.present
          ? data.connectionCard.value
          : this.connectionCard,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboundFollowRequestEntry(')
          ..write('pubkey: $pubkey, ')
          ..write('connectionCard: $connectionCard, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pubkey, connectionCard, createdAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboundFollowRequestEntry &&
          other.pubkey == this.pubkey &&
          other.connectionCard == this.connectionCard &&
          other.createdAt == this.createdAt &&
          other.status == this.status);
}

class OutboundFollowRequestEntriesCompanion
    extends UpdateCompanion<OutboundFollowRequestEntry> {
  final Value<String> pubkey;
  final Value<String> connectionCard;
  final Value<int> createdAt;
  final Value<String> status;
  final Value<int> rowid;
  const OutboundFollowRequestEntriesCompanion({
    this.pubkey = const Value.absent(),
    this.connectionCard = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboundFollowRequestEntriesCompanion.insert({
    required String pubkey,
    required String connectionCard,
    required int createdAt,
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : pubkey = Value(pubkey),
       connectionCard = Value(connectionCard),
       createdAt = Value(createdAt);
  static Insertable<OutboundFollowRequestEntry> custom({
    Expression<String>? pubkey,
    Expression<String>? connectionCard,
    Expression<int>? createdAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pubkey != null) 'pubkey': pubkey,
      if (connectionCard != null) 'connection_card': connectionCard,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboundFollowRequestEntriesCompanion copyWith({
    Value<String>? pubkey,
    Value<String>? connectionCard,
    Value<int>? createdAt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return OutboundFollowRequestEntriesCompanion(
      pubkey: pubkey ?? this.pubkey,
      connectionCard: connectionCard ?? this.connectionCard,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (connectionCard.present) {
      map['connection_card'] = Variable<String>(connectionCard.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboundFollowRequestEntriesCompanion(')
          ..write('pubkey: $pubkey, ')
          ..write('connectionCard: $connectionCard, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboundQueueEntriesTable extends OutboundQueueEntries
    with TableInfo<$OutboundQueueEntriesTable, OutboundQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboundQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetPubkeyMeta = const VerificationMeta(
    'targetPubkey',
  );
  @override
  late final GeneratedColumn<String> targetPubkey = GeneratedColumn<String>(
    'target_pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventBlobMeta = const VerificationMeta(
    'eventBlob',
  );
  @override
  late final GeneratedColumn<Uint8List> eventBlob = GeneratedColumn<Uint8List>(
    'event_blob',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetPubkey,
    eventBlob,
    createdAt,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbound_queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboundQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_pubkey')) {
      context.handle(
        _targetPubkeyMeta,
        targetPubkey.isAcceptableOrUnknown(
          data['target_pubkey']!,
          _targetPubkeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetPubkeyMeta);
    }
    if (data.containsKey('event_blob')) {
      context.handle(
        _eventBlobMeta,
        eventBlob.isAcceptableOrUnknown(data['event_blob']!, _eventBlobMeta),
      );
    } else if (isInserting) {
      context.missing(_eventBlobMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboundQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboundQueueEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetPubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_pubkey'],
      )!,
      eventBlob: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}event_blob'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $OutboundQueueEntriesTable createAlias(String alias) {
    return $OutboundQueueEntriesTable(attachedDatabase, alias);
  }
}

class OutboundQueueEntry extends DataClass
    implements Insertable<OutboundQueueEntry> {
  final int id;
  final String targetPubkey;
  final Uint8List eventBlob;
  final int createdAt;
  final int retryCount;
  const OutboundQueueEntry({
    required this.id,
    required this.targetPubkey,
    required this.eventBlob,
    required this.createdAt,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_pubkey'] = Variable<String>(targetPubkey);
    map['event_blob'] = Variable<Uint8List>(eventBlob);
    map['created_at'] = Variable<int>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  OutboundQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboundQueueEntriesCompanion(
      id: Value(id),
      targetPubkey: Value(targetPubkey),
      eventBlob: Value(eventBlob),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
    );
  }

  factory OutboundQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboundQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      targetPubkey: serializer.fromJson<String>(json['targetPubkey']),
      eventBlob: serializer.fromJson<Uint8List>(json['eventBlob']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetPubkey': serializer.toJson<String>(targetPubkey),
      'eventBlob': serializer.toJson<Uint8List>(eventBlob),
      'createdAt': serializer.toJson<int>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  OutboundQueueEntry copyWith({
    int? id,
    String? targetPubkey,
    Uint8List? eventBlob,
    int? createdAt,
    int? retryCount,
  }) => OutboundQueueEntry(
    id: id ?? this.id,
    targetPubkey: targetPubkey ?? this.targetPubkey,
    eventBlob: eventBlob ?? this.eventBlob,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
  );
  OutboundQueueEntry copyWithCompanion(OutboundQueueEntriesCompanion data) {
    return OutboundQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      targetPubkey: data.targetPubkey.present
          ? data.targetPubkey.value
          : this.targetPubkey,
      eventBlob: data.eventBlob.present ? data.eventBlob.value : this.eventBlob,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboundQueueEntry(')
          ..write('id: $id, ')
          ..write('targetPubkey: $targetPubkey, ')
          ..write('eventBlob: $eventBlob, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetPubkey,
    $driftBlobEquality.hash(eventBlob),
    createdAt,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboundQueueEntry &&
          other.id == this.id &&
          other.targetPubkey == this.targetPubkey &&
          $driftBlobEquality.equals(other.eventBlob, this.eventBlob) &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount);
}

class OutboundQueueEntriesCompanion
    extends UpdateCompanion<OutboundQueueEntry> {
  final Value<int> id;
  final Value<String> targetPubkey;
  final Value<Uint8List> eventBlob;
  final Value<int> createdAt;
  final Value<int> retryCount;
  const OutboundQueueEntriesCompanion({
    this.id = const Value.absent(),
    this.targetPubkey = const Value.absent(),
    this.eventBlob = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  OutboundQueueEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String targetPubkey,
    required Uint8List eventBlob,
    required int createdAt,
    this.retryCount = const Value.absent(),
  }) : targetPubkey = Value(targetPubkey),
       eventBlob = Value(eventBlob),
       createdAt = Value(createdAt);
  static Insertable<OutboundQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? targetPubkey,
    Expression<Uint8List>? eventBlob,
    Expression<int>? createdAt,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetPubkey != null) 'target_pubkey': targetPubkey,
      if (eventBlob != null) 'event_blob': eventBlob,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  OutboundQueueEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? targetPubkey,
    Value<Uint8List>? eventBlob,
    Value<int>? createdAt,
    Value<int>? retryCount,
  }) {
    return OutboundQueueEntriesCompanion(
      id: id ?? this.id,
      targetPubkey: targetPubkey ?? this.targetPubkey,
      eventBlob: eventBlob ?? this.eventBlob,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetPubkey.present) {
      map['target_pubkey'] = Variable<String>(targetPubkey.value);
    }
    if (eventBlob.present) {
      map['event_blob'] = Variable<Uint8List>(eventBlob.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboundQueueEntriesCompanion(')
          ..write('id: $id, ')
          ..write('targetPubkey: $targetPubkey, ')
          ..write('eventBlob: $eventBlob, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

class $UnknownEnvelopeItemEntriesTable extends UnknownEnvelopeItemEntries
    with TableInfo<$UnknownEnvelopeItemEntriesTable, UnknownEnvelopeItemEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnknownEnvelopeItemEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourcePubkeyMeta = const VerificationMeta(
    'sourcePubkey',
  );
  @override
  late final GeneratedColumn<String> sourcePubkey = GeneratedColumn<String>(
    'source_pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _envelopeVersionMeta = const VerificationMeta(
    'envelopeVersion',
  );
  @override
  late final GeneratedColumn<String> envelopeVersion = GeneratedColumn<String>(
    'envelope_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extensionsMeta = const VerificationMeta(
    'extensions',
  );
  @override
  late final GeneratedColumn<Uint8List> extensions = GeneratedColumn<Uint8List>(
    'extensions',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<int> receivedAt = GeneratedColumn<int>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourcePubkey,
    envelopeVersion,
    type,
    payload,
    extensions,
    receivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unknown_envelope_item_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnknownEnvelopeItemEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_pubkey')) {
      context.handle(
        _sourcePubkeyMeta,
        sourcePubkey.isAcceptableOrUnknown(
          data['source_pubkey']!,
          _sourcePubkeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourcePubkeyMeta);
    }
    if (data.containsKey('envelope_version')) {
      context.handle(
        _envelopeVersionMeta,
        envelopeVersion.isAcceptableOrUnknown(
          data['envelope_version']!,
          _envelopeVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_envelopeVersionMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('extensions')) {
      context.handle(
        _extensionsMeta,
        extensions.isAcceptableOrUnknown(data['extensions']!, _extensionsMeta),
      );
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnknownEnvelopeItemEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnknownEnvelopeItemEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourcePubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_pubkey'],
      )!,
      envelopeVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}envelope_version'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
      extensions: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}extensions'],
      ),
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at'],
      )!,
    );
  }

  @override
  $UnknownEnvelopeItemEntriesTable createAlias(String alias) {
    return $UnknownEnvelopeItemEntriesTable(attachedDatabase, alias);
  }
}

class UnknownEnvelopeItemEntry extends DataClass
    implements Insertable<UnknownEnvelopeItemEntry> {
  final int id;

  /// The peer pubkey we received this item from. Lets us scope retention /
  /// purge by source if a peer turns hostile.
  final String sourcePubkey;

  /// `Envelope.version` at receive time — useful when we eventually decide
  /// whether to forward the item back during sync.
  final String envelopeVersion;

  /// The unknown `type` string, e.g. `"commit"` or `"receipt"`.
  final String type;

  /// Raw payload bytes. We never decode these.
  final Uint8List payload;

  /// Item-level extensions, raw CBOR (or null if absent).
  final Uint8List? extensions;
  final int receivedAt;
  const UnknownEnvelopeItemEntry({
    required this.id,
    required this.sourcePubkey,
    required this.envelopeVersion,
    required this.type,
    required this.payload,
    this.extensions,
    required this.receivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_pubkey'] = Variable<String>(sourcePubkey);
    map['envelope_version'] = Variable<String>(envelopeVersion);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<Uint8List>(payload);
    if (!nullToAbsent || extensions != null) {
      map['extensions'] = Variable<Uint8List>(extensions);
    }
    map['received_at'] = Variable<int>(receivedAt);
    return map;
  }

  UnknownEnvelopeItemEntriesCompanion toCompanion(bool nullToAbsent) {
    return UnknownEnvelopeItemEntriesCompanion(
      id: Value(id),
      sourcePubkey: Value(sourcePubkey),
      envelopeVersion: Value(envelopeVersion),
      type: Value(type),
      payload: Value(payload),
      extensions: extensions == null && nullToAbsent
          ? const Value.absent()
          : Value(extensions),
      receivedAt: Value(receivedAt),
    );
  }

  factory UnknownEnvelopeItemEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnknownEnvelopeItemEntry(
      id: serializer.fromJson<int>(json['id']),
      sourcePubkey: serializer.fromJson<String>(json['sourcePubkey']),
      envelopeVersion: serializer.fromJson<String>(json['envelopeVersion']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
      extensions: serializer.fromJson<Uint8List?>(json['extensions']),
      receivedAt: serializer.fromJson<int>(json['receivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourcePubkey': serializer.toJson<String>(sourcePubkey),
      'envelopeVersion': serializer.toJson<String>(envelopeVersion),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<Uint8List>(payload),
      'extensions': serializer.toJson<Uint8List?>(extensions),
      'receivedAt': serializer.toJson<int>(receivedAt),
    };
  }

  UnknownEnvelopeItemEntry copyWith({
    int? id,
    String? sourcePubkey,
    String? envelopeVersion,
    String? type,
    Uint8List? payload,
    Value<Uint8List?> extensions = const Value.absent(),
    int? receivedAt,
  }) => UnknownEnvelopeItemEntry(
    id: id ?? this.id,
    sourcePubkey: sourcePubkey ?? this.sourcePubkey,
    envelopeVersion: envelopeVersion ?? this.envelopeVersion,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    extensions: extensions.present ? extensions.value : this.extensions,
    receivedAt: receivedAt ?? this.receivedAt,
  );
  UnknownEnvelopeItemEntry copyWithCompanion(
    UnknownEnvelopeItemEntriesCompanion data,
  ) {
    return UnknownEnvelopeItemEntry(
      id: data.id.present ? data.id.value : this.id,
      sourcePubkey: data.sourcePubkey.present
          ? data.sourcePubkey.value
          : this.sourcePubkey,
      envelopeVersion: data.envelopeVersion.present
          ? data.envelopeVersion.value
          : this.envelopeVersion,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      extensions: data.extensions.present
          ? data.extensions.value
          : this.extensions,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnknownEnvelopeItemEntry(')
          ..write('id: $id, ')
          ..write('sourcePubkey: $sourcePubkey, ')
          ..write('envelopeVersion: $envelopeVersion, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('extensions: $extensions, ')
          ..write('receivedAt: $receivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourcePubkey,
    envelopeVersion,
    type,
    $driftBlobEquality.hash(payload),
    $driftBlobEquality.hash(extensions),
    receivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnknownEnvelopeItemEntry &&
          other.id == this.id &&
          other.sourcePubkey == this.sourcePubkey &&
          other.envelopeVersion == this.envelopeVersion &&
          other.type == this.type &&
          $driftBlobEquality.equals(other.payload, this.payload) &&
          $driftBlobEquality.equals(other.extensions, this.extensions) &&
          other.receivedAt == this.receivedAt);
}

class UnknownEnvelopeItemEntriesCompanion
    extends UpdateCompanion<UnknownEnvelopeItemEntry> {
  final Value<int> id;
  final Value<String> sourcePubkey;
  final Value<String> envelopeVersion;
  final Value<String> type;
  final Value<Uint8List> payload;
  final Value<Uint8List?> extensions;
  final Value<int> receivedAt;
  const UnknownEnvelopeItemEntriesCompanion({
    this.id = const Value.absent(),
    this.sourcePubkey = const Value.absent(),
    this.envelopeVersion = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.extensions = const Value.absent(),
    this.receivedAt = const Value.absent(),
  });
  UnknownEnvelopeItemEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String sourcePubkey,
    required String envelopeVersion,
    required String type,
    required Uint8List payload,
    this.extensions = const Value.absent(),
    required int receivedAt,
  }) : sourcePubkey = Value(sourcePubkey),
       envelopeVersion = Value(envelopeVersion),
       type = Value(type),
       payload = Value(payload),
       receivedAt = Value(receivedAt);
  static Insertable<UnknownEnvelopeItemEntry> custom({
    Expression<int>? id,
    Expression<String>? sourcePubkey,
    Expression<String>? envelopeVersion,
    Expression<String>? type,
    Expression<Uint8List>? payload,
    Expression<Uint8List>? extensions,
    Expression<int>? receivedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePubkey != null) 'source_pubkey': sourcePubkey,
      if (envelopeVersion != null) 'envelope_version': envelopeVersion,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (extensions != null) 'extensions': extensions,
      if (receivedAt != null) 'received_at': receivedAt,
    });
  }

  UnknownEnvelopeItemEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? sourcePubkey,
    Value<String>? envelopeVersion,
    Value<String>? type,
    Value<Uint8List>? payload,
    Value<Uint8List?>? extensions,
    Value<int>? receivedAt,
  }) {
    return UnknownEnvelopeItemEntriesCompanion(
      id: id ?? this.id,
      sourcePubkey: sourcePubkey ?? this.sourcePubkey,
      envelopeVersion: envelopeVersion ?? this.envelopeVersion,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      extensions: extensions ?? this.extensions,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourcePubkey.present) {
      map['source_pubkey'] = Variable<String>(sourcePubkey.value);
    }
    if (envelopeVersion.present) {
      map['envelope_version'] = Variable<String>(envelopeVersion.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (extensions.present) {
      map['extensions'] = Variable<Uint8List>(extensions.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<int>(receivedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnknownEnvelopeItemEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sourcePubkey: $sourcePubkey, ')
          ..write('envelopeVersion: $envelopeVersion, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('extensions: $extensions, ')
          ..write('receivedAt: $receivedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $IdentityEntriesTable identityEntries = $IdentityEntriesTable(
    this,
  );
  late final $FollowEntriesTable followEntries = $FollowEntriesTable(this);
  late final $EventEntriesTable eventEntries = $EventEntriesTable(this);
  late final $MediaCacheEntriesTable mediaCacheEntries =
      $MediaCacheEntriesTable(this);
  late final $InboundFollowRequestEntriesTable inboundFollowRequestEntries =
      $InboundFollowRequestEntriesTable(this);
  late final $OutboundFollowRequestEntriesTable outboundFollowRequestEntries =
      $OutboundFollowRequestEntriesTable(this);
  late final $OutboundQueueEntriesTable outboundQueueEntries =
      $OutboundQueueEntriesTable(this);
  late final $UnknownEnvelopeItemEntriesTable unknownEnvelopeItemEntries =
      $UnknownEnvelopeItemEntriesTable(this);
  late final IdentityDao identityDao = IdentityDao(this as AppDatabase);
  late final FollowsDao followsDao = FollowsDao(this as AppDatabase);
  late final EventsDao eventsDao = EventsDao(this as AppDatabase);
  late final MediaCacheDao mediaCacheDao = MediaCacheDao(this as AppDatabase);
  late final FollowRequestsDao followRequestsDao = FollowRequestsDao(
    this as AppDatabase,
  );
  late final OutboundQueueDao outboundQueueDao = OutboundQueueDao(
    this as AppDatabase,
  );
  late final UnknownItemsDao unknownItemsDao = UnknownItemsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    identityEntries,
    followEntries,
    eventEntries,
    mediaCacheEntries,
    inboundFollowRequestEntries,
    outboundFollowRequestEntries,
    outboundQueueEntries,
    unknownEnvelopeItemEntries,
  ];
}

typedef $$IdentityEntriesTableCreateCompanionBuilder =
    IdentityEntriesCompanion Function({
      required String pubkey,
      required Uint8List feedKey,
      Value<int> feedKeyEpoch,
      Value<String?> recoveryPhrase,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$IdentityEntriesTableUpdateCompanionBuilder =
    IdentityEntriesCompanion Function({
      Value<String> pubkey,
      Value<Uint8List> feedKey,
      Value<int> feedKeyEpoch,
      Value<String?> recoveryPhrase,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$IdentityEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $IdentityEntriesTable> {
  $$IdentityEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get feedKey => $composableBuilder(
    column: $table.feedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedKeyEpoch => $composableBuilder(
    column: $table.feedKeyEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoveryPhrase => $composableBuilder(
    column: $table.recoveryPhrase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IdentityEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $IdentityEntriesTable> {
  $$IdentityEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get feedKey => $composableBuilder(
    column: $table.feedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedKeyEpoch => $composableBuilder(
    column: $table.feedKeyEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoveryPhrase => $composableBuilder(
    column: $table.recoveryPhrase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IdentityEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IdentityEntriesTable> {
  $$IdentityEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);

  GeneratedColumn<Uint8List> get feedKey =>
      $composableBuilder(column: $table.feedKey, builder: (column) => column);

  GeneratedColumn<int> get feedKeyEpoch => $composableBuilder(
    column: $table.feedKeyEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoveryPhrase => $composableBuilder(
    column: $table.recoveryPhrase,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$IdentityEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IdentityEntriesTable,
          IdentityEntry,
          $$IdentityEntriesTableFilterComposer,
          $$IdentityEntriesTableOrderingComposer,
          $$IdentityEntriesTableAnnotationComposer,
          $$IdentityEntriesTableCreateCompanionBuilder,
          $$IdentityEntriesTableUpdateCompanionBuilder,
          (
            IdentityEntry,
            BaseReferences<_$AppDatabase, $IdentityEntriesTable, IdentityEntry>,
          ),
          IdentityEntry,
          PrefetchHooks Function()
        > {
  $$IdentityEntriesTableTableManager(
    _$AppDatabase db,
    $IdentityEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdentityEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdentityEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdentityEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pubkey = const Value.absent(),
                Value<Uint8List> feedKey = const Value.absent(),
                Value<int> feedKeyEpoch = const Value.absent(),
                Value<String?> recoveryPhrase = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IdentityEntriesCompanion(
                pubkey: pubkey,
                feedKey: feedKey,
                feedKeyEpoch: feedKeyEpoch,
                recoveryPhrase: recoveryPhrase,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pubkey,
                required Uint8List feedKey,
                Value<int> feedKeyEpoch = const Value.absent(),
                Value<String?> recoveryPhrase = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => IdentityEntriesCompanion.insert(
                pubkey: pubkey,
                feedKey: feedKey,
                feedKeyEpoch: feedKeyEpoch,
                recoveryPhrase: recoveryPhrase,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IdentityEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IdentityEntriesTable,
      IdentityEntry,
      $$IdentityEntriesTableFilterComposer,
      $$IdentityEntriesTableOrderingComposer,
      $$IdentityEntriesTableAnnotationComposer,
      $$IdentityEntriesTableCreateCompanionBuilder,
      $$IdentityEntriesTableUpdateCompanionBuilder,
      (
        IdentityEntry,
        BaseReferences<_$AppDatabase, $IdentityEntriesTable, IdentityEntry>,
      ),
      IdentityEntry,
      PrefetchHooks Function()
    >;
typedef $$FollowEntriesTableCreateCompanionBuilder =
    FollowEntriesCompanion Function({
      required String pubkey,
      Value<String?> displayName,
      Value<String?> avatarHash,
      required String connectionCard,
      required Uint8List feedKey,
      Value<int> feedKeyEpoch,
      Value<int> lastSyncedAt,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$FollowEntriesTableUpdateCompanionBuilder =
    FollowEntriesCompanion Function({
      Value<String> pubkey,
      Value<String?> displayName,
      Value<String?> avatarHash,
      Value<String> connectionCard,
      Value<Uint8List> feedKey,
      Value<int> feedKeyEpoch,
      Value<int> lastSyncedAt,
      Value<String> status,
      Value<int> rowid,
    });

class $$FollowEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FollowEntriesTable> {
  $$FollowEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarHash => $composableBuilder(
    column: $table.avatarHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get connectionCard => $composableBuilder(
    column: $table.connectionCard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get feedKey => $composableBuilder(
    column: $table.feedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedKeyEpoch => $composableBuilder(
    column: $table.feedKeyEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FollowEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowEntriesTable> {
  $$FollowEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarHash => $composableBuilder(
    column: $table.avatarHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connectionCard => $composableBuilder(
    column: $table.connectionCard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get feedKey => $composableBuilder(
    column: $table.feedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedKeyEpoch => $composableBuilder(
    column: $table.feedKeyEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FollowEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowEntriesTable> {
  $$FollowEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarHash => $composableBuilder(
    column: $table.avatarHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get connectionCard => $composableBuilder(
    column: $table.connectionCard,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get feedKey =>
      $composableBuilder(column: $table.feedKey, builder: (column) => column);

  GeneratedColumn<int> get feedKeyEpoch => $composableBuilder(
    column: $table.feedKeyEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$FollowEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FollowEntriesTable,
          FollowEntry,
          $$FollowEntriesTableFilterComposer,
          $$FollowEntriesTableOrderingComposer,
          $$FollowEntriesTableAnnotationComposer,
          $$FollowEntriesTableCreateCompanionBuilder,
          $$FollowEntriesTableUpdateCompanionBuilder,
          (
            FollowEntry,
            BaseReferences<_$AppDatabase, $FollowEntriesTable, FollowEntry>,
          ),
          FollowEntry,
          PrefetchHooks Function()
        > {
  $$FollowEntriesTableTableManager(_$AppDatabase db, $FollowEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pubkey = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> avatarHash = const Value.absent(),
                Value<String> connectionCard = const Value.absent(),
                Value<Uint8List> feedKey = const Value.absent(),
                Value<int> feedKeyEpoch = const Value.absent(),
                Value<int> lastSyncedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FollowEntriesCompanion(
                pubkey: pubkey,
                displayName: displayName,
                avatarHash: avatarHash,
                connectionCard: connectionCard,
                feedKey: feedKey,
                feedKeyEpoch: feedKeyEpoch,
                lastSyncedAt: lastSyncedAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pubkey,
                Value<String?> displayName = const Value.absent(),
                Value<String?> avatarHash = const Value.absent(),
                required String connectionCard,
                required Uint8List feedKey,
                Value<int> feedKeyEpoch = const Value.absent(),
                Value<int> lastSyncedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FollowEntriesCompanion.insert(
                pubkey: pubkey,
                displayName: displayName,
                avatarHash: avatarHash,
                connectionCard: connectionCard,
                feedKey: feedKey,
                feedKeyEpoch: feedKeyEpoch,
                lastSyncedAt: lastSyncedAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FollowEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FollowEntriesTable,
      FollowEntry,
      $$FollowEntriesTableFilterComposer,
      $$FollowEntriesTableOrderingComposer,
      $$FollowEntriesTableAnnotationComposer,
      $$FollowEntriesTableCreateCompanionBuilder,
      $$FollowEntriesTableUpdateCompanionBuilder,
      (
        FollowEntry,
        BaseReferences<_$AppDatabase, $FollowEntriesTable, FollowEntry>,
      ),
      FollowEntry,
      PrefetchHooks Function()
    >;
typedef $$EventEntriesTableCreateCompanionBuilder =
    EventEntriesCompanion Function({
      required String id,
      required String pubkey,
      required int createdAt,
      required int kind,
      Value<String?> refId,
      required Uint8List content,
      Value<String?> mediaRefs,
      required Uint8List sig,
      Value<int> isOwn,
      Value<int> isSaved,
      required int fetchedAt,
      Value<int?> lastViewed,
      Value<String> version,
      Value<Uint8List?> extensions,
      Value<int> rowid,
    });
typedef $$EventEntriesTableUpdateCompanionBuilder =
    EventEntriesCompanion Function({
      Value<String> id,
      Value<String> pubkey,
      Value<int> createdAt,
      Value<int> kind,
      Value<String?> refId,
      Value<Uint8List> content,
      Value<String?> mediaRefs,
      Value<Uint8List> sig,
      Value<int> isOwn,
      Value<int> isSaved,
      Value<int> fetchedAt,
      Value<int?> lastViewed,
      Value<String> version,
      Value<Uint8List?> extensions,
      Value<int> rowid,
    });

class $$EventEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EventEntriesTable> {
  $$EventEntriesTableFilterComposer({
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

  ColumnFilters<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaRefs => $composableBuilder(
    column: $table.mediaRefs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get sig => $composableBuilder(
    column: $table.sig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isOwn => $composableBuilder(
    column: $table.isOwn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isSaved => $composableBuilder(
    column: $table.isSaved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastViewed => $composableBuilder(
    column: $table.lastViewed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get extensions => $composableBuilder(
    column: $table.extensions,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EventEntriesTable> {
  $$EventEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaRefs => $composableBuilder(
    column: $table.mediaRefs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get sig => $composableBuilder(
    column: $table.sig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isOwn => $composableBuilder(
    column: $table.isOwn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isSaved => $composableBuilder(
    column: $table.isSaved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastViewed => $composableBuilder(
    column: $table.lastViewed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get extensions => $composableBuilder(
    column: $table.extensions,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventEntriesTable> {
  $$EventEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<Uint8List> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get mediaRefs =>
      $composableBuilder(column: $table.mediaRefs, builder: (column) => column);

  GeneratedColumn<Uint8List> get sig =>
      $composableBuilder(column: $table.sig, builder: (column) => column);

  GeneratedColumn<int> get isOwn =>
      $composableBuilder(column: $table.isOwn, builder: (column) => column);

  GeneratedColumn<int> get isSaved =>
      $composableBuilder(column: $table.isSaved, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<int> get lastViewed => $composableBuilder(
    column: $table.lastViewed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<Uint8List> get extensions => $composableBuilder(
    column: $table.extensions,
    builder: (column) => column,
  );
}

class $$EventEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventEntriesTable,
          EventEntry,
          $$EventEntriesTableFilterComposer,
          $$EventEntriesTableOrderingComposer,
          $$EventEntriesTableAnnotationComposer,
          $$EventEntriesTableCreateCompanionBuilder,
          $$EventEntriesTableUpdateCompanionBuilder,
          (
            EventEntry,
            BaseReferences<_$AppDatabase, $EventEntriesTable, EventEntry>,
          ),
          EventEntry,
          PrefetchHooks Function()
        > {
  $$EventEntriesTableTableManager(_$AppDatabase db, $EventEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pubkey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> kind = const Value.absent(),
                Value<String?> refId = const Value.absent(),
                Value<Uint8List> content = const Value.absent(),
                Value<String?> mediaRefs = const Value.absent(),
                Value<Uint8List> sig = const Value.absent(),
                Value<int> isOwn = const Value.absent(),
                Value<int> isSaved = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int?> lastViewed = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<Uint8List?> extensions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventEntriesCompanion(
                id: id,
                pubkey: pubkey,
                createdAt: createdAt,
                kind: kind,
                refId: refId,
                content: content,
                mediaRefs: mediaRefs,
                sig: sig,
                isOwn: isOwn,
                isSaved: isSaved,
                fetchedAt: fetchedAt,
                lastViewed: lastViewed,
                version: version,
                extensions: extensions,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pubkey,
                required int createdAt,
                required int kind,
                Value<String?> refId = const Value.absent(),
                required Uint8List content,
                Value<String?> mediaRefs = const Value.absent(),
                required Uint8List sig,
                Value<int> isOwn = const Value.absent(),
                Value<int> isSaved = const Value.absent(),
                required int fetchedAt,
                Value<int?> lastViewed = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<Uint8List?> extensions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventEntriesCompanion.insert(
                id: id,
                pubkey: pubkey,
                createdAt: createdAt,
                kind: kind,
                refId: refId,
                content: content,
                mediaRefs: mediaRefs,
                sig: sig,
                isOwn: isOwn,
                isSaved: isSaved,
                fetchedAt: fetchedAt,
                lastViewed: lastViewed,
                version: version,
                extensions: extensions,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventEntriesTable,
      EventEntry,
      $$EventEntriesTableFilterComposer,
      $$EventEntriesTableOrderingComposer,
      $$EventEntriesTableAnnotationComposer,
      $$EventEntriesTableCreateCompanionBuilder,
      $$EventEntriesTableUpdateCompanionBuilder,
      (
        EventEntry,
        BaseReferences<_$AppDatabase, $EventEntriesTable, EventEntry>,
      ),
      EventEntry,
      PrefetchHooks Function()
    >;
typedef $$MediaCacheEntriesTableCreateCompanionBuilder =
    MediaCacheEntriesCompanion Function({
      required String hash,
      required String path,
      required int size,
      required int lastAccessed,
      Value<int> rowid,
    });
typedef $$MediaCacheEntriesTableUpdateCompanionBuilder =
    MediaCacheEntriesCompanion Function({
      Value<String> hash,
      Value<String> path,
      Value<int> size,
      Value<int> lastAccessed,
      Value<int> rowid,
    });

class $$MediaCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MediaCacheEntriesTable> {
  $$MediaCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaCacheEntriesTable> {
  $$MediaCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaCacheEntriesTable> {
  $$MediaCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => column,
  );
}

class $$MediaCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaCacheEntriesTable,
          MediaCacheEntry,
          $$MediaCacheEntriesTableFilterComposer,
          $$MediaCacheEntriesTableOrderingComposer,
          $$MediaCacheEntriesTableAnnotationComposer,
          $$MediaCacheEntriesTableCreateCompanionBuilder,
          $$MediaCacheEntriesTableUpdateCompanionBuilder,
          (
            MediaCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $MediaCacheEntriesTable,
              MediaCacheEntry
            >,
          ),
          MediaCacheEntry,
          PrefetchHooks Function()
        > {
  $$MediaCacheEntriesTableTableManager(
    _$AppDatabase db,
    $MediaCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> hash = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<int> lastAccessed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaCacheEntriesCompanion(
                hash: hash,
                path: path,
                size: size,
                lastAccessed: lastAccessed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String hash,
                required String path,
                required int size,
                required int lastAccessed,
                Value<int> rowid = const Value.absent(),
              }) => MediaCacheEntriesCompanion.insert(
                hash: hash,
                path: path,
                size: size,
                lastAccessed: lastAccessed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaCacheEntriesTable,
      MediaCacheEntry,
      $$MediaCacheEntriesTableFilterComposer,
      $$MediaCacheEntriesTableOrderingComposer,
      $$MediaCacheEntriesTableAnnotationComposer,
      $$MediaCacheEntriesTableCreateCompanionBuilder,
      $$MediaCacheEntriesTableUpdateCompanionBuilder,
      (
        MediaCacheEntry,
        BaseReferences<_$AppDatabase, $MediaCacheEntriesTable, MediaCacheEntry>,
      ),
      MediaCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$InboundFollowRequestEntriesTableCreateCompanionBuilder =
    InboundFollowRequestEntriesCompanion Function({
      required String pubkey,
      required Uint8List encryptedEndpoints,
      required int createdAt,
      Value<int> requestTimestamp,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$InboundFollowRequestEntriesTableUpdateCompanionBuilder =
    InboundFollowRequestEntriesCompanion Function({
      Value<String> pubkey,
      Value<Uint8List> encryptedEndpoints,
      Value<int> createdAt,
      Value<int> requestTimestamp,
      Value<String> status,
      Value<int> rowid,
    });

class $$InboundFollowRequestEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $InboundFollowRequestEntriesTable> {
  $$InboundFollowRequestEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedEndpoints => $composableBuilder(
    column: $table.encryptedEndpoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requestTimestamp => $composableBuilder(
    column: $table.requestTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InboundFollowRequestEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $InboundFollowRequestEntriesTable> {
  $$InboundFollowRequestEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedEndpoints => $composableBuilder(
    column: $table.encryptedEndpoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requestTimestamp => $composableBuilder(
    column: $table.requestTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InboundFollowRequestEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InboundFollowRequestEntriesTable> {
  $$InboundFollowRequestEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptedEndpoints => $composableBuilder(
    column: $table.encryptedEndpoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get requestTimestamp => $composableBuilder(
    column: $table.requestTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$InboundFollowRequestEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InboundFollowRequestEntriesTable,
          InboundFollowRequestEntry,
          $$InboundFollowRequestEntriesTableFilterComposer,
          $$InboundFollowRequestEntriesTableOrderingComposer,
          $$InboundFollowRequestEntriesTableAnnotationComposer,
          $$InboundFollowRequestEntriesTableCreateCompanionBuilder,
          $$InboundFollowRequestEntriesTableUpdateCompanionBuilder,
          (
            InboundFollowRequestEntry,
            BaseReferences<
              _$AppDatabase,
              $InboundFollowRequestEntriesTable,
              InboundFollowRequestEntry
            >,
          ),
          InboundFollowRequestEntry,
          PrefetchHooks Function()
        > {
  $$InboundFollowRequestEntriesTableTableManager(
    _$AppDatabase db,
    $InboundFollowRequestEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InboundFollowRequestEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InboundFollowRequestEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InboundFollowRequestEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> pubkey = const Value.absent(),
                Value<Uint8List> encryptedEndpoints = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> requestTimestamp = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InboundFollowRequestEntriesCompanion(
                pubkey: pubkey,
                encryptedEndpoints: encryptedEndpoints,
                createdAt: createdAt,
                requestTimestamp: requestTimestamp,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pubkey,
                required Uint8List encryptedEndpoints,
                required int createdAt,
                Value<int> requestTimestamp = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InboundFollowRequestEntriesCompanion.insert(
                pubkey: pubkey,
                encryptedEndpoints: encryptedEndpoints,
                createdAt: createdAt,
                requestTimestamp: requestTimestamp,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InboundFollowRequestEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InboundFollowRequestEntriesTable,
      InboundFollowRequestEntry,
      $$InboundFollowRequestEntriesTableFilterComposer,
      $$InboundFollowRequestEntriesTableOrderingComposer,
      $$InboundFollowRequestEntriesTableAnnotationComposer,
      $$InboundFollowRequestEntriesTableCreateCompanionBuilder,
      $$InboundFollowRequestEntriesTableUpdateCompanionBuilder,
      (
        InboundFollowRequestEntry,
        BaseReferences<
          _$AppDatabase,
          $InboundFollowRequestEntriesTable,
          InboundFollowRequestEntry
        >,
      ),
      InboundFollowRequestEntry,
      PrefetchHooks Function()
    >;
typedef $$OutboundFollowRequestEntriesTableCreateCompanionBuilder =
    OutboundFollowRequestEntriesCompanion Function({
      required String pubkey,
      required String connectionCard,
      required int createdAt,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$OutboundFollowRequestEntriesTableUpdateCompanionBuilder =
    OutboundFollowRequestEntriesCompanion Function({
      Value<String> pubkey,
      Value<String> connectionCard,
      Value<int> createdAt,
      Value<String> status,
      Value<int> rowid,
    });

class $$OutboundFollowRequestEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OutboundFollowRequestEntriesTable> {
  $$OutboundFollowRequestEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get connectionCard => $composableBuilder(
    column: $table.connectionCard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboundFollowRequestEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboundFollowRequestEntriesTable> {
  $$OutboundFollowRequestEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pubkey => $composableBuilder(
    column: $table.pubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connectionCard => $composableBuilder(
    column: $table.connectionCard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboundFollowRequestEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboundFollowRequestEntriesTable> {
  $$OutboundFollowRequestEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);

  GeneratedColumn<String> get connectionCard => $composableBuilder(
    column: $table.connectionCard,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$OutboundFollowRequestEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboundFollowRequestEntriesTable,
          OutboundFollowRequestEntry,
          $$OutboundFollowRequestEntriesTableFilterComposer,
          $$OutboundFollowRequestEntriesTableOrderingComposer,
          $$OutboundFollowRequestEntriesTableAnnotationComposer,
          $$OutboundFollowRequestEntriesTableCreateCompanionBuilder,
          $$OutboundFollowRequestEntriesTableUpdateCompanionBuilder,
          (
            OutboundFollowRequestEntry,
            BaseReferences<
              _$AppDatabase,
              $OutboundFollowRequestEntriesTable,
              OutboundFollowRequestEntry
            >,
          ),
          OutboundFollowRequestEntry,
          PrefetchHooks Function()
        > {
  $$OutboundFollowRequestEntriesTableTableManager(
    _$AppDatabase db,
    $OutboundFollowRequestEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboundFollowRequestEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OutboundFollowRequestEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OutboundFollowRequestEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> pubkey = const Value.absent(),
                Value<String> connectionCard = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboundFollowRequestEntriesCompanion(
                pubkey: pubkey,
                connectionCard: connectionCard,
                createdAt: createdAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pubkey,
                required String connectionCard,
                required int createdAt,
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboundFollowRequestEntriesCompanion.insert(
                pubkey: pubkey,
                connectionCard: connectionCard,
                createdAt: createdAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboundFollowRequestEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboundFollowRequestEntriesTable,
      OutboundFollowRequestEntry,
      $$OutboundFollowRequestEntriesTableFilterComposer,
      $$OutboundFollowRequestEntriesTableOrderingComposer,
      $$OutboundFollowRequestEntriesTableAnnotationComposer,
      $$OutboundFollowRequestEntriesTableCreateCompanionBuilder,
      $$OutboundFollowRequestEntriesTableUpdateCompanionBuilder,
      (
        OutboundFollowRequestEntry,
        BaseReferences<
          _$AppDatabase,
          $OutboundFollowRequestEntriesTable,
          OutboundFollowRequestEntry
        >,
      ),
      OutboundFollowRequestEntry,
      PrefetchHooks Function()
    >;
typedef $$OutboundQueueEntriesTableCreateCompanionBuilder =
    OutboundQueueEntriesCompanion Function({
      Value<int> id,
      required String targetPubkey,
      required Uint8List eventBlob,
      required int createdAt,
      Value<int> retryCount,
    });
typedef $$OutboundQueueEntriesTableUpdateCompanionBuilder =
    OutboundQueueEntriesCompanion Function({
      Value<int> id,
      Value<String> targetPubkey,
      Value<Uint8List> eventBlob,
      Value<int> createdAt,
      Value<int> retryCount,
    });

class $$OutboundQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OutboundQueueEntriesTable> {
  $$OutboundQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetPubkey => $composableBuilder(
    column: $table.targetPubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get eventBlob => $composableBuilder(
    column: $table.eventBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboundQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboundQueueEntriesTable> {
  $$OutboundQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetPubkey => $composableBuilder(
    column: $table.targetPubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get eventBlob => $composableBuilder(
    column: $table.eventBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboundQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboundQueueEntriesTable> {
  $$OutboundQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetPubkey => $composableBuilder(
    column: $table.targetPubkey,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get eventBlob =>
      $composableBuilder(column: $table.eventBlob, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$OutboundQueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboundQueueEntriesTable,
          OutboundQueueEntry,
          $$OutboundQueueEntriesTableFilterComposer,
          $$OutboundQueueEntriesTableOrderingComposer,
          $$OutboundQueueEntriesTableAnnotationComposer,
          $$OutboundQueueEntriesTableCreateCompanionBuilder,
          $$OutboundQueueEntriesTableUpdateCompanionBuilder,
          (
            OutboundQueueEntry,
            BaseReferences<
              _$AppDatabase,
              $OutboundQueueEntriesTable,
              OutboundQueueEntry
            >,
          ),
          OutboundQueueEntry,
          PrefetchHooks Function()
        > {
  $$OutboundQueueEntriesTableTableManager(
    _$AppDatabase db,
    $OutboundQueueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboundQueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboundQueueEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OutboundQueueEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetPubkey = const Value.absent(),
                Value<Uint8List> eventBlob = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => OutboundQueueEntriesCompanion(
                id: id,
                targetPubkey: targetPubkey,
                eventBlob: eventBlob,
                createdAt: createdAt,
                retryCount: retryCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String targetPubkey,
                required Uint8List eventBlob,
                required int createdAt,
                Value<int> retryCount = const Value.absent(),
              }) => OutboundQueueEntriesCompanion.insert(
                id: id,
                targetPubkey: targetPubkey,
                eventBlob: eventBlob,
                createdAt: createdAt,
                retryCount: retryCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboundQueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboundQueueEntriesTable,
      OutboundQueueEntry,
      $$OutboundQueueEntriesTableFilterComposer,
      $$OutboundQueueEntriesTableOrderingComposer,
      $$OutboundQueueEntriesTableAnnotationComposer,
      $$OutboundQueueEntriesTableCreateCompanionBuilder,
      $$OutboundQueueEntriesTableUpdateCompanionBuilder,
      (
        OutboundQueueEntry,
        BaseReferences<
          _$AppDatabase,
          $OutboundQueueEntriesTable,
          OutboundQueueEntry
        >,
      ),
      OutboundQueueEntry,
      PrefetchHooks Function()
    >;
typedef $$UnknownEnvelopeItemEntriesTableCreateCompanionBuilder =
    UnknownEnvelopeItemEntriesCompanion Function({
      Value<int> id,
      required String sourcePubkey,
      required String envelopeVersion,
      required String type,
      required Uint8List payload,
      Value<Uint8List?> extensions,
      required int receivedAt,
    });
typedef $$UnknownEnvelopeItemEntriesTableUpdateCompanionBuilder =
    UnknownEnvelopeItemEntriesCompanion Function({
      Value<int> id,
      Value<String> sourcePubkey,
      Value<String> envelopeVersion,
      Value<String> type,
      Value<Uint8List> payload,
      Value<Uint8List?> extensions,
      Value<int> receivedAt,
    });

class $$UnknownEnvelopeItemEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $UnknownEnvelopeItemEntriesTable> {
  $$UnknownEnvelopeItemEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePubkey => $composableBuilder(
    column: $table.sourcePubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get envelopeVersion => $composableBuilder(
    column: $table.envelopeVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get extensions => $composableBuilder(
    column: $table.extensions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnknownEnvelopeItemEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $UnknownEnvelopeItemEntriesTable> {
  $$UnknownEnvelopeItemEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePubkey => $composableBuilder(
    column: $table.sourcePubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get envelopeVersion => $composableBuilder(
    column: $table.envelopeVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get extensions => $composableBuilder(
    column: $table.extensions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnknownEnvelopeItemEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnknownEnvelopeItemEntriesTable> {
  $$UnknownEnvelopeItemEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourcePubkey => $composableBuilder(
    column: $table.sourcePubkey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get envelopeVersion => $composableBuilder(
    column: $table.envelopeVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<Uint8List> get extensions => $composableBuilder(
    column: $table.extensions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );
}

class $$UnknownEnvelopeItemEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnknownEnvelopeItemEntriesTable,
          UnknownEnvelopeItemEntry,
          $$UnknownEnvelopeItemEntriesTableFilterComposer,
          $$UnknownEnvelopeItemEntriesTableOrderingComposer,
          $$UnknownEnvelopeItemEntriesTableAnnotationComposer,
          $$UnknownEnvelopeItemEntriesTableCreateCompanionBuilder,
          $$UnknownEnvelopeItemEntriesTableUpdateCompanionBuilder,
          (
            UnknownEnvelopeItemEntry,
            BaseReferences<
              _$AppDatabase,
              $UnknownEnvelopeItemEntriesTable,
              UnknownEnvelopeItemEntry
            >,
          ),
          UnknownEnvelopeItemEntry,
          PrefetchHooks Function()
        > {
  $$UnknownEnvelopeItemEntriesTableTableManager(
    _$AppDatabase db,
    $UnknownEnvelopeItemEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnknownEnvelopeItemEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UnknownEnvelopeItemEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UnknownEnvelopeItemEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourcePubkey = const Value.absent(),
                Value<String> envelopeVersion = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<Uint8List?> extensions = const Value.absent(),
                Value<int> receivedAt = const Value.absent(),
              }) => UnknownEnvelopeItemEntriesCompanion(
                id: id,
                sourcePubkey: sourcePubkey,
                envelopeVersion: envelopeVersion,
                type: type,
                payload: payload,
                extensions: extensions,
                receivedAt: receivedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourcePubkey,
                required String envelopeVersion,
                required String type,
                required Uint8List payload,
                Value<Uint8List?> extensions = const Value.absent(),
                required int receivedAt,
              }) => UnknownEnvelopeItemEntriesCompanion.insert(
                id: id,
                sourcePubkey: sourcePubkey,
                envelopeVersion: envelopeVersion,
                type: type,
                payload: payload,
                extensions: extensions,
                receivedAt: receivedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnknownEnvelopeItemEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnknownEnvelopeItemEntriesTable,
      UnknownEnvelopeItemEntry,
      $$UnknownEnvelopeItemEntriesTableFilterComposer,
      $$UnknownEnvelopeItemEntriesTableOrderingComposer,
      $$UnknownEnvelopeItemEntriesTableAnnotationComposer,
      $$UnknownEnvelopeItemEntriesTableCreateCompanionBuilder,
      $$UnknownEnvelopeItemEntriesTableUpdateCompanionBuilder,
      (
        UnknownEnvelopeItemEntry,
        BaseReferences<
          _$AppDatabase,
          $UnknownEnvelopeItemEntriesTable,
          UnknownEnvelopeItemEntry
        >,
      ),
      UnknownEnvelopeItemEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$IdentityEntriesTableTableManager get identityEntries =>
      $$IdentityEntriesTableTableManager(_db, _db.identityEntries);
  $$FollowEntriesTableTableManager get followEntries =>
      $$FollowEntriesTableTableManager(_db, _db.followEntries);
  $$EventEntriesTableTableManager get eventEntries =>
      $$EventEntriesTableTableManager(_db, _db.eventEntries);
  $$MediaCacheEntriesTableTableManager get mediaCacheEntries =>
      $$MediaCacheEntriesTableTableManager(_db, _db.mediaCacheEntries);
  $$InboundFollowRequestEntriesTableTableManager
  get inboundFollowRequestEntries =>
      $$InboundFollowRequestEntriesTableTableManager(
        _db,
        _db.inboundFollowRequestEntries,
      );
  $$OutboundFollowRequestEntriesTableTableManager
  get outboundFollowRequestEntries =>
      $$OutboundFollowRequestEntriesTableTableManager(
        _db,
        _db.outboundFollowRequestEntries,
      );
  $$OutboundQueueEntriesTableTableManager get outboundQueueEntries =>
      $$OutboundQueueEntriesTableTableManager(_db, _db.outboundQueueEntries);
  $$UnknownEnvelopeItemEntriesTableTableManager
  get unknownEnvelopeItemEntries =>
      $$UnknownEnvelopeItemEntriesTableTableManager(
        _db,
        _db.unknownEnvelopeItemEntries,
      );
}
