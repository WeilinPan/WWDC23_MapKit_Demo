//
//  LocationDetailsView.swift
//  WWDC23_MapKit_Demo
//
//  Created by 潘威霖 on 2023/8/24.
//

import SwiftUI
import MapKit

struct LocationDetailsView: View {
    
    @Binding var mapSelection: MKMapItem?
    @Binding var show: Bool
    @State private var lookAroundScene: MKLookAroundScene?
    @Binding var getDirections: Bool
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(mapSelection?.placemark.name ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(mapSelection?.placemark.title ?? "")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                        .padding(.trailing)
                }
                
                Spacer()
                
                Button {
                    show.toggle()
                    mapSelection = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.gray, Color(.systemGray4))
                }
            }
            
            if let scene = lookAroundScene {
                LookAroundPreview(initialScene: scene)
                    .frame(width: 200)
                    .cornerRadius(12)
                    .padding()
            } else {
                ContentUnavailableView("NO Preview Avalible", systemImage: "eye.slash")
            }
            
            HStack(spacing: 24) {
                Button {
                    if let mapSelection {
                        mapSelection.openInMaps()
                    }
                } label: {
                    Text("Open in Maps")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 170, height: 48)
                        .background(.green)
                        .cornerRadius(12)
                }
                
                Button {
                    getDirections = true
                    show = false
                } label: {
                    Text("Get Directions")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 170, height: 48)
                        .background(.green)
                        .cornerRadius(12)
                }
            }
        }
        .onAppear {
            fetchLookAroundPreView()
        }
        .onChange(of: mapSelection) { oldValue, newValue in
            fetchLookAroundPreView()
        }
        .padding()
    }
}

extension LocationDetailsView {
    
    func fetchLookAroundPreView() {
        if let mapSelection {
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(mapItem: mapSelection)
                lookAroundScene = try? await request.scene
            }
        }
    }
    
}

#Preview {
    LocationDetailsView(mapSelection: .constant(nil), show: .constant(false), getDirections: .constant(false))
}
