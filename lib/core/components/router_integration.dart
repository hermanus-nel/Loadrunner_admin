// ============================================================
// STEP 13: DOCUMENT VIEWER - ROUTER INTEGRATION
// ============================================================
//
// Add this route to your app_router.dart file in the routes list.
//
// Note: The DocumentViewerScreen is designed to work with both:
// 1. Direct Navigator.push() via the extension method
// 2. GoRouter with extra parameters
//
// ============================================================

// OPTION 1: Using Navigator extension (RECOMMENDED)
// ============================================================
// This is the simplest approach and works without modifying the router.
//
// Usage in any screen:
// ```dart
// import 'package:loadrunner_admin/core/components/document_viewer_screen.dart';
//
// // Navigate to viewer
// context.pushDocumentViewer(
//   documents: [
//     ViewerDocument(url: 'https://example.com/doc1.jpg', label: 'License Front'),
//     ViewerDocument(url: 'https://example.com/doc2.jpg', label: 'License Back'),
//   ],
//   initialIndex: 0,
//   title: 'Driver Documents',
// );
// ```

// OPTION 2: Using GoRouter (if you prefer centralized routing)
// ============================================================
// Add this import to app_router.dart:
// ```dart
// import '../components/document_viewer_screen.dart';
// ```
//
// Add this route inside your routes list:
// ```dart
// GoRoute(
//   path: '/document-viewer',
//   name: 'documentViewer',
//   pageBuilder: (context, state) {
//     final extra = state.extra as Map<String, dynamic>?;
//     final documents = (extra?['documents'] as List<dynamic>?)
//             ?.map((d) => d as ViewerDocument)
//             .toList() ??
//         [];
//     final initialIndex = extra?['initialIndex'] as int? ?? 0;
//     final title = extra?['title'] as String?;
//
//     return CustomTransitionPage(
//       key: state.pageKey,
//       child: DocumentViewerScreen(
//         documents: documents,
//         initialIndex: initialIndex,
//         title: title,
//       ),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return FadeTransition(
//           opacity: animation,
//           child: child,
//         );
//       },
//     );
//   },
// ),
// ```
//
// Usage with GoRouter:
// ```dart
// context.push(
//   '/document-viewer',
//   extra: {
//     'documents': [
//       ViewerDocument(url: 'https://...', label: 'License Front'),
//       ViewerDocument(url: 'https://...', label: 'License Back'),
//     ],
//     'initialIndex': 0,
//     'title': 'Driver Documents',
//   },
// );
// ```

// UPDATING DRIVER PROFILE SCREEN TO USE NEW VIEWER
// ============================================================
// In driver_profile_screen.dart, update the _showImageViewer method:
//
// ```dart
// void _showDocumentViewer(List<DriverDocument> documents, int initialIndex) {
//   context.pushDocumentViewer(
//     documents: documents.map((doc) => ViewerDocument(
//       url: doc.docUrl,
//       label: doc.label,
//     )).toList(),
//     initialIndex: initialIndex,
//     title: 'Driver Documents',
//   );
// }
// ```
//
// For vehicle photos:
// ```dart
// void _showVehiclePhotos(VehicleEntity vehicle) {
//   final photos = <ViewerDocument>[];
//   
//   if (vehicle.photoUrl != null) {
//     photos.add(ViewerDocument(url: vehicle.photoUrl!, label: 'Main Photo'));
//   }
//   if (vehicle.registrationDocumentUrl != null) {
//     photos.add(ViewerDocument(url: vehicle.registrationDocumentUrl!, label: 'Registration'));
//   }
//   if (vehicle.insuranceDocumentUrl != null) {
//     photos.add(ViewerDocument(url: vehicle.insuranceDocumentUrl!, label: 'Insurance'));
//   }
//   if (vehicle.roadworthyCertificateUrl != null) {
//     photos.add(ViewerDocument(url: vehicle.roadworthyCertificateUrl!, label: 'Roadworthy'));
//   }
//   if (vehicle.additionalPhotos != null) {
//     for (int i = 0; i < vehicle.additionalPhotos!.length; i++) {
//       photos.add(ViewerDocument(
//         url: vehicle.additionalPhotos![i],
//         label: 'Photo ${i + 1}',
//       ));
//     }
//   }
//   
//   if (photos.isNotEmpty) {
//     context.pushDocumentViewer(
//       documents: photos,
//       title: '${vehicle.make} ${vehicle.model} - Photos',
//     );
//   }
// }
// ```

// EXPORTS
// ============================================================
// Add to lib/core/core.dart or create lib/core/components/components.dart:
//
// ```dart
// export 'document_viewer_screen.dart';
// export 'document_viewer_state.dart';
// export 'document_viewer_controller.dart';
// ```
