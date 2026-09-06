import '../enums/institution_type.dart';
class Institution {
  final String id; final String name; final InstitutionType type; final List<String> colors; final List<String> organizations; final String? status; final DateTime? createdAt;
  const Institution({required this.id,required this.name,required this.type, this.colors=const[],this.organizations=const[],this.status,this.createdAt});
  factory Institution.fromJson(Map<String,dynamic> j)=>Institution(id:j['id'] as String,name:j['name'] as String,type:InstitutionType.fromJson(j['type'] as String),colors:(j['colors'] as List?)?.cast<String>()??[],organizations:(j['organizations'] as List?)?.cast<String>()??[],status:j['status'] as String?,createdAt:j['createdAt'] is String?DateTime.tryParse(j['createdAt'] as String):null);
  Map<String,dynamic> toJson()=>{'name':name,'type':type.toJson(),'colors':colors,'organizations':organizations};
}
