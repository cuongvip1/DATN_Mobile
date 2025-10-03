class Billing {
  final int room;
  final int electricity;
  final int water;
  int get total => room + electricity + water;

  Billing({
    required this.room,
    required this.electricity,
    required this.water,
  });

  factory Billing.fromJson(Map<String, dynamic> json) => Billing(
        room: json['room'] ?? 0,
        electricity: json['electricity'] ?? 0,
        water: json['water'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'room': room,
        'electricity': electricity,
        'water': water,
        'total': total,
      };
}