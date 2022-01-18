import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:websafe_svg/websafe_svg.dart';
import 'package:http/http.dart' as http;

main() => runApp(MyApp());

Future<String> getJson(jsonName) {
  return rootBundle.loadString('assets/' + jsonName + '.json');
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var questionIndex = 0;
  var questionsCount = 0;
  var succesQuestionsCount = 0;
  var errorQuestionsCount = 0;
  List countryByCity = [];
  List cities = [];

  void getCountries() async {
    var res = await json.decode(await getJson('country_by_city'));
    setState(() {
      countryByCity = res;
      questionsCount = countryByCity.length;
      setCities();
    });
  }

  void setCities() {
    cities.clear();

    setCity(questionIndex);
    for (var i = 0; i < 3; i++) {
      setCity(getRandomIndex(countryByCity.length));
    }
    cities.shuffle();
  }

  void setCity(index) async {
    var cityName = countryByCity[index]['city'];

    final response = await http.get(
        Uri.parse(
            'https://api.weatherapi.com/v1/current.json?key=2f21a9b719db41ad849151311221301&q=' +
                cityName.toLowerCase()),
        headers: {HttpHeaders.accessControlAllowHeadersHeader: '*'});

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      setState(() {
        cities.add({'name': cityName, 'weather': data['current']['temp_c']});
      });
    } else {
      setState(() {
        cities.add({'name': cityName, 'weather': null});
      });
    }
  }

  int getRandomIndex(length) {
    Random random = Random();
    return random.nextInt(length);
  }

  void shuffleCountries() {
    setState(() {
      countryByCity.shuffle();
    });
  }

  void answerQuiestion(answerName) {
    setState(() {
      if (answerName == countryByCity[questionIndex]['city']) {
        succesQuestionsCount += 1;
      } else {
        errorQuestionsCount += 1;
      }

      if (countryByCity.length - 1 == questionIndex) {
        questionIndex = 0;
      } else {
        questionIndex += 1;
      }

      setCities();
    });
  }

  @override
  void initState() {
    super.initState();
    getCountries();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Capital Quiz'),
          actions: [
            Row(
              children: [
                const Icon(
                  Icons.how_to_vote,
                  color: Colors.black,
                ),
                Text(
                  questionsCount.toString(),
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(
                  width: 20,
                ),
                const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                ),
                Text(
                  succesQuestionsCount.toString(),
                  style: const TextStyle(
                      color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  width: 20,
                ),
                const Icon(
                  Icons.error,
                  color: Colors.redAccent,
                ),
                Text(
                  errorQuestionsCount.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(
                  width: 50,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Shuffle countries',
                  onPressed: () => shuffleCountries(),
                ),
              ],
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: RichText(
                    text: TextSpan(
                        style: const TextStyle(fontSize: 20),
                        children: [
                      const TextSpan(text: 'What\'s Capital of '),
                      TextSpan(
                        text: (countryByCity.isNotEmpty
                            ? countryByCity[questionIndex]['country']
                            : ''),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' ?'),
                    ])),
              ),
              Image.network(
                'https://countryflagsapi.com/png/' +
                    (countryByCity.isNotEmpty
                        ? countryByCity[questionIndex]['country']
                        : ''),
                width: 200.0,
                height: 140.0,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200.0,
                  height: 140.0,
                  color: Colors.black54,
                ),
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
              Expanded(
                flex: 8,
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 30.0,
                    runSpacing: 20.0,
                    children: cities.isNotEmpty
                        ? cities
                            .map(
                              (city) => ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(20.0),
                                  primary: (Colors.yellowAccent),
                                  onPrimary: Colors.black,
                                  elevation: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      city['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          city['weather'] != null
                                              ? ((city['weather'] > 0
                                                      ? '+'
                                                      : '-') +
                                                  city['weather'].toString())
                                              : '',
                                          style: TextStyle(
                                            color: city['weather'] != null
                                                ? (city['weather'] > 0
                                                    ? Colors.orange
                                                    : Colors.blue)
                                                : Colors.grey,
                                          ),
                                        ),
                                        Icon(
                                          Icons.device_thermostat,
                                          color: city['weather'] != null
                                              ? (city['weather'] > 0
                                                  ? Colors.orange
                                                  : Colors.blue)
                                              : Colors.grey,
                                        ),
                                        WebsafeSvg.asset(
                                          'assets/city.svg',
                                          width: 20.0,
                                          height: 20.0,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onPressed: () => answerQuiestion(city['name']),
                              ),
                            )
                            .toList()
                        : [
                            for (int i = 0; i < 4; i++)
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(30.0),
                                      primary: (Colors.yellowAccent),
                                      onPrimary: Colors.black,
                                      elevation: 10),
                                  child: Row(
                                    children: [],
                                  ),
                                  onPressed: () => {}),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
