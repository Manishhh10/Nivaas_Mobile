// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_host_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdminHostHiveModelAdapter extends TypeAdapter<AdminHostHiveModel> {
  @override
  final int typeId = 1;

  @override
  AdminHostHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdminHostHiveModel(
      id: fields[0] as String,
      userName: fields[1] as String,
      userEmail: fields[2] as String,
      userPhone: fields[3] as String,
      legalName: fields[4] as String,
      hostPhone: fields[5] as String,
      address: fields[6] as String,
      governmentId: fields[7] as String,
      idDocument: fields[8] as String,
      verificationStatus: fields[9] as String,
      rejectionReason: fields[10] as String,
      createdAt: fields[11] as String,
      cachedAt: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AdminHostHiveModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userName)
      ..writeByte(2)
      ..write(obj.userEmail)
      ..writeByte(3)
      ..write(obj.userPhone)
      ..writeByte(4)
      ..write(obj.legalName)
      ..writeByte(5)
      ..write(obj.hostPhone)
      ..writeByte(6)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.governmentId)
      ..writeByte(8)
      ..write(obj.idDocument)
      ..writeByte(9)
      ..write(obj.verificationStatus)
      ..writeByte(10)
      ..write(obj.rejectionReason)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminHostHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AdminPendingActionAdapter extends TypeAdapter<AdminPendingAction> {
  @override
  final int typeId = 2;

  @override
  AdminPendingAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdminPendingAction(
      hostId: fields[0] as String,
      action: fields[1] as String,
      reason: fields[2] as String,
      createdAt: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AdminPendingAction obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.hostId)
      ..writeByte(1)
      ..write(obj.action)
      ..writeByte(2)
      ..write(obj.reason)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPendingActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
