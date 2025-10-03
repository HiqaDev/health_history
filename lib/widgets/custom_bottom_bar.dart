import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BottomBarVariant {
  standard,      // Standard bottom navigation
  floating,      // Floating action bar style
  minimal,       // Minimal design with icons only
  emergency,     // Emergency mode with high contrast
}

/// Custom Bottom Navigation Bar implementing Clinical Minimalism design
/// with adaptive behavior and gesture-aware hiding functionality
class CustomBottomBar extends StatefulWidget {
  /// Navigation item data
  static const List<BottomBarItem> _navigationItems = [
    BottomBarItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/health-dashboard',
    ),
    BottomBarItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder,
      label: 'Records',
      route: '/medical-records-library',
    ),
    BottomBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      route: '/user-registration',
    ),
  ];

  /// Creates a custom bottom navigation bar
  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.variant = BottomBarVariant.standard,
    this.isVisible = true,
    this.isEmergencyMode = false,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  /// Current selected index
  final int currentIndex;
  
  /// Tap callback
  final ValueChanged<int>? onTap;
  
  /// Bottom bar variant
  final BottomBarVariant variant;
  
  /// Visibility state for gesture-aware hiding
  final bool isVisible;
  
  /// Emergency mode flag
  final bool isEmergencyMode;
  
  /// Custom background color
  final Color? backgroundColor;
  
  /// Custom selected item color
  final Color? selectedItemColor;
  
  /// Custom unselected item color
  final Color? unselectedItemColor;

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CustomBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case BottomBarVariant.floating:
        return _buildFloatingBottomBar(context);
      case BottomBarVariant.minimal:
        return _buildMinimalBottomBar(context);
      case BottomBarVariant.emergency:
        return _buildEmergencyBottomBar(context);
      case BottomBarVariant.standard:
      default:
        return _buildStandardBottomBar(context);
    }
  }

  /// Build standard bottom navigation bar
  Widget _buildStandardBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: widget.currentIndex.clamp(0, CustomBottomBar._navigationItems.length - 1),
              onTap: _handleTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: widget.selectedItemColor ?? colorScheme.primary,
              unselectedItemColor: widget.unselectedItemColor ?? 
                  colorScheme.onSurface.withValues(alpha: 0.6),
              selectedLabelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              items: CustomBottomBar._navigationItems.map((item) {
                final isSelected = CustomBottomBar._navigationItems.indexOf(item) == widget.currentIndex;
                return BottomNavigationBarItem(
                  icon: _buildIcon(item.icon, isSelected: false),
                  activeIcon: _buildIcon(item.activeIcon, isSelected: true),
                  label: item.label,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Build floating bottom navigation bar
  Widget _buildFloatingBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            color: widget.backgroundColor ?? colorScheme.surface,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: CustomBottomBar._navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == widget.currentIndex;
                  
                  return _buildFloatingItem(context, item, index, isSelected);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build minimal bottom navigation bar
  Widget _buildMinimalBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: CustomBottomBar._navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == widget.currentIndex;
                
                return _buildMinimalItem(context, item, index, isSelected);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Build emergency bottom navigation bar
  Widget _buildEmergencyBottomBar(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B6B),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEmergencyItem(
                    context,
                    Icons.emergency,
                    'Emergency',
                    0,
                  ),
                  _buildEmergencyItem(
                    context,
                    Icons.local_hospital,
                    'Medical ID',
                    1,
                  ),
                  _buildEmergencyItem(
                    context,
                    Icons.phone,
                    'Call 102',
                    2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build icon with proper sizing
  Widget _buildIcon(IconData icon, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Icon(
        icon,
        size: 24,
      ),
    );
  }

  /// Build floating navigation item
  Widget _buildFloatingItem(BuildContext context, BottomBarItem item, int index, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: () => _handleTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (widget.selectedItemColor ?? colorScheme.primary).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected 
                  ? (widget.selectedItemColor ?? colorScheme.primary)
                  : (widget.unselectedItemColor ?? colorScheme.onSurface.withValues(alpha: 0.6)),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.selectedItemColor ?? colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build minimal navigation item
  Widget _buildMinimalItem(BuildContext context, BottomBarItem item, int index, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected 
                  ? (widget.selectedItemColor ?? colorScheme.primary)
                  : (widget.unselectedItemColor ?? colorScheme.onSurface.withValues(alpha: 0.6)),
              size: 24,
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 20,
              decoration: BoxDecoration(
                color: isSelected 
                    ? (widget.selectedItemColor ?? colorScheme.primary)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build emergency navigation item
  Widget _buildEmergencyItem(BuildContext context, IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () => _handleEmergencyTap(context, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle navigation tap
  void _handleTap(int index) {
    if (index >= 0 && index < CustomBottomBar._navigationItems.length) {
      widget.onTap?.call(index);
      
      // Navigate to the corresponding route
      final route = CustomBottomBar._navigationItems[index].route;
      if (route.isNotEmpty) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          route,
          (route) => false,
        );
      }
    }
  }

  /// Handle emergency tap
  void _handleEmergencyTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Emergency info
        _showEmergencyInfo(context);
        break;
      case 1:
        // Medical ID
        _showMedicalId(context);
        break;
      case 2:
        // Call 102
        _callEmergency(context);
        break;
    }
  }

  /// Show emergency information
  void _showEmergencyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emergency, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 8),
            Text(
              'Emergency Information',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Contacts:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Emergency Services: 102\n• Poison Control: 1-800-222-1222\n• Crisis Hotline: 988',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show medical ID
  void _showMedicalId(BuildContext context) {
    Navigator.pushNamed(context, '/user-registration');
  }

  /// Call emergency services
  void _callEmergency(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.phone, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 8),
            Text(
              'Call Emergency Services',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'This will call 102. Are you sure you want to proceed?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // In a real app, this would initiate a phone call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency call initiated'),
                  backgroundColor: Color(0xFFFF6B6B),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Call 102'),
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation bar item data class
class BottomBarItem {
  const BottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}