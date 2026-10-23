/// Domain constants shared across features.
class AppConstants {
  AppConstants._();

  /// Firestore collection names — single source of truth.
  static const colProfiles = 'profiles';
  static const colListings = 'listings';
  static const colOffers = 'offers';
  static const colBarterProposals = 'barterProposals';
  static const colConversations = 'conversations';
  static const colMessages = 'messages'; // subcollection of conversations
  static const colNotifications = 'notifications';
  static const colDeviceTokens = 'deviceTokens';

  /// Roles supported by the multi-role account model.
  static const roleSeller = 'seller';
  static const roleBuyer = 'buyer';
  static const roleTrader = 'trader';
  static const roleAdmin = 'admin';
  static const allRoles = [roleSeller, roleBuyer, roleTrader, roleAdmin];

  /// Calinan District barangays for the profiling form dropdown.
  /// Verify/extend this list during barangay coordination.
  static const calinanBarangays = <String>[
    'Calinan Poblacion',
    'Wangan',
    'Riverside',
    'Lamanan',
    'Tamayong',
    'Cawayan',
    'Dacudao',
    'Dalagdag',
    'Dominga',
    'Inayangan',
    'Lacson',
    'Megkawayan',
    'Pangyan',
    'Saloy',
    'Sirib',
    'Subasta',
    'Talomo River',
    'Wines',
  ];

  /// Listing categories for the marketplace feed (Sprint 2).
  static const listingCategories = <String>[
    'Fruits',
    'Vegetables',
    'Poultry & Eggs',
    'Livestock',
    'Compost & By-products',
    'Seedlings & Feeds',
    'Others',
  ];

  /// Selling units common to Calinan farm produce (post-listing form).
  static const listingUnits = <String>[
    'kg',
    'sack',
    'tray',
    'dozen',
    'piece',
    'bundle',
    'head',
    'liter',
  ];

  /// Photo cap per listing — keeps uploads cheap on rural data plans
  /// and Storage usage well inside the free-tier budget.
  static const maxListingPhotos = 4;

  /// Marketplace feed page size. The pilot cohort is small (~dozens of
  /// listings) so one capped query keeps Firestore reads predictable.
  static const feedQueryLimit = 100;

  /// Cloud Storage folder roots.
  static const storageListingsFolder = 'listings';
  static const storageProfilesFolder = 'profiles';
}
