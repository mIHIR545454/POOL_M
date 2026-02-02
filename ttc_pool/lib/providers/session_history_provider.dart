import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/table_model.dart';
import '../services/api_service.dart';

class SessionHistoryState {
  final List<SessionModel> sessions;
  final bool isLoading;
  final String? error;

  SessionHistoryState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  SessionHistoryState copyWith({
    List<SessionModel>? sessions,
    bool? isLoading,
    String? error,
  }) {
    return SessionHistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SessionHistoryNotifier extends StateNotifier<SessionHistoryState> {
  SessionHistoryNotifier() : super(SessionHistoryState());

  Future<void> fetchHistory(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/tables/history/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final sessions = data.map((s) => SessionModel.fromJson(s)).toList();
        state = state.copyWith(sessions: sessions, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to fetch history');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final sessionHistoryProvider = StateNotifierProvider<SessionHistoryNotifier, SessionHistoryState>((ref) {
  return SessionHistoryNotifier();
});
