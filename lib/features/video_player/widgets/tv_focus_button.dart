part of '../imports.dart';

class TvFocusButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double? size;
  final double? iconSize;
  final String? label;
  final bool autofocus;

  const TvFocusButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size,
    this.iconSize,
    this.label,
    this.autofocus = false,
  });

  @override
  State<TvFocusButton> createState() => _TvFocusButtonState();
}

class _TvFocusButtonState extends State<TvFocusButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onFocusChange: (focus) => setState(() => _isFocused = focus),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onTap(),
        ),
      },
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.all(8.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppConstants.animationDurationFast,
                width:
                    (widget.size ?? AppConstants.tvSecondaryButtonSize).w,
                height:
                    (widget.size ?? AppConstants.tvSecondaryButtonSize).h,
                decoration: BoxDecoration(
                  color: _isFocused ? AppColors.primary : AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 15.r,
                            spreadRadius: 5.r,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  widget.icon,
                  color: _isFocused ? AppColors.black : AppColors.onSurface,
                  size:
                      (widget.iconSize ?? AppConstants.tvSecondaryIconSize)
                          .r,
                ),
              ),
              if (widget.label != null) ...[
                SizedBox(height: 8.h),
                Text(
                  widget.label!,
                  key: ValueKey('lbl_${widget.label}'),
                  style: TextStyle(
                    color: _isFocused
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    fontSize: 14.sp,
                    fontWeight: _isFocused
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
