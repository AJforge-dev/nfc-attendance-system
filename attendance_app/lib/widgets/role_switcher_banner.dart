import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/attendance_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class RoleSwitcherBanner extends StatelessWidget {
  const RoleSwitcherBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = provider.currentUser;
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B18) : const Color(0xFFEBF2EF),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkLine : AppTheme.lightLine,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF072722) : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSoft : AppTheme.lightSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            user.role.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      user.role == UserRole.student
                          ? 'Roll: ${user.rollNumber ?? "N/A"} • Tag: ${user.tagUid ?? "N/A"}'
                          : user.department,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Theme Toggle
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20,
                ),
                tooltip: 'Toggle Theme',
                onPressed: () => themeProvider.toggleTheme(),
              ),
              // Logout Action
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.logout_rounded, size: 20),
                tooltip: 'Sign Out / Switch Account',
                onPressed: () {
                  provider.logout();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Quick Role Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.users.map((u) {
                final isSelected = u.id == user.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(
                      _getRoleIcon(u.role),
                      size: 14,
                      color: isSelected
                          ? (isDark ? const Color(0xFF072722) : Colors.white)
                          : (isDark ? AppTheme.darkAccent : AppTheme.lightAccent),
                    ),
                    label: Text(
                      '${u.name.split(" ").first} (${u.role.displayName})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? const Color(0xFF072722) : Colors.white)
                            : (isDark ? AppTheme.darkFg : AppTheme.lightFg),
                      ),
                    ),
                    backgroundColor: isDark ? AppTheme.darkPanel : AppTheme.lightPanel,
                    selectedColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? AppTheme.darkLine : AppTheme.lightLine),
                    ),
                    onSelected: (_) => provider.switchUser(u),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Icons.school_rounded;
      case UserRole.faculty:
        return Icons.person_rounded;
      case UserRole.advisor:
        return Icons.verified_user_rounded;
      case UserRole.hod:
        return Icons.military_tech_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }
}
