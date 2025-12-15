// import 'package:enmkit/viewmodels/smsViewmodel.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';


// class SmsListenerPage extends StatelessWidget {
//   const SmsListenerPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => SmsListenerViewModel(),
//       child: Scaffold(
//         appBar: AppBar(title: const Text("Écoute SMS filtré")),
//         body: Consumer<SmsListenerViewModel>(
//           builder: (context, vm, child) {
//             return Center(
//               child: Text(
//                 vm.lastSms,
//                 style: const TextStyle(fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
