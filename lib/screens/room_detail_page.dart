import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RoomDetailPage extends StatefulWidget {
  final Map<String, dynamic> room;
  const RoomDetailPage({super.key, required this.room});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final _prevElec = TextEditingController();
  final _currElec = TextEditingController();
  final _prevWater = TextEditingController();
  final _currWater = TextEditingController();

  final _roomRentCtrl = TextEditingController();
  final _rateElecCtrl = TextEditingController(text: '3500');
  final _rateWaterCtrl = TextEditingController(text: '15000');

  int _elecUsage = 0;
  int _waterUsage = 0;
  int _roomAmount = 0;
  int _elecAmount = 0;
  int _waterAmount = 0;
  int _totalAmount = 0;
  bool _loading = true;
  bool _isOwner = false;
  String? _roomId;

  @override
  void initState() {
    super.initState();
    _roomId = widget.room['id']?.toString();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    final role = await ApiService.instance.getCurrentUserRole();
    _isOwner = role == 'owner';
    if (_roomId != null) {
      final r = await ApiService.instance.getRoomById(_roomId!);
      if (r != null) {
        _prevElec.text = (r['prev_elec'] ?? 0).toString();
        _prevWater.text = (r['prev_water'] ?? 0).toString();
        _roomRentCtrl.text = (r['fixed_rent'] ?? 0).toString();
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _prevElec.dispose();
    _currElec.dispose();
    _prevWater.dispose();
    _currWater.dispose();
    _roomRentCtrl.dispose();
    _rateElecCtrl.dispose();
    _rateWaterCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveFixedRent() async {
    final rent = int.tryParse(_roomRentCtrl.text) ?? 0;
    if (_roomId == null) return;
    await ApiService.instance.setFixedRent(_roomId!, rent);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiền phòng đã lưu')));
  }

  Future<void> _submitReadings() async {
    final currE = int.tryParse(_currElec.text) ?? 0;
    final currW = int.tryParse(_currWater.text) ?? 0;
    if (_roomId == null) return;
    await ApiService.instance.submitCurrentReadings(_roomId!, currE, currW);
    setState(() {
      _elecUsage = (currE - (int.tryParse(_prevElec.text) ?? 0)).clamp(0, 999999);
      _waterUsage = (currW - (int.tryParse(_prevWater.text) ?? 0)).clamp(0, 999999);
      _prevElec.text = currE.toString();
      _prevWater.text = currW.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chỉ số đã lưu (và cập nhật cho tháng sau)')));
  }

  void _calculateLocal() {
    final room = int.tryParse(_roomRentCtrl.text) ?? 0;
    final rateE = int.tryParse(_rateElecCtrl.text) ?? 0;
    final rateW = int.tryParse(_rateWaterCtrl.text) ?? 0;
    setState(() {
      _roomAmount = room;
      _elecAmount = _elecUsage * rateE;
      _waterAmount = _waterUsage * rateW;
      _totalAmount = _roomAmount + _elecAmount + _waterAmount;
    });
  }

  Widget _buildReadingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Chỉ số (số tháng trước được lấy tự động)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _prevElec, decoration: const InputDecoration(labelText: 'Số tháng trước (kWh)'), readOnly: true)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _currElec, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số hiện tại (kWh)'))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: _prevWater, decoration: const InputDecoration(labelText: 'Số tháng trước (m³)'), readOnly: true)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _currWater, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số hiện tại (m³)'))),
          ]),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _submitReadings, child: const Text('Lưu chỉ số hiện tại')),
          const SizedBox(height: 12),
          if (_elecUsage > 0 || _waterUsage > 0) ...[
            Text('Sử dụng điện: $_elecUsage kWh'),
            Text('Sử dụng nước: $_waterUsage m³'),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Tiền phòng (cố định)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _roomRentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tiền phòng (VND)')),
          const SizedBox(height: 12),
          if (_isOwner) ElevatedButton(onPressed: _saveFixedRent, child: const Text('Lưu tiền phòng')),
          const SizedBox(height: 20),
          _amountRow('Tiền phòng', int.tryParse(_roomRentCtrl.text) ?? 0),
        ],
      ),
    );
  }

  Widget _buildBillingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Tính tiền', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _rateElecCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Đơn giá điện (VND/kWh)'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _rateWaterCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Đơn giá nước (VND/m³)'))),
          ]),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculateLocal, child: const Text('Tính tiền')),
          const SizedBox(height: 16),
          _amountRow('Tiền phòng', _roomAmount),
          _amountRow('Tiền điện', _elecAmount),
          _amountRow('Tiền nước', _waterAmount),
          const Divider(),
          _amountRow('Tổng', _totalAmount, bold: true),
        ],
      ),
    );
  }

  Widget _amountRow(String label, int value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    final display = value == 0 ? '-' : '${value.toString()} VND';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(display, style: style)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final name = widget.room['name'] ?? widget.room['id'] ?? 'Phòng';
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chi tiết $name'),
          bottom: const TabBar(tabs: [Tab(text: 'Nhập chỉ số'), Tab(text: 'Tiền phòng'), Tab(text: 'Tính tiền')]),
        ),
        body: TabBarView(children: [_buildReadingsTab(), _buildRoomTab(), _buildBillingTab()]),
      ),
    );
  }
}