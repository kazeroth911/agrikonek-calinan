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
  static const colAnnouncements = 'announcements';
  static const colCooperatives = 'cooperatives';

  /// IDs of hidden profiles. Readable by every signed-in user so the app
  /// can filter the marketplace, while the hidden profiles themselves
  /// are readable only by their owner and admins.
  static const colHiddenProfiles = 'hiddenProfiles';

  /// Phone sign-in with profile claiming (paper §3.5.4). On by default:
  /// a phone-verified account takes over the researcher-prepared profile
  /// with the same number. Build with --dart-define=ENABLE_OTP=false to
  /// hide it again (for example, while only email accounts are tested).
  static const enableOtpSignIn =
      bool.fromEnvironment('ENABLE_OTP', defaultValue: true);

  /// Shown wherever a hidden profile would otherwise appear.
  static const profileUnavailable = 'This profile is unavailable.';
  static const profileUnavailableCeb = 'Dili na makita kini nga profile.';

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
