import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/theme_notifier.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final List<Color> lightColorOptions = [
    Colors.red[300]!,
    Colors.lightBlueAccent,
    Colors.lightGreenAccent,
    Colors.white,
    Colors.orange[300]!,
    Colors.purple[300]!,
  ];

  final List<Color> darkColorOptions = [
    Colors.red[900]!,
    Colors.blue[900]!,
    Colors.lightGreen[900]!,
    Colors.black,
    Colors.orange[900]!,
    Colors.purple[900]!,
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return ListView(
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
              _buildColorOptions(
                themeNotifier.backgroundColor,
                themeNotifier.foregroundColor,
                themeNotifier.setBackgroundColor,
              ),
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Foreground (Text) Color",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _buildColorOptions(
                themeNotifier.foregroundColor,
                themeNotifier.backgroundColor,
                themeNotifier.setForegroundColor,
              ),
              const SizedBox(height: 16),
            ],
          ),
      ],
    );
  }

  Widget _buildColorOptions(
    Color selectedColor,
    Color disabledColor,
    Function(Color) onColorSelected,
  ) {
    return Column(
      children: [
        _buildColorRow(lightColorOptions, selectedColor, disabledColor, onColorSelected),
        _buildColorRow(darkColorOptions, selectedColor, disabledColor, onColorSelected),
      ],
    );
  }

  Widget _buildColorRow(
    List<Color> colors,
    Color selectedColor,
    Color disabledColor,
    Function(Color) onColorSelected,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors.map((color) {
        final isDisabled = color == disabledColor;

        return GestureDetector(
          onTap: isDisabled ? null : () => onColorSelected(color),
          child: Container(
            margin: const EdgeInsets.all(6),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                width: selectedColor == color ? 3 : 1,
                color: isDisabled ? Colors.grey : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
