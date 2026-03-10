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

  // Updated to LinearGradients fading into white
  final List<Gradient> lightGradients = [
    LinearGradient(colors: [Colors.red, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.lightBlue, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.lightGreen, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.white, Colors.grey], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.orange, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.purple, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
  ];

  // Updated to LinearGradients fading into black
  final List<Gradient> darkGradients = [
    LinearGradient(colors: [Colors.red[900]!, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.blue[900]!, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.lightGreen[900]!, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.black, Colors.blueGrey], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.orange[900]!, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.purple[900]!, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
  ];

  // Helper function to safely extract the first color from any gradient type
  Color _getPrimaryColor(Gradient gradient) {
    if (gradient is RadialGradient) return gradient.colors.first;
    if (gradient is LinearGradient) return gradient.colors.first;
    return Colors.white; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    final Gradient selectedBackgroundGradient = themeNotifier.backgroundColor;
    final Color selectedForegroundColor = themeNotifier.foregroundColor;

    // Safely extract the primary (first) color from the gradient to check for clashes with the foreground
    final Color backgroundPrimaryColor = _getPrimaryColor(selectedBackgroundGradient);

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
                  "Background Gradient",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _buildGradientOptions(
                selectedBackgroundGradient,
                selectedForegroundColor,
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
                selectedForegroundColor,
                backgroundPrimaryColor,
                themeNotifier.setForegroundColor,
              ),
              const SizedBox(height: 16),
            ],
          ),
      ],
    );
  }

  Widget _buildGradientOptions(
      Gradient selectedGradient,
      Color disabledColor,
      Function(Gradient) onGradientSelected,
      ) {
    return Column(
      children: [
        _buildGradientRow(lightGradients, selectedGradient, disabledColor, onGradientSelected),
        _buildGradientRow(darkGradients, selectedGradient, disabledColor, onGradientSelected),
      ],
    );
  }

  Widget _buildGradientRow(
      List<Gradient> gradients,
      Gradient selectedGradient,
      Color disabledColor,
      Function(Gradient) onGradientSelected,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: gradients.map((gradient) {
        // Safely extract the primary color
        final primaryColor = _getPrimaryColor(gradient);
        final isDisabled = primaryColor == disabledColor;

        return GestureDetector(
          onTap: isDisabled ? null : () => onGradientSelected(gradient),
          child: Container(
            margin: const EdgeInsets.all(6),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              border: Border.all(
                width: selectedGradient == gradient ? 3 : 1,
                color: isDisabled ? Colors.grey : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
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