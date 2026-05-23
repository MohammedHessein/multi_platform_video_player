part of '../imports.dart';

class SpeedSelectorBottomSheet extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  const SpeedSelectorBottomSheet({
    super.key,
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Text(
                  AppStrings.playbackSpeed,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: AppColors.outline),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: AppConstants.playbackSpeeds.map((speed) {
                    final isSelected = speed == currentSpeed;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                      title: Text(
                        AppStrings.speed(speed),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        onSpeedChanged(speed);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
