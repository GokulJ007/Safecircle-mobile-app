/// Clean representation of selected place details to pass to Start Journey flows.
class SafeCirclePlace {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  SafeCirclePlace({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() {
    return 'SafeCirclePlace(placeId: $placeId, name: $name, address: $address, latitude: $latitude, longitude: $longitude)';
  }
}
