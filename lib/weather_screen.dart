import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather_app/additional_info_item.dart';
import 'package:weather_app/hourly_forcast_item.dart';
import 'package:weather_app/secrets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Future<Map<String, dynamic>> getCurrentWeather() async {
    const String latitude = "39.9523";
    const String longitude = "-75.1638";
    const String uri =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$openWeatherAPIKey";
    try {
      final result = await http.get(Uri.parse(uri));

      final data = jsonDecode(result.body);
      if (data['cod'] != '200') {
        throw "An unexpected connection error occured";
      }

      return data;
    } on Exception catch (e) {
      throw e.toString();
    }
  }

  List<Widget> _getHourlyForcasts(int numCards, Map<String, dynamic> rawData) {
    List<Widget> list = List.empty();
    int maxForecast = rawData['cnt'] - 1;
    if (numCards <= 0) numCards = 1;
    if (numCards > maxForecast) numCards = 5;

    List<Map<String, dynamic>> data = _getWeatherPrediction(numCards, rawData);
    for (var element in data) {
      String time = element['dt_txt'];
      double temp = element['main']['temp'];
      IconData icon = _getWeatherIcon(element['weather']['id']);
      list.add(
        HourlyForcastItem(
          icon: icon,
          temp: temp.toString(),
          time: time,
        ),
      );
    }

    return list;
  }

  List<Map<String, dynamic>> _getWeatherPrediction(
      int numCards, Map<String, dynamic> data) {
    List<Map<String, dynamic>> list = List.empty();
    for (var i = 1; i <= numCards; i++) {
      list.add(data['list'][i]);
    }
    return list;
  }

  IconData _getWeatherIcon(int weatherID) {
    // default
    IconData icon = Icons.error_rounded;
    // Thunderstorms
    if (weatherID >= 200 && weatherID <= 232) {
      icon = Icons.thunderstorm;
    }
    // Drizzle or Rain
    if ((weatherID >= 300 && weatherID <= 321) ||
        (weatherID >= 500 && weatherID <= 531)) {
      icon = Icons.cloudy_snowing;
    }
    // Snow
    if (weatherID >= 600 && weatherID <= 622) {
      icon = Icons.snowing;
    }
    // Clear
    if (weatherID == 800) {
      icon = Icons.sunny;
    }
    // Cloudy
    if (weatherID >= 801 && weatherID <= 804) {
      icon = Icons.cloud;
    }
    return icon;
  }

  String _getTimeFromDTxt(String stringTime) {
    final time = DateTime.parse(stringTime);
    final timeString = DateFormat.Hm().format(time);
    String result = timeString;

    return result;
  }

  @override
  void initState() {
    super.initState();
    getCurrentWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            "Weather App",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            InkWell(
              child: const Icon(Icons.refresh),
              onTap: () {
                setState(() {});
              },
            ),
          ]),
      body: FutureBuilder(
        future: getCurrentWeather(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          final double currentTemp = data['list'][0]['main']['temp'];
          final int currentHumidity = data['list'][0]['main']['humidity'];
          final double currentWindSpeed = data['list'][0]['wind']['speed'];
          final int currentPressure = data['list'][0]['main']['pressure'];
          final String currentSky = data['list'][0]['weather'][0]['main'];
          final int currentWeatherCode = data['list'][0]['weather'][0]['id'];

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main card
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Temperature
                                Text(
                                  "${currentTemp.toStringAsFixed(1)}° K",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Symbol
                                Icon(
                                  _getWeatherIcon(currentWeatherCode),
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                // Weather Text
                                Text(
                                  currentSky,
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Weather Forcast title
                  const Text(
                    "Weather Forcast",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Weather forcast tiles
                  // SingleChildScrollView(
                  //   scrollDirection: Axis.horizontal,
                  //   child: Row(
                  //     children: [
                  //       for (int i = 1; i <= 5; i++)
                  //         HourlyForcastItem(
                  //           icon: _getWeatherIcon(
                  //               data['list'][i]['weather'][0]['id']),
                  //           temp: (data['list'][i]['main']['temp'])
                  //               .toStringAsFixed(1),
                  //           time: (data['list'][i]['dt']).toString(),
                  //         ),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final hourlyForecast = data['list'][index + 1];
                        final hourlySky =
                            _getWeatherIcon(hourlyForecast['weather'][0]['id']);
                        final hourlyTemp =
                            (hourlyForecast['main']['temp']).toStringAsFixed(1);
                        final hourlyTime =
                            _getTimeFromDTxt(hourlyForecast['dt_txt']);
                        return HourlyForcastItem(
                          icon: hourlySky,
                          temp: hourlyTemp,
                          time: hourlyTime,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Additional Information title
                  const Text(
                    "Additional Information",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Additional information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AdditionalInfoItem(
                        icon: Icons.water_drop,
                        label: "Humidity",
                        value: "${currentHumidity.toString()}%",
                      ),
                      AdditionalInfoItem(
                        icon: Icons.air,
                        label: "Wind Speed",
                        value: "${currentWindSpeed.toStringAsFixed(2)} kph",
                      ),
                      AdditionalInfoItem(
                        icon: Icons.beach_access,
                        label: "Pressure",
                        value: "${currentPressure.toString()} N",
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
