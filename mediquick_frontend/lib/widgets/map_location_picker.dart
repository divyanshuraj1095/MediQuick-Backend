import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng initialLocation;
  final Function(String address, LatLng location) onLocationSelected;

  const MapLocationPicker({
    super.key,
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final MapController _mapController = MapController();
  late LatLng _centerLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _centerLocation = widget.initialLocation;
  }

  Future<void> _confirmLocation() async {
    setState(() => _isLoading = true);
    
    String address = "${_centerLocation.latitude.toStringAsFixed(4)}, ${_centerLocation.longitude.toStringAsFixed(4)}";
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(_centerLocation.latitude, _centerLocation.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
        
        if (addressParts.isEmpty && place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (addressParts.isEmpty && place.name != null && place.name!.isNotEmpty) {
          addressParts.add(place.name!);
        }
        
        if (addressParts.isNotEmpty) {
          address = addressParts.join(', ');
        }
      }
    } catch (e) {
      // Ignore geocoding errors (like on Web) and use native coordinates
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLocationSelected(address, _centerLocation);
        Navigator.pop(context); // Close the dialog
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Delivery Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _centerLocation,
                      initialZoom: 15.0,
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture && position.center != null) {
                          setState(() {
                            _centerLocation = position.center!;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.mediquick_frontend',
                      ),
                    ],
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40.0), // Adjust pin pointing to exact center slightly upwards depending on icon
                      child: Icon(Icons.location_pin, color: AppTheme.dashboardGreen, size: 40),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dashboardGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Location', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
