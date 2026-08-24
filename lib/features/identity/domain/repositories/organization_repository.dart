import '../entities/organization.dart';

abstract class OrganizationRepository {
  Future<Organization?> getOrganizationById(String id);
  Future<Organization?> getOrganizationByCode(String code);
}
