import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/booking_model.dart';

class BookingDetailScreen extends StatelessWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    // Mock booking data - will be replaced with actual BLoC
    final booking = BookingModel.empty();
    final steps = BookingStatus.values;
    final currentStep = _getStepIndex(booking.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => context.push('/chat/$bookingId'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status stepper
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHorizontalStepper(context, currentStep, steps),
                  const SizedBox(height: 16),
                  _buildStatusText(booking.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Booking info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Hauler Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Hauler', 'Ahmed Transport'),
                  _buildInfoRow('Truck', 'AB-123-CD'),
                  _buildInfoRow('Capacity', '15 tons'),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Route', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Pickup', 'Downtown Project, Main St'),
                  _buildInfoRow('Delivery', 'RecycleMax Facility, Industrial Ave'),
                  _buildInfoRow('Distance', '12.5 km'),
                  _buildInfoRow('Est. Duration', '45 mins'),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Pricing', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Base Price', '\$150.00'),
                  _buildInfoRow('Distance Fee', '\$25.00'),
                  _buildInfoRow('Total', '\$175.00', isTotal: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Action buttons based on status
          _buildActionButtons(context, booking.status),
        ],
      ),
    );
  }

  Widget _buildHorizontalStepper(BuildContext context, int currentStep, List<BookingStatus> steps) {
    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        
        return Expanded(
          child: Row(
            children: [
              _buildStepCircle(index, isCompleted, isCurrent, context),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepCircle(int index, bool isCompleted, bool isCurrent, BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? Theme.of(context).colorScheme.primary
            : isCurrent
                ? Theme.of(context).colorScheme.secondary
                : Colors.grey.shade300,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, size: 20, color: Colors.white)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color: isCurrent ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildStatusText(BookingStatus status) {
    String statusText;
    switch (status) {
      case BookingStatus.assigned:
        statusText = 'Hauler Assigned';
      case BookingStatus.enRoutePickup:
        statusText = 'En Route to Pickup';
      case BookingStatus.atPickupSite:
        statusText = 'At Pickup Location';
      case BookingStatus.pickedUp:
        statusText = 'Picked Up';
      case BookingStatus.enRouteDelivery:
        statusText = 'En Route to Delivery';
      case BookingStatus.atDeliverySite:
        statusText = 'At Delivery Location';
      case BookingStatus.delivered:
        statusText = 'Delivered';
      case BookingStatus.completed:
        statusText = 'Completed';
      case BookingStatus.cancelled:
        statusText = 'Cancelled';
    }
    
    return Text(statusText, style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          Text(
            value,
            style: isTotal
                ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingStatus status) {
    // Show different buttons based on user role and booking status
    return Column(
      children: [
        if (status == BookingStatus.assigned)
          ElevatedButton.icon(
            onPressed: () {
              // Update status to en route
            },
            icon: const Icon(Icons.directions),
            label: const Text('Start Trip'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        if (status == BookingStatus.enRoutePickup)
          ElevatedButton.icon(
            onPressed: () {
              // Update status to at pickup
            },
            icon: const Icon(Icons.location_on),
            label: const Text('Arrived at Pickup'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        if (status == BookingStatus.atPickupSite)
          ElevatedButton.icon(
            onPressed: () {
              // Update status to picked up
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirm Pickup'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
      ],
    );
  }

  int _getStepIndex(BookingStatus status) {
    return status.index;
  }
}
