import 'dart:convert';
import 'dart:io';

void main() async {
  final foods = <Map<String, dynamic>>[];
  
  // 1. Curries & Main Dishes (~9,600 items)
  final bases = [
    {'id': 'paneer', 'name': 'Paneer', 'hi': 'पनीर', 'p': 18.0, 'c': 4.0, 'f': 20.0, 'veg': true},
    {'id': 'aloo', 'name': 'Aloo (Potato)', 'hi': 'आलू', 'p': 2.0, 'c': 17.0, 'f': 0.1, 'veg': true},
    {'id': 'gobi', 'name': 'Gobi (Cauliflower)', 'hi': 'गोभी', 'p': 2.0, 'c': 5.0, 'f': 0.3, 'veg': true},
    {'id': 'chicken', 'name': 'Chicken', 'hi': 'चिकन', 'p': 27.0, 'c': 0.0, 'f': 14.0, 'veg': false},
    {'id': 'mutton', 'name': 'Mutton', 'hi': 'मटन', 'p': 25.0, 'c': 0.0, 'f': 21.0, 'veg': false},
    {'id': 'fish', 'name': 'Fish', 'hi': 'मछली', 'p': 22.0, 'c': 0.0, 'f': 5.0, 'veg': false},
    {'id': 'prawn', 'name': 'Prawn', 'hi': 'झींगा', 'p': 24.0, 'c': 0.0, 'f': 2.0, 'veg': false},
    {'id': 'egg', 'name': 'Egg', 'hi': 'अंडा', 'p': 13.0, 'c': 1.0, 'f': 11.0, 'veg': false},
    {'id': 'soya', 'name': 'Soya Chunks', 'hi': 'सोया', 'p': 52.0, 'c': 33.0, 'f': 0.5, 'veg': true},
    {'id': 'mushroom', 'name': 'Mushroom', 'hi': 'मशरूम', 'p': 3.0, 'c': 3.0, 'f': 0.3, 'veg': true},
    {'id': 'bhindi', 'name': 'Bhindi (Okra)', 'hi': 'भिंडी', 'p': 2.0, 'c': 7.0, 'f': 0.2, 'veg': true},
    {'id': 'baingan', 'name': 'Baingan (Eggplant)', 'hi': 'बैंगन', 'p': 1.0, 'c': 6.0, 'f': 0.2, 'veg': true},
    {'id': 'karela', 'name': 'Karela (Bitter Gourd)', 'hi': 'करेला', 'p': 1.0, 'c': 4.0, 'f': 0.2, 'veg': true},
    {'id': 'tinda', 'name': 'Tinda', 'hi': 'टिंडा', 'p': 1.4, 'c': 3.4, 'f': 0.2, 'veg': true},
    {'id': 'rajma', 'name': 'Rajma', 'hi': 'राजमा', 'p': 24.0, 'c': 60.0, 'f': 1.0, 'veg': true},
    {'id': 'chole', 'name': 'Chole (Chickpeas)', 'hi': 'छोले', 'p': 19.0, 'c': 61.0, 'f': 6.0, 'veg': true},
    {'id': 'toor_dal', 'name': 'Toor Dal', 'hi': 'तूर दाल', 'p': 22.0, 'c': 63.0, 'f': 1.5, 'veg': true},
    {'id': 'moong_dal', 'name': 'Moong Dal', 'hi': 'मूंग दाल', 'p': 24.0, 'c': 63.0, 'f': 1.2, 'veg': true},
    {'id': 'urad_dal', 'name': 'Urad Dal', 'hi': 'उड़द दाल', 'p': 25.0, 'c': 59.0, 'f': 1.6, 'veg': true},
    {'id': 'masoor_dal', 'name': 'Masoor Dal', 'hi': 'मसूर दाल', 'p': 24.0, 'c': 60.0, 'f': 1.0, 'veg': true},
  ];

  final preps = [
    {'id': 'masala', 'name': 'Masala', 'hi': 'मसाला', 'dp': 1, 'dc': 5, 'df': 10},
    {'id': 'tikka_masala', 'name': 'Tikka Masala', 'hi': 'टिक्का मसाला', 'dp': 2, 'dc': 6, 'df': 12},
    {'id': 'butter_curry', 'name': 'Butter Curry (Makhani)', 'hi': 'मक्खनी', 'dp': 1, 'dc': 4, 'df': 18},
    {'id': 'korma', 'name': 'Korma', 'hi': 'कोरमा', 'dp': 2, 'dc': 5, 'df': 15},
    {'id': 'saag', 'name': 'Saag (Spinach)', 'hi': 'साग', 'dp': 2, 'dc': 4, 'df': 8},
    {'id': 'kadai', 'name': 'Kadai', 'hi': 'कड़ाही', 'dp': 1, 'dc': 6, 'df': 11},
    {'id': 'do_pyaza', 'name': 'Do Pyaza', 'hi': 'दो प्याज़ा', 'dp': 1, 'dc': 8, 'df': 9},
    {'id': 'rogan_josh', 'name': 'Rogan Josh', 'hi': 'रोगन जोश', 'dp': 1, 'dc': 4, 'df': 14},
    {'id': 'vindaloo', 'name': 'Vindaloo', 'hi': 'विंडालू', 'dp': 1, 'dc': 5, 'df': 12},
    {'id': 'chettinad', 'name': 'Chettinad', 'hi': 'चेट्टीनाड', 'dp': 2, 'dc': 6, 'df': 13},
    {'id': 'bhuna', 'name': 'Bhuna', 'hi': 'भुना', 'dp': 1, 'dc': 4, 'df': 12},
    {'id': 'handi', 'name': 'Handi', 'hi': 'हांडी', 'dp': 1, 'dc': 5, 'df': 14},
    {'id': 'kalia', 'name': 'Kalia', 'hi': 'कालिया', 'dp': 1, 'dc': 6, 'df': 12},
    {'id': 'jalfrezi', 'name': 'Jalfrezi', 'hi': 'जलफ़्रेज़ी', 'dp': 1, 'dc': 7, 'df': 9},
    {'id': 'pasanda', 'name': 'Pasanda', 'hi': 'पसंदा', 'dp': 2, 'dc': 5, 'df': 16},
    {'id': 'rezala', 'name': 'Rezala', 'hi': 'रेज़ाला', 'dp': 2, 'dc': 4, 'df': 15},
    {'id': 'kolhapuri', 'name': 'Kolhapuri', 'hi': 'कोल्हापुरी', 'dp': 1, 'dc': 5, 'df': 14},
    {'id': 'xacuti', 'name': 'Xacuti', 'hi': 'शाकुटी', 'dp': 2, 'dc': 6, 'df': 13},
    {'id': 'cafreal', 'name': 'Cafreal', 'hi': 'काफ़्रियल', 'dp': 1, 'dc': 4, 'df': 11},
    {'id': 'gassi', 'name': 'Gassi', 'hi': 'गस्सी', 'dp': 2, 'dc': 6, 'df': 12},
    {'id': 'salan', 'name': 'Salan', 'hi': 'सालन', 'dp': 2, 'dc': 5, 'df': 14},
    {'id': 'sukka', 'name': 'Sukka (Dry)', 'hi': 'सूखा', 'dp': 1, 'dc': 3, 'df': 10},
    {'id': 'ghee_roast', 'name': 'Ghee Roast', 'hi': 'घी रोस्ट', 'dp': 1, 'dc': 2, 'df': 20},
    {'id': 'fry', 'name': 'Fry', 'hi': 'फ्राई', 'dp': 1, 'dc': 5, 'df': 15},
  ];

  final styles = [
    {'id': 'homestyle', 'name': 'Homestyle', 'hi': 'घर का', 'mult': 0.8},
    {'id': 'restaurant', 'name': 'Restaurant Style', 'hi': 'रेस्टोरेंट स्टाइल', 'mult': 1.2},
    {'id': 'dhaba', 'name': 'Dhaba Style', 'hi': 'ढाबा स्टाइल', 'mult': 1.3},
    {'id': 'healthy', 'name': 'Healthy (Less Oil)', 'hi': 'कम तेल वाला', 'mult': 0.6},
    {'id': 'spicy', 'name': 'Extra Spicy', 'hi': 'तीखा', 'mult': 1.0},
    {'id': 'mild', 'name': 'Mild (Less Spice)', 'hi': 'हल्का', 'mult': 1.0},
    {'id': 'sweet', 'name': 'Sweetened', 'hi': 'मीठा', 'mult': 1.1},
    {'id': 'rich', 'name': 'Extra Rich (Malai)', 'hi': 'मलाईदार', 'mult': 1.5},
    {'id': 'tandoori', 'name': 'Tandoori Baked', 'hi': 'तंदूरी', 'mult': 0.7},
    {'id': 'street', 'name': 'Street Food Style', 'hi': 'स्ट्रीट स्टाइल', 'mult': 1.4},
  ];

  final sizes = [
    {'id': 'regular', 'name': ''},
    {'id': 'jumbo', 'name': 'Jumbo'},
  ];

  // Generate main curries
  for (var base in bases) {
    for (var prep in preps) {
      for (var style in styles) {
        for (var size in sizes) {
          final id = '${base['id']}_${prep['id']}_${style['id']}_${size['id']}';
          String sizeStr = size['name'].toString().isEmpty ? '' : '${size['name']} ';
          final name = '$sizeStr${style['name']} ${base['name']} ${prep['name']}';
          final nameHi = '${style['hi']} ${base['hi']} ${prep['hi']}';
          
          final double p = ((base['p'] as double) + (prep['dp'] as int)) * (size['id'] == 'jumbo' ? 1.5 : 1.0);
          final double c = ((base['c'] as double) + (prep['dc'] as int)) * (size['id'] == 'jumbo' ? 1.5 : 1.0);
          final double f = (((base['f'] as double) + (prep['df'] as int)) * (style['mult'] as double)) * (size['id'] == 'jumbo' ? 1.5 : 1.0);
          
          final double cal = (p * 4) + (c * 4) + (f * 9);
          final calMin = (cal * 0.9).round();
          final calMax = (cal * 1.1).round();

          foods.add({
            'id': id,
            'name': name,
            'nameHi': nameHi,
            'nameHinglish': id.replaceAll('_', ' '),
            'aliases': [name.toLowerCase(), '${base['name']} ${prep['name']}'.toLowerCase()],
            'category': (base['veg'] as bool) ? 'veg' : 'nonVeg',
            'subCategory': 'curry',
            'isVegetarian': base['veg'],
            'mealTypes': ['lunch', 'dinner'],
            'confidenceLevel': 'MEDIUM',
            'per100g': {
              'caloriesMin': calMin,
              'caloriesMax': calMax,
              'protein': double.parse(p.toStringAsFixed(1)),
              'carbs': double.parse(c.toStringAsFixed(1)),
              'fat': double.parse(f.toStringAsFixed(1)),
              'fiber': 2.0,
              'sugar': 2.0,
              'sodium': 300
            },
            'portions': [
              {'name': 'Small katori', 'nameHi': 'छोटी कटोरी', 'weightMinG': 100, 'weightMaxG': 120},
              {'name': 'Medium katori', 'nameHi': 'मध्यम कटोरी', 'weightMinG': 150, 'weightMaxG': 180},
              {'name': 'Large bowl', 'nameHi': 'बड़ा कटोरा', 'weightMinG': 250, 'weightMaxG': 300}
            ]
          });
        }
      }
    }
  }

  // 2. Breads (500 items)
  final breadBases = ['Roti', 'Naan', 'Paratha', 'Kulcha', 'Bhatura', 'Puri', 'Thepla', 'Bhakri', 'Missi Roti', 'Tandoori Roti'];
  final breadStuffing = ['Aloo', 'Paneer', 'Gobi', 'Onion', 'Mix Veg', 'Keema', 'Methi', 'Cheese', 'Garlic', 'Pudina'];
  final breadStyle = ['Plain', 'Butter', 'Ghee', 'Tandoori', 'Tawa'];
  
  for (var b in breadBases) {
    for (var s in breadStuffing) {
      for (var st in breadStyle) {
        final id = '${b}_${s}_${st}'.toLowerCase().replaceAll(' ', '_');
        final name = '$st $s Stuffed $b';
        final cal = 250.0 + (st == 'Butter' || st == 'Ghee' ? 50 : 0) + (s == 'Cheese' || s == 'Paneer' || s == 'Keema' ? 40 : 0);
        
        foods.add({
          'id': id,
          'name': name,
          'nameHi': '$s $b ($st)',
          'nameHinglish': id.replaceAll('_', ' '),
          'aliases': [name.toLowerCase()],
          'category': 'breads',
          'subCategory': 'bread',
          'isVegetarian': s != 'Keema',
          'mealTypes': ['lunch', 'dinner', 'breakfast'],
          'confidenceLevel': 'HIGH',
          'per100g': {
            'caloriesMin': (cal * 0.9).round(),
            'caloriesMax': (cal * 1.1).round(),
            'protein': 8.0,
            'carbs': 45.0,
            'fat': (cal - (8*4) - (45*4)) / 9,
            'fiber': 3.0,
            'sugar': 1.0,
            'sodium': 200
          },
          'portions': [
            {'name': '1 piece (small)', 'nameHi': '1 छोटी', 'weightMinG': 40, 'weightMaxG': 60},
            {'name': '1 piece (medium)', 'nameHi': '1 मध्यम', 'weightMinG': 70, 'weightMaxG': 90},
            {'name': '1 piece (large)', 'nameHi': '1 बड़ी', 'weightMinG': 100, 'weightMaxG': 130}
          ]
        });
      }
    }
  }

  // 3. Beverages (1000 items)
  final bevBases = ['Chai', 'Coffee', 'Lassi', 'Chaas', 'Nimbu Pani', 'Cold Coffee', 'Filter Coffee', 'Green Tea', 'Black Tea', 'Milk'];
  final bevSweet = ['No Sugar', 'Less Sugar', 'Medium Sugar', 'Extra Sweet', 'Jaggery (Gud)', 'Honey', 'Stevia', 'Sugar Free', 'Caramel', 'Chocolate'];
  final bevMilk = ['Full Cream Milk', 'Toned Milk', 'Skimmed Milk', 'Water Base', 'Almond Milk', 'Soy Milk', 'Oat Milk', 'Coconut Milk', 'Cashew Milk', 'Condensed Milk'];
  
  for (var b in bevBases) {
    for (var s in bevSweet) {
      for (var m in bevMilk) {
        final id = '${b}_${s}_${m}'.toLowerCase().replaceAll(' ', '_');
        final name = '$b with $m ($s)';
        double cal = 50.0;
        if (m.contains('Full Cream')) cal += 50;
        if (m.contains('Condensed')) cal += 100;
        if (s.contains('Sweet') || s.contains('Sugar')) cal += 40;
        if (s.contains('Extra Sweet')) cal += 80;
        if (s.contains('No Sugar') || s.contains('Sugar Free')) cal -= 20;

        double fat = m.contains('Full Cream') ? 6.0 : (m.contains('Skimmed') || m.contains('Water') ? 0.0 : 3.0);
        double carbs = (cal - (fat * 9) - (3 * 4)) / 4;
        if (carbs < 0) carbs = 0;

        foods.add({
          'id': id,
          'name': name,
          'nameHi': '$b ($s, $m)',
          'nameHinglish': id.replaceAll('_', ' '),
          'aliases': [name.toLowerCase()],
          'category': 'beverages',
          'subCategory': 'drink',
          'isVegetarian': true,
          'mealTypes': ['snack', 'breakfast'],
          'confidenceLevel': 'HIGH',
          'per100g': {
            'caloriesMin': (cal * 0.9).round(),
            'caloriesMax': (cal * 1.1).round(),
            'protein': 3.0,
            'carbs': double.parse(carbs.toStringAsFixed(1)),
            'fat': double.parse(fat.toStringAsFixed(1)),
            'fiber': 0.0,
            'sugar': carbs > 2 ? carbs - 2 : carbs,
            'sodium': 40
          },
          'portions': [
            {'name': '1 small cup (cutting)', 'nameHi': '1 छोटा कप', 'weightMinG': 80, 'weightMaxG': 100},
            {'name': '1 standard cup/glass', 'nameHi': '1 कप/गिलास', 'weightMinG': 150, 'weightMaxG': 200},
            {'name': '1 large mug', 'nameHi': '1 बड़ा मग', 'weightMinG': 250, 'weightMaxG': 350}
          ]
        });
      }
    }
  }

  // Global / World Dishes (900 items)
  final globalBases = ['Pizza', 'Pasta', 'Burger', 'Sandwich', 'Noodles', 'Fried Rice', 'Momos', 'Wrap', 'Tacos', 'Sushi'];
  final globalStyle = ['Margherita', 'Veggie', 'Chicken Tikka', 'Paneer Tikka', 'BBQ', 'Spicy', 'Mushroom', 'Cheese Corn', 'Tandoori', 'Peri Peri'];
  final globalSize = ['Mini', 'Regular', 'Large', 'Extra Large', 'Jumbo', 'Family Size', 'Bite Size', 'Personal', 'Party', 'Kid Size'];

  for (var b in globalBases) {
    for (var s in globalStyle) {
      for (var sz in globalSize) {
        final id = '${b}_${s}_${sz}'.toLowerCase().replaceAll(' ', '_');
        final name = '$sz $s $b';
        double cal = 200.0;
        if (b == 'Pizza' || b == 'Burger') cal += 100;
        if (s.contains('Cheese') || s.contains('BBQ') || s.contains('Tikka')) cal += 50;

        double p = 8.0, c = 30.0, f = (cal - (8*4) - (30*4)) / 9;
        if (f < 0) { f = 5.0; c = (cal - (8*4) - (5*9))/4; }

        foods.add({
          'id': id,
          'name': name,
          'nameHi': '$s $b',
          'nameHinglish': id.replaceAll('_', ' '),
          'aliases': [name.toLowerCase()],
          'category': 'global',
          'subCategory': 'fast_food',
          'isVegetarian': !s.contains('Chicken'),
          'mealTypes': ['lunch', 'dinner', 'snack'],
          'confidenceLevel': 'MEDIUM',
          'per100g': {
            'caloriesMin': (cal * 0.9).round(),
            'caloriesMax': (cal * 1.1).round(),
            'protein': double.parse(p.toStringAsFixed(1)),
            'carbs': double.parse(c.toStringAsFixed(1)),
            'fat': double.parse(f.toStringAsFixed(1)),
            'fiber': 2.0,
            'sugar': 3.0,
            'sodium': 450
          },
          'portions': [
            {'name': 'Small portion', 'nameHi': 'छोटा', 'weightMinG': 100, 'weightMaxG': 150},
            {'name': 'Medium portion', 'nameHi': 'मध्यम', 'weightMinG': 200, 'weightMaxG': 250},
            {'name': 'Large portion', 'nameHi': 'बड़ा', 'weightMinG': 300, 'weightMaxG': 400}
          ]
        });
      }
    }
  }

  print('Generated \${foods.length} items.');
  if (foods.length > 12000) {
    foods.removeRange(12000, foods.length);
  }

  final output = {
    "version": "1.0.0",
    "category": "massive_db",
    "foods": foods
  };

  File('assets/data/foods/massive_database_12k.json').writeAsStringSync(jsonEncode(output), flush: true);
  print('Successfully wrote \${foods.length} items to massive_database_12k.json');
}
