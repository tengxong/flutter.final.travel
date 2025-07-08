import 'package:flutter/material.dart';
import 'package:app_travel/home/home_page.dart';
import 'package:app_travel/screens/profile_screen.dart';
import 'package:app_travel/screens/category_screen.dart';
import 'package:app_travel/screens/explore_screen.dart';
import 'package:app_travel/screens/add_post_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  // Lazy load pages only when needed
  late final List<Widget> _widgetOptions = [
    const HomePage(),
    const CategoryScreen(),
    const ExploreScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      // floatingActionButton: FloatingActionButton( // Comment out or remove this block
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const AddPostScreen()),
      //     );
      //   },
      //   backgroundColor: Colors.orange,
      //   shape: const CircleBorder(),
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Comment out or remove this line
      bottomNavigationBar: BottomAppBar(
        // shape: const CircularNotchedRectangle(), // Remove this line
        // notchMargin: 8.0, // Remove this line
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(child: _buildNavItem(0, Icons.home, 'Home')),
            Expanded(child: _buildNavItem(1, Icons.grid_view, 'Category')),
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPostScreen()),
                );
              },
              backgroundColor: Colors.orange,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white),
            ), // FAB as a child of the row
            Expanded(child: _buildNavItem(2, Icons.location_on, 'Explore')),
            Expanded(child: _buildNavItem(3, Icons.person, 'Profile')),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      customBorder: const CircleBorder(),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blueAccent : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.grey,
                fontSize: 10,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }


} 