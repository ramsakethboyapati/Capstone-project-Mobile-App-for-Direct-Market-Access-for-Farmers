import 'package:flutter/material.dart';

class CropSuggestionPage extends StatefulWidget {
  const CropSuggestionPage({super.key});

  @override
  State<CropSuggestionPage> createState() => _CropSuggestionPageState();
}

class _CropSuggestionPageState extends State<CropSuggestionPage> {
  double ph = 6.5;
  String water = 'Medium';
  String district = 'Hyderabad';
  String season = 'Kharif';

  List<Map<String, dynamic>> suggestedCrops = [];

  final List<Map<String, dynamic>> crops = [
    {
      "crop": "Wheat",
      "minPh": 6.0,
      "maxPh": 7.5,
      "water": "Medium",
      "districts": ["Hyderabad", "Nizamabad"],
      "season": ["Rabi"]
    },
    {
      "crop": "Rice",
      "minPh": 5.5,
      "maxPh": 7.0,
      "water": "High",
      "districts": ["Hyderabad", "Warangal"],
      "season": ["Kharif"]
    },
    {
      "crop": "Maize",
      "minPh": 5.5,
      "maxPh": 7.5,
      "water": "Medium",
      "districts": ["Hyderabad", "Karimnagar"],
      "season": ["Kharif", "Rabi"]
    },
  ];

  void suggestCrops() {
    List<Map<String, dynamic>> suggestions = [];
    for (var crop in crops) {
      if (ph >= crop['minPh'] &&
          ph <= crop['maxPh'] &&
          crop['water'] == water &&
          crop['districts'].contains(district) &&
          crop['season'].contains(season)) {
        suggestions.add(crop);
      }
    }
    setState(() {
      suggestedCrops = suggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Suggestion"),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Soil pH: "),
                Expanded(
                  child: Slider(
                    value: ph,
                    min: 4.0,
                    max: 8.5,
                    divisions: 45,
                    label: ph.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        ph = value;
                      });
                    },
                  ),
                ),
                Text(ph.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 10),

            // Water Availability Dropdown + Hint
            Row(
              children: [
                const Text("Water Availability: "),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: water,
                  items: ['Low', 'Medium', 'High']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      water = val!;
                    });
                  },
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8.0, top: 4.0),
              child: Text(
                "Low = less irrigation | Medium = normal need | High = requires more water",
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // District Dropdown
            Row(
              children: [
                const Text("District: "),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: district,
                  items: ['Hyderabad', 'Nizamabad', 'Warangal', 'Karimnagar']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      district = val!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Season Dropdown + Hint
            Row(
              children: [
                const Text("Season: "),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: season,
                  items: ['Kharif', 'Rabi', 'Summer']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      season = val!;
                    });
                  },
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8.0, top: 4.0),
              child: Text(
                "Kharif = Monsoon (Jun–Oct) | Rabi = Winter (Nov–Mar) | Summer = Hot season (Apr–Jun)",
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Suggest Button
            ElevatedButton(
              onPressed: suggestCrops,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
              child: const Text("Suggest Crops"),
            ),

            const SizedBox(height: 20),

            // Suggested Crops List
            if (suggestedCrops.isNotEmpty)
              ...suggestedCrops.map((crop) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(crop['crop'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Water Need: ${crop['water']}"),
                      Text("Season(s): ${crop['season'].join(', ')}"),
                    ],
                  ),
                ),
              )),
            if (suggestedCrops.isEmpty)
              const Text("No crops match your inputs yet."),
          ],
        ),
      ),
    );
  }
}
