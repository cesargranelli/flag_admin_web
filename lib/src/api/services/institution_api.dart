import 'package:flag_admin_web/src/domain/models/institution.dart';
import '../api_client.dart';
class InstitutionApi {
  final ApiClient _c; InstitutionApi(this._c);
  Future<List<Institution>> list()=>_c.getList('/api/v1/institutions', Institution.fromJson);
  Future<Institution> getById(String id)=>_c.getOne('/api/v1/institutions/$id', Institution.fromJson);
  Future<Institution> create(Map<String,dynamic> body)=>_c.post('/api/v1/institutions', body, Institution.fromJson);
  Future<Institution> update(String id, Map<String,dynamic> body)=>_c.put('/api/v1/institutions/$id', body, Institution.fromJson);
  Future<void> delete(String id)=>_c.delete('/api/v1/institutions/$id');
  Future<void> updateOrganizations(String id, List<String> orgIds)=>_c.put('/api/v1/institutions/$id/organizations', {'organizationIds': orgIds}, (j)=>j);
}
