import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App bar variant types
enum AppBarVariant {
  standard,      // Default app bar with title
  search,        // App bar with search functionality
  profile,       // App bar with profile actions
  emergency,     // High contrast emergency mode
  minimal,       // Clean minimal design
}

/// Custom AppBar widget implementing Clinical Minimalism design
/// with contextual elevation and adaptive behavior for health applications
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a custom app bar
  const CustomAppBar({
    super.key,
    required this.title,
    this.variant = AppBarVariant.standard,
    this.showBackButton = true,
    this.actions,
    this.onSearchChanged,
    this.searchHint = 'Search medical records...',
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.isEmergencyMode = false,
  });

  /// App bar title
  final String title;
  
  /// App bar variant
  final AppBarVariant variant;
  
  /// Whether to show back button
  final bool showBackButton;
  
  /// Action buttons
  final List<Widget>? actions;
  
  /// Search callback
  final ValueChanged<String>? onSearchChanged;
  
  /// Search hint text
  final String searchHint;
  
  /// Custom background color
  final Color? backgroundColor;
  
  /// Custom foreground color
  final Color? foregroundColor;
  
  /// Custom elevation
  final double? elevation;
  
  /// Whether to center title
  final bool centerTitle;
  
  /// Emergency mode flag
  final bool isEmergencyMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Emergency mode color overrides
    final effectiveBackgroundColor = backgroundColor ?? 
        (isEmergencyMode ? const Color(0xFFFF6B6B) : colorScheme.surface);
    final effectiveForegroundColor = foregroundColor ?? 
        (isEmergencyMode ? Colors.white : colorScheme.onSurface);
    
    switch (variant) {
      case AppBarVariant.search:
        return _buildSearchAppBar(context, effectiveBackgroundColor, effectiveForegroundColor);
      case AppBarVariant.profile:
        return _buildProfileAppBar(context, effectiveBackgroundColor, effectiveForegroundColor);
      case AppBarVariant.emergency:
        return _buildEmergencyAppBar(context);
      case AppBarVariant.minimal:
        return _buildMinimalAppBar(context, effectiveBackgroundColor, effectiveForegroundColor);
      case AppBarVariant.standard:
      default:
        return _buildStandardAppBar(context, effectiveBackgroundColor, effectiveForegroundColor);
    }
  }

  /// Build standard app bar
  Widget _buildStandardAppBar(BuildContext context, Color bgColor, Color fgColor) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: fgColor,
        ),
      ),
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton ? _buildBackButton(context, fgColor) : null,
      actions: actions ?? _buildDefaultActions(context, fgColor),
      surfaceTintColor: Colors.transparent,
    );
  }

  /// Build search app bar
  Widget _buildSearchAppBar(BuildContext context, Color bgColor, Color fgColor) {
    return AppBar(
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: TextField(
          onChanged: onSearchChanged,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: searchHint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation ?? 2,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton ? _buildBackButton(context, fgColor) : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterDialog(context),
          tooltip: 'Filter results',
        ),
      ],
      surfaceTintColor: Colors.transparent,
    );
  }

  /// Build profile app bar
  Widget _buildProfileAppBar(BuildContext context, Color bgColor, Color fgColor) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: fgColor,
        ),
      ),
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton ? _buildBackButton(context, fgColor) : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _navigateToNotifications(context),
          tooltip: 'Notifications',
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => _navigateToProfile(context),
          tooltip: 'Profile',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Help & Support'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'emergency',
              child: ListTile(
                leading: Icon(Icons.emergency, color: Color(0xFFFF6B6B)),
                title: Text('Emergency Mode'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      surfaceTintColor: Colors.transparent,
    );
  }

  /// Build emergency app bar
  Widget _buildEmergencyAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emergency,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'EMERGENCY MODE',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFF6B6B),
      foregroundColor: Colors.white,
      elevation: 4,
      centerTitle: true,
      automaticallyImplyLeading: false,
      actions: [
        TextButton(
          onPressed: () => _exitEmergencyMode(context),
          child: Text(
            'EXIT',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
      surfaceTintColor: Colors.transparent,
    );
  }

  /// Build minimal app bar
  Widget _buildMinimalAppBar(BuildContext context, Color bgColor, Color fgColor) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: fgColor,
        ),
      ),
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton ? _buildMinimalBackButton(context, fgColor) : null,
      actions: actions,
      surfaceTintColor: Colors.transparent,
    );
  }

  /// Build back button
  Widget _buildBackButton(BuildContext context, Color color) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios,
        color: color,
        size: 20,
      ),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Back',
    );
  }

  /// Build minimal back button
  Widget _buildMinimalBackButton(BuildContext context, Color color) {
    return IconButton(
      icon: Icon(
        Icons.close,
        color: color,
        size: 24,
      ),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Close',
    );
  }

  /// Build default actions
  List<Widget> _buildDefaultActions(BuildContext context, Color color) {
    return [
      IconButton(
        icon: Icon(
          Icons.search,
          color: color,
        ),
        onPressed: () => _navigateToSearch(context),
        tooltip: 'Search',
      ),
    ];
  }

  /// Navigate to search
  void _navigateToSearch(BuildContext context) {
    Navigator.pushNamed(context, '/medical-records-library');
  }

  /// Navigate to notifications
  void _navigateToNotifications(BuildContext context) {
    // Navigate to notifications screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications feature coming soon')),
    );
  }

  /// Navigate to profile
  void _navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/user-registration');
  }

  /// Handle menu actions
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings feature coming soon')),
        );
        break;
      case 'help':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help & Support feature coming soon')),
        );
        break;
      case 'emergency':
        _activateEmergencyMode(context);
        break;
    }
  }

  /// Show filter dialog
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter Options',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Recent Records'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Lab Results'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Prescriptions'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  /// Activate emergency mode
  void _activateEmergencyMode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Emergency mode activated'),
        backgroundColor: const Color(0xFFFF6B6B),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Exit emergency mode
  void _exitEmergencyMode(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/health-dashboard',
      (route) => false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}