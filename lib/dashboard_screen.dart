import 'package:flutter/material.dart';
import 'websocket_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // Import Syncfusion Chart

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WebSocketService _webSocketService = WebSocketService();
  List<_EnergyData> _energyData = [];
  late ChartSeriesController _chartController;

  // Variables pour stocker les données avec des valeurs par défaut
  double temperature = 20.0;
  double humidity = 50.0;
  double luminosity = 90.0;
  double totalEnergy = 0.0;
  double peakPower = 0.0;
  double current = 0.0;
  double voltage = 0.0;
  double batteryLevel = 75.0; // Valeur par défaut pour le niveau de batterie
  String controlMode = 'Auto';
  int fanSpeed = 50;
  bool lamp1State = false;
  bool lamp2State = false;
  bool lamp3State = false;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _energyData.add(_EnergyData(DateTime.now(), 0, 0, 0)); // Initial data
  }

  void _initializeWebSocket() {
    _webSocketService.connect();
    _webSocketService.stream.listen((message) {
      setState(() {
        isLoading = false;
        errorMessage = '';
        temperature = message['temperature'] ?? temperature;
        humidity = message['humidity'] ?? humidity;
        luminosity = message['lux'] ?? luminosity;
        totalEnergy = message['energy']['totalEnergy'] ?? totalEnergy;
        peakPower = message['energy']['peakPower'] ?? peakPower;
        current = message['energy']['current'] ?? current;
        voltage = message['energy']['voltage'] ?? voltage;
        batteryLevel = message['battery']['level'] ?? batteryLevel; // Ajout du niveau de batterie
        fanSpeed = message['manual']['fanSpeed'] ?? fanSpeed;
        lamp1State = message['manual']['lamp1State'] ?? lamp1State;
        lamp2State = message['manual']['lamp2State'] ?? lamp2State;
        lamp3State = message['manual']['lamp3State'] ?? lamp3State;
        controlMode = message['settings']['autoMode'] ? 'Auto' : 'Manual';

        _updateChartData(); // Mise à jour des données du graphique
      });
    }, onError: (error) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur de connexion. Tentative de reconnexion...';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: _initializeWebSocket,
        ),
      ));
    });
  }

  void _updateChartData() {
    _energyData.add(_EnergyData(DateTime.now(), totalEnergy, voltage, current));
    if (_energyData.length > 20) {
      _energyData.removeAt(0); // Limite les données à 20 points
    }
    _chartController.updateDataSource(addedDataIndex: _energyData.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Smart Control'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            isLoading = true;
            errorMessage = '';
          });
          _initializeWebSocket();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildEnergyChartCard(), // Nouveau card pour affichage du graphique
                _buildStatusCards(),
                _buildFanControlCard(),
                _buildLampControlCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyChartCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 8.0,
      margin: EdgeInsets.symmetric(vertical: 1.0),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          children: [
            Text(
              'Consommation Énergétique en Temps Réel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SfCartesianChart(
              primaryXAxis: DateTimeAxis(),
              series: <ChartSeries<_EnergyData, DateTime>>[
                LineSeries<_EnergyData, DateTime>(
                  dataSource: _energyData,
                  xValueMapper: (_EnergyData data, _) => data.time,
                  yValueMapper: (_EnergyData data, _) => data.energy,
                  name: 'Wh',
                  color: Colors.blue,
                  onRendererCreated: (ChartSeriesController controller) {
                    _chartController = controller;
                  },
                ),
                LineSeries<_EnergyData, DateTime>(
                  dataSource: _energyData,
                  xValueMapper: (_EnergyData data, _) => data.time,
                  yValueMapper: (_EnergyData data, _) => data.voltage,
                  name: 'V',
                  color: Colors.green,
                ),
                LineSeries<_EnergyData, DateTime>(
                  dataSource: _energyData,
                  xValueMapper: (_EnergyData data, _) => data.time,
                  yValueMapper: (_EnergyData data, _) => data.current,
                  name: 'A',
                  color: Colors.red,
                ),
              ],
              legend: Legend(isVisible: true),
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 8.0,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildArcProgress("Température", temperature.toStringAsFixed(1), "°C", Colors.blue),
            _buildArcProgress("Humidité", humidity.toStringAsFixed(1), "%", Colors.blue),
            _buildArcProgress("Lumière", luminosity.toStringAsFixed(1), "%", Colors.blue),
            _buildArcProgress("Batterie", batteryLevel.toStringAsFixed(1), "%", Colors.orange), // Nouvelle colonne pour le niveau de batterie
          ],
        ),
      ),
    );
  }

  Widget _buildArcProgress(String title, String progress, String suffix, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          value: double.parse(progress) / 100,
          backgroundColor: Colors.grey[300],
          color: color,
          strokeWidth: 6.0,
        ),
        SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          "$progress$suffix",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFanControlCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 7.0,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFanImage(),
                _buildFanSpeedInfo(),
                _buildFanControls(),
              ],
            ),
            _buildFanSpeedSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildFanImage() {
    return Column(
      children: [
        Image.asset(
          'assets/images/ic_star_128.png',
          width: 100,
          height: 100,
        ),
        Text(
          'État',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFanSpeedInfo() {
    return Column(
      children: [
        Text('Température', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text('${temperature.toStringAsFixed(1)} °C', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text('Vitesse', style: TextStyle(fontSize: 14)),
        Text('$fanSpeed%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ],
    );
  }

  Widget _buildFanControls() {
    return Column(
      children: [
        Text('Mode Auto', style: TextStyle(fontWeight: FontWeight.bold)),
        Switch(
          value: controlMode == 'Auto',
          onChanged: (value) {
            setState(() {
              controlMode = value ? 'Auto' : 'Manual';
            });
          },
        ),
        ElevatedButton(
          onPressed: () {},
          child: Text('Basculer'),
        ),
      ],
    );
  }

  Widget _buildFanSpeedSlider() {
    return Slider(
      value: fanSpeed.toDouble(),
      min: 1,
      max: 100,
      divisions: 99,
      label: fanSpeed.toString(),
      onChanged: (value) {
        setState(() {
          fanSpeed = value.toInt();
          _webSocketService.send({"fanSpeed": fanSpeed});
        });
      },
    );
  }

  Widget _buildLampControlCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 7.0,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLampControl('Lumière 1', lamp1State, (value) {
              setState(() {
                lamp1State = value;
                _webSocketService.send({"lamp1State": lamp1State});
              });
            }),
            _buildLampControl('Lumière 2', lamp2State, (value) {
              setState(() {
                lamp2State = value;
                _webSocketService.send({"lamp2State": lamp2State});
              });
            }),
            _buildLampControl('Lumière 3', lamp3State, (value) {
              setState(() {
                lamp3State = value;
                _webSocketService.send({"lamp3State": lamp3State});
              });
            }),
            _buildLedModeControls()
          ],
        ),
      ),
    );
  }

  Widget _buildLedModeControls() {
    return Column(
      children: [
        Text('Mode Auto', style: TextStyle(fontWeight: FontWeight.bold)),
        Switch(
          value: controlMode == 'Auto',
          onChanged: (value) {
            setState(() {
              controlMode = value ? 'Auto' : 'Manual';
            });
          },
        ),
        ElevatedButton(
          onPressed: () {},
          child: Text('Basculer'),
        ),
      ],
    );
  }

  Widget _buildLampControl(String title, bool state, Function(bool) onChanged) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
        GestureDetector(
          onTap: () {
            onChanged(!state);
          },
          child: Image.asset(
            state ? 'assets/images/lamp_on.png' : 'assets/images/lamp_off.png',
            width: 60,
            height: 100,
          ),
        ),
        Switch(
          value: state,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _EnergyData {
  _EnergyData(this.time, this.energy, this.voltage, this.current);
  final DateTime time;
  final double energy;
  final double voltage;
  final double current;
}
