import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_state.dart';
import '../../utils/responsive_utils.dart';

/// The tab bar for the main screen navigation
class MainTabBar extends StatelessWidget {
  final TabController tabController;

  const MainTabBar({
    Key? key,
    required this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final layoutConstraints = responsive.layoutConstraints;
    
    // Check if platinum frame is active
    final bool isPlatinumFrameActive = Provider.of<GameState>(context).isPlatinumFrameUnlocked && 
                                      Provider.of<GameState>(context).isPlatinumFrameActive;
    
    return Container(
      height: layoutConstraints.tabBarHeight,
      decoration: BoxDecoration(
        gradient: isPlatinumFrameActive
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3D2B5B),  // Deep royal purple
                  Color(0xFF34385E),  // Rich royal blue
                ],
              )
            : null,
        color: isPlatinumFrameActive ? null : Colors.white,
        border: Border(
          top: BorderSide(
            color: isPlatinumFrameActive ? const Color(0xFFFFD700) : Colors.grey.shade300,
            width: isPlatinumFrameActive ? 2.0 : 1.0,
          ),
          bottom: BorderSide(
            color: isPlatinumFrameActive ? const Color(0xFFFFD700) : Colors.grey.shade300,
            width: isPlatinumFrameActive ? 0.5 : 1.0,
          ),
        ),
        boxShadow: isPlatinumFrameActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: responsive.spacing(8),
                  spreadRadius: responsive.spacing(-4),
                  offset: Offset(0, responsive.spacing(-2)),
                ),
              ]
            : null,
      ),
      child: TabBar(
        controller: tabController,
        labelColor: isPlatinumFrameActive ? const Color(0xFFFFD700) : Colors.blue,
        unselectedLabelColor: isPlatinumFrameActive ? Colors.grey.shade400 : Colors.grey,
        indicatorWeight: 3,
        indicatorColor: isPlatinumFrameActive ? const Color(0xFFFFD700) : Colors.blue,
        indicatorPadding: isPlatinumFrameActive ? EdgeInsets.symmetric(horizontal: responsive.spacing(10)) : EdgeInsets.zero,
        isScrollable: false,
        labelPadding: EdgeInsets.zero,
        labelStyle: TextStyle(
          fontSize: responsive.fontSize(12), 
          fontWeight: FontWeight.bold,
          shadows: isPlatinumFrameActive
              ? [
                  Shadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        unselectedLabelStyle: TextStyle(fontSize: responsive.fontSize(12)),
        tabs: [
          Tab(
            icon: Icon(Icons.touch_app, size: responsive.iconSize(20)), 
            text: responsive.isVeryCompact ? 'Tap' : 'Hustle'
          ),
          Tab(
            icon: Icon(Icons.business, size: responsive.iconSize(20)), 
            text: 'Biz'
          ),
          Tab(
            icon: Icon(Icons.trending_up, size: responsive.iconSize(20)), 
            text: responsive.isVeryCompact ? '\$' : 'Invest'
          ),
          Tab(
            icon: Icon(Icons.home, size: responsive.iconSize(20)), 
            text: responsive.isVeryCompact ? 'RE' : 'Estate'
          ),
          Tab(
            icon: Icon(Icons.bar_chart, size: responsive.iconSize(20)), 
            text: 'Stats'
          ),
          Tab(
            icon: Icon(Icons.person, size: responsive.iconSize(20)), 
            text: responsive.isVeryCompact ? 'Me' : 'Profile'
          ),
        ],
      ),
    );
  }
} 