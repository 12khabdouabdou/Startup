import 'package:flutter/material.dart';
import '../../features/jobs/models/job_model.dart';

class JobStatusStepper extends StatelessWidget {
  final JobStatus currentStatus;
  
  const JobStatusStepper({super.key, required this.currentStatus});

  int get _currentStepIndex {
    switch (currentStatus) {
      case JobStatus.enRoute: return 0;
      case JobStatus.atPickup: return 1;
      case JobStatus.loaded: return 2;
      case JobStatus.inTransit: return 3;
      case JobStatus.atDropoff: return 4;
      case JobStatus.completed: return 5;
      default: return -1;
    }
  }

  static const List<String> _stages = [
    'En Route',
    'At Pickup',
    'Loaded',
    'En Route Drop',
    'At Drop',
    'Dumped',
  ];

  @override
  Widget build(BuildContext context) {
    final curIndex = _currentStepIndex;
    if (curIndex < 0 && currentStatus != JobStatus.assigned) return const SizedBox(); 
    // Wait, if it's assigned, the stepper could show 0 highlighted faintly?
    // Let's just show the stepper starting from step 0 when assigned to indicate next step.
    final displayIndex = curIndex < 0 ? 0 : curIndex; // For 'assigned', show En Route as grey or just display it
    final isActive = curIndex >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Job Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_stages.length, (index) {
            final isCompleted = isActive && index < curIndex;
            final isCurrent = isActive && index == curIndex;
            final color = (isCompleted || isCurrent) ? const Color(0xFF2E7D32) : Colors.grey[400]!;

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index == 0 ? Colors.transparent : (isActive && index <= curIndex ? const Color(0xFF2E7D32) : Colors.grey[400]!),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent ? color : (isCompleted ? color : Colors.white),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text('${index + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent ? Colors.white : color)),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index == _stages.length - 1 ? Colors.transparent : 
                              (isActive && index < curIndex ? const Color(0xFF2E7D32) : Colors.grey[400]!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stages[index],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? color : (isCompleted ? color : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
