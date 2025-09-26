import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'services_page.dart';
import 'bills_page.dart';
import 'staff_page.dart';
import 'reports_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    ServicesPage(),
    BillsPage(),
    StaffPage(),
    ReportsPage(),
  ];

  final List<String> _titles = const [
    "Dashboard",
    "Services",
    "Bills",
    "Staff",
    "Reports"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text("Dashboard"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.design_services),
                label: Text("Services"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long),
                label: Text("Bills"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text("Staff"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart),
                label: Text("Reports"),
              ),
            ],
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(title: Text(_titles[_selectedIndex])),
              body: _pages[_selectedIndex],
            ),
          )
        ],
      ),
    );
  }
}
