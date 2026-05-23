part of '../imports.dart';

class DoubleTapFeedback extends StatelessWidget {
  final String side;

  const DoubleTapFeedback({
    super.key,
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Positioned(
      left: side == AppConstants.sideLeft ? 0 : null,
      right: side == AppConstants.sideRight ? 0 : null,
      top: 0,
      bottom: 0,
      width: screenWidth * 0.35,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(
              side == AppConstants.sideLeft ? 1000 : 0,
            ),
            bottomRight: Radius.circular(
              side == AppConstants.sideLeft ? 1000 : 0,
            ),
            topLeft: Radius.circular(
              side == AppConstants.sideRight ? 1000 : 0,
            ),
            bottomLeft: Radius.circular(
              side == AppConstants.sideRight ? 1000 : 0,
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  side == AppConstants.sideLeft
                      ? Icons.fast_rewind
                      : Icons.fast_forward,
                  color: AppColors.white,
                  size: 32.r,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppStrings.seekDuration,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
