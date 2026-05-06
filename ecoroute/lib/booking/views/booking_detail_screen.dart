import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking_model.dart';

class BookingDetailScreen extends StatelessWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Wire to BookingBloc
    final booking = BookingModel.empty();
    final currentStep = booking.status.index;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => context.push('/chat'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusStepperCard(
            currentStep: currentStep,
            status: booking.status,
          ),
          const SizedBox(height: 16),
          _BookingInfoCard(booking: booking),
          const SizedBox(height: 16),
          _ActionButtons(status: booking.status),
        ],
      ),
    );
  }
}

class _StatusStepperCard extends StatelessWidget {
  final int currentStep;
  final BookingStatus status;

  const _StatusStepperCard({
    required this.currentStep,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _HorizontalStepper(currentStep: currentStep),
            const SizedBox(height: 16),
            Text(
              _statusLabel(status),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(BookingStatus s) => switch (s) {
        BookingStatus.assigned => 'Hauler Assigned',
        BookingStatus.enRoutePickup => 'En Route to Pickup',
        BookingStatus.atPickupSite => 'At Pickup Location',
        BookingStatus.pickedUp => 'Picked Up',
        BookingStatus.enRouteDelivery => 'En Route to Delivery',
        BookingStatus.atDeliverySite => 'At Delivery Location',
        BookingStatus.delivered => 'Delivered',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
      };
}

class _HorizontalStepper extends StatelessWidget {
  final int currentStep;

  const _HorizontalStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = BookingStatus.values;
    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return Expanded(
          child: Row(
            children: [
              Container(
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
                            color: isCurrent
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
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
}

class _BookingInfoCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingInfoCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.local_shipping,
              title: 'Hauler Information',
            ),
            const SizedBox(height: 12),
            const _InfoRow(label: 'Hauler', value: '—'),
            const _InfoRow(label: 'Truck', value: '—'),
            const SizedBox(height: 16),
            const _SectionHeader(
              icon: Icons.route,
              title: 'Route',
            ),
            const SizedBox(height: 12),
            const _InfoRow(label: 'Pickup', value: '—'),
            const _InfoRow(label: 'Delivery', value: '—'),
            if (booking.routeDistanceM != null)
              _InfoRow(
                label: 'Distance',
                value: '${(booking.routeDistanceM! / 1000).toStringAsFixed(1)} km',
              ),
            if (booking.routeDurationS != null)
              _InfoRow(
                label: 'Est. Duration',
                value: '${(booking.routeDurationS! / 60).round()} mins',
              ),
            if (booking.price != null) ...[
              const SizedBox(height: 16),
              const _SectionHeader(
                icon: Icons.attach_money,
                title: 'Pricing',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Total',
                value: '\$${booking.price!.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
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
}

class _ActionButtons extends StatelessWidget {
  final BookingStatus status;

  const _ActionButtons({required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (status == BookingStatus.enRoutePickup ||
            status == BookingStatus.enRouteDelivery)
          ElevatedButton.icon(
            onPressed: () => _openNavigation(context),
            icon: const Icon(Icons.navigation),
            label: const Text('Open Navigation'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        if (status == BookingStatus.assigned)
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Update status to en_route_pickup
            },
            icon: const Icon(Icons.directions),
            label: const Text('Start Trip'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        if (status == BookingStatus.atPickupSite)
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Update status to picked_up
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

  Future<void> _openNavigation(BuildContext context) async {
    final double? lat;
    final double? lng;

    if (status == BookingStatus.enRoutePickup) {
      lat = null; // TODO: booking.pickupLat
      lng = null; // TODO: booking.pickupLng
    } else {
      lat = null; // TODO: booking.deliveryLat
      lng = null; // TODO: booking.deliveryLng
    }

    if (lat != null && lng != null) {
      final googleMapsUrl = Uri.parse(
        'google.navigation:q=$lat,$lng',
      );
      final wazeUrl = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(wazeUrl)) {
        await launchUrl(wazeUrl);
      }
    }
  }
}
