import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Map preview on the listing detail (paper §2.8, §3.4.1, Table 3.2):
/// flutter_map with OpenStreetMap tiles, attribution shown, no API key.
///
/// Only shown when the owner consented to sharing farm GPS (C3), and
/// even then only as an APPROXIMATE area: the point is rounded to about
/// one kilometre and drawn as a circle, never as an exact pin.
class ListingMapPreview extends StatelessWidget {
  const ListingMapPreview({super.key, required this.farm});

  final GeoPoint farm;

  /// Rounds to 2 decimal places (about 1.1 km) so the exact farm spot
  /// is never shown to other users.
  static LatLng approximate(GeoPoint p) => LatLng(
        (p.latitude * 100).roundToDouble() / 100,
        (p.longitude * 100).roundToDouble() / 100,
      );

  @override
  Widget build(BuildContext context) {
    final center = approximate(farm);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Required by the OpenStreetMap tile usage policy.
                  userAgentPackageName: 'com.agrikonek.agrikonek_calinan',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: center,
                      radius: 700,
                      useRadiusInMeter: true,
                      color: scheme.primary.withValues(alpha: 0.2),
                      borderColor: scheme.primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Approximate area only / Gibanabana lang nga lugar',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
