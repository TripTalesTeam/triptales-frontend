//
//  JournalView.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 9/5/2568 BE.
//

import SwiftUI
import MapKit

// MARK: - Location Model
struct Location: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Journal View (Map with Pins)
struct JournalView: View {
    @AppStorage("username") var username: String = ""
    @AppStorage("token") var token: String = ""
    
    let locations = [
        Location(coordinate: CLLocationCoordinate2D(latitude: 19.85627, longitude: 102.49550)), // Laos
        Location(coordinate: CLLocationCoordinate2D(latitude: 15.87003, longitude: 100.99254)), // Thailand
        Location(coordinate: CLLocationCoordinate2D(latitude: 12.56568, longitude: 104.99101))  // Cambodia
    ]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 16.0, longitude: 103.0),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: locations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .foregroundColor(.red)
                        .frame(width: 30, height: 30)
                }
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // Add new pin action
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding()
                }
                .padding()
//                .background(Color(red: 1.0, green: 0.94, blue: 0.92))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.bottom, 10)
            }
        }
    }
}
