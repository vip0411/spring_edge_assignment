import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freight Rate Search',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF4F6FC),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF686868)),
        ),
      ),
      home: FreightSearchForm(),
    );
  }
}

class FreightSearchForm extends StatefulWidget {
  @override
  _FreightSearchFormState createState() => _FreightSearchFormState();
}

class _FreightSearchFormState extends State<FreightSearchForm> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _boxesController = TextEditingController();
  final TextEditingController _cutOffDateController = TextEditingController();

  String selectedContainerSize = '40\' Standard';
  String? selectedCommodity;
  bool includeBearbyOriginPorts = false;
  bool includeNearbyDestinationPorts = false;
  bool isFCL = false;
  bool isLCL = false;

  List<String> containerSizes = ['20\' Standard', '40\' Standard', '60\' Standard'];
  List<String> commodities = ['General Cargo', 'Hazardous', 'Perishable', 'Electronics'];

  Future<List<String>> fetchSuggestions(String pattern) async {
    if (pattern.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?name=$pattern'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => item['name'].toString()).toList();
      }
    } catch (e) {
      return [
        '$pattern International Port',
        '$pattern Harbor',
        '$pattern Terminal',
        '$pattern Bay'
      ];
    }
    return [];
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Color(0xFF686868)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildLocationField(String label, TextEditingController controller, bool isOrigin) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return await fetchSuggestions(textEditingValue.text);
            },
            onSelected: (String selection) {
              controller.text = selection;
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return Row(
                children: [
                  Image.asset(
                    'assets/location.png',
                    width: 24,
                    height: 24,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: _getInputDecoration(label),
                    ),
                  ),
                ],
              );
            },
          ),
          Theme(
            data: ThemeData(
              checkboxTheme: CheckboxThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            child: CheckboxListTile(
              title: Text(
                'Include nearby ${isOrigin ? "origin" : "destination"} ports',
                style: TextStyle(color: Color(0xFF686868), fontSize: 14),
              ),
              value: isOrigin ? includeBearbyOriginPorts : includeNearbyDestinationPorts,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onChanged: (bool? value) {
                setState(() {
                  if (isOrigin) {
                    includeBearbyOriginPorts = value ?? false;
                  } else {
                    includeNearbyDestinationPorts = value ?? false;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Search the best Freight Rates',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.history, color: Colors.blue),
              label: Text(
                'History',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Color(0xFFF4F6FC),
        child: Card(
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origin and Destination Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationField('Origin', _originController, true),
                    SizedBox(width: 16),
                    _buildLocationField('Destination', _destinationController, false),
                  ],
                ),

                SizedBox(height: 16),

                // Commodity and Cut Off Date Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCommodity,
                        decoration: _getInputDecoration('Commodity'),
                        items: commodities.map((String commodity) {
                          return DropdownMenuItem<String>(
                            value: commodity,
                            child: Text(commodity),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCommodity = newValue;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _cutOffDateController,
                        decoration: _getInputDecoration('Cut Off Date'),
                        readOnly: true,
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              _cutOffDateController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Shipment Type
                Text(
                  'Shipment Type:',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isFCL,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          isFCL = value ?? false;
                        });
                      },
                    ),
                    Text('FCL', style: TextStyle(color: Color(0xFF686868))),
                    SizedBox(width: 24),
                    Checkbox(
                      value: isLCL,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          isLCL = value ?? false;
                        });
                      },
                    ),
                    Text('LCL', style: TextStyle(color: Color(0xFF686868))),
                  ],
                ),

                SizedBox(height: 16),

                // Container Size Dropdown
                DropdownButtonFormField<String>(
                  value: selectedContainerSize,
                  decoration: _getInputDecoration('Container Size'),
                  items: containerSizes.map((String size) {
                    return DropdownMenuItem<String>(
                      value: size,
                      child: Text(size),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedContainerSize = newValue ?? '40\' Standard';
                    });
                  },
                ),

                SizedBox(height: 16),

                // Number of Boxes and Weight
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _boxesController,
                        keyboardType: TextInputType.number,
                        decoration: _getInputDecoration('No of Boxes'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: _getInputDecoration('Weight (Kg)'),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Info text
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Color(0xFF686868)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'To obtain accurate rate for spot rate with guaranteed space and booking, please ensure your container count and weight per container is accurate.',
                          style: TextStyle(
                            color: Color(0xFF686868),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Container Dimensions
                Text(
                  'Container Internal Dimensions:',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Length   39.46ft',
                            style: TextStyle(color: Color(0xFF686868))),
                        SizedBox(height: 4),
                        Text('Width     7.70 ft',
                            style: TextStyle(color: Color(0xFF686868))),
                        SizedBox(height: 4),
                        Text('Height    7.84 ft',
                            style: TextStyle(color: Color(0xFF686868))),
                      ],
                    ),
                    Expanded(
                      child: Container(
                        height: 75,
                        margin: EdgeInsets.only(left: 48),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          margin: EdgeInsets.only(right: 500),
                          child: Image.asset(
                            'assets/container_image.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Search Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        surfaceTintColor: Colors.blue,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Search',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}