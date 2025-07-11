import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';

class Session {
  final String id;
  final String description;
  final int stressLevel;
  final DateTime date;

  Session({
    required this.id,
    required this.description,
    required this.stressLevel,
    required this.date,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        description: json['description'] as String,
        stressLevel: json['stress_level'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}

class SessionsService {
  static const _baseUrl = 'http://10.0.2.2:8080';

  static Future<List<Session>> fetchSessions() async {
    final token = await AuthService().savedToken;
    if (token == null) throw Exception('The token was not found');

    final resp = await http.get(
      Uri.parse('$_baseUrl/sessions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body) as List;
      return data.map((e) => Session.fromJson(e)).toList();
    }
    throw Exception('Download error: ${resp.statusCode}');
  }
}

// UI LAYER

class SessionsListScreen extends StatefulWidget {
  const SessionsListScreen({super.key});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  late Future<List<Session>> _sessionsFut;

  @override
  void initState() {
    super.initState();
    _sessionsFut = SessionsService.fetchSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9EEEC),
      body: Stack(
        children: [
          // листва сверху‑справа
          Positioned(
            top: -30,
            right: -10,
            child: Image.asset('assets/images/leaf_top.png', width: 180),
          ),
          // листва снизу‑слева
          Positioned(
            bottom: -20,
            left: -20,
            child: Image.asset('assets/images/leaf_bottom.png', width: 200),
          ),
          // контент
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'List of sessions',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<Session>>(
                      future: _sessionsFut,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              snapshot.error.toString(),
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final sessions = snapshot.data ?? [];
                        if (sessions.isEmpty) {
                          return const Center(
                            child: Text('There are no records, add the first session!'),
                          );
                        }
                        return ListView.builder(
                          itemCount: sessions.length,
                          itemBuilder: (context, i) {
                            final s = sessions[i];
                            return _SessionCard(session: s);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E5E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // уровень стресса как бейдж
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7FC6A6),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              session.stressLevel.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // описание + дата
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(session.date),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
