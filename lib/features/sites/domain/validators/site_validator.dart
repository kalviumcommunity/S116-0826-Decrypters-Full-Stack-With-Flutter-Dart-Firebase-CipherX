import '../entities/site.dart';
import '../failures/site_failure.dart';

class SiteValidator {
  static String? validateOrganizationId(String organizationId) {
    if (organizationId.trim().isEmpty) {
      return 'Organization ID cannot be empty.';
    }
    return null;
  }

  static String? validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Site name cannot be empty.';
    }
    return null;
  }

  static String? validateAddress(String address) {
    if (address.trim().isEmpty) {
      return 'Site address cannot be empty.';
    }
    return null;
  }

  static String? validateLatitude(double latitude) {
    if (!latitude.isFinite) {
      return 'Latitude must be a finite number.';
    }
    if (latitude < -90.0 || latitude > 90.0) {
      return 'Latitude must be between -90 and 90 degrees.';
    }
    return null;
  }

  static String? validateLongitude(double longitude) {
    if (!longitude.isFinite) {
      return 'Longitude must be a finite number.';
    }
    if (longitude < -180.0 || longitude > 180.0) {
      return 'Longitude must be between -180 and 180 degrees.';
    }
    return null;
  }

  static String? validateGeofenceRadius(double geofenceRadius) {
    if (!geofenceRadius.isFinite) {
      return 'Geofence radius must be a finite number.';
    }
    if (geofenceRadius <= 0) {
      return 'Geofence radius must be greater than 0 meters.';
    }
    return null;
  }

  /// Normalizes string fields (trims name and address)
  static Site normalize(Site site) {
    return site.copyWith(
      organizationId: site.organizationId.trim(),
      name: site.name.trim(),
      address: site.address.trim(),
    );
  }

  /// Validates all fields of [site]. Throws [SiteValidationFailure] if invalid.
  /// Returns normalized [Site] if valid.
  static Site validate(Site site) {
    final orgErr = validateOrganizationId(site.organizationId);
    if (orgErr != null) throw SiteValidationFailure(orgErr);

    final nameErr = validateName(site.name);
    if (nameErr != null) throw SiteValidationFailure(nameErr);

    final addrErr = validateAddress(site.address);
    if (addrErr != null) throw SiteValidationFailure(addrErr);

    final latErr = validateLatitude(site.latitude);
    if (latErr != null) throw SiteValidationFailure(latErr);

    final lngErr = validateLongitude(site.longitude);
    if (lngErr != null) throw SiteValidationFailure(lngErr);

    final radiusErr = validateGeofenceRadius(site.geofenceRadius);
    if (radiusErr != null) throw SiteValidationFailure(radiusErr);

    return normalize(site);
  }
}
