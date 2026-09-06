import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/providers.dart';
class InstitutionDetailScreen extends ConsumerWidget{
  final String id; const InstitutionDetailScreen({super.key,required this.id});
  @override Widget build(BuildContext c, WidgetRef ref){
    final a=ref.watch(institutionProvider(id));
    return Scaffold(appBar:AppBar(title:const Text('Instituição')), body: a.when(data:(d)=>ListView(padding:const EdgeInsets.all(16), children:[Text(d.name,style:const TextStyle(fontSize:20)), Text(d.type.label), Wrap(children:d.colors.map((e)=>Container(width:24,height:24,margin:const EdgeInsets.all(4),decoration:BoxDecoration(color:Color(int.parse(e.substring(1),radix:16)+0xFF000000),shape:BoxShape.circle))).toList())]), loading:()=>const Center(child:CircularProgressIndicator()), error:(e,s)=>Center(child:Text('$e'))));
  }
}
