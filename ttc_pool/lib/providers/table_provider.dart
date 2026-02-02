import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import '../models/table_model.dart';
import '../services/api_service.dart';

class TableState {
  final List<TableModel> tables;
  final bool isLoading;
  final String? error;

  TableState({this.tables = const [], this.isLoading = false, this.error});

  TableState copyWith({
    List<TableModel>? tables,
    bool? isLoading,
    String? error,
  }) {
    return TableState(
      tables: tables ?? this.tables,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TableNotifier extends StateNotifier<TableState> {
  IO.Socket? _socket;

  TableNotifier() : super(TableState()) {
    _initSocket();
    fetchInitialTables();
  }

  void _initSocket() {
    _socket = IO.io(
      'http://localhost:5001',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Connected to Socket');
    });

    _socket!.on('tableUpdate', (data) {
      if (data is List) {
        final tables = data.map((t) => TableModel.fromJson(t)).toList();
        state = state.copyWith(tables: tables, isLoading: false);
      }
    });

    _socket!.onDisconnect((_) => print('Disconnected from Socket'));
  }

  Future<void> fetchInitialTables() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse(ApiService.baseUrl + '/tables'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final tables = data.map((t) => TableModel.fromJson(t)).toList();
        state = state.copyWith(tables: tables, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch tables',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> startTable({
    required String tableId,
    required String type,
    required String pricingMode,
    required int players,
    required String userId,
    int timeLimitInMinutes = 0,
    double? fixedPrice,
  }) async {
    try {
      final token = await ApiService.getToken();
      final body = {
        'type': type,
        'pricingMode': pricingMode,
        'players': players,
        'timeLimitInMinutes': timeLimitInMinutes,
        'userId': userId,
      };
      if (fixedPrice != null) body['fixedPrice'] = fixedPrice;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/tables/$tableId/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        state = state.copyWith(error: 'Failed to start table');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> pauseTable(String tableId, String reason, String userId) async {
    try {
      final token = await ApiService.getToken();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/tables/$tableId/pause'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason, 'userId': userId}),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resumeTable(String tableId, String userId) async {
    try {
      final token = await ApiService.getToken();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/tables/$tableId/resume'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> endTable(String tableId, String userId) async {
    try {
      final token = await ApiService.getToken();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/tables/$tableId/end'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> clearTable(
    String tableId,
    String userId,
    String paymentMethod, {
    bool autoDelete = false,
  }) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/tables/$tableId/clear'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'paymentMethod': paymentMethod,
          'autoDelete': autoDelete,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}

final tableProvider = StateNotifierProvider<TableNotifier, TableState>((ref) {
  return TableNotifier();
});
