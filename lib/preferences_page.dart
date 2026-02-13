import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/theme_notifier.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final List<Color> colorOptions = [
    Colors.red,
    Colors.blue,
    Colors.lightGreenAccent,
    Colors.black,
    Colors.white,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Preferences")),
      body: ListView(
        children: [
          RadioListTile<ThemeType>(
            title: const Text("Light Mode"),
            value: ThemeType.light,
            groupValue: themeNotifier.themeType,
            onChanged: (_) => themeNotifier.setLightMode(),
          ),
          RadioListTile<ThemeType>(
            title: const Text("Dark Mode"),
            value: ThemeType.dark,
            groupValue: themeNotifier.themeType,
            onChanged: (_) => themeNotifier.setDarkMode(),
          ),
          RadioListTile<ThemeType>(
            title: const Text("Advanced"),
            value: ThemeType.advanced,
            groupValue: themeNotifier.themeType,
            onChanged: (_) => themeNotifier.setAdvancedMode(),
          ),
          if (themeNotifier.themeType == ThemeType.advanced)
            ExpansionTile(
              title: const Text("Advanced Color Options"),
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "Background Color",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Wrap(
                  children: colorOptions.map((color) {
                    final isDisabled = color == themeNotifier.foregroundColor;

                    return GestureDetector(
                      onTap: isDisabled
                          ? null
                          : () => themeNotifier.setBackgroundColor(color),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: themeNotifier.backgroundColor == color ? 3 : 1,
                            color: isDisabled ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "Foreground (Text) Color",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Wrap(
                  children: colorOptions.map((color) {
                    final isDisabled = color == themeNotifier.backgroundColor;

                    return GestureDetector(
                      onTap: isDisabled
                          ? null
                          : () => themeNotifier.setForegroundColor(color),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: themeNotifier.foregroundColor == color ? 3 : 1,
                            color: isDisabled ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}