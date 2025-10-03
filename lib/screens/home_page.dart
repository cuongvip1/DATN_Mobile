import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'room_detail_page.dart';
import 'room_select_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool? _isOwner;
  bool _loading = true;
  List<Map<String, dynamic>> _rooms = [];

  final _prevElec = TextEditingController();
  final _currElec = TextEditingController();
  final _prevWater = TextEditingController();
  final _currWater = TextEditingController();
  final _roomRentCtrl = TextEditingController(text: '0');
  final _rateElecCtrl = TextEditingController(text: '3500');
  final _rateWaterCtrl = TextEditingController(text: '15000');

  int _elecUsage = 0;
  int _waterUsage = 0;
  int _roomAmount = 0;
  int _elecAmount = 0;
  int _waterAmount = 0;
  int _totalAmount = 0;
  bool _saving = false;

  String? _tenantRoomId;
  String? _tenantRoomName;

  @override
  void initState() {
    super.initState();
    _initRole();
  }

  Future<void> _initRole() async {
    final role = await ApiService.instance.getCurrentUserRole();
    if (role == 'owner') {
      _rooms = await ApiService.instance.getRoomsForOwner();
      setState(() {
        _isOwner = true;
        _loading = false;
      });
    } else {
      final room = await ApiService.instance.getRoomForCurrentTenant();
      if (room != null) {
        _tenantRoomId = room['id']?.toString();
        _tenantRoomName = room['name']?.toString();
        _prevElec.text = (room['prev_elec'] ?? 0).toString();
        _prevWater.text = (room['prev_water'] ?? 0).toString();
        _roomRentCtrl.text = (room['fixed_rent'] ?? 0).toString();
      }
      setState(() {
        _isOwner = false;
        _loading = false;
      });
    }
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

  Future<void> _openRoomSelector() async {
    final selected = await Navigator.push<Map<String, dynamic>?>(context, MaterialPageRoute(builder: (_) => const RoomSelectPage()));
    if (selected != null) {
      setState(() {
        _tenantRoomId = selected['id']?.toString();
        _tenantRoomName = selected['name']?.toString();
        _prevElec.text = (selected['prev_elec'] ?? 0).toString();
        _prevWater.text = (selected['prev_water'] ?? 0).toString();
        _roomRentCtrl.text = (selected['fixed_rent'] ?? 0).toString();
        _elecUsage = 0;
        _waterUsage = 0;
        _elecAmount = 0;
        _waterAmount = 0;
        _totalAmount = 0;
      });
    }
  }

  void _saveReadings() async {
    final prevE = int.tryParse(_prevElec.text) ?? 0;
    final currE = int.tryParse(_currElec.text) ?? 0;
    final prevW = int.tryParse(_prevWater.text) ?? 0;
    final currW = int.tryParse(_currWater.text) ?? 0;
    setState(() {
      _elecUsage = (currE - prevE).clamp(0, 999999);
      _waterUsage = (currW - prevW).clamp(0, 999999);
    });
    if (_tenantRoomId != null) {
      await ApiService.instance.submitCurrentReadings(_tenantRoomId!, currE, currW);
      _prevElec.text = currE.toString();
      _prevWater.text = currW.toString();
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chỉ số đã lưu')));
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

  Future<void> _payTenantBill() async {
    if (_tenantRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn chưa chọn phòng')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.instance.payBill(_tenantRoomId!, _totalAmount);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanh toán thành công (mock)')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi thanh toán: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _ownerView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý phòng (Chủ trọ)')),
      body: _rooms.isEmpty
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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RoomDetailPage(room: r)));
                  },
                );
              },
            ),
    );
  }

  Widget _tenantChooseRoomView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý phòng')),
      body: Center(
        child: ElevatedButton(
          onPressed: _openRoomSelector,
          child: const Text('Chọn phòng để quản lý / nhập chỉ số'),
        ),
      ),
    );
  }

  Widget _tenantTabsView() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tenantRoomName == null ? 'Quản lý phòng' : 'Phòng: ${_tenantRoomName!}'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Nhập chỉ số'),
            Tab(text: 'Tiền phòng'),
            Tab(text: 'Tiền điện/nước'),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.switch_right),
              tooltip: 'Chọn phòng khác',
              onPressed: _openRoomSelector,
            )
          ],
        ),
        body: TabBarView(children: [
          _buildReadingsTab(),
          _buildRoomTab(),
          _buildBillingTabTenant(),
        ]),
      ),
    );
  }

  Widget _buildReadingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Nhập chỉ số', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _tenantRoomId == null ? null : _saveReadings, child: const Text('Lưu chỉ số')),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              setState(() => _saving = true);
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) setState(() => _saving = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gọi API lấy hoá đơn (mock)')));
            },
            child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Lấy hoá đơn từ server'),
          ),
          const SizedBox(height: 20),
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
          const Text('Tiền phòng', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _roomRentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tiền phòng (VND)'), readOnly: true),
          const SizedBox(height: 16),
          const SizedBox(height: 20),
          _amountRow('Tiền phòng', int.tryParse(_roomRentCtrl.text) ?? 0),
        ],
      ),
    );
  }

  Widget _buildBillingTabTenant() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Tiền điện + nước', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _rateElecCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Đơn giá điện (VND/kWh)'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _rateWaterCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Đơn giá nước (VND/m³)'))),
          ]),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculateLocal, child: const Text('Tính tiền (local)')),
          const SizedBox(height: 16),
          _amountRow('Tiền điện', _elecAmount),
          _amountRow('Tiền nước', _waterAmount),
          const Divider(),
          _amountRow('Tổng', _totalAmount, bold: true),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _payTenantBill, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Thanh toán'))),
        ],
      ),
    );
  }

  Widget _amountRow(String label, int value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    final display = value == 0 ? '-' : '${value.toString()} VND';
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(display, style: style)]));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_isOwner == true) return _ownerView();
    if (_tenantRoomId == null) return _tenantChooseRoomView();
    return _tenantTabsView();
  }
}