import 'package:flutter/material.dart';

import 'package:kicko/appbar.dart';
import 'package:kicko/end_point.dart';
import 'package:kicko/services/app_state.dart';

import 'package:kicko/shared/domain/chat.dart';

import 'package:kicko/professional/domain/professional_home_logic.dart';
import 'package:kicko/styles/professional_home_style.dart';
import 'package:kicko/mixins/ui/block.dart';

class ProfessionalJobOfferPage extends StatefulWidget {
  final String jobOfferId;
  const ProfessionalJobOfferPage({Key? key, required this.jobOfferId})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ProfessionalJobOfferPage();
  }
}

class _ProfessionalJobOfferPage extends State<ProfessionalJobOfferPage> {
  Map<String, dynamic> jobOfferFilters = {"city": TextEditingController()};
  ProfessionalHomeLogic logic = ProfessionalHomeLogic();
  ProfessionalHomeStyle style = ProfessionalHomeStyle();
  String userId = appState.currentUser.id;
  late Future<Map> jobOffer;
  late Future<List> appliers;
  late Future<Map> candidateSyntax;

  Map<String, dynamic> appliersFilterJson = {};
  Map<String, dynamic> appliersFilterJsonDropDown = {};

  onReBuild() {
    appliers = postRequest(
        "professional_get_appliers", [widget.jobOfferId], appliersFilterJson);
  }

  @override
  void initState() {
    super.initState();
    candidateSyntax = getRequest("get_candidate_syntax", []);
    jobOffer = getRequest<Map>("candidate_get_job_offer", [widget.jobOfferId]);
    onReBuild();
  }

  Widget buildJobOffer() {
    return FutureBuilder<Map<dynamic, dynamic>>(
      future: jobOffer,
      builder: (BuildContext context,
          AsyncSnapshot<Map<dynamic, dynamic>> snapshot) {
        Widget body;
        if (snapshot.hasData) {
          Map _jobOffer = snapshot.data!;

          dynamic _block = block([
            _jobOffer['name'],
            _jobOffer['description'],
            _jobOffer['requires']
          ]);

          body = Center(
            child: Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                child: ListView(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  children: _block,
                ),
              ),
            ),
          );
          // body = listView;
        } else if (snapshot.hasError) {
          body = Text('Error: ${snapshot.error}');
        } else {
          body = const Text('Awaiting result...');
        }
        return Scaffold(body: body);
      },
    );
  }

  Widget buildDropDown(String key, List<dynamic> list, String dropdownValue) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Color.fromARGB(255, 10, 24, 229)),
      underline: Container(
        height: 2,
        color: Color.fromARGB(255, 7, 59, 231),
      ),
      onChanged: (String? value) {
        setState(() {
          appliersFilterJson[key] = value;
          appliersFilterJsonDropDown[key] = value;
        });
      },
      items: list.map<DropdownMenuItem<String>>((dynamic value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget buildAppliers() {
    return FutureBuilder<List>(
      future: Future.wait([appliers, candidateSyntax]),
      builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
        Widget body;
        if (snapshot.hasData) {
          Widget filters;
          Widget appliers;

          List _appliers = snapshot.data![0];
          Map _candidateSyntax = snapshot.data![1];

          List<Widget> dropDownButtons = [];
          for (String key in _candidateSyntax.keys) {
            if (appliersFilterJsonDropDown.containsKey(key)) {
              appliersFilterJson[key] = appliersFilterJsonDropDown[key];
            } else {
              appliersFilterJson[key] = "";
            }
            dropDownButtons.add(
              buildDropDown(
                  key, _candidateSyntax[key], appliersFilterJson[key]),
            );
          }

          filters = Column(
            children: dropDownButtons +
                [
                  TextButton(
                      onPressed: () async {
                        setState(() {
                          onReBuild();
                        });
                      },
                      child: const Text("Appliquer filtres",
                          style: TextStyle(
                              color: Color.fromARGB(255, 10, 24, 229))))
                ],
          );

          if (_appliers.isNotEmpty) {
            appliers = ListView.builder(
              itemCount: _appliers.length,
              itemBuilder: (context, index) {
                final _applier = _appliers[index];
                return ListView(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  children: <Widget>[
                    ...block([
                      _applier['username'],
                      _applier['study_level'],
                      _applier['sex']
                    ]),
                    IconButton(
                      icon: Icon(Icons.message),
                      onPressed: () {
                        sendMessage(context, _applier["username"]);
                      },
                    ),
                  ],
                );
              },
            );
          } else {
            appliers = const Text(
                "Aucun candidat n'a encore postulé à cette offre ou ne correspond à vos critères de recherche.");
          }

          body = Center(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: filters,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: appliers,
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          body = Text('Error: ${snapshot.error}');
        } else {
          body = const Text('Awaiting result...');
        }
        return Scaffold(body: body);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: simpleAppBar(context),
        body: Center(
          child: Column(
            children: [
              Flexible(child: buildJobOffer()),
              Flexible(child: buildAppliers())
            ],
          ),
        ));
  }
}
