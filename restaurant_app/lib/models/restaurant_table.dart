class RestaurantTable {
final String id;
final int number;
final String status; // free|occupied|reserved
final String? currentOrderId;
final int? seats;


RestaurantTable({required this.id, required this.number, required this.status, this.currentOrderId, this.seats});


factory RestaurantTable.fromMap(String id, Map<String, dynamic> data) => RestaurantTable(
id: id,
number: data['number'] ?? 0,
status: data['status'] ?? 'free',
currentOrderId: data['currentOrderId'],
seats: data['seats'] ?? 0
);


Map<String, dynamic> toMap() => {
'number': number,
'status': status,
'currentOrderId': currentOrderId,
'seats': seats,
};
}