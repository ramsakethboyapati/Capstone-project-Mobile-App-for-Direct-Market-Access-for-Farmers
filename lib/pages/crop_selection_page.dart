import 'package:flutter/material.dart';
import 'add_product_page.dart';

class CropSelectionPage extends StatefulWidget {
  final String category;
  const CropSelectionPage({super.key, required this.category});

  @override
  State<CropSelectionPage> createState() => _CropSelectionPageState();
}

class _CropSelectionPageState extends State<CropSelectionPage> {
  late List<Map<String, String>> crops;
  List<Map<String, String>> filteredCrops = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Food vs Commercial crops
    crops = widget.category == "commercial"
        ? [
      // 💰 Commercial crops
      {"name": "Cotton", "image": "assets/crops/cotton.png"},
      {"name": "Sugarcane", "image": "assets/crops/sugarcane.png"},
      {"name": "Sunflower", "image": "assets/crops/sun flower.png"},
    ]
        : [
      // 🌾 Food crops
      {"name": "Wheat", "image": "assets/crops/wheat.png"},
      {"name": "Rice", "image": "assets/crops/rice.png"},
      {"name": "Maize", "image": "assets/crops/maize.png"},
      {"name": "Barley", "image": "assets/crops/barley.png"},
      {"name": "Jowar", "image": "assets/crops/jowar.png"},
      {"name": "Bajra", "image": "assets/crops/bajra.png"},
      {"name": "Ragi", "image": "assets/crops/ragi.png"},
      {"name": "Black Gram", "image": "assets/crops/black gram.png"},
      {"name": "Green Gram", "image": "assets/crops/green gram.png"},
      {"name": "Peas", "image": "assets/crops/peas.png"},
      {"name": "Brinjal", "image": "assets/crops/brinjal.png"},
      {"name": "Onion", "image": "assets/crops/onion.png"},
      {"name": "Chilli", "image": "assets/crops/chilli.png"},
      {"name": "Mango", "image": "assets/crops/mango.png"},
      {"name": "Banana", "image": "assets/crops/banana.png"},
      {"name": "Orange", "image": "assets/crops/orange.png"},
    ];

    filteredCrops = crops;

    // search filter
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        filteredCrops = crops
            .where((crop) => crop["name"]!.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select ${widget.category} crop")),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search crops...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Grid of crops (scrolls automatically)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredCrops.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // two columns
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3 / 4,
              ),
              itemBuilder: (context, index) {
                final crop = filteredCrops[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProductPage(
                          cropName: crop["name"]!,
                          cropImage: crop["image"]!,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            crop["image"]!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          child: Text(
                            crop["name"]!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
