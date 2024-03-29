import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/material.dart';
import 'package:kicko/services/firebase.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kicko/mock_firebase_app_workaround.dart';
import 'package:kicko/professional/ui/professional_home_page.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kicko/get_it_service_locator.dart';
import 'package:kicko/services/app_state.dart';
import 'package:kicko/services/network_image.dart';
import 'utils.dart';

void main() {
  setupFirebaseAuthMocks();
  late DioAdapter dioAdapter;
  late Dio dio;

  setUp(() async {
    await Firebase.initializeApp();
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
    getIt.registerLazySingleton<Dio>(() => dio);
  });

  tearDown(() {
    getIt.unregister<Dio>();
  });

  testWidgets('Professional Home', (WidgetTester tester) async {
    final fakeStorage = MockFirebaseStorage();
    final fakeFirestore = FakeFirebaseFirestore();

    appState.currentUser.id = "5";
    appState.userGroup = "professional";

    dioAdapter
      ..onGet(
          "http://10.0.2.2:5000/api/professional_get_profile/${appState.currentUser.id}",
          (server) {
        server.reply(200, {
          "email": "bachata7@gmail.com",
          "username": "bachata7",
          "firebase_id": "pi1L32q35BMz9y0ay0QgyNrlB8a2",
          "id": "1",
          "image_id": "post_1711277686477.jpg",
        });
      })
      ..onGet(
          "http://10.0.2.2:5000/api/get_business/${appState.currentUser.id}",
          (server) {
        server.reply(
            200, {'id': '1', 'professional_id': '1', 'name': 'kicko corp'});
      })
      ..onGet(
          "http://10.0.2.2:5000/api/professional_get_job_offers/${appState.currentUser.id}",
          (server) {
        server.reply(200, [
          {
            'id': '1',
            'name': 'chargé de recrutements',
            'description': '',
            'requires': 'empathie, bonne gestion des émotions',
            'business_id': '1'
          }
        ]);
      });

    await tester.pumpWidget(
      MultiProvider(providers: [
        Provider<FireBaseServiceInterface>(
            create: (_) => FireBaseService(
                firestore: fakeFirestore, firebaseStorage: fakeStorage)),
        Provider<ImageNetworkServiceInterface>(
          create: (_) => MockImageNetworkService(),
        ),
      ], child: MaterialApp(home: ProHome())),
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();

    expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is Text && widget.data!.contains('Error'),
        ),
        findsNothing);
  });
}
