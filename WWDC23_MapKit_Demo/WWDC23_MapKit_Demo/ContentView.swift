//
//  ContentView.swift
//  WWDC23_MapKit_Demo
//
//  Created by 潘威霖 on 2023/8/24.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var cameraPosition: MapCameraPosition = .region(.userRegion)
    @State private var searchText: String = ""
    @State private var results = [MKMapItem]()
    
    @State private var mapSelection: MKMapItem?
    
    @State private var showDetails: Bool = false
    
    @State private var getDirections: Bool = false
    @State private var routeDisplaying: Bool = false
    @State private var route: MKRoute?
    @State private var routeDestination: MKMapItem?
    
    var body: some View {
        Map(position: $cameraPosition, selection: $mapSelection) {
//            Marker("My Location", coordinate: .userLocation)
            Annotation("My Location", coordinate: .userLocation) {
                ZStack {
                    Circle()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.blue.opacity(0.25))
                    
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                    
                    Circle()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.blue)
                }
            }
            .annotationTitles(.hidden)
            
            ForEach(results, id: \.self) { item in
                let placemark = item.placemark
                Marker(placemark.name ?? "", coordinate: placemark.coordinate)
            }
            
            if let route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 5)
            }
        }
        .mapControls {
            /// 旋轉地圖時顯示方位
            MapCompass()
            /// 跑出2D、3D選項按鈕
            MapPitchButton()
            /// 回到User Location
            MapUserLocationButton()
        }
        .overlay(alignment: .top) {
            TextField("Search for a location...", text: $searchText)
                .font(.subheadline)
                .padding(12)
                .background(.white)
                .padding()
                .padding(.trailing, 50)
                .shadow(radius: 10)
        }
        .onSubmit(of: .text) {
            if searchText.isEmpty {
                self.cameraPosition = .region(.userRegion)
                self.results.removeAll()
                self.clear()
            } else {
                Task {
                    await searchPlaces()
                }
            }
        }
        .onChange(of: mapSelection, { oldValue, newValue in
            showDetails = newValue != nil
            
            clear()
        })
        .sheet(isPresented: $showDetails, content: {
            LocationDetailsView(mapSelection: $mapSelection, show: $showDetails, getDirections: $getDirections)
                .presentationDetents([.height(340)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(340)))
                .presentationCornerRadius(12)
        })
        .onChange(of: getDirections, { oldValue, newValue in
            if newValue {
                fetchRoute()
            }
        })
    }
}

extension ContentView {
    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = .userRegion
        
        let results = try? await MKLocalSearch(request: request).start()
        self.results = results?.mapItems ?? []
    }
    
    func fetchRoute() {
        if let mapSelection {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: .userLocation))
            request.destination = mapSelection
            
            Task {
                let result = try? await MKDirections(request: request).calculate()
                route = result?.routes.first
                routeDestination = mapSelection
                
                withAnimation(.snappy) {
                    routeDisplaying = true
                    showDetails = false
                    
                    if let rect = route?.polyline.boundingMapRect, routeDisplaying {
                        cameraPosition = .rect(rect)
                    }
                }
            }
        }
    }
    
    func clear() {
        getDirections = false
        route = nil
        routeDestination = nil
        routeDisplaying = false
    }
}

extension CLLocationCoordinate2D {
    static var userLocation: CLLocationCoordinate2D {
        return .init(latitude: 25.040898820548488, longitude: 121.56701099224831)
    }
}

extension MKCoordinateRegion {
    static var userRegion: MKCoordinateRegion {
        return .init(center: .userLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
    }
}

#Preview {
    ContentView()
}
