import 'package:flutter/material.dart';

/// Icon and colours for each listing category, so farmers can find
/// produce by picture as well as by word.
class CategoryStyle {
  const CategoryStyle(this.icon, this.background, this.foreground);

  final IconData icon;
  final Color background;
  final Color foreground;

  static const _styles = <String, CategoryStyle>{
    'Fruits': CategoryStyle(
        Icons.local_florist_outlined, Color(0xFFFFE6A8), Color(0xFF7A5200)),
    'Vegetables': CategoryStyle(
        Icons.eco_outlined, Color(0xFFCDEBD3), Color(0xFF1F6B3A)),
    'Poultry & Eggs': CategoryStyle(
        Icons.egg_outlined, Color(0xFFFFF1D6), Color(0xFF8A5F00)),
    'Livestock': CategoryStyle(
        Icons.pets_outlined, Color(0xFFFFDCC8), Color(0xFF8A3F1E)),
    'Compost & By-products': CategoryStyle(
        Icons.compost_outlined, Color(0xFFE9DFCF), Color(0xFF5E4B2E)),
    'Seedlings & Feeds': CategoryStyle(
        Icons.grass_outlined, Color(0xFFDCEFC9), Color(0xFF3F6A1C)),
  };

  static const _other = CategoryStyle(
      Icons.category_outlined, Color(0xFFE5DECD), Color(0xFF4A4F45));

  static CategoryStyle of(String category) => _styles[category] ?? _other;

  /// Cebuano name for a stored category, shown when Cebuano is chosen.
  /// The stored value stays in English.
  static String cebuanoName(String category) => switch (category) {
        'Fruits' => 'Prutas',
        'Vegetables' => 'Utanon',
        'Poultry & Eggs' => 'Manok ug Itlog',
        'Livestock' => 'Hayop',
        'Compost & By-products' => 'Abono ug uban pa',
        'Seedlings & Feeds' => 'Binhi ug Pakaon',
        'Others' => 'Uban pa',
        _ => category,
      };
}

/// Shown where a listing has no photo (common while the project is on the
/// free Firebase tier, which has no photo storage).
class ProducePlaceholder extends StatelessWidget {
  const ProducePlaceholder({
    super.key,
    required this.category,
    this.width,
    this.height,
    this.iconSize = 32,
  });

  final String category;
  final double? width;
  final double? height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category);
    return Container(
      width: width,
      height: height,
      color: style.background,
      alignment: Alignment.center,
      child: Icon(style.icon, size: iconSize, color: style.foreground),
    );
  }
}
