import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/table_model.dart';

class AdminStats {
  final Map<String, dynamic> revenue;
  final List<dynamic> tableUtilization;
  final List<dynamic> staffPerformance;
  final List<dynamic> peakHours;
  final int activeTablesCount;

  AdminStats({
    required this.revenue,
    required this.tableUtilization,
    required this.staffPerformance,
    required this.peakHours,
    required this.activeTablesCount,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      revenue: json['revenue'],
      tableUtilization: json['tableUtilization'],
      staffPerformance: json['staffPerformance'],
      peakHours: json['peakHours'],
      activeTablesCount: json['activeTablesCount'],
    );
  }
}

class AdminState {
  final AdminStats? stats;
  final List<TableModel> allTables;
  final List<dynamic> staffList;
  final Map<String, dynamic>? settings;
  final bool isLoading;
  final String? error;

  AdminState({
    this.stats,
    this.allTables = const [],
    this.staffList = const [],
    this.settings,
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    AdminStats? stats,
    List<TableModel>? allTables,
    List<dynamic>? staffList,
    Map<String, dynamic>? settings,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      stats: stats ?? this.stats,
      allTables: allTables ?? this.allTables,
      staffList: staffList ?? this.staffList,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState(isLoading: true)) {
    fetchStats();
    fetchAllTables();
    fetchSettings();
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/staff'),
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          staffList: jsonDecode(response.body),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch staff (${response.statusCode})',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error fetching staff: $e',
      );
    }
  }

  Future<bool> addStaff(Map<String, dynamic> data) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        fetchStaff();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateStaff(String id, Map<String, dynamic> data) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/admin/staff/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        fetchStaff();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> fetchSettings() async {
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/settings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(settings: jsonDecode(response.body));
      }
    } catch (e) {
      print('Error fetching settings: $e');
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(settings: jsonDecode(response.body));
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> fetchStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          stats: AdminStats.fromJson(jsonDecode(response.body)),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch analytics',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchAllTables() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/tables'),
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final tables = data.map((t) => TableModel.fromJson(t)).toList();
        state = state.copyWith(allTables: tables, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch tables (${response.statusCode})',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error fetching tables: $e',
      );
    }
  }

  Future<bool> addTable(Map<String, dynamic> data) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/tables'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        fetchAllTables();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateTable(String id, Map<String, dynamic> data) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/admin/tables/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        fetchAllTables();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});
