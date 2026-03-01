import 'package:hive/hive.dart';
import 'package:nivaas/core/constants/hive_table_constant.dart';

part 'admin_host_hive_model.g.dart';

@HiveType(typeId: HiveTableConstant.adminHostTypeId)
class AdminHostHiveModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userName;

  @HiveField(2)
  final String userEmail;

  @HiveField(3)
  final String userPhone;

  @HiveField(4)
  final String legalName;

  @HiveField(5)
  final String hostPhone;

  @HiveField(6)
  final String address;

  @HiveField(7)
  final String governmentId;

  @HiveField(8)
  final String idDocument;

  @HiveField(9)
  final String verificationStatus;

  @HiveField(10)
  final String rejectionReason;

  @HiveField(11)
  final String createdAt;

  @HiveField(12)
  final String cachedAt;

  AdminHostHiveModel({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.legalName,
    required this.hostPhone,
    required this.address,
    required this.governmentId,
    required this.idDocument,
    required this.verificationStatus,
    required this.rejectionReason,
    required this.createdAt,
    required this.cachedAt,
  });

  factory AdminHostHiveModel.fromApiMap(Map<String, dynamic> host) {
    final user = host['userId'];
    return AdminHostHiveModel(
      id: host['_id']?.toString() ?? '',
      userName: user is Map<String, dynamic> ? (user['name']?.toString() ?? '') : '',
      userEmail: user is Map<String, dynamic> ? (user['email']?.toString() ?? '') : '',
      userPhone: user is Map<String, dynamic> ? (user['phoneNumber']?.toString() ?? '') : '',
      legalName: host['legalName']?.toString() ?? '',
      hostPhone: host['phoneNumber']?.toString() ?? '',
      address: host['address']?.toString() ?? '',
      governmentId: host['governmentId']?.toString() ?? '',
      idDocument: host['idDocument']?.toString() ?? '',
      verificationStatus: host['verificationStatus']?.toString() ?? 'pending',
      rejectionReason: host['rejectionReason']?.toString() ?? '',
      createdAt: host['createdAt']?.toString() ?? '',
      cachedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Convert back to the Map format the screen expects.
  Map<String, dynamic> toApiMap() {
    return {
      '_id': id,
      'userId': {
        'name': userName,
        'email': userEmail,
        'phoneNumber': userPhone,
      },
      'legalName': legalName,
      'phoneNumber': hostPhone,
      'address': address,
      'governmentId': governmentId,
      'idDocument': idDocument,
      'verificationStatus': verificationStatus,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
    };
  }
}

@HiveType(typeId: HiveTableConstant.adminActionTypeId)
class AdminPendingAction {
  @HiveField(0)
  final String hostId;

  @HiveField(1)
  final String action; // 'approve' or 'reject'

  @HiveField(2)
  final String reason;

  @HiveField(3)
  final String createdAt;

  AdminPendingAction({
    required this.hostId,
    required this.action,
    required this.reason,
    required this.createdAt,
  });
}
