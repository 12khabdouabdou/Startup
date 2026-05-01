import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waste_logistics/models/order.dart';
import 'package:waste_logistics/models/user.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Order> createOrder(Order order) async {
    final response = await _supabase.from('orders').insert(order.toJson()).select();
    return Order.fromJson(response.first);
  }

  Future<Order?> getOrder(String orderId) async {
    final response = await _supabase
        .from('orders')
        .select()
        .eq('id', orderId)
        .maybeSingle();

    if (response != null) {
      return Order.fromJson(response);
    }
    return null;
  }

  Future<List<Order>> getCustomerOrders(String customerId) async {
    final response = await _supabase
        .from('orders')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return response.map((data) => Order.fromJson(data)).toList();
  }

  Future<List<Order>> getDriverOrders(String driverId) async {
    final response = await _supabase
        .from('orders')
        .select()
        .eq('assigned_driver_id', driverId)
        .in_('status', ['confirmed', 'inProgress'])
        .order('scheduled_date');

    return response.map((data) => Order.fromJson(data)).toList();
  }

  Future<List<Order>> getRecyclerOrders(String recyclerId) async {
    final response = await _supabase
        .from('orders')
        .select()
        .eq('assigned_recycler_id', recyclerId)
        .order('scheduled_date', ascending: false);

    return response.map((data) => Order.fromJson(data)).toList();
  }

  Future<List<Order>> getAvailableOrders() async {
    final response = await _supabase
        .from('orders')
        .select()
        .in_('status', ['pending', 'confirmed'])
        .is_('assigned_driver_id', null)
        .order('scheduled_date');

    return response.map((data) => Order.fromJson(data)).toList();
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    await _supabase.from('orders').update({
      'status': status.name,
      if (status == OrderStatus.completed) 'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  Future<void> assignDriver(
    String orderId,
    String driverId,
    String driverName,
  ) async {
    await _supabase.from('orders').update({
      'assigned_driver_id': driverId,
      'assigned_driver_name': driverName,
      'status': OrderStatus.confirmed.name,
    }).eq('id', orderId);
  }

  Future<void> assignRecycler(
    String orderId,
    String recyclerId,
    String recyclerName,
  ) async {
    await _supabase.from('orders').update({
      'assigned_recycler_id': recyclerId,
      'assigned_recycler_name': recyclerName,
    }).eq('id', orderId);
  }

  Future<void> updateOrderWeight(
    String orderId,
    double actualWeight,
    double finalPrice,
  ) async {
    await _supabase.from('orders').update({
      'actual_weight': actualWeight,
      'final_price': finalPrice,
    }).eq('id', orderId);
  }

  Stream<List<Order>> watchCustomerOrders(String customerId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .map((data) => data.map((order) => Order.fromJson(order)).toList());
  }

  Stream<Order?> watchOrder(String orderId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((data) => data.isNotEmpty ? Order.fromJson(data.first) : null);
  }

  Future<void> cancelOrder(String orderId) async {
    await _supabase.from('orders').update({
      'status': OrderStatus.cancelled.name,
    }).eq('id', orderId);
  }

  Future<double> calculateEstimatedPrice(
    WasteType wasteType,
    double estimatedWeight,
  ) async {
    final pricePerTon = await _getPricePerTon(wasteType);
    return (estimatedWeight / 1000) * pricePerTon;
  }

  Future<double> _getPricePerTon(WasteType wasteType) async {
    final response = await _supabase
        .from('pricing')
        .select()
        .eq('waste_type', wasteType.name)
        .maybeSingle();

    if (response != null) {
      return (response['price_per_ton'] as num).toDouble();
    }

    final defaultPrices = {
      WasteType.concrete: 50.0,
      WasteType.metal: 120.0,
      WasteType.wood: 30.0,
      WasteType.plastic: 80.0,
      WasteType.glass: 60.0,
      WasteType.drywall: 40.0,
      WasteType.asphalt: 55.0,
      WasteType.mixed: 70.0,
      WasteType.other: 45.0,
    };

    return defaultPrices[wasteType] ?? 50.0;
  }
}
