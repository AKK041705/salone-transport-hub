 import 'dart:io';
    
// FARE AND PLACE DATA
const String disclaimer =
    'Note: [Official price list] fares come from the price lists supplied for this project.\n'
    '[Published sample (news)] fares come from news reports of Ministry announcements.\n'
    '[Simulated estimate] fares are calculated by this prototype and are NOT official.\n'
    'Always confirm with the latest official notice from the Ministry of Transport and Aviation.';

// Each place: [area, approximate simulated road distance from central Freetown in km].
// Areas: City and Peninsula (together the Western Area), then provincial areas.
const Map<String, List<Object>> placeData = {
  // Freetown city
  'Freetown': ['City', 0],
  'PZ': ['City', 1],
  'Bombay Street': ['City', 3],
  'Douzak': ['City', 3],
  'Wilberforce': ['City', 4],
  'Imatt': ['City', 4],
  'Model': ['City', 4],
  'Up-gun': ['City', 5],
  'Aberdeen': ['City', 5],
  'Aberdeen Road Junction': ['City', 6],
  'Wilkinson Road': ['City', 6],
  'Congo Cross': ['City', 6],
  'Lumley': ['City', 7],
  'Regent': ['City', 9],
  'Bah Junction': ['City', 9],
  'Levumaa Beach': ['City', 9],
  'Funkia Junction': ['City', 9],
  'Femi Turner': ['City', 10],
  'College Junction': ['City', 10],
  'Ogu Farm Junction': ['City', 11],
  'Laka Junction': ['City', 12],
  'Hamilton Junction': ['City', 12],
  'Mambo Junction': ['City', 14],
  // Western Area peninsula
  'Calaba Town': ['Peninsula', 14],
  'Jui': ['Peninsula', 17],
  'Yams Farm': ['Peninsula', 20],
  'Tombo Junction': ['Peninsula', 29],
  'Waterloo 55': ['Peninsula', 33],
  'Kerry Town': ['Peninsula', 34],
  'Devil Hole': ['Peninsula', 34],
  'Fire Force': ['Peninsula', 34],
  'Waterloo': ['Peninsula', 35],
  'Rokel': ['Peninsula', 36],
  '4 Mile': ['Peninsula', 38],
  'Crossing': ['Peninsula', 40],
  'Brama': ['Peninsula', 42],
  'Tombo': ['Peninsula', 45],
  'Songo': ['Peninsula', 50],
  'Tokeh': ['Peninsula', 55],
  // Lungi
  'Lungi': ['Lungi', 40],
  // North
  'Port Loko': ['North', 90],
  'Lunsar': ['North', 105],
  'Kambia': ['North', 150],
  'Makeni': ['North', 180],
  'Kamabai': ['North', 220],
  'Kamakwei': ['North', 250],
  'Kabala': ['North', 290],
  // South and East
  'Moyamba': ['Southeast', 130],
  'Gbangbatoke': ['Southeast', 200],
  'Magburaka': ['Southeast', 215],
  'Mattru/Bonthe': ['Southeast', 215],
  'Mattru Jong': ['Southeast', 220],
  'Rutile': ['Southeast', 230],
  'Bo': ['Southeast', 250],
  'Taima': ['Southeast', 270],
  'Jendema': ['Southeast', 300],
  'Kenema': ['Southeast', 300],
  'Pujehun': ['Southeast', 300],
  'Kono': ['Southeast', 330],
  'Segbema': ['Southeast', 330],
  'Pamalap': ['Southeast', 340],
  'Gendema': ['Southeast', 360],
  'Kailahun': ['Southeast', 380],
};

final List<String> locations = placeData.keys.toList();

String areaOf(String place) => placeData[place]![0] as String;
int kmOf(String place) => placeData[place]![1] as int;
bool inCity(String place) => areaOf(place) == 'City';
bool inWesternArea(String place) =>
    areaOf(place) == 'City' || areaOf(place) == 'Peninsula';
String corridorOf(String place) =>
    inWesternArea(place) ? 'Western' : areaOf(place);

// Modes shown in the comparison screen.
const List<String> fareModes = [
  'Okada',
  'Kekeh',
  'Taxi (shared)',
  'Taxi (private hire)',
  'Poda-poda',
  'Bus',
];

// Seats in each vehicle type (assumed for this prototype). These are also the
// transport types a passenger can request.
const Map<String, int> seatCapacity = {
  'Okada': 1,
  'Kekeh': 3,
  'Taxi (shared)': 4,
  'Taxi (private hire)': 4,
  'Private vehicle': 6,
  'Poda-poda': 12,
  'Bus': 30,
};

// Simulated pricing rule for each mode: [base fare in NLe, rate per km in NLe].
const Map<String, List<double>> rates = {
  'Okada': [5.0, 1.6],
  'Kekeh': [5.0, 1.3],
  'Taxi (shared)': [5.0, 0.8],
  'Taxi (private hire)': [20.0, 2.5],
  'Private vehicle': [30.0, 3.0],
  'Poda-poda': [3.0, 0.45],
  'Bus': [5.0, 0.62],
};

// Fare type shown for each mode.
const Map<String, String> fareTypes = {
  'Okada': 'Per passenger',
  'Kekeh': 'Per passenger',
  'Taxi (shared)': 'Shared, per passenger',
  'Taxi (private hire)': 'Private hire, per trip',
  'Private vehicle': 'Private hire, per trip',
  'Poda-poda': 'Per passenger',
  'Bus': 'Per passenger',
};

// Modes where every reserved seat is paid for (the others are per trip).
const List<String> perPassengerModes = [
  'Okada',
  'Kekeh',
  'Taxi (shared)',
  'Poda-poda',
  'Bus',
];

// What a driver registers as. Both taxi request types are served by a Taxi driver.
const List<String> driverTypes = [
  'Okada',
  'Kekeh',
  'Taxi',
  'Private vehicle',
  'Poda-poda',
  'Bus',
];

String driverTypeFor(String mode) => mode.startsWith('Taxi') ? 'Taxi' : mode;

// Builds one tariff record. fare == null means "at the rider's discretion".
Map<String, dynamic> route(
  String mode,
  String from,
  String to,
  double? fare, {
  String type = 'Per passenger',
  String source = 'Official price list',
}) {
  return {
    'mode': mode,
    'from': from,
    'to': to,
    'fare': fare,
    'type': type,
    'source': source,
  };
}

// Published tariffs. from == '*' means a flat pole-to-pole fare (not route based).
final List<Map<String, dynamic>> tariffs = [
  // Okada and Kekeh pole-to-pole (new price NLe 7, old price NLe 6.1)
  route('Okada', '*', '*', 7.0, type: 'Flat pole-to-pole'),
  route('Kekeh', '*', '*', 7.0, type: 'Flat pole-to-pole'),

  // Kekeh routes (Western Area only; kekeh do not run in the provinces)
  route('Kekeh', 'Lumley', 'Wilberforce', 12.0),
  route('Kekeh', 'Wilberforce', 'Imatt', 12.0),
  route('Kekeh', 'Wilberforce', 'Regent', 20.0),
  route('Kekeh', 'Wilberforce', 'Douzak', 12.0),
  route('Kekeh', 'Douzak', 'Up-gun', 12.0),
  route('Kekeh', 'Lumley', 'PZ', 30.0),
  route('Kekeh', 'Lumley', 'Douzak', 23.0),
  route('Kekeh', 'Lumley', 'Model', 30.0),
  route('Kekeh', 'Lumley', 'Congo Cross', 15.0),
  route('Kekeh', 'Lumley', 'Aberdeen', 12.0),
  route('Kekeh', 'Lumley', 'Bah Junction', 12.0),
  route('Kekeh', 'Lumley', 'Levumaa Beach', 12.0),
  route('Kekeh', 'Lumley', 'Funkia Junction', 12.0),
  route('Kekeh', 'Lumley', 'Femi Turner', 15.0),
  route('Kekeh', 'Lumley', 'College Junction', 15.0),
  route('Kekeh', 'Lumley', 'Ogu Farm Junction', 18.0),
  route('Kekeh', 'Lumley', 'Laka Junction', 18.0),
  route('Kekeh', 'Lumley', 'Hamilton Junction', 23.0),
  route('Kekeh', 'Lumley', 'Mambo Junction', 28.0),
  route('Kekeh', 'Up-gun', 'PZ', 15.0),
  route('Kekeh', 'PZ', 'Model', 15.0),
  route('Kekeh', 'Lumley', 'Wilkinson Road', 12.0),
  route('Kekeh', 'Lumley', 'Aberdeen Road Junction', 12.0),
  route('Kekeh', 'Wilberforce', 'Jui', 35.0),
  route('Kekeh', 'Lumley', 'Jui', null, type: "At the rider's discretion"),
  route('Kekeh', 'Regent', 'Jui', 18.0),
  route('Kekeh', 'Up-gun', 'Jui', 33.0),
  route('Kekeh', 'Up-gun', 'Calaba Town', 20.0),
  route('Kekeh', 'Calaba Town', 'Jui', 12.0),
  route('Kekeh', 'Jui', 'Tombo Junction', 20.0),
  route('Kekeh', 'Jui', 'Waterloo 55', 25.0),
  route('Kekeh', 'Tombo Junction', 'Waterloo 55', 7.0),
  route('Kekeh', 'Waterloo 55', '4 Mile', 12.0),
  route('Kekeh', 'Waterloo 55', 'Crossing', 18.0),
  route('Kekeh', 'Waterloo 55', 'Brama', 22.0),
  route('Kekeh', 'Waterloo 55', 'Songo', 30.0),
  route('Kekeh', 'Tombo Junction', 'Kerry Town', 12.0),
  route('Kekeh', 'Tombo Junction', 'Tombo', 25.0),
  route('Kekeh', 'Tombo Junction', 'Rokel', 12.0),
  route('Kekeh', 'Tombo Junction', 'Devil Hole', 10.0),
  route('Kekeh', 'Tombo Junction', 'Fire Force', 10.0),
  route('Kekeh', 'Jui', 'Yams Farm', 10.0),

  // Provincial buses: SLRTC and private operators (fares at NLe 45.00 per litre)
  route('Bus', 'Freetown', 'Kailahun', 394.9),
  route('Bus', 'Freetown', 'Kono', 300.2),
  route('Bus', 'Freetown', 'Kabala', 252.7),
  route('Bus', 'Freetown', 'Kenema', 236.9),
  route('Bus', 'Freetown', 'Bo', 205.3),
  route('Bus', 'Freetown', 'Kambia', 189.6),
  route('Bus', 'Freetown', 'Makeni', 189.6),
  route('Bus', 'Freetown', 'Port Loko', 189.6),
  route('Bus', 'Freetown', 'Moyamba', 205.3),
  route('Bus', 'Freetown', 'Mattru/Bonthe', 221.2),
  route('Bus', 'Freetown', 'Lunsar', 142.2),
  route('Bus', 'Kenema', 'Kailahun', 190.0),
  route('Bus', 'Kenema', 'Jendema', 292.0),
  route('Bus', 'Kenema', 'Segbema', 118.0),
  route('Bus', 'Kenema', 'Gendema', 332.0),
  route('Bus', 'Kenema', 'Bo', 95.0),
  route('Bus', 'Kenema', 'Pamalap', 411.0),
  route('Bus', 'Kenema', 'Mattru Jong', 142.0),
  route('Bus', 'Kenema', 'Rutile', 134.0),
  route('Bus', 'Kenema', 'Gbangbatoke', 142.0),
  route('Bus', 'Kenema', 'Makeni', 332.0),
  route('Bus', 'Bo', 'Jendema', 213.0),
  route('Bus', 'Bo', 'Taima', 71.0),
  route('Bus', 'Bo', 'Pujehun', 103.0),
  route('Bus', 'Bo', 'Magburaka', 63.0),
  route('Bus', 'Bo', 'Kabala', 205.0, type: 'Per passenger (mini-bus)'),
  route('Bus', 'Makeni', 'Kamabai', 79.0),
  route('Bus', 'Makeni', 'Kono', 190.0),
  route('Bus', 'Makeni', 'Lunsar', 95.0),
  route('Bus', 'Makeni', 'Kamakwei', 205.0),

  // Poda-poda samples from news reports
  route(
    'Poda-poda',
    'Waterloo',
    'Bombay Street',
    14.7,
    source: 'Published sample (news)',
  ),
  route(
    'Poda-poda',
    'Waterloo',
    'Tokeh',
    30.7,
    source: 'Published sample (news)',
  ),
];

// ------------------------------------------------------------
// IN-MEMORY RECORDS (no database: lost when the program closes)
// ------------------------------------------------------------

final List<Map<String, dynamic>> users = [
  {
    'username': 'admin',
    'password': 'admin123',
    'role': 'Administrator',
    'name': 'System Administrator',
    'phone': 'N/A',
    'verified': true,
  },
  demoDriver('rider1', 'Sample Rider A', 'Okada', 'Motorbike', 'SL-DEMO-01'),
  demoDriver('kekeh1', 'Sample Rider B', 'Kekeh', 'Tricycle', 'SL-DEMO-02'),
  demoDriver('taxi1', 'Sample Driver C', 'Taxi', 'Saloon car', 'SL-DEMO-03'),
  demoDriver('taxi2', 'Sample Driver D', 'Taxi', 'Saloon car', 'SL-DEMO-04'),
  demoDriver(
    'van1',
    'Sample Driver E',
    'Private vehicle',
    'Minivan',
    'SL-DEMO-05',
  ),
  demoDriver('poda1', 'Sample Driver F', 'Poda-poda', 'Minibus', 'SL-DEMO-06'),
  demoDriver('bus1', 'Sample Driver G', 'Bus', 'Coach', 'SL-DEMO-07'),
];

Map<String, dynamic> demoDriver(
  String username,
  String name,
  String type,
  String vehicle,
  String plate,
) {
  return {
    'username': username,
    'password': '1234',
    'role': 'Driver',
    'name': name,
    'phone': 'Demo',
    'type': type,
    'vehicle': vehicle,
    'plate': plate,
    'verified': true,
  };
}

final List<Map<String, dynamic>> requests = [];
final List<Map<String, dynamic>> complaints = [];
final List<Map<String, dynamic>> notifications = [];

// The user who is logged in right now (null when nobody is logged in).
Map<String, dynamic>? currentUser;

String me() => currentUser!['username'] as String;

Map<String, dynamic>? findUser(String username) {
  for (final u in users) {
    if (u['username'] == username) return u;
  }
  return null;
}

// ----------------------
// INPUT HELPERS
// ----------------------

String readText(String prompt) {
  stdout.write(prompt);
  final line = stdin.readLineSync();
  if (line == null) {
    print('\nInput closed. Goodbye.');
    exit(0);
  }
  return line.trim();
}

String readRequired(String prompt) {
  while (true) {
    final value = readText(prompt);
    if (value.isNotEmpty) return value;
    print('  This field cannot be empty.');
  }
}

int readChoice(String prompt, int min, int max) {
  while (true) {
    final value = int.tryParse(readText(prompt));
    if (value != null && value >= min && value <= max) return value;
    print('  Please enter a number from $min to $max.');
  }
}

double readAmount(String prompt) {
  while (true) {
    final value = double.tryParse(readText(prompt));
    if (value != null && value > 0) return value;
    print('  Please enter a valid amount greater than 0.');
  }
}

String chooseFromList(String label, List<String> options) {
  print('\n$label:');
  for (var i = 0; i < options.length; i++) {
    print('  ${i + 1}. ${options[i]}');
  }
  final choice = readChoice('Select number: ', 1, options.length);
  return options[choice - 1];
}

void printLocations() {
  print('\nAvailable places:');
  var line = '';
  for (var i = 0; i < locations.length; i++) {
    line += locations[i].padRight(24);
    if ((i + 1) % 3 == 0) {
      print('  $line');
      line = '';
    }
  }
  if (line.isNotEmpty) print('  $line');
}

// The user types part of a place name; the program finds the matching place.
String chooseLocation(String label) {
  while (true) {
    final query = readText(
      '\n$label - type a place name (? lists all places): ',
    );
    if (query == '?') {
      printLocations();
      continue;
    }
    if (query.isEmpty) {
      print('  Please type at least one letter.');
      continue;
    }
    final q = query.toLowerCase();
    for (final place in locations) {
      if (place.toLowerCase() == q) return place;
    }
    final matches = locations
        .where((p) => p.toLowerCase().contains(q))
        .toList();
    if (matches.isEmpty) {
      print('  No place found. Type ? to see all places.');
      continue;
    }
    if (matches.length == 1) {
      print('  Selected: ${matches[0]}');
      return matches[0];
    }
    print('  Several places match:');
    for (var i = 0; i < matches.length; i++) {
      print('    ${i + 1}. ${matches[i]}');
    }
    final pick = readChoice(
      '  Select number (0 to search again): ',
      0,
      matches.length,
    );
    if (pick != 0) return matches[pick - 1];
  }
}

void printHeader(String title) {
  print('\n${'=' * 48}');
  print(' $title');
  print('=' * 48);
}

bool validRoute(String a, String b) {
  if (a == b) {
    print('\nPickup and destination cannot be the same place.');
    return false;
  }
  return true;
}

// --------------------
// FARE LOGIC
// --------------------

// Simulated road distance between two places.
int distanceKm(String a, String b) {
  if (corridorOf(a) == corridorOf(b)) return (kmOf(a) - kmOf(b)).abs();
  return kmOf(a) + kmOf(b); // different roads: travel via Freetown
}

// A route tariff in either direction (flat pole-to-pole records are skipped).
Map<String, dynamic>? routeTariff(String mode, String a, String b) {
  for (final t in tariffs) {
    if (t['mode'] != mode || t['from'] == '*') continue;
    final sameWay = t['from'] == a && t['to'] == b;
    final reverse = t['from'] == b && t['to'] == a;
    if (sameWay || reverse) return t;
  }
  return null;
}

// A route tariff, or the flat pole-to-pole fare when both places are in the city.
Map<String, dynamic>? publishedTariff(String mode, String a, String b) {
  final t = routeTariff(mode, a, b);
  if (t != null) return t;
  if (inCity(a) && inCity(b)) {
    for (final flat in tariffs) {
      if (flat['mode'] == mode && flat['from'] == '*') return flat;
    }
  }
  return null;
}

// Simple rules for when a mode is not realistic for a trip.
String? unavailableReason(String mode, String a, String b) {
  final km = distanceKm(a, b);
  if (mode == 'Kekeh' && !(inWesternArea(a) && inWesternArea(b))) {
    return 'Kekeh do not run in the provinces';
  }
  if ((mode == 'Okada' || mode == 'Kekeh') && km > 60) {
    return 'Not typically available for this distance (simulated rule)';
  }
  if (mode == 'Bus' && km < 20) {
    return 'No scheduled bus service assumed for this short distance';
  }
  return null;
}

// Simulated fare = base fare + (rate per km x distance), rounded to the nearest 0.5.
Map<String, dynamic>? estimateFare(String mode, String a, String b) {
  if (unavailableReason(mode, a, b) != null) return null;
  final rule = rates[mode]!;
  final raw = rule[0] + rule[1] * distanceKm(a, b);
  final amount = (raw * 2).roundToDouble() / 2;
  return {
    'amount': amount,
    'type': fareTypes[mode],
    'source': 'Simulated estimate',
    'flat': false,
  };
}

// Use the published fare when there is one, otherwise the simulated estimate.
Map<String, dynamic>? getFare(String mode, String a, String b) {
  final t = publishedTariff(mode, a, b);
  if (t != null) {
    return {
      'amount': t['fare'],
      'type': t['type'],
      'source': t['source'],
      'flat': t['from'] == '*',
    };
  }
  return estimateFare(mode, a, b);
}

String fareLine(String mode, String a, String b) {
  final fare = getFare(mode, a, b);
  if (fare == null) {
    return unavailableReason(mode, a, b) ?? 'No fare available';
  }
  final amount = fare['amount'] as double?;
  if (amount == null) return '${fare['type']} [${fare['source']}]';
  var text =
      'NLe ${amount.toStringAsFixed(1)} (${fare['type']}) [${fare['source']}]';
  if (fare['flat'] == true) text += ' - one short trip';
  return text;
}

// Total estimated fare for a request. Every reserved seat is paid for in
// per-passenger modes; private hire is one fare for the whole trip.
String requestFareText(
  String mode,
  String a,
  String b,
  int people,
  int freeSeats,
) {
  final fare = getFare(mode, a, b);
  if (fare == null) return 'No fare available - agree with the driver';
  final each = fare['amount'] as double?;
  if (each == null) return "At the rider's discretion - agree with the driver";
  final source = fare['source'];
  if (perPassengerModes.contains(mode)) {
    final seats = people + freeSeats;
    final total = each * seats;
    return 'NLe ${total.toStringAsFixed(1)} for $seats seat(s) '
        '(NLe ${each.toStringAsFixed(1)} per seat) [$source]';
  }
  return 'NLe ${each.toStringAsFixed(1)} for the whole trip [$source]';
}

// ----------------------
// NOTIFICATIONS
// ----------------------

void notify(String to, String text) {
  notifications.add({'to': to, 'text': text, 'read': false});
}

void notifyAllWithRole(String role, String text) {
  for (final u in users) {
    if (u['role'] == role) notify(u['username'] as String, text);
  }
}

int unreadCount(String username) {
  var count = 0;
  for (final n in notifications) {
    if (n['to'] == username && n['read'] == false) count++;
  }
  return count;
}

void showNotifications() {
  printHeader('NOTIFICATIONS (REFRESH)');
  var count = 0;
  for (final n in notifications) {
    if (n['to'] != me()) continue;
    count++;
    final tag = n['read'] == true ? '     ' : '[NEW]';
    print('  $tag ${n['text']}');
    n['read'] = true;
  }
  if (count == 0) print('  No notifications yet.');
}

void printMenuHeader(String title) {
  printHeader(title);
  final unread = unreadCount(me());
  if (unread > 0) print(' You have $unread new notification(s).');
}

// --------------------------------------
// FARE SCREENS (used by everyone)
// --------------------------------------

void viewFares() {
  printHeader('VIEW TRANSPORTATION FARES');
  final from = chooseLocation('Pickup');
  final to = chooseLocation('Destination');
  if (!validRoute(from, to)) return;

  print('\nApproximate distance: ${distanceKm(from, to)} km (simulated)');
  print('Fares for $from -> $to:');
  for (final mode in fareModes) {
    if (getFare(mode, from, to) != null) {
      print('  ${mode.padRight(20)} ${fareLine(mode, from, to)}');
    }
  }
  print('\n$disclaimer');
}

void compareTransportation() {
  printHeader('COMPARE TRANSPORTATION');
  final from = chooseLocation('Pickup');
  final to = chooseLocation('Destination');
  if (!validRoute(from, to)) return;

  print('\nAVAILABLE TRANSPORTATION: $from -> $to');
  print('Approximate distance: ${distanceKm(from, to)} km (simulated)');
  for (var i = 0; i < fareModes.length; i++) {
    final mode = fareModes[i];
    print('  ${i + 1}. ${mode.padRight(20)} ${fareLine(mode, from, to)}');
  }
  print(
    '\nThe system does not rank options. A cheaper mode may offer a different',
  );
  print('level of service (shared vs private, capacity, comfort).');
  print('\n$disclaimer');
}

void browseFares() {
  while (true) {
    printHeader('BROWSE FARES (NO LOGIN)');
    print('1. View Transportation Fares');
    print('2. Compare Transportation');
    print('3. Back');
    final option = readChoice('\nSelect option: ', 1, 3);
    if (option == 1) viewFares();
    if (option == 2) compareTransportation();
    if (option == 3) return;
  }
}

// ----------------------------
// REGISTER AND LOG IN
// ----------------------------

String readNewUsername() {
  while (true) {
    final value = readRequired('Choose a username (no spaces): ').toLowerCase();
    if (value.contains(' ')) {
      print('  Username cannot contain spaces.');
    } else if (findUser(value) != null) {
      print('  That username is already taken.');
    } else {
      return value;
    }
  }
}

String readNewPassword() {
  while (true) {
    final value = readRequired('Choose a password (at least 4 characters): ');
    if (value.length >= 4) return value;
    print('  Password is too short.');
  }
}

void registerUser() {
  printHeader('REGISTER');
  final role = chooseFromList('Register as', ['Passenger', 'Driver']);
  final name = readRequired('Full name: ');
  final username = readNewUsername();
  final password = readNewPassword();
  final phone = readRequired('Phone number: ');

  final Map<String, dynamic> user = {
    'username': username,
    'password': password,
    'role': role,
    'name': name,
    'phone': phone,
    'verified': true,
  };

  if (role == 'Driver') {
    user['type'] = chooseFromList(
      'Transportation type you operate',
      driverTypes,
    );
    user['vehicle'] = readRequired(
      'Vehicle description (e.g. Toyota saloon): ',
    );
    user['plate'] = readRequired('Vehicle plate number: ');
    user['verified'] = false;
  }

  users.add(user);
  print('\nRegistration successful. You can now log in as "$username".');
  if (role == 'Driver') {
    print('Your account must be verified by the administrator before you');
    print('can receive transport requests.');
    notifyAllWithRole(
      'Administrator',
      'New driver registered: $name ($username). Verification needed.',
    );
  }
}

void loginUser() {
  printHeader('LOG IN');
  for (var attempt = 1; attempt <= 3; attempt++) {
    final username = readText('Username: ').toLowerCase();
    final password = readText('Password: ');
    final user = findUser(username);
    if (user != null && user['password'] == password) {
      currentUser = user;
      print('\nWelcome, ${user['name']} (${user['role']}).');
      final role = user['role'];
      if (role == 'Passenger') passengerMenu();
      if (role == 'Driver') driverMenu();
      if (role == 'Administrator') adminMenu();
      currentUser = null;
      print('\nYou have been logged out.');
      return;
    }
    print('  Wrong username or password ($attempt of 3).');
  }
  print('Too many failed attempts. Returning to the main menu.');
}

// -----------------------
//      PASSENGER
// -----------------------

void passengerMenu() {
  while (true) {
    printMenuHeader('PASSENGER MENU - ${currentUser!['name']}');
    print('1. View Transportation Fares');
    print('2. Compare Transportation');
    print('3. Request Transportation');
    print('4. My Requests (accept or reject a driver)');
    print('5. Report Fare Issue');
    print('6. My Fare Reports');
    print('7. Notifications (refresh)');
    print('8. Log out');

    final option = readChoice('\nSelect option: ', 1, 8);
    switch (option) {
      case 1:
        viewFares();
        break;
      case 2:
        compareTransportation();
        break;
      case 3:
        requestTransportation();
        break;
      case 4:
        passengerRequests();
        break;
      case 5:
        reportFareIssue();
        break;
      case 6:
        myFareReports();
        break;
      case 7:
        showNotifications();
        break;
      case 8:
        return;
    }
  }
}

int countVerifiedDrivers(String type) {
  var count = 0;
  for (final u in users) {
    if (u['role'] == 'Driver' && u['verified'] == true && u['type'] == type) {
      count++;
    }
  }
  return count;
}

void requestTransportation() {
  printHeader('TRANSPORTATION REQUEST');
  final pickup = chooseLocation('Pickup');
  final destination = chooseLocation('Destination');
  if (!validRoute(pickup, destination)) return;

  print(
    '\nApproximate distance: ${distanceKm(pickup, destination)} km (simulated)',
  );
  final mode = chooseFromList(
    'Transportation type',
    seatCapacity.keys.toList(),
  );
  final reason = unavailableReason(mode, pickup, destination);
  if (reason != null) {
    print('\n$mode: $reason.');
    print('Please choose another transportation type.');
    return;
  }

  final capacity = seatCapacity[mode]!;
  print(
    '\n$mode seats up to $capacity person(s) (assumed for this prototype).',
  );
  final people = readChoice(
    'How many people will travel (1-$capacity)? ',
    1,
    capacity,
  );

  var freeSeats = 0;
  if (perPassengerModes.contains(mode)) {
    final spare = capacity - people;
    if (spare > 0) {
      print(
        'You can keep extra seats free for more space. You pay for every seat you reserve.',
      );
      freeSeats = readChoice(
        'How many extra seats do you want to keep free (0-$spare)? ',
        0,
        spare,
      );
    }
  } else {
    print('This is a private trip: the whole vehicle is yours for one fare.');
  }

  final fareText = requestFareText(
    mode,
    pickup,
    destination,
    people,
    freeSeats,
  );
  print('\nSummary');
  print('  Route:          $pickup -> $destination');
  print('  Transport:      $mode');
  print('  People:         $people');
  print('  Extra seats free: $freeSeats');
  print('  Estimated fare: $fareText');

  final driverType = driverTypeFor(mode);
  final available = countVerifiedDrivers(driverType);
  if (available == 0) {
    print(
      '\nNo verified $driverType driver is registered yet. Your request will wait.',
    );
  }

  print('\nSubmit this request?');
  print('  1. Yes, submit');
  print('  2. No, cancel');
  if (readChoice('Select number: ', 1, 2) == 2) {
    print('Request not submitted.');
    return;
  }

  final Map<String, dynamic> request = {
    'id': 'REQ-${requests.length + 1}',
    'passenger': me(),
    'pickup': pickup,
    'destination': destination,
    'mode': mode,
    'people': people,
    'freeSeats': freeSeats,
    'fare': fareText,
    'status': 'Pending',
    'driver': null,
    'declinedDrivers': <String>[],
  };
  requests.add(request);
  print('\nRequest ${request['id']} submitted. Status: Pending.');
  print('A verified $driverType driver can now accept it. Use "My Requests"');
  print('and "Notifications" to see the response.');
}

void printRequestDetails(Map<String, dynamic> r) {
  print('\n  Request:        ${r['id']}');
  print('  Route:          ${r['pickup']} -> ${r['destination']}');
  print('  Transport:      ${r['mode']}');
  print(
    '  People:         ${r['people']}   (extra seats kept free: ${r['freeSeats']})',
  );
  print('  Estimated fare: ${r['fare']}');
  print('  Status:         ${r['status']}');
  final driverName = r['driver'];
  if (driverName != null) {
    final d = findUser(driverName as String)!;
    print('  Driver:         ${d['name']} (${d['phone']})');
    print('  Vehicle:        ${d['vehicle']}, plate ${d['plate']}');
  }
}

String requestSummary(Map<String, dynamic> r) {
  return '${r['id']} | ${r['pickup']} -> ${r['destination']} | ${r['mode']} | ${r['status']}';
}

void passengerRequests() {
  printHeader('MY TRANSPORT REQUESTS');
  final mine = requests.where((r) => r['passenger'] == me()).toList();
  if (mine.isEmpty) {
    print('You have no requests yet.');
    return;
  }
  for (var i = 0; i < mine.length; i++) {
    print('  ${i + 1}. ${requestSummary(mine[i])}');
  }
  final pick = readChoice('\nOpen a request (0 to go back): ', 0, mine.length);
  if (pick == 0) return;
  manageRequest(mine[pick - 1]);
}

void manageRequest(Map<String, dynamic> r) {
  printRequestDetails(r);
  final status = r['status'];

  if (status == 'Awaiting Passenger') {
    final driver = findUser(r['driver'] as String)!;
    print('\nA driver has accepted your request. Do you accept this driver?');
    print('  1. Accept this driver');
    print('  2. Reject this driver (request goes back to Pending)');
    print('  3. Cancel the request');
    print('  4. Back');
    final choice = readChoice('Select number: ', 1, 4);
    if (choice == 1) {
      r['status'] = 'Confirmed';
      notify(
        driver['username'] as String,
        '${r['id']}: the passenger accepted you. Trip confirmed.',
      );
      print('\nDriver accepted. Request ${r['id']} is Confirmed.');
    } else if (choice == 2) {
      (r['declinedDrivers'] as List<String>).add(driver['username'] as String);
      r['driver'] = null;
      r['status'] = 'Pending';
      notify(
        driver['username'] as String,
        '${r['id']}: the passenger rejected you. The request is open to other drivers.',
      );
      print(
        '\nDriver rejected. Request ${r['id']} is Pending again so another driver can accept it.',
      );
    } else if (choice == 3) {
      cancelRequest(r);
    }
  } else if (status == 'Pending' || status == 'Confirmed') {
    print('\n  1. Cancel the request');
    print('  2. Back');
    if (readChoice('Select number: ', 1, 2) == 1) cancelRequest(r);
  }
}

void cancelRequest(Map<String, dynamic> r) {
  final driverName = r['driver'];
  r['status'] = 'Cancelled';
  if (driverName != null) {
    notify(
      driverName as String,
      '${r['id']}: the passenger cancelled the request.',
    );
  }
  print('\nRequest ${r['id']} cancelled.');
}

void reportFareIssue() {
  printHeader('REPORT FARE ISSUE');
  final from = chooseLocation('Pickup');
  final to = chooseLocation('Destination');
  if (!validRoute(from, to)) return;

  final mode = chooseFromList('Transportation type', fareModes);
  final reported = readAmount(
    'Fare you were asked to pay per passenger/trip (NLe): ',
  );
  final note = readText('Short description (optional): ');

  final fare = getFare(mode, from, to);
  print('\nRoute: $from -> $to | Mode: $mode');
  final listed = fare == null ? null : fare['amount'] as double?;
  if (fare == null || listed == null) {
    print('No fixed fare is available in the system to compare with.');
  } else {
    final difference = reported - listed;
    print(
      'Fare in the system: NLe ${listed.toStringAsFixed(1)} [${fare['source']}]',
    );
    print('Fare reported:      NLe ${reported.toStringAsFixed(1)}');
    if (difference > 0.05) {
      print(
        'Difference:         NLe ${difference.toStringAsFixed(1)} above the fare in the system',
      );
    } else if (difference < -0.05) {
      print(
        'Difference:         NLe ${(-difference).toStringAsFixed(1)} below the fare in the system',
      );
    } else {
      print('The reported fare matches the fare in the system.');
    }
    if (fare['source'] == 'Simulated estimate') {
      print('(The system fare is a simulated estimate, not an official fare.)');
    }
  }

  final id = 'RPT-${complaints.length + 1}';
  complaints.add({
    'id': id,
    'passenger': me(),
    'route': '$from -> $to',
    'mode': mode,
    'reported': reported,
    'note': note.isEmpty ? 'No description' : note,
    'status': 'Pending Review',
    'response': '',
  });
  notifyAllWithRole(
    'Administrator',
    'New fare issue report $id ($from -> $to, $mode).',
  );
  print('\nReport $id submitted. Status: Pending Review');
  print('This is a record for review. It is not a finding of fault.');
}

void myFareReports() {
  printHeader('MY FARE REPORTS');
  var count = 0;
  for (final c in complaints) {
    if (c['passenger'] != me()) continue;
    count++;
    print(
      '  ${c['id']}: ${c['route']} | ${c['mode']} | NLe ${(c['reported'] as double).toStringAsFixed(1)} | ${c['status']}',
    );
    if ((c['response'] as String).isNotEmpty) {
      print('       Administrator response: ${c['response']}');
    }
  }
  if (count == 0) print('  You have not submitted any reports.');
}

// --------------------
// DRIVER
// --------------------

void driverMenu() {
  while (true) {
    printMenuHeader('DRIVER MENU - ${currentUser!['name']}');
    print('1. Incoming Requests (accept or decline)');
    print('2. My Trips');
    print('3. My Profile');
    print('4. View Transportation Fares');
    print('5. Notifications (refresh)');
    print('6. Log out');

    final option = readChoice('\nSelect option: ', 1, 6);
    switch (option) {
      case 1:
        incomingRequests();
        break;
      case 2:
        driverTrips();
        break;
      case 3:
        driverProfile();
        break;
      case 4:
        viewFares();
        break;
      case 5:
        showNotifications();
        break;
      case 6:
        return;
    }
  }
}

void driverProfile() {
  final u = currentUser!;
  printHeader('MY PROFILE');
  print('  Name:     ${u['name']}');
  print('  Phone:    ${u['phone']}');
  print('  Type:     ${u['type']}');
  print('  Vehicle:  ${u['vehicle']}');
  print('  Plate:    ${u['plate']}');
  print(
    '  Status:   ${u['verified'] == true ? 'Verified' : 'Waiting for verification'}',
  );
}

void incomingRequests() {
  final driver = currentUser!;
  printHeader('INCOMING REQUESTS');
  if (driver['verified'] != true) {
    print('Your account is waiting for verification by the administrator.');
    print('You cannot receive requests yet.');
    return;
  }

  final open = requests.where((r) {
    final declined = r['declinedDrivers'] as List<String>;
    return r['status'] == 'Pending' &&
        driverTypeFor(r['mode'] as String) == driver['type'] &&
        !declined.contains(me());
  }).toList();

  if (open.isEmpty) {
    print('No pending requests for ${driver['type']} drivers right now.');
    print('Use Notifications (refresh) or come back later.');
    return;
  }

  for (var i = 0; i < open.length; i++) {
    final r = open[i];
    final passenger = findUser(r['passenger'] as String)!;
    print(
      '  ${i + 1}. ${r['id']} | ${passenger['name']} | ${r['pickup']} -> ${r['destination']} | ${r['mode']} | ${r['people']} person(s)',
    );
  }
  final pick = readChoice('\nOpen a request (0 to go back): ', 0, open.length);
  if (pick == 0) return;

  final r = open[pick - 1];
  final passenger = findUser(r['passenger'] as String)!;
  printRequestDetails(r);
  print('  Passenger:      ${passenger['name']} (${passenger['phone']})');
  print('\n  1. Accept this request');
  print('  2. Decline this request');
  print('  3. Back');
  final choice = readChoice('Select number: ', 1, 3);

  if (choice == 1) {
    r['driver'] = me();
    r['status'] = 'Awaiting Passenger';
    notify(
      r['passenger'] as String,
      '${r['id']}: ${driver['name']} accepted your request. Open My Requests to accept or reject this driver.',
    );
    print(
      '\nYou accepted ${r['id']}. Now waiting for the passenger to accept you.',
    );
  } else if (choice == 2) {
    (r['declinedDrivers'] as List<String>).add(me());
    print('\nYou declined ${r['id']}. Other drivers can still accept it.');
  }
}

void driverTrips() {
  printHeader('MY TRIPS');
  final mine = requests.where((r) => r['driver'] == me()).toList();
  if (mine.isEmpty) {
    print('You have no trips yet.');
    return;
  }
  for (var i = 0; i < mine.length; i++) {
    print('  ${i + 1}. ${requestSummary(mine[i])}');
  }
  final pick = readChoice('\nOpen a trip (0 to go back): ', 0, mine.length);
  if (pick == 0) return;

  final r = mine[pick - 1];
  printRequestDetails(r);
  if (r['status'] == 'Confirmed') {
    print('\n  1. Mark trip as completed');
    print('  2. Back');
    if (readChoice('Select number: ', 1, 2) == 1) {
      r['status'] = 'Completed';
      notify(
        r['passenger'] as String,
        '${r['id']}: your trip was marked as completed.',
      );
      print('\nTrip ${r['id']} marked as completed.');
    }
  }
}

// ---------------------
// ADMINISTRATOR
// ---------------------

void adminMenu() {
  while (true) {
    printMenuHeader('ADMINISTRATOR MENU - ${currentUser!['name']}');
    print('1. Verify Drivers');
    print('2. Manage Fares');
    print('3. Review Fare Issue Reports');
    print('4. Dashboard Summary');
    print('5. Notifications (refresh)');
    print('6. Log out');

    final option = readChoice('\nSelect option: ', 1, 6);
    switch (option) {
      case 1:
        verifyDrivers();
        break;
      case 2:
        manageFares();
        break;
      case 3:
        reviewReports();
        break;
      case 4:
        dashboard();
        break;
      case 5:
        showNotifications();
        break;
      case 6:
        return;
    }
  }
}

void verifyDrivers() {
  printHeader('VERIFY DRIVERS');
  final waiting = users
      .where((u) => u['role'] == 'Driver' && u['verified'] == false)
      .toList();
  if (waiting.isEmpty) {
    print('No drivers are waiting for verification.');
    return;
  }
  for (var i = 0; i < waiting.length; i++) {
    final u = waiting[i];
    print(
      '  ${i + 1}. ${u['name']} | ${u['type']} | ${u['vehicle']} | ${u['plate']} | ${u['phone']}',
    );
  }
  final pick = readChoice(
    '\nSelect a driver (0 to go back): ',
    0,
    waiting.length,
  );
  if (pick == 0) return;

  final u = waiting[pick - 1];
  print('\n  1. Verify this driver');
  print('  2. Back');
  if (readChoice('Select number: ', 1, 2) == 1) {
    u['verified'] = true;
    notify(
      u['username'] as String,
      'Your driver account has been verified. You can now receive requests.',
    );
    print('\n${u['name']} is now verified.');
  }
}

void manageFares() {
  while (true) {
    printHeader('MANAGE FARES');
    print('1. List published fares for a transport mode');
    print('2. Add or update a route fare');
    print('3. Update the flat pole-to-pole fare (Okada/Kekeh)');
    print('4. Back');
    final option = readChoice('\nSelect option: ', 1, 4);
    if (option == 1) listPublishedFares();
    if (option == 2) addOrUpdateFare();
    if (option == 3) updatePoleToPole();
    if (option == 4) return;
  }
}

void listPublishedFares() {
  final mode = chooseFromList('Transport mode', [
    'Okada',
    'Kekeh',
    'Poda-poda',
    'Bus',
  ]);
  print('\nPublished fares for $mode:');
  var count = 0;
  for (final t in tariffs) {
    if (t['mode'] != mode) continue;
    count++;
    final fare = t['fare'] as double?;
    final amount = fare == null
        ? "rider's discretion"
        : 'NLe ${fare.toStringAsFixed(1)}';
    final place = t['from'] == '*'
        ? 'Pole to pole'
        : '${t['from']} <-> ${t['to']}';
    print('  ${place.padRight(36)} $amount [${t['source']}]');
  }
  if (count == 0) print('  None.');
}

void addOrUpdateFare() {
  printHeader('ADD OR UPDATE A ROUTE FARE');
  final mode = chooseFromList('Transport mode', [
    'Okada',
    'Kekeh',
    'Poda-poda',
    'Bus',
  ]);
  final from = chooseLocation('From');
  final to = chooseLocation('To');
  if (!validRoute(from, to)) return;
  if (mode == 'Kekeh' && !(inWesternArea(from) && inWesternArea(to))) {
    print('\nKekeh do not run in the provinces. Fare not saved.');
    return;
  }
  final amount = readAmount('New fare (NLe): ');

  final existing = routeTariff(mode, from, to);
  if (existing != null) {
    existing['fare'] = amount;
    existing['source'] = 'Administrator update';
    print(
      '\nUpdated: $mode $from <-> $to is now NLe ${amount.toStringAsFixed(1)}.',
    );
  } else {
    tariffs.add(route(mode, from, to, amount, source: 'Administrator update'));
    print('\nAdded: $mode $from <-> $to at NLe ${amount.toStringAsFixed(1)}.');
  }
  notifyAllWithRole(
    'Passenger',
    'Fare update: $mode $from <-> $to is now NLe ${amount.toStringAsFixed(1)}.',
  );
}

void updatePoleToPole() {
  final mode = chooseFromList('Transport mode', ['Okada', 'Kekeh']);
  final amount = readAmount('New pole-to-pole fare (NLe): ');
  for (final t in tariffs) {
    if (t['mode'] == mode && t['from'] == '*') {
      t['fare'] = amount;
      t['source'] = 'Administrator update';
    }
  }
  print('\n$mode pole-to-pole fare is now NLe ${amount.toStringAsFixed(1)}.');
  notifyAllWithRole(
    'Passenger',
    'Fare update: $mode pole-to-pole fare is now NLe ${amount.toStringAsFixed(1)}.',
  );
}

void reviewReports() {
  printHeader('FARE ISSUE REPORTS');
  if (complaints.isEmpty) {
    print('No reports have been submitted.');
    return;
  }
  for (var i = 0; i < complaints.length; i++) {
    final c = complaints[i];
    print(
      '  ${i + 1}. ${c['id']} | ${c['route']} | ${c['mode']} | NLe ${(c['reported'] as double).toStringAsFixed(1)} | ${c['status']}',
    );
  }
  final pick = readChoice(
    '\nOpen a report (0 to go back): ',
    0,
    complaints.length,
  );
  if (pick == 0) return;

  final c = complaints[pick - 1];
  print('\n  Report:      ${c['id']}');
  print('  Route:       ${c['route']}');
  print('  Mode:        ${c['mode']}');
  print('  Reported:    NLe ${(c['reported'] as double).toStringAsFixed(1)}');
  print('  Description: ${c['note']}');
  print('  Status:      ${c['status']}');
  print('\n  1. Mark as Under Review');
  print('  2. Close the report');
  print('  3. Back');
  final choice = readChoice('Select number: ', 1, 3);
  if (choice == 3) return;

  final response = readText('Short message for the passenger (optional): ');
  c['status'] = choice == 1 ? 'Under Review' : 'Closed';
  c['response'] = response;
  notify(
    c['passenger'] as String,
    'Report ${c['id']} is now: ${c['status']}. ${response.isEmpty ? '' : response}',
  );
  print('\nReport ${c['id']} updated to ${c['status']}.');
}

void dashboard() {
  printHeader('DASHBOARD SUMMARY');
  final drivers = users.where((u) => u['role'] == 'Driver').length;
  final waiting = users
      .where((u) => u['role'] == 'Driver' && u['verified'] == false)
      .length;
  final passengers = users.where((u) => u['role'] == 'Passenger').length;
  print('  Registered passengers:        $passengers');
  print(
    '  Registered drivers:           $drivers (waiting for verification: $waiting)',
  );
  print('  Published fare records:       ${tariffs.length}');
  print('  Requests - total:             ${requests.length}');
  print(
    '  Requests - pending:           ${requests.where((r) => r['status'] == 'Pending').length}',
  );
  print(
    '  Requests - awaiting passenger: ${requests.where((r) => r['status'] == 'Awaiting Passenger').length}',
  );
  print(
    '  Requests - confirmed:         ${requests.where((r) => r['status'] == 'Confirmed').length}',
  );
  print(
    '  Requests - completed:         ${requests.where((r) => r['status'] == 'Completed').length}',
  );
  print(
    '  Fare reports pending review:  ${complaints.where((c) => c['status'] == 'Pending Review').length}',
  );
}

// -----------------
// MAIN
// -----------------
void main() {
  while (true) {
    printHeader('SALONE TRANSPORT HUB');
    print('1. Register');
    print('2. Log in');
    print('3. Browse Fares (no login)');
    print('4. Exit');

    final option = readChoice('\nSelect option: ', 1, 4);
    switch (option) {
      case 1:
        registerUser();
        break;
      case 2:
        loginUser();
        break;
      case 3:
        browseFares();
        break;
      case 4:
        print('\nThank you for using Salone Transport Hub. Goodbye.');
        return;
    }
  }
}
