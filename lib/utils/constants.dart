/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const appName = 'SLAtrix';
  static const brandLabel = 'SLA Tracker';

  static const databaseName = 'slatrix.db';
  static const databaseVersion = 1;

  /// A task becomes At Risk once 75% of its planned lifecycle has elapsed.
  static const atRiskThreshold = 0.75;

  static const minTitleLength = 3;
  static const maxTitleLength = 80;
  static const maxDescriptionLength = 500;

  static const recentWorkLimit = 3;
}
