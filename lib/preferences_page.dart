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

  // Restored your Gradient Logic
  final List<Gradient> lightGradients = [
    LinearGradient(colors: [Colors.red, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.lightBlue, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.lightGreen, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.white, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.orange[300]!, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.purple[300]!, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
  ];

  final List<Gradient> darkGradients = [
    LinearGradient(colors: [Colors.red[900]!, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.blue[900]!, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Colors.lightGreen[900]!, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Color(0xFF1C1C1C), Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
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
    final colorScheme = Theme.of(context).colorScheme;

    final Gradient selectedBackgroundGradient = themeNotifier.backgroundColor;
    final Color selectedForegroundColor = themeNotifier.foregroundColor;

    // Safely extract the primary (first) color from the gradient to check for clashes with the foreground
    final Color backgroundPrimaryColor = _getPrimaryColor(selectedBackgroundGradient);

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

  // Integrated Colleague's checkmark & shadow styling into your gradients
  Widget _buildGradientRow(
      List<Gradient> gradients,
      Gradient selectedGradient,
      Color disabledColor,
      Function(Gradient) onGradientSelected,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: gradients.map((gradient) {
        final primaryColor = _getPrimaryColor(gradient);
        final isDisabled = primaryColor == disabledColor;
        final isSelected = selectedGradient == gradient;

        return GestureDetector(
          onTap: isDisabled ? null : () => onGradientSelected(gradient),
          child: Container(
            margin: const EdgeInsets.all(6),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              border: Border.all(
                width: isSelected ? 3 : 1,
                color: isDisabled ? Colors.grey : Colors.black,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.45),
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