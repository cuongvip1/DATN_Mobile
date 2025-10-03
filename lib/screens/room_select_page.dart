import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RoomSelectPage extends StatefulWidget {
  const RoomSelectPage({super.key});

  @override
  State<RoomSelectPage> createState() => _RoomSelectPageState();
}

class _RoomSelectPageState extends State<RoomSelectPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final rooms = await ApiService.instance.getRoomsForOwner();
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn phòng')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? const Center(child: Text('Chưa có phòng'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rooms.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final r = _rooms[i];
                    final tenant = r['tenant'] ?? 'Trống';
                    return ListTile(
                      title: Text(r['name'] ?? r['id'] ?? 'Phòng'),
                      subtitle: Text('Tenant: ${tenant ?? 'Trống'}'),
                      onTap: () => Navigator.pop(context, r),
                    );
                  },
                ),
    );
  }
}