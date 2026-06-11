import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/listing.dart';

final _priceFormat = NumberFormat('#,##0.##');

/// "₱1,250 / sack", "₱80 / kg", or "Barter" when the listing has no price.
String listingPriceLabel(Listing listing) {
  if (listing.price == null) return 'Barter / Baylo';
  final price = '₱${_priceFormat.format(listing.price)}';
  return listing.unit == null ? price : '$price / ${listing.unit}';
}

/// One marketplace feed card. Kept image-light (single 72dp thumbnail,
/// faded-in) so the feed scrolls smoothly on low-end devices.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barterable = listing.modes.contains(ListingMode.barter);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(url:
                  listing.photoUrls.isEmpty ? null : listing.photoUrls.first),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
                    Text(
                      listingPriceLabel(listing),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.ownerName} • ${listing.ownerBarangay}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _MiniChip(label: listing.category),
                        if (barterable)
                          _MiniChip(
                            label: 'Open to barter',
                            color: theme.colorScheme.tertiaryContainer,
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
  const _Thumbnail({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 72,
      height: 72,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.agriculture, size: 32),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              width: 72,
              height: 72,
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
  const _MiniChip({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
