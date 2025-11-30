import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:collection/collection.dart'; // NLatLngBounds.fromPoints 등을 사용하기 위해 추가
import '../api/dio_client.dart'; // DioClient

class MainMapPage extends StatefulWidget {
  @override
  _MainMapPageState createState() => _MainMapPageState();
}

class _MainMapPageState extends State<MainMapPage> {
  NaverMapController? _mapController;
  
  // 위치 추적 관련
  StreamSubscription<Position>? _positionStreamSubscription;
  NLatLng? _currentUserPosition; 
  NLatLng? _boardingStopPosition; 
  final Set<NMarker> _markers = {}; // 마커 관리

  // ⭐️ [Method 3 핵심] 하드코딩된 경로 데이터 정의 (최종 버전)
  static const Map<String, Map<String, num>> _MAJOR_ROUTES_DATA = {
    // Key: 목적지 좌표 (위도, 경도, 소수점 4자리까지)
    '36.7945,127.0735': { 
      'T_total': 12,    // 총 12분 소요 (실측값)
      'D_total': 1000, // 총 직선 거리 1000m (실측값)
    },
  };
  static const double _WALKING_SPEED = 80; // 분당 80m (폴백용)

  bool _isLoading = true;
  String _estimatedTime = "계산 중...";
  String _boardingLocation = "로딩 중...";
  String _boardingTime = "";
  
  String _walkingDistance = "- m";
  String _walkingTime = "- 분";

  static const NCameraPosition _initialCameraPosition = NCameraPosition(
    target: NLatLng(36.7945, 127.0735),
    zoom: 14.5,
  );

  @override
  void initState() {
    super.initState();
    _checkPermissionAndListenLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // --- 1. 위치 권한 확인 및 실시간 추적 ---
  Future<void> _checkPermissionAndListenLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    final locationSettings = const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
    
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      
      final newPos = NLatLng(position.latitude, position.longitude);
      _currentUserPosition = newPos;

      if (_mapController != null) {
        final locationOverlay = _mapController!.getLocationOverlay();
        locationOverlay.setPosition(newPos);
        locationOverlay.setIsVisible(true);
        _updatePathAndInfo(); // 위치 바뀔 때마다 경로 업데이트
      }
    });
  }

  // --- 2. 경로 계산 및 UI 업데이트 (Method 3 적용) ---
  void _updatePathAndInfo() {
    if (_currentUserPosition == null || _boardingStopPosition == null || _mapController == null) return;

    // 1. 현재 직선 거리 계산 (D_current)
    double currentStraightDistance = Geolocator.distanceBetween(
      _currentUserPosition!.latitude, _currentUserPosition!.longitude,
      _boardingStopPosition!.latitude, _boardingStopPosition!.longitude,
    );

    // 2. 목적지 좌표를 Key로 변환 (소수점 4자리까지 비교)
    final destKey = 
      '${_boardingStopPosition!.latitude.toStringAsFixed(4)},'
      '${_boardingStopPosition!.longitude.toStringAsFixed(4)}';

    double finalDistance;
    int finalMinutes;

    // 3. 하드코딩된 경로 데이터 확인 (Method 3)
    if (_MAJOR_ROUTES_DATA.containsKey(destKey)) {
      final data = _MAJOR_ROUTES_DATA[destKey]!;
      final totalTime = data['T_total'] as num;
      final totalStraightDistance = data['D_total'] as num;

      // Method 3: 남은 시간 = 총 시간 * (현재 직선 거리 / 총 직선 거리)
      final ratio = currentStraightDistance / totalStraightDistance;
      finalMinutes = (totalTime * ratio).ceil();
      finalDistance = (finalMinutes * _WALKING_SPEED); 

    } else {
      // 4. 폴백 (Method 1: 보정 계수 1.3 적용)
      const correctionFactor = 1.3;
      finalDistance = currentStraightDistance * correctionFactor;
      finalMinutes = (finalDistance / _WALKING_SPEED).ceil();
    }

    // [안전장치] 선 지우고 다시 그림 (경로 업데이트)
    try { 
      _mapController!.deleteOverlay(NOverlayInfo(type: NOverlayType.polylineOverlay, id: 'walking_path_main'));
    } catch (e) {}

    final pathOverlay = NPolylineOverlay(
      id: 'walking_path_main',
      coords: [_currentUserPosition!, _boardingStopPosition!],
      color: Colors.blueAccent, width: 6,
    );
    _mapController!.addOverlay(pathOverlay);
    
    if (mounted) {
      setState(() {
        _walkingDistance = finalDistance > 1000 ? "${(finalDistance / 1000).toStringAsFixed(1)} km" : "${finalDistance.toStringAsFixed(0)} m";
        _walkingTime = "$finalMinutes 분";
      });
    }
  }

  // --- 3. 데이터 가져오기 (마커 설정 및 경로 시작) ---
  Future<void> _fetchBusData() async {
    try {
      // DioClient를 사용한 데이터 fetch 및 마커 업데이트 로직
      // --- 테스트용 가짜 데이터 ---
      await Future.delayed(const Duration(milliseconds: 500));
      // ------------------------

      // 아산역 좌표 (목적지 설정)
      final stopPosition = NLatLng(36.7945, 127.0735); 
      final busPosition = NLatLng(36.7930, 127.0750); 

      _boardingStopPosition = stopPosition; // 목적지 변수에 할당 (Method 3 키와 일치)

      final Set<NMarker> localMarkers = {
        NMarker(id: 'bus_stop', position: stopPosition, caption: NOverlayCaption(text: '아산역')),
        NMarker(id: 'current_bus', position: busPosition, caption: NOverlayCaption(text: '현재 셔틀'), iconTintColor: Colors.green),
      };
      
      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.addAll(localMarkers);
          _isLoading = false;
        });
      }

      if (_mapController != null) {
        await _mapController!.clearOverlays(type: NOverlayType.marker);
        await _mapController!.addOverlayAll(_markers);
        
        // 데이터 로딩 후 경로 즉시 업데이트 (Location Stream이 시작되었으면 선이 그려짐)
        _updatePathAndInfo();
      }

    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // --- 4. UI 빌드 및 헬퍼 함수 ---
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildNoticeBar(),
        Expanded(
          child: Stack(
            children: [
              NaverMap(
                options: const NaverMapViewOptions(
                  initialCameraPosition: _initialCameraPosition,
                  locationButtonEnable: true, mapType: NMapType.basic,
                ),
                onMapReady: (controller) {
                  _mapController = controller;
                  _fetchBusData(); 
                },
              ),
              Positioned(top: 16, right: 16, child: _buildInfoCard()),
              
              // 하단 정보 카드 (도보 거리/시간)
              Positioned(
                bottom: 20, left: 20, right: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("아산역까지 거리", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        SizedBox(height: 4),
                        Text(_walkingDistance, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[800])),
                      ]),
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text("도보 예상 시간", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        SizedBox(height: 4),
                        Text(_walkingTime, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                      ]),
                    ],
                  ),
                ),
              ),

              if (_isLoading) Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ],
    );
  }
  
  // --- 헬퍼 위젯 정의 ---

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(Icons.directions_bus_filled, size: 40, color: Colors.blue[800]),
            SizedBox(width: 12),
            Text('선문대 셔틀버스', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF202020))),
            Spacer(),
            Icon(Icons.star_border, size: 30, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(color: Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12.0)),
        child: Row(children: [Text('공지사항', style: TextStyle(fontSize: 14, color: Color(0xFF202020)))]),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.blue[800]!, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('탑승 위치 / 출발', style: TextStyle(fontSize: 12, color: Color(0xFF616161), fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("$_boardingLocation / $_boardingTime", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
          SizedBox(height: 4),
          Text("셔틀 도착까지 $_estimatedTime", style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}