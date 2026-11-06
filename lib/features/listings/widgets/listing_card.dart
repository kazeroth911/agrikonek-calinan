import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/listing.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/widgets/category_style.dart';

final _priceFormat = NumberFormat('#,##0.##');

/// "₱1,250 / sack", "₱80 / kg", or "Barter" when the listing has no price.
String listingPriceLabel(Listing listing,
    [AppLanguage language = AppLanguage.english]) {
  if (listing.price == null) return tr(language, 'Barter', 'Baylo');
  final price = '₱${_priceFormat.format(listing.price)}';
  return listing.unit == null ? price : '$price / ${listing.unit}';
}

/// One marketplace feed card. Kept image-light (one thumbnail, with a
/// category picture when there is no photo) so the feed scrolls smoothly
/// on low-end devices.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barterable = listing.modes.contains(ListingMode.barter);
    final category = CategoryStyle.of(listing.category);
    final cebuano = context.language == AppLanguage.cebuano;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(
                url: listing.photoUrls.isEmpty ? null : listing.photoUrls.first,
                category: listing.category,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listingPriceLabel(listing, context.language),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: listing.price == null
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 15, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${listing.ownerName} · ${listing.ownerBarangay}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniChip(
                          label: cebuano
                              ? CategoryStyle.cebuanoName(listing.category)
                              : listing.category,
                          color: category.background,
                          textColor: category.foreground,
                        ),
                        if (barterable)
                          _MiniChip(
                            icon: Icons.swap_horiz,
                            label: context.tr('Open to barter', 'Pwede i-baylo'),
                            color: theme.colorScheme.tertiaryContainer,
                            textColor: theme.colorScheme.onTertiaryContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.url, required this.category});
  final String? url;
  final String category;

  static const _size = 96.0;

  @override
  Widget build(BuildContext context) {
    final placeholder = ProducePlaceholder(
        category: category, width: _size, height: _size, iconSize: 40);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              // Slow rural connections: keep the card laid out while
              // the image streams in, and never break on a dead URL.
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (context, error, stack) => placeholder,
            ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
