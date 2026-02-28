// lib/features/users/presentation/screens/users_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shippers/presentation/screens/shippers_list_screen.dart';
import 'drivers_list_screen.dart';

/// Users screen - Wrapper with tabs for Drivers and Shippers
/// Drivers tab now uses the full DriversListScreen implementation
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Users'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.drive_eta),
              text: 'Drivers',
            ),
            Tab(
              icon: Icon(Icons.business),
              text: 'Shippers',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Drivers tab - Uses DriversListScreen content
          _DriversTabContent(),
          // Shippers tab - Uses ShippersListScreenContent
          _ShippersTabContent(),
        ],
      ),
    );
  }
}

/// Drivers tab content - Embeds DriversListScreen functionality
class _DriversTabContent extends StatelessWidget {
  const _DriversTabContent();

  @override
  Widget build(BuildContext context) {
    // Use the full DriversListScreen
    // We extract just the body since we're already inside a tab
    return const DriversListScreenContent();
  }
}

/// Shippers tab content - Embeds ShippersListScreenContent functionality
class _ShippersTabContent extends StatelessWidget {
  const _ShippersTabContent();

  @override
  Widget build(BuildContext context) {
    return const ShippersListScreenContent();
  }
}
