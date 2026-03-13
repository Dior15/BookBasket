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
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Customize your reading experience',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
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
              ],
            ),
          ),
        ),
        if (themeNotifier.themeType == ThemeType.advanced)
          Card(
            child: ExpansionTile(
              initiallyExpanded: true,
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
          ),
        const SizedBox(height: 10),
        Text(
          'Theme changes are saved automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
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
        final isSelected = selectedColor == color;

        return GestureDetector(
          onTap: isDisabled ? null : () => onColorSelected(color),
          child: Container(
            margin: const EdgeInsets.all(6),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                width: isSelected ? 3 : 1,
                color: isDisabled ? Colors.grey : Colors.black,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
