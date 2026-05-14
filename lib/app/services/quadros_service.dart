import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quadro_model.dart';

class QuadrosService {
  final CollectionReference<Map<String, dynamic>> _quadrosRef =
      FirebaseFirestore.instance.collection('quadros');

  Future<void> salvarQuadro(Quadro quadro) async {
    final data = quadro.toJson()
      ..remove('id')
      ..['criadoEm'] = DateTime.now().toIso8601String();

    await _quadrosRef.add(data);
  }

  Future<List<Quadro>> listarQuadros() async {
    final consulta = _quadrosRef.orderBy('criadoEm', descending: true);
    final snapshot = await consulta.get();

    return snapshot.docs.map((doc) {
      return Quadro.fromJson({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();
  }
}
