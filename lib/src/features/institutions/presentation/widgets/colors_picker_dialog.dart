import 'package:flutter/material.dart';
import 'package:flag_admin_web/src/core/theme/app_colors.dart';
class ColorsPickerDialog extends StatefulWidget {
  final List<String> initial; const ColorsPickerDialog({super.key, required this.initial});
  @override State<ColorsPickerDialog> createState()=>_S();
}
class _S extends State<ColorsPickerDialog>{
  late List<String> colors; final c=TextEditingController();
  @override void initState(){super.initState(); colors=List.from(widget.initial);}
  bool _isHex(String s)=>RegExp(r'^#([0-9a-fA-F]{6})$').hasMatch(s);
  Color _c(String h){return Color(int.parse(h.substring(1),radix:16)+0xFF000000);}
  @override Widget build(BuildContext context){
    return Dialog(shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 8, child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize:MainAxisSize.min, children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[const Text('Cores',style:TextStyle(fontWeight:FontWeight.bold)), IconButton(onPressed:()=>Navigator.pop(context,colors), icon:const Icon(Icons.close))]),
      const SizedBox(height:20),
      Row(children: colors.take(3).map((e)=>Container(width:48,height:48,margin:const EdgeInsets.only(right:8),decoration:BoxDecoration(color:_isHex(e)?_c(e):AppColors.surfaceMuted,shape:BoxShape.circle,border:Border.all(color:Colors.black12)))).toList()),
      const SizedBox(height:20),
      ...colors.asMap().entries.map((e)=>Row(children:[Container(width:24,height:24, decoration:BoxDecoration(color:_isHex(e.value)?_c(e.value):Colors.grey,shape:BoxShape.circle)), const SizedBox(width:8), Expanded(child:Text(e.value)), IconButton(icon:const Icon(Icons.delete),onPressed:(){setState(()=>colors.removeAt(e.key));})])),
      Row(children:[Expanded(child:TextField(controller:c,decoration:const InputDecoration(hintText:'#RRGGBB'))), IconButton(icon:const Icon(Icons.add),onPressed:(){if(colors.length>=6)return; final v=c.text.trim(); if(_isHex(v)){setState(()=>colors.add(v)); c.clear();}})]),
      const SizedBox(height:20),
      FilledButton(onPressed:()=>Navigator.pop(context,colors), child:const Text('Confirmar')),
    ])));
  }
}
