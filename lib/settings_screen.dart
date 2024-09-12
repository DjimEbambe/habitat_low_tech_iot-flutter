import 'package:flutter/material.dart';
import 'websocket_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final WebSocketService _webSocketService = WebSocketService();

  // Variables pour les paramètres
  String ssid = '';
  String password = '';
  double kp = 2.0, ki = 5.0, kd = 1.0;
  double setpointTemp = 25.0, setpointLux = 300.0;
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _webSocketService.connect();
    _webSocketService.stream.listen((message) {
      setState(() {
        isLoading = false;
        errorMessage = '';
        ssid = message['settings']['ap_ssid'];
        password = message['settings']['ap_password'];
        kp = message['settings']['Kp'];
        ki = message['settings']['Ki'];
        kd = message['settings']['Kd'];
        setpointTemp = message['settings']['setpointTemp'];
        setpointLux = message['settings']['setpointLux'];
      });
    }, onError: (error) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur lors de la réception des données.';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: () {
            setState(() {
              isLoading = true;
              errorMessage = '';
            });
            _connectWebSocket(); // Appelle maintenant la bonne méthode
          },
        ),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configurations')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField('SSID', ssid, (value) => ssid = value),
            _buildTextField('Password', password, (value) => password = value, obscureText: true),
            _buildSlider('Kp', kp, 0, 10, (value) => kp = value),
            _buildSlider('Ki', ki, 0, 10, (value) => ki = value),
            _buildSlider('Kd', kd, 0, 10, (value) => kd = value),
            _buildSlider('Consigne Température', setpointTemp, 0, 40, (value) => setpointTemp = value),
            _buildSlider('Consigne Luminosité', setpointLux, 0, 1000, (value) => setpointLux = value),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = '';
                });
                _webSocketService.send({
                  "ap_ssid": ssid,
                  "ap_password": password,
                  "Kp": kp,
                  "Ki": ki,
                  "Kd": kd,
                  "setpointTemp": setpointTemp,
                  "setpointLux": setpointLux,
                });
              },
              child: Text('Enregistrer les paramètres'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue, Function(String) onChanged, {bool obscureText = false}) {
    return TextField(
      decoration: InputDecoration(labelText: label),
      controller: TextEditingController(text: initialValue),
      onChanged: onChanged,
      obscureText: obscureText,
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 18)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          label: value.toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
