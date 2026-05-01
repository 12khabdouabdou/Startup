import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:waste_logistics/models/order.dart';
import 'package:waste_logistics/models/user.dart';
import 'package:waste_logistics/services/order_service.dart';
import 'package:waste_logistics/theme/app_theme.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

class TrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
      ),
      body: StreamBuilder<Order?>(
        stream: ref.read(orderServiceProvider).watchOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Order not found'),
            );
          }

          final order = snapshot.data!;
          final pickupLocation = LatLng(order.pickupLat, order.pickupLng);

          return Column(
            children: [
              SizedBox(
                height: 300,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: pickupLocation,
                    initialZoom: 14,
                    minZoom: 2,
                    maxZoom: 19,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.construction.waste_logistics',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pickupLocation,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Order Status',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      _getStatusText(order.status),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor:
                                        _getStatusColor(order.status).withOpacity(0.1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTimeline(order),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _DetailRow(
                                icon: Icons.recycling,
                                label: 'Waste Type',
                                value: order.wasteType.name[0].toUpperCase() +
                                    order.wasteType.name.substring(1),
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                icon: Icons.scale,
                                label: 'Estimated Weight',
                                value: '${order.estimatedWeight.toStringAsFixed(1)} kg',
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                icon: Icons.calendar_today,
                                label: 'Scheduled Date',
                                value:
                                    '${order.scheduledDate.day}/${order.scheduledDate.month}/${order.scheduledDate.year}',
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                icon: Icons.access_time,
                                label: 'Scheduled Time',
                                value:
                                    '${order.scheduledDate.hour}:${order.scheduledDate.minute.toString().padLeft(2, '0')}',
                              ),
                              if (order.actualWeight != null) ...[
                                const SizedBox(height: 8),
                                _DetailRow(
                                  icon: Icons.scale,
                                  label: 'Actual Weight',
                                  value: '${order.actualWeight!.toStringAsFixed(1)} kg',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pickup Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: AppTheme.primaryColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      order.pickupAddress,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (order.assignedDriverName != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Assigned Driver',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(order.assignedDriverName!),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Estimated Price'),
                                  Text(
                                    '\$${order.estimatedPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              if (order.finalPrice != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Final Price'),
                                    Text(
                                      '\$${order.finalPrice!.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppTheme.successColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Chip(
                                label: Text(
                                  _getPaymentStatusText(order.paymentStatus),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor:
                                    _getPaymentStatusColor(order.paymentStatus).withOpacity(0.1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeline(Order order) {
    final steps = [
      _TimelineStep(
        title: 'Order Placed',
        description: 'Your order has been received',
        isCompleted: true,
        isActive: order.status == OrderStatus.pending,
      ),
      _TimelineStep(
        title: 'Confirmed',
        description: 'Driver assigned to your order',
        isCompleted: order.status.index >= OrderStatus.confirmed.index,
        isActive: order.status == OrderStatus.confirmed,
      ),
      _TimelineStep(
        title: 'In Progress',
        description: 'Driver is on the way',
        isCompleted: order.status.index >= OrderStatus.inProgress.index,
        isActive: order.status == OrderStatus.inProgress,
      ),
      _TimelineStep(
        title: 'Completed',
        description: 'Waste collected successfully',
        isCompleted: order.status == OrderStatus.completed,
        isActive: order.status == OrderStatus.completed,
      ),
    ];

    return Column(
      children: steps.map((step) {
        return _TimelineStepWidget(step: step);
      }).toList(),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.grey;
    }
  }

  String _getPaymentStatusText(PaymentStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _TimelineStep {
  final String title;
  final String description;
  final bool isCompleted;
  final bool isActive;

  _TimelineStep({
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.isActive,
  });
}

class _TimelineStepWidget extends StatelessWidget {
  final _TimelineStep step;

  const _TimelineStepWidget({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.isCompleted
                    ? AppTheme.successColor
                    : step.isActive
                        ? AppTheme.primaryColor
                        : Colors.grey[300],
                border: Border.all(
                  color: step.isActive ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: step.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (!step.isCompleted)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: step.isCompleted || step.isActive
                        ? Colors.black
                        : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
