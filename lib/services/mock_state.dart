import 'package:flutter/material.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

class MockState extends ChangeNotifier {
  // Singleton Pattern
  static final MockState _instance = MockState._internal();
  factory MockState() => _instance;
  MockState._internal() {
    _initData();
  }

  // Active session
  User? currentUser;

  // Mock Database lists
  List<User> users = [];
  List<Room> rooms = [];
  List<LostFoundItem> lostFoundItems = [];
  List<Project> projects = [];

  void _initData() {
    // 1. Setup Users
    users = [
      User(
        id: '1',
        name: 'Andi Manager',
        email: 'manager@rehat.co.id',
        role: UserRole.manager,
        department: 'Administration',
        hotelUnit: 'Kurnia',
      ),
      User(
        id: '2',
        name: 'Budi Leader',
        email: 'leader@rehat.co.id',
        role: UserRole.leader,
        department: 'Housekeeping',
        hotelUnit: 'Kurnia',
      ),
      User(
        id: '3',
        name: 'Cici Staff',
        email: 'staff@rehat.co.id',
        role: UserRole.staff,
        department: 'Housekeeping',
        hotelUnit: 'Kurnia',
      ),
      User(
        id: '4',
        name: 'Dedi Staff',
        email: 'dedi@rehat.co.id',
        role: UserRole.staff,
        department: 'Housekeeping',
        hotelUnit: 'Graha Sartika',
      ),
    ];

    // Helper for checklists
    List<ChecklistItem> defaultChecklist() => [
      ChecklistItem(id: '1', name: 'Bed / Ranjang', isChecked: false),
      ChecklistItem(id: '2', name: 'Bathroom / Kamar Mandi', isChecked: false),
      ChecklistItem(id: '3', name: 'Amenities / Perlengkapan', isChecked: false),
      ChecklistItem(id: '4', name: 'Floor / Lantai', isChecked: false),
      ChecklistItem(id: '5', name: 'Mini Bar', isChecked: false),
      ChecklistItem(id: '6', name: 'Towel / Handuk', isChecked: false),
    ];

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 2. Setup Rooms
    rooms = [
      Room(
        roomNumber: '101',
        type: 'Standard',
        workType: 'Make Up Room',
        status: 'Vacant Dirty',
        defectNote: '',
        staffName: 'Cici Staff',
        startTime: '08:00',
        endTime: '08:30',
        verifiedStatus: 'Pending',
        hotelUnit: 'Kurnia',
        date: today,
        checklist: defaultChecklist(),
      ),
      Room(
        roomNumber: '102',
        type: 'Superior',
        workType: 'General Cleaning',
        status: 'Vacant Clean',
        defectNote: 'Keran air shower bocor sedikit',
        staffName: 'Cici Staff',
        startTime: '09:00',
        endTime: '09:45',
        verifiedStatus: 'Verified',
        verifierName: 'Budi Leader',
        hotelUnit: 'Kurnia',
        date: today,
        checklist: defaultChecklist().map((e) => e.copyWith(isChecked: true)).toList(),
      ),
      Room(
        roomNumber: '103',
        type: 'Deluxe',
        workType: 'Make Up Room',
        status: 'Occupied',
        defectNote: '',
        staffName: 'Cici Staff',
        startTime: '10:00',
        endTime: '10:20',
        verifiedStatus: 'Not Verified',
        verifierName: 'Budi Leader',
        hotelUnit: 'Kurnia',
        date: today,
        checklist: defaultChecklist().map((e) => e.copyWith(isChecked: true)).toList(),
      ),
      Room(
        roomNumber: '104',
        type: 'Suite',
        workType: 'General Cleaning',
        status: 'Occupied',
        defectNote: 'AC kurang dingin di ruang tamu',
        staffName: 'Cici Staff',
        startTime: '11:00',
        endTime: '12:00',
        verifiedStatus: 'Pending',
        hotelUnit: 'Kurnia',
        date: today,
        checklist: defaultChecklist(),
      ),
      Room(
        roomNumber: '105',
        type: 'Standard',
        workType: 'Make Up Room',
        status: 'Check Out',
        defectNote: '',
        staffName: 'Cici Staff',
        startTime: '',
        endTime: '',
        verifiedStatus: 'Pending',
        hotelUnit: 'Kurnia',
        date: today,
        checklist: defaultChecklist(),
      ),
      Room(
        roomNumber: '201',
        type: 'Deluxe',
        workType: 'General Cleaning',
        status: 'Out of Order',
        defectNote: 'Dinding rembes dari kamar mandi sebelah',
        staffName: 'Dedi Staff',
        startTime: '08:30',
        endTime: '09:30',
        verifiedStatus: 'Verified',
        verifierName: 'Budi Leader',
        hotelUnit: 'Graha Sartika',
        date: today,
        checklist: defaultChecklist().map((e) => e.copyWith(isChecked: true)).toList(),
      ),
    ];

    // 3. Setup Lost and Found Items
    lostFoundItems = [
      LostFoundItem(
        id: 'LF001',
        date: today,
        refNumber: 'REF-2026-0001',
        roomNumber: '102',
        itemCategory: 'Elektronik',
        itemName: 'Charger iPhone 15 White',
        location: 'Di bawah tempat tidur',
        description: 'Kabel charger USB-C merk Apple warna putih, kondisi mulus.',
        condition: 'Baik',
        value: 'Sedang (Rp 100rb – 1jt)',
        status: 'Disimpan',
        reportedBy: 'Cici Staff',
        hotelUnit: 'Kurnia',
        handoverTo: 'Disimpan di Housekeeping',
      ),
      LostFoundItem(
        id: 'LF002',
        date: today,
        refNumber: 'REF-2026-0002',
        roomNumber: '103',
        itemCategory: 'Uang / Dompet',
        itemName: 'Dompet Kulit Coklat',
        location: 'Di dalam laci meja nakas',
        description: 'Dompet kulit lipat merk Bifold warna coklat gelap. Berisi KTP an. Budi Santoso dan uang tunai Rp 150.000.',
        condition: 'Baik',
        value: 'Sedang (Rp 100rb – 1jt)',
        status: 'Diklaim',
        reportedBy: 'Cici Staff',
        hotelUnit: 'Kurnia',
        handoverTo: 'Diserahkan ke Front Office',
        claimedBy: 'Budi Santoso',
        claimDate: today,
      ),
    ];

    // 4. Setup Projects
    projects = [
      Project(
        id: 'PRJ001',
        name: 'Pengecatan Koridor Lt. 1',
        area: 'Koridor Depan Kamar 101-112',
        category: 'Pengecatan',
        status: 'Sedang Berlangsung',
        priority: 'Sedang',
        pic: 'Udin (Maint)',
        startDate: today,
        endDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
        progress: 45,
        cost: 2500000,
        description: 'Pengecatan ulang dinding koridor lantai 1 yang sudah mulai kusam dan kotor terkena noda roda troli.',
        hotelUnit: 'Kurnia',
      ),
      Project(
        id: 'PRJ002',
        name: 'Perbaikan Pipa Bocor Lobby',
        area: 'Toilet Belakang Resepsionis',
        category: 'Perbaikan',
        status: 'Akan Dikerjakan',
        priority: 'Tinggi',
        pic: 'Tono (Maint)',
        startDate: today,
        endDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 2))),
        progress: 0,
        cost: 750000,
        description: 'Rembeas air terdeteksi di dinding partisi dekat toilet lobby, perlu perbaikan pipa PVC 3/4 inch.',
        hotelUnit: 'Kurnia',
      ),
    ];
  }

  // --- ACTIONS ---

  // Auth Action
  bool login(String email, String password) {
    // Check local database
    final found = users.where((u) => u.email.toLowerCase().trim() == email.toLowerCase().trim()).toList();
    if (found.isNotEmpty) {
      currentUser = found.first;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool signup(String name, String email, String password, String department, String roleStr, String hotelUnit) {
    // Check if email already registered
    if (users.any((u) => u.email.toLowerCase().trim() == email.toLowerCase().trim())) {
      return false;
    }
    
    UserRole roleVal = UserRole.staff;
    if (roleStr == 'Leader') roleVal = UserRole.leader;
    if (roleStr == 'Manager') roleVal = UserRole.manager;

    final newUser = User(
      id: (users.length + 1).toString(),
      name: name,
      email: email,
      role: roleVal,
      department: department,
      hotelUnit: hotelUnit,
    );
    users.add(newUser);
    currentUser = newUser;
    notifyListeners();
    return true;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // Update checklist items for a room
  void toggleChecklistItem(String roomNumber, String itemId) {
    final roomIdx = rooms.indexWhere((r) => r.roomNumber == roomNumber);
    if (roomIdx != -1) {
      final updatedChecklist = rooms[roomIdx].checklist.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isChecked: !item.isChecked);
        }
        return item;
      }).toList();
      rooms[roomIdx] = rooms[roomIdx].copyWith(checklist: updatedChecklist);
      notifyListeners();
    }
  }

  // Submit checklist and change status to Pending Validation
  void submitRoomChecklist(String roomNumber, String defectNote, String startTime, String endTime, {String? photoPath}) {
    final roomIdx = rooms.indexWhere((r) => r.roomNumber == roomNumber);
    if (roomIdx != -1) {
      rooms[roomIdx] = rooms[roomIdx].copyWith(
        status: 'Vacant Clean',
        defectNote: defectNote,
        startTime: startTime,
        endTime: endTime,
        verifiedStatus: 'Pending',
        photoPath: photoPath ?? 'assets/images/room_checked.jpg', // dummy path
      );
      notifyListeners();
    }
  }

  // Add room log manually (from Staff)
  void addRoomLog(String roomNumber, String type, String workType, String roomStatus, String start, String end, String defect) {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Check if room number already exists for today, update it
    final existingIdx = rooms.indexWhere((r) => r.roomNumber == roomNumber && r.hotelUnit == (currentUser?.hotelUnit ?? 'Kurnia'));
    
    List<ChecklistItem> defaultChecklist() => [
      ChecklistItem(id: '1', name: 'Bed / Ranjang', isChecked: true),
      ChecklistItem(id: '2', name: 'Bathroom / Kamar Mandi', isChecked: true),
      ChecklistItem(id: '3', name: 'Amenities / Perlengkapan', isChecked: true),
      ChecklistItem(id: '4', name: 'Floor / Lantai', isChecked: true),
      ChecklistItem(id: '5', name: 'Mini Bar', isChecked: true),
      ChecklistItem(id: '6', name: 'Towel / Handuk', isChecked: true),
    ];

    if (existingIdx != -1) {
      rooms[existingIdx] = rooms[existingIdx].copyWith(
        status: roomStatus,
        defectNote: defect,
        startTime: start,
        endTime: end,
        verifiedStatus: 'Pending',
      );
    } else {
      rooms.insert(0, Room(
        roomNumber: roomNumber,
        type: type,
        workType: workType,
        status: roomStatus,
        defectNote: defect,
        staffName: currentUser?.name ?? 'Unknown Staff',
        startTime: start,
        endTime: end,
        verifiedStatus: 'Pending',
        hotelUnit: currentUser?.hotelUnit ?? 'Kurnia',
        date: today,
        checklist: defaultChecklist(),
      ));
    }
    notifyListeners();
  }

  // Leader: Validate Room Work
  void validateRoom(String roomNumber, String status) {
    final idx = rooms.indexWhere((r) => r.roomNumber == roomNumber);
    if (idx != -1) {
      rooms[idx] = rooms[idx].copyWith(
        verifiedStatus: status,
        verifierName: currentUser?.name ?? 'Leader',
      );
      notifyListeners();
    }
  }

  // Lost & Found: Add new item report
  void addLostFound(String roomNumber, String category, String name, String location, String description, String condition, String value, String handover) {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final int nextNum = lostFoundItems.length + 1;
    final String refNum = 'REF-2026-${nextNum.toString().padLeft(4, '0')}';
    
    lostFoundItems.insert(0, LostFoundItem(
      id: 'LF${nextNum.toString().padLeft(3, '0')}',
      date: today,
      refNumber: refNum,
      roomNumber: roomNumber,
      itemCategory: category,
      itemName: name,
      location: location,
      description: description,
      condition: condition,
      value: value,
      status: 'Disimpan',
      reportedBy: currentUser?.name ?? 'Staff',
      hotelUnit: currentUser?.hotelUnit ?? 'Kurnia',
      handoverTo: handover,
      photoPath: 'assets/images/lost_item_dummy.jpg',
    ));
    notifyListeners();
  }

  // Update LF Item Status (Claimed or handed over to FO)
  void updateLFStatus(String lfId, String status, {String? claimedBy, String? claimDate}) {
    final idx = lostFoundItems.indexWhere((item) => item.id == lfId);
    if (idx != -1) {
      lostFoundItems[idx] = lostFoundItems[idx].copyWith(
        status: status,
        claimedBy: claimedBy,
        claimDate: claimDate,
      );
      notifyListeners();
    }
  }

  // Project: Add Project
  void addProject(String name, String area, String category, String status, String priority, String pic, String start, String end, int progress, double cost, String desc) {
    final int nextNum = projects.length + 1;
    projects.insert(0, Project(
      id: 'PRJ${nextNum.toString().padLeft(3, '0')}',
      name: name,
      area: area,
      category: category,
      status: status,
      priority: priority,
      pic: pic,
      startDate: start,
      endDate: end,
      progress: progress,
      cost: cost,
      description: desc,
      hotelUnit: currentUser?.hotelUnit ?? 'Kurnia',
    ));
    notifyListeners();
  }

  // Project: Update/Edit Project
  void updateProject(String id, {
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
    final idx = projects.indexWhere((p) => p.id == id);
    if (idx != -1) {
      projects[idx] = projects[idx].copyWith(
        name: name,
        area: area,
        category: category,
        status: status,
        priority: priority,
        pic: pic,
        startDate: startDate,
        endDate: endDate,
        progress: progress,
        cost: cost,
        description: description,
      );
      notifyListeners();
    }
  }
}
