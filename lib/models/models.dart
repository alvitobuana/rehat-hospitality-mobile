import 'package:flutter/material.dart';

enum UserRole { staff, leader, manager }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String hotelUnit;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.hotelUnit,
  });

  String get roleString {
    switch (role) {
      case UserRole.staff:
        return 'Staff';
      case UserRole.leader:
        return 'Leader';
      case UserRole.manager:
        return 'Manager';
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.toString().split('.').last == json['role']),
      department: json['department'],
      hotelUnit: json['hotelUnit'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.toString().split('.').last,
    'department': department,
    'hotelUnit': hotelUnit,
  };
}

class ChecklistItem {
  final String id;
  final String name;
  final bool isChecked;

  ChecklistItem({
    required this.id,
    required this.name,
    required this.isChecked,
  });

  ChecklistItem copyWith({bool? isChecked}) {
    return ChecklistItem(
      id: id,
      name: name,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

class Room {
  final String roomNumber;
  final String type;
  final String workType; // 'Make Up Room', 'General Cleaning'
  final String status; // 'Occupied', 'Vacant Clean', 'Vacant Dirty', 'Out of Order', 'Check Out'
  final String defectNote;
  final String staffName;
  final String startTime;
  final String endTime;
  final String verifiedStatus; // 'Pending', 'Verified', 'Not Verified'
  final String? verifierName;
  final String hotelUnit;
  final String date;
  final List<ChecklistItem> checklist;
  final String? photoPath; // dummy path or true/false if photo was taken

  Room({
    required this.roomNumber,
    required this.type,
    required this.workType,
    required this.status,
    required this.defectNote,
    required this.staffName,
    required this.startTime,
    required this.endTime,
    required this.verifiedStatus,
    this.verifierName,
    required this.hotelUnit,
    required this.date,
    required this.checklist,
    this.photoPath,
  });

  Room copyWith({
    String? status,
    String? defectNote,
    String? startTime,
    String? endTime,
    String? verifiedStatus,
    String? verifierName,
    List<ChecklistItem>? checklist,
    String? photoPath,
  }) {
    return Room(
      roomNumber: roomNumber,
      type: type,
      workType: workType,
      status: status ?? this.status,
      defectNote: defectNote ?? this.defectNote,
      staffName: staffName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      verifiedStatus: verifiedStatus ?? this.verifiedStatus,
      verifierName: verifierName ?? this.verifierName,
      hotelUnit: hotelUnit,
      date: date,
      checklist: checklist ?? this.checklist,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

class LostFoundItem {
  final String id;
  final String date;
  final String refNumber;
  final String roomNumber;
  final String itemCategory; // 'Elektronik', 'Pakaian', 'Uang / Dompet', etc.
  final String itemName;
  final String location; // 'Di bawah tempat tidur', 'Di lemari', etc.
  final String description;
  final String condition; // 'Baik', 'Rusak sebagian', 'Tidak diketahui'
  final String value; // 'Rendah', 'Sedang', 'Tinggi', 'Tidak diketahui'
  final String status; // 'Disimpan', 'Diklaim', 'Diserahkan ke FO'
  final String reportedBy;
  final String hotelUnit;
  final String handoverTo; // 'Disimpan di Housekeeping', 'Diserahkan ke FO', etc.
  final String? claimedBy;
  final String? claimDate;
  final String? photoPath;

  LostFoundItem({
    required this.id,
    required this.date,
    required this.refNumber,
    required this.roomNumber,
    required this.itemCategory,
    required this.itemName,
    required this.location,
    required this.description,
    required this.condition,
    required this.value,
    required this.status,
    required this.reportedBy,
    required this.hotelUnit,
    required this.handoverTo,
    this.claimedBy,
    this.claimDate,
    this.photoPath,
  });

  LostFoundItem copyWith({
    String? status,
    String? claimedBy,
    String? claimDate,
  }) {
    return LostFoundItem(
      id: id,
      date: date,
      refNumber: refNumber,
      roomNumber: roomNumber,
      itemCategory: itemCategory,
      itemName: itemName,
      location: location,
      description: description,
      condition: condition,
      value: value,
      status: status ?? this.status,
      reportedBy: reportedBy,
      hotelUnit: hotelUnit,
      handoverTo: handoverTo,
      claimedBy: claimedBy ?? this.claimedBy,
      claimDate: claimDate ?? this.claimDate,
      photoPath: photoPath,
    );
  }
}

class Project {
  final String id;
  final String name;
  final String area;
  final String category; // 'Perbaikan', 'Pengecatan', 'Renovasi', etc.
  final String status; // 'Akan Dikerjakan', 'Sedang Berlangsung', 'Selesai'
  final String priority; // 'Tinggi', 'Sedang', 'Rendah'
  final String pic;
  final String startDate;
  final String endDate;
  final int progress; // 0 to 100
  final double cost;
  final String description;
  final String hotelUnit;

  Project({
    required this.id,
    required this.name,
    required this.area,
    required this.category,
    required this.status,
    required this.priority,
    required this.pic,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.cost,
    required this.description,
    required this.hotelUnit,
  });

  Project copyWith({
    String? name,
    String? area,
    String? category,
    String? status,
    String? priority,
    String? pic,
    String? startDate,
    String? endDate,
    int? progress,
    double? cost,
    String? description,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      area: area ?? this.area,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      pic: pic ?? this.pic,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      cost: cost ?? this.cost,
      description: description ?? this.description,
      hotelUnit: hotelUnit,
    );
  }
}
