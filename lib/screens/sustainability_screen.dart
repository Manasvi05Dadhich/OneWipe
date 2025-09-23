import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

class SustainabilityScreen extends StatefulWidget {
  const SustainabilityScreen({super.key});

  @override
  State<SustainabilityScreen> createState() => _SustainabilityScreenState();
}

class _SustainabilityScreenState extends State<SustainabilityScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  
  // Data
  Map<String, dynamic>? _globalStats;
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic>? _orgStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSustainabilityData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSustainabilityData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load global stats
      final globalResponse = await _api.getSustainabilityStats();
      if (globalResponse['success']) {
        _globalStats = globalResponse['data'];
      }

      // Load leaderboard (mock for now)
      _leaderboard = [
        {
          'orgName': 'EcoTech Solutions',
          'co2Saved': 15000,
          'devicesWiped': 75,
          'rank': 1,
          'greenTokens': 75
        },
        {
          'orgName': 'Green IT Corp',
          'co2Saved': 12000,
          'devicesWiped': 60,
          'rank': 2,
          'greenTokens': 60
        },
        {
          'orgName': 'Sustainable Systems',
          'co2Saved': 8500,
          'devicesWiped': 42,
          'rank': 3,
          'greenTokens': 42
        },
        {
          'orgName': 'CleanTech Innovations',
          'co2Saved': 6200,
          'devicesWiped': 31,
          'rank': 4,
          'greenTokens': 31
        },
        {
          'orgName': 'Circular Computing',
          'co2Saved': 4800,
          'devicesWiped': 24,
          'rank': 5,
          'greenTokens': 24
        },
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load sustainability data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const TopNavBar(currentRoute: '/sustainability'),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(theme),
        desktop: _buildDesktopLayout(theme),
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return Column(
      children: [
        _buildHeader(theme),
        _buildTabBar(theme),
        Expanded(child: _buildTabBarView(theme)),
      ],
    );
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    return Column(
      children: [
        _buildHeader(theme),
        _buildTabBar(theme),
        Expanded(child: _buildTabBarView(theme)),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Green Wipe Credits',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tokenized Environmental Impact',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Track and gamify your organization\'s contribution to circular economy through blockchain-verified sustainability tokens.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
        tabs: const [
          Tab(
            icon: Icon(Icons.public, size: 20),
            text: 'Global Impact',
          ),
          Tab(
            icon: Icon(Icons.leaderboard, size: 20),
            text: 'Leaderboard',
          ),
          Tab(
            icon: Icon(Icons.account_circle, size: 20),
            text: 'My Impact',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSustainabilityData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildGlobalImpactTab(theme),
        _buildLeaderboardTab(theme),
        _buildMyImpactTab(theme),
      ],
    );
  }

  Widget _buildGlobalImpactTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Global Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme: theme,
                  title: 'Total CO₂ Saved',
                  value: _formatCO2(_globalStats?['totalCO2Saved'] ?? 46200),
                  subtitle: 'Tons of CO₂',
                  icon: Icons.cloud_off,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  theme: theme,
                  title: 'Devices Recycled',
                  value: (_globalStats?['totalDevicesWiped'] ?? 231).toString(),
                  subtitle: 'Total devices',
                  icon: Icons.devices,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme: theme,
                  title: 'Active Organizations',
                  value: '12',
                  subtitle: 'Participating orgs',
                  icon: Icons.business,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  theme: theme,
                  title: 'Green Tokens',
                  value: '231',
                  subtitle: 'NFTs minted',
                  icon: Icons.eco,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Impact Visualization
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Environmental Impact',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImpactComparison(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Text(
                'Sustainability Champions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Top 3 Podium
          _buildPodium(theme),
          
          const SizedBox(height: 24),
          
          // Full Leaderboard
          Card(
            child: Column(
              children: _leaderboard.asMap().entries.map((entry) {
                final index = entry.key;
                final org = entry.value;
                return _buildLeaderboardItem(theme, org, index + 1);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyImpactTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization Setup
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Organization Setup',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Register your organization to start earning Green Wipe Credits and track your environmental impact.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showRegisterOrgDialog,
                    icon: const Icon(Icons.add_business),
                    label: const Text('Register Organization'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // My Green Tokens
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        'My Green Tokens',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your sustainability NFTs will appear here after completing secure wipe operations.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Complete your first secure wipe to earn your first Green Token NFT!',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactComparison(ThemeData theme) {
    final co2Saved = _globalStats?['totalCO2Saved'] ?? 46200;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildComparisonItem(
          'Cars removed from road for 1 year',
          '${(co2Saved / 4600).round()}',
          Icons.car_repair,
          Colors.red,
          theme,
        ),
        const SizedBox(height: 12),
        _buildComparisonItem(
          'Trees planted equivalent',
          '${(co2Saved * 16).round()}',
          Icons.forest,
          Colors.green,
          theme,
        ),
        const SizedBox(height: 12),
        _buildComparisonItem(
          'Homes powered for 1 year',
          '${(co2Saved / 5).round()}',
          Icons.home,
          Colors.blue,
          theme,
        ),
      ],
    );
  }

  Widget _buildComparisonItem(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(ThemeData theme) {
    if (_leaderboard.length < 3) return Container();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        _buildPodiumPlace(theme, _leaderboard[1], 2, 80, Colors.grey),
        // 1st place
        _buildPodiumPlace(theme, _leaderboard[0], 1, 100, Colors.amber),
        // 3rd place
        _buildPodiumPlace(theme, _leaderboard[2], 3, 60, Colors.orange),
      ],
    );
  }

  Widget _buildPodiumPlace(
    ThemeData theme,
    Map<String, dynamic> org,
    int place,
    double height,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            place.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                org['orgName'].toString().split(' ').first,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatCO2(org['co2Saved'])} t',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(
    ThemeData theme,
    Map<String, dynamic> org,
    int rank,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: rank <= 3 
              ? (rank == 1 ? Colors.amber : rank == 2 ? Colors.grey : Colors.orange)
              : theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: rank <= 3
              ? Icon(Icons.emoji_events, color: Colors.white, size: 20)
              : Text(
                  rank.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
      title: Text(
        org['orgName'],
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${org['devicesWiped']} devices • ${org['greenTokens']} Green Tokens',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${_formatCO2(org['co2Saved'])} tons',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Text(
            'CO₂ saved',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatCO2(int kg) {
    return (kg / 1000).toStringAsFixed(1);
  }

  void _showRegisterOrgDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register Organization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Organization Name',
                hintText: 'Enter your organization name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Wallet Address',
                hintText: '0x...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement organization registration
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Organization registration will be implemented when Green Token contract is deployed'),
                ),
              );
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}