class RestaurantTable {
final String id;
final int number;
final String status; // free|occupied|reserved
final String? currentOrderId;


RestaurantTable({required this.id, required this.number, required this.status, this.currentOrderId});


factory RestaurantTable.fromMap(String id, Map<String, dynamic> data) => RestaurantTable(
id: id,
number: data['number'] ?? 0,
status: data['status'] ?? 'free',
currentOrderId: data['currentOrderId'],
);


Map<String, dynamic> toMap() => {
'number': number,
'status': status,
'currentOrderId': currentOrderId,
};
}