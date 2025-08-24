import SwiftUI
import MapKit

struct MapLocationView: View {
    let nextStep: () -> Void
    
    @EnvironmentObject var locationViewModel: LocationViewModel
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showConfirmation = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 16.5062, longitude: 80.6480), // Amaravati default
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var animateInstructions = false
    
    var body: some View {
        ZStack {
            // Map
            MapView(
                region: $mapRegion,
                selectedCoordinate: $selectedCoordinate,
                onTap: { coordinate in
                    selectedCoordinate = coordinate
                    locationViewModel.setSelectedLocation(coordinate)
                    withAnimation(.spring()) {
                        showConfirmation = true
                    }
                }
            )
            .ignoresSafeArea(edges: .bottom)
            
            // Top Overlay
            VStack {
                // Header Card
                VStack(spacing: 12) {
                    HStack {
                        Button(action: {
                            // Go back
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("Select Location")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    
                    Text("Tap anywhere on the map to select your location")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .scaleEffect(animateInstructions ? 1.0 : 0.9)
                        .opacity(animateInstructions ? 1.0 : 0.7)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateInstructions)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Confirmation Overlay
            if showConfirmation {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showConfirmation = false
                        }
                    }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    LocationConfirmationCard(
                        coordinate: selectedCoordinate,
                        onConfirm: {
                            withAnimation(.spring()) {
                                showConfirmation = false
                            }
                            nextStep()
                        },
                        onCancel: {
                            withAnimation(.spring()) {
                                showConfirmation = false
                                selectedCoordinate = nil
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            
            // Current Location Button
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        locationViewModel.getCurrentLocation { coordinate in
                            if let coordinate = coordinate {
                                mapRegion.center = coordinate
                                selectedCoordinate = coordinate
                                withAnimation(.spring()) {
                                    showConfirmation = true
                                }
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.blue)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, showConfirmation ? 300 : 100)
                }
            }
        }
        .onAppear {
            animateInstructions = true
        }
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    let onTap: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        if let coordinate = selectedCoordinate {
            // Remove existing annotations
            mapView.removeAnnotations(mapView.annotations)
            
            // Add new annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Selected Location"
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            parent.onTap(coordinate)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "LocationPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerAnnotationView = annotationView as? MKMarkerAnnotationView {
                markerAnnotationView.markerTintColor = .systemOrange
                markerAnnotationView.glyphImage = UIImage(systemName: "sun.max.fill")
            }
            
            return annotationView
        }
    }
}

struct LocationConfirmationCard: View {
    let coordinate: CLLocationCoordinate2D?
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                
                Text("Confirm Location")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // Coordinates
            if let coordinate = coordinate {
                VStack(spacing: 8) {
                    Text("Selected Coordinates")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text("Latitude: \(coordinate.latitude, specifier: "%.6f")")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Text("Longitude: \(coordinate.longitude, specifier: "%.6f")")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            
            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                )
                
                Button("Confirm") {
                    onConfirm()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
    }
}

#Preview {
    MapLocationView(nextStep: {})
        .environmentObject(LocationViewModel())
}
