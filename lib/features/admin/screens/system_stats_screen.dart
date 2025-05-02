import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SystemStatsScreen extends StatefulWidget {
  const SystemStatsScreen({super.key});

  @override
  State<SystemStatsScreen> createState() => _SystemStatsScreenState();
}

class _SystemStatsScreenState extends State<SystemStatsScreen> {
  String _selectedPeriod = 'Week';

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width <= 600;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector - responsive layout
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'Week', label: Text('Week')),
                              ButtonSegment(
                                  value: 'Month', label: Text('Month')),
                              ButtonSegment(value: 'Year', label: Text('Year')),
                            ],
                            selected: {_selectedPeriod},
                            onSelectionChanged: (Set<String> selection) {
                              setState(() {
                                _selectedPeriod = selection.first;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Week', label: Text('Week')),
                          ButtonSegment(value: 'Month', label: Text('Month')),
                          ButtonSegment(value: 'Year', label: Text('Year')),
                        ],
                        selected: {_selectedPeriod},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() {
                            _selectedPeriod = selection.first;
                          });
                        },
                      ),
                    ],
                  ),

            const SizedBox(height: 24),

            // Summary cards - scrollable on mobile
            SingleChildScrollView(
              scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
              child: isMobile
                  ? Row(
                      children: _buildSummaryCardsForMobile(),
                    )
                  : _buildSummaryCards(),
            ),

            const SizedBox(height: 24),

            // User activity chart
            _buildUserActivityChart(isMobile),

            const SizedBox(height: 24),

            // System performance charts - stacked on mobile
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildPerformanceGridForMobile(),
                  )
                : _buildPerformanceGrid(),

            const SizedBox(height: 24),

            // Recent activities and logs
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSummaryCardsForMobile() {
    return [
      SizedBox(
        width: 220,
        child: _buildModernStatsCard(
          title: 'Active Users',
          count: 0,
          icon: Icons.people,
          color: Colors.blue,
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          subtitle: 'Today',
          trend: '+5%',
          isPositiveTrend: true,
        ),
      ),
      const SizedBox(width: 16),
      SizedBox(
        width: 220,
        child: _buildModernStatsCard(
          title: 'Assignments',
          count: 0,
          icon: Icons.assignment_turned_in,
          color: Colors.green,
          stream:
              FirebaseFirestore.instance.collection('submissions').snapshots(),
          subtitle: 'This week',
          trend: '+12%',
          isPositiveTrend: true,
        ),
      ),
      const SizedBox(width: 16),
      SizedBox(
        width: 220,
        child: _buildModernStatsCard(
          title: 'Enrollments',
          count: 0,
          icon: Icons.school,
          color: Colors.orange,
          stream: FirebaseFirestore.instance
              .collection('course_registrations')
              .snapshots(),
          subtitle: 'This month',
          trend: '+8%',
          isPositiveTrend: true,
        ),
      ),
      const SizedBox(width: 16),
      SizedBox(
        width: 220,
        child: _buildModernStatsCard(
          title: 'Announcements',
          count: 0,
          icon: Icons.campaign,
          color: Colors.purple,
          stream:
              FirebaseFirestore.instance.collection('broadcasts').snapshots(),
          subtitle: 'This week',
          trend: '-3%',
          isPositiveTrend: false,
        ),
      ),
    ];
  }

  Widget _buildModernStatsCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
    required String subtitle,
    required String trend,
    required bool isPositiveTrend,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int itemCount = 0;
        if (snapshot.hasData) {
          itemCount = snapshot.data!.docs.length;
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  color.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPositiveTrend
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            trend,
                            style: TextStyle(
                              color:
                                  isPositiveTrend ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Icon(
                            isPositiveTrend
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isPositiveTrend ? Colors.green : Colors.red,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  itemCount.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserActivityChart(bool isMobile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'User Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isMobile)
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Activity over time by user role',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: !isMobile,
                    horizontalInterval: 2,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade100,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.shade100,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: !isMobile, // Hide side titles on mobile
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final labels = _selectedPeriod == 'Week'
                              ? [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun'
                                ]
                              : _selectedPeriod == 'Month'
                                  ? ['W1', 'W2', 'W3', 'W4']
                                  : [
                                      'Jan',
                                      'Mar',
                                      'May',
                                      'Jul',
                                      'Sep',
                                      'Nov'
                                    ]; // Simplified for mobile

                          final index = value.toInt();
                          if (index >= 0 && index < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[index],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: isMobile
                                      ? 10
                                      : 12, // Smaller font on mobile
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  minX: 0,
                  maxX: _selectedPeriod == 'Week'
                      ? 6
                      : _selectedPeriod == 'Month'
                          ? 3
                          : 11,
                  minY: 0,
                  maxY: 10,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipBorder: BorderSide(
                        color: Colors.grey.shade200,
                      ),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          String role = "Unknown";
                          Color color = Colors.grey;

                          if (spot.barIndex == 0) {
                            role = "Students";
                            color = Colors.blue;
                          } else if (spot.barIndex == 1) {
                            role = "Lecturers";
                            color = Colors.green;
                          } else if (spot.barIndex == 2) {
                            role = "Admins";
                            color = Colors.orange;
                          }

                          return LineTooltipItem(
                            "$role: ${spot.y.toInt()}",
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (_, spots) {
                      return spots.map((spot) {
                        return TouchedSpotIndicatorData(
                          FlLine(color: Colors.grey, strokeWidth: 0),
                          FlDotData(
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: barData.color!,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                        );
                      }).toList();
                    },
                  ),
                  lineBarsData: [
                    // Students activity line
                    LineChartBarData(
                      spots: _generateRandomSpots(color: Colors.blue),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.2),
                            Colors.blue.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Lecturers activity line
                    LineChartBarData(
                      spots: _generateRandomSpots(color: Colors.green),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.2),
                            Colors.green.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Admin activity line
                    LineChartBarData(
                      spots: _generateRandomSpots(color: Colors.orange),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.2),
                            Colors.orange.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: isMobile
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  _buildModernLegendItem('Students', Colors.blue),
                  const SizedBox(width: 16),
                  _buildModernLegendItem('Lecturers', Colors.green),
                  const SizedBox(width: 16),
                  _buildModernLegendItem('Admins', Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPerformanceGridForMobile() {
    return [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pie_chart,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'System Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildMobilePieChart(
        title: 'User Distribution',
        data: [
          PieChartSectionData(
            value: 65,
            title: '65%',
            color: Colors.blue,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: 30,
            title: '30%',
            color: Colors.green,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: 5,
            title: '5%',
            color: Colors.red,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        legends: [
          _buildModernLegendItem('Students', Colors.blue),
          _buildModernLegendItem('Lecturers', Colors.green),
          _buildModernLegendItem('Admins', Colors.red),
        ],
      ),
      const SizedBox(height: 16),
      _buildMobilePieChart(
        title: 'Course Distribution by Level',
        data: [
          PieChartSectionData(
            value: 30,
            title: '30%',
            color: Colors.blue.shade300,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: 25,
            title: '25%',
            color: Colors.blue.shade500,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: 25,
            title: '25%',
            color: Colors.blue.shade700,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: 20,
            title: '20%',
            color: Colors.blue.shade900,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        legends: [
          _buildModernLegendItem('100 Level', Colors.blue.shade300),
          _buildModernLegendItem('200 Level', Colors.blue.shade500),
          _buildModernLegendItem('300 Level', Colors.blue.shade700),
          _buildModernLegendItem('400 Level', Colors.blue.shade900),
        ],
      ),
    ];
  }

  Widget _buildMobilePieChart({
    required String title,
    required List<PieChartSectionData> data,
    required List<Widget> legends,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: data,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Handle touch interactions here
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: legends.map((legend) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: legend,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(
            title: 'Active Users',
            count: 0,
            icon: Icons.people,
            color: Colors.blue,
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            subtitle: 'Today',
            trend: '+5%',
            isPositiveTrend: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            title: 'Assignments Submitted',
            count: 0,
            icon: Icons.assignment_turned_in,
            color: Colors.green,
            stream: FirebaseFirestore.instance
                .collection('submissions')
                .snapshots(),
            subtitle: 'This week',
            trend: '+12%',
            isPositiveTrend: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            title: 'Course Enrollments',
            count: 0,
            icon: Icons.school,
            color: Colors.orange,
            stream: FirebaseFirestore.instance
                .collection('course_registrations')
                .snapshots(),
            subtitle: 'This month',
            trend: '+8%',
            isPositiveTrend: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            title: 'New Announcements',
            count: 0,
            icon: Icons.campaign,
            color: Colors.purple,
            stream:
                FirebaseFirestore.instance.collection('broadcasts').snapshots(),
            subtitle: 'This week',
            trend: '-3%',
            isPositiveTrend: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
    required String subtitle,
    required String trend,
    required bool isPositiveTrend,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int itemCount = 0;
        if (snapshot.hasData) {
          itemCount = snapshot.data!.docs.length;
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      trend,
                      style: TextStyle(
                        color: isPositiveTrend ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      isPositiveTrend
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: isPositiveTrend ? Colors.green : Colors.red,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  itemCount.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateRandomSpots({required Color color}) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final modifier = color == Colors.blue
        ? 0.1
        : color == Colors.green
            ? 0.08
            : 0.05;

    final range = _selectedPeriod == 'Week'
        ? 7
        : _selectedPeriod == 'Month'
            ? 4
            : 12;

    return List.generate(range, (index) {
      final value = 2 + ((random * index * modifier) % 8);
      return FlSpot(index.toDouble(), value);
    });
  }

  Widget _buildPerformanceGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPieChartCard(
                title: 'User Distribution',
                data: [
                  PieChartSectionData(
                    value: 65,
                    title: '65%',
                    color: Colors.blue,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 30,
                    title: '30%',
                    color: Colors.green,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 5,
                    title: '5%',
                    color: Colors.red,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                legends: [
                  _buildLegendItem('Students', Colors.blue),
                  _buildLegendItem('Lecturers', Colors.green),
                  _buildLegendItem('Admins', Colors.red),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPieChartCard(
                title: 'Course Distribution by Level',
                data: [
                  PieChartSectionData(
                    value: 30,
                    title: '30%',
                    color: Colors.blue.shade300,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 25,
                    title: '25%',
                    color: Colors.blue.shade500,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 25,
                    title: '25%',
                    color: Colors.blue.shade700,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: '20%',
                    color: Colors.blue.shade900,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                legends: [
                  _buildLegendItem('100 Level', Colors.blue.shade300),
                  _buildLegendItem('200 Level', Colors.blue.shade500),
                  _buildLegendItem('300 Level', Colors.blue.shade700),
                  _buildLegendItem('400 Level', Colors.blue.shade900),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPieChartCard({
    required String title,
    required List<PieChartSectionData> data,
    required List<Widget> legends,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: data,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: legends,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width <= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.history,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // Navigate to full logs
              },
              icon: const Icon(Icons.access_time, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('system_logs')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final logs = snapshot.data?.docs ?? [];

              if (logs.isEmpty) {
                // Generate sample logs if no real logs exist
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final daysAgo = index * 2;
                    final date =
                        DateTime.now().subtract(Duration(days: daysAgo));

                    String activity;
                    IconData icon;
                    Color color;

                    switch (index) {
                      case 0:
                        activity = 'New user registered: John Smith (Student)';
                        icon = Icons.person_add;
                        color = Colors.blue;
                        break;
                      case 1:
                        activity =
                            'Course created: Introduction to Flutter (CSC301)';
                        icon = Icons.book;
                        color = Colors.green;
                        break;
                      case 2:
                        activity = 'System backup completed successfully';
                        icon = Icons.backup;
                        color = Colors.purple;
                        break;
                      case 3:
                        activity = 'Admin login: System Administrator';
                        icon = Icons.login;
                        color = Colors.orange;
                        break;
                      case 4:
                        activity = 'Maintenance scheduled for next weekend';
                        icon = Icons.build;
                        color = Colors.red;
                        break;
                      default:
                        activity = 'System activity';
                        icon = Icons.info;
                        color = Colors.grey;
                    }

                    return isMobile
                        ? _buildMobileActivityItem(
                            activity: activity,
                            date: date,
                            icon: icon,
                            color: color,
                          )
                        : ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            title: Text(
                              activity,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(DateFormat('MMM dd, yyyy - HH:mm')
                                .format(date)),
                            trailing: IconButton(
                              icon:
                                  const Icon(Icons.arrow_forward_ios, size: 14),
                              onPressed: () {},
                            ),
                          );
                  },
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final logData = logs[index].data() as Map<String, dynamic>;

                  final activity =
                      logData['activity'] as String? ?? 'Unknown activity';
                  final type = logData['type'] as String? ?? 'info';
                  final timestamp = logData['timestamp'] as Timestamp?;
                  final date = timestamp?.toDate() ?? DateTime.now();

                  IconData icon;
                  Color color;

                  switch (type) {
                    case 'user':
                      icon = Icons.person;
                      color = Colors.blue;
                      break;
                    case 'course':
                      icon = Icons.book;
                      color = Colors.green;
                      break;
                    case 'system':
                      icon = Icons.computer;
                      color = Colors.purple;
                      break;
                    case 'alert':
                      icon = Icons.warning;
                      color = Colors.orange;
                      break;
                    case 'error':
                      icon = Icons.error;
                      color = Colors.red;
                      break;
                    default:
                      icon = Icons.info;
                      color = Colors.grey;
                  }

                  return isMobile
                      ? _buildMobileActivityItem(
                          activity: activity,
                          date: date,
                          icon: icon,
                          color: color,
                        )
                      : ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.1),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          title: Text(
                            activity,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                              DateFormat('MMM dd, yyyy - HH:mm').format(date)),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 14),
                            onPressed: () {},
                          ),
                        );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActivityItem({
    required String activity,
    required DateTime date,
    required IconData icon,
    required Color color,
  }) {
    final now = DateTime.now();
    final difference = now.difference(date);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes}m ago';
    } else {
      timeAgo = 'Just now';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
