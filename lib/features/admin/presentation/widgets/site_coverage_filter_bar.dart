import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/site_coverage_filter.dart';

/// Filter bar providing selectable chips to filter site coverage items.
class SiteCoverageFilterBar extends StatelessWidget {
  final SiteCoverageFilter currentFilter;
  final ValueChanged<SiteCoverageFilter> onFilterChanged;

  const SiteCoverageFilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context: context,
            label: 'All Sites',
            filter: SiteCoverageFilter.all,
            key: const Key('filter_chip_all'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: 'Fully Staffed',
            filter: SiteCoverageFilter.fullyStaffed,
            icon: Icons.check_circle_outline,
            color: Colors.green,
            key: const Key('filter_chip_fully_staffed'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: 'Understaffed',
            filter: SiteCoverageFilter.understaffed,
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            key: const Key('filter_chip_understaffed'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required SiteCoverageFilter filter,
    required Key key,
    IconData? icon,
    Color? color,
  }) {
    final isSelected = currentFilter == filter;

    return ChoiceChip(
      key: key,
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? (color ?? AppColors.primary)
              : AppColors.borderLight,
        ),
      ),
      avatar: icon != null
          ? Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (color ?? AppColors.textSecondaryLight),
            )
          : null,
      selected: isSelected,
      selectedColor: color ?? AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: AppTextStyles.caption(
        color: isSelected ? Colors.white : AppColors.textPrimaryLight,
      ).copyWith(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(filter);
        }
      },
    );
  }
}
