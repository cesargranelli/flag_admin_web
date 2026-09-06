import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/repositories/auth_controller.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
class InstitutionsScreen extends ConsumerWidget{
  const InstitutionsScreen({super.key});
  bool _canWrite(AuthController a){ final r=a.state.user?.role; return r==UserRole.organizer||r==UserRole.manager||r==UserRole.admin||r==UserRole.adminLiga;}
  @override Widget build(BuildContext c, WidgetRef ref){
    final list=ref.watch(institutionsProvider); final auth=ref.watch(authControllerProvider);
    final canWrite=_canWrite(auth); final pending=auth.state.user?.status=='PENDING';
    return Scaffold(appBar:AppBar(title:const Text('Instituições')), floatingActionButton: canWrite&&!pending?FloatingActionButton(onPressed:()=>c.go('/institutions/new'), child:const Icon(Icons.add)):null, body: list.when(data:(d)=>ListView(children:d.map((e)=>ListTile(title:Text(e.name),subtitle:Text(e.type.label),trailing:Container(width:24,height:24,decoration:BoxDecoration(color:e.colors.isNotEmpty?Color(int.parse(e.colors.first.substring(1),radix:16)+0xFF000000):AppColors.surfaceMuted,shape:BoxShape.circle)),onTap:()=>c.go('/institutions/${e.id}/edit'))).toList()), loading:()=>const Center(child:CircularProgressIndicator()), error:(e,s)=>Center(child:Text('$e'))));
  }
}
