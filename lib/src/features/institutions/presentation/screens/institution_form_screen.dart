import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/domain.dart';
import '../../../../providers/providers.dart';
import '../widgets/colors_picker_dialog.dart';
class InstitutionFormScreen extends ConsumerStatefulWidget{
  final String? id; const InstitutionFormScreen({super.key,this.id});
  @override ConsumerState<InstitutionFormScreen> createState()=>_S();
}
class _S extends ConsumerState<InstitutionFormScreen>{
  final _form=GlobalKey<FormState>(); String name=''; InstitutionType type=InstitutionType.club; List<String> colors=[]; List<String> selectedOrgs=[];
  @override void initState(){super.initState(); if(widget.id!=null){WidgetsBinding.instance.addPostFrameCallback((_)async{final inst=await ref.read(institutionProvider(widget.id!).future); setState((){name=inst.name; type=inst.type; colors=List.from(inst.colors); selectedOrgs=List.from(inst.organizations);});});}}
  @override Widget build(BuildContext c){
    final orgs=ref.watch(organizationsProvider);
    return Scaffold(appBar:AppBar(title:Text(widget.id==null?'Nova Instituição':'Editar')), body: Form(key:_form, child: ListView(padding:const EdgeInsets.all(16), children:[
      TextFormField(initialValue:name, decoration:const InputDecoration(labelText:'Nome'), validator:(v)=>v==null||v.isEmpty?'Obrigatório':null, onSaved:(v)=>name=v!.trim()),
      DropdownButtonFormField<InstitutionType>(value:type, items: InstitutionType.values.map((e)=>DropdownMenuItem(value:e,child:Text(e.label))).toList(), onChanged:(v)=>setState(()=>type=v!), decoration:const InputDecoration(labelText:'Tipo')),
      const SizedBox(height:16),
      ElevatedButton(onPressed:()async{final res=await showDialog<List<String>>(context:c, builder:(_)=>ColorsPickerDialog(initial:colors)); if(res!=null) setState(()=>colors=res);}, child:const Text('Editar cores')),
      Wrap(children: colors.map((e)=>Container(width:24,height:24,margin:const EdgeInsets.all(4),decoration:BoxDecoration(color:RegExp(r'^#([0-9a-fA-F]{6})$').hasMatch(e)?Color(int.parse(e.substring(1),radix:16)+0xFF000000):Colors.grey,shape:BoxShape.circle))).toList()),
      const SizedBox(height:16), const Text('Organizações (opcional)'),
      orgs.when(data:(list)=>Column(children:list.map((o)=>CheckboxListTile(value:selectedOrgs.contains(o.id), title:Text(o.tradeName), onChanged:(v){setState((){if(v==true)selectedOrgs.add(o.id); else selectedOrgs.remove(o.id);});})).toList()), loading:()=>const CircularProgressIndicator(), error:(e,s)=>Text('$e')),
      const SizedBox(height:16),
      FilledButton(onPressed:()async{if(!_form.currentState!.validate())return; _form.currentState!.save(); final body={'name':name,'type':type.toJson(),'colors':colors}; Institution inst; if(widget.id==null) inst=await ref.read(institutionApiProvider).create(body); else inst=await ref.read(institutionApiProvider).update(widget.id!,body); await ref.read(institutionApiProvider).updateOrganizations(inst.id, selectedOrgs); ref.invalidate(institutionsProvider); if(c.mounted) c.go('/institutions');}, child:const Text('Salvar')),
    ])));
  }
}
