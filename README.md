# Waste Logistics - Construction Waste & Recycling Platform

A comprehensive Flutter application for managing construction waste pickup and recycling logistics. The platform connects customers, drivers, and recycling facilities in an efficient ecosystem.

## Features

### For Customers
- **Schedule Waste Pickup**: Easy booking for construction waste collection
- **Real-time Tracking**: Track your orders in real-time with OpenStreetMaps
- **Multiple Waste Types**: Support for various waste types (concrete, metal, wood, plastic, etc.)
- **Order History**: View all past and current orders
- **Secure Payments**: Integrated payment processing

### For Recyclers
- **Order Management**: View and manage incoming waste orders
- **Capacity Tracking**: Monitor facility capacity in real-time
- **Revenue Tracking**: Track earnings and payments
- **Rating System**: Build reputation through customer reviews

### For Drivers
- **Order Acceptance**: Accept and manage pickup orders
- **Navigation**: Built-in navigation to pickup locations
- **Earnings Dashboard**: Track daily, weekly, and monthly earnings
- **Availability Toggle**: Go online/offline to control order flow

### For Admins
- **Dashboard Overview**: Comprehensive platform statistics
- **Order Management**: Monitor and manage all orders
- **User Management**: Manage customers, drivers, and recyclers
- **Analytics**: Detailed analytics and reporting

## Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Maps**: OpenStreetMaps (flutter_map)
- **Location**: Geolocator, Geocoding
- **Payments**: Stripe (Flutter Stripe)
- **Local Storage**: Hive, SharedPreferences

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode
- Supabase account
- Stripe account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/waste_logistics.git
cd waste_logistics
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Supabase:
- Create a Supabase project at https://supabase.com
- Run the SQL schema provided in the documentation
- Get your Supabase URL and anon key
- Update the keys in `lib/main.dart`

4. Configure Stripe:
- Get your Stripe publishable and secret keys
- Update the keys in `lib/services/payment_service.dart`

5. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── order.dart
│   ├── recycler.dart
│   └── driver.dart
├── screens/                  # UI screens
│   ├── splash/
│   ├── auth/
│   ├── customer/
│   ├── recycler/
│   ├── driver/
│   └── admin/
├── services/                 # Business logic & API calls
│   ├── auth_service.dart
│   ├── order_service.dart
│   ├── recycler_service.dart
│   ├── driver_service.dart
│   ├── payment_service.dart
│   └── location_service.dart
├── widgets/                  # Reusable widgets
│   └── common_widgets.dart
├── utils/                    # Utility functions
│   └── app_utils.dart
└── theme/                    # App theming
    └── app_theme.dart
```

## User Types

### Customer
- Can schedule waste pickups
- Track orders in real-time
- View order history
- Make payments

### Recycler
- View incoming orders
- Manage facility capacity
- Track revenue
- Accept/reject orders

### Driver
- Accept pickup orders
- Navigate to locations
- Track earnings
- Manage availability

### Admin
- View platform statistics
- Manage all orders
- Manage users
- View analytics

## Waste Types Supported

- Concrete
- Metal
- Wood
- Plastic
- Glass
- Drywall
- Asphalt
- Mixed
- Other

## Order Status Flow

1. **Pending** - Order placed, awaiting driver assignment
2. **Confirmed** - Driver assigned, pickup scheduled
3. **In Progress** - Driver en route to pickup location
4. **Completed** - Waste collected and delivered
5. **Cancelled** - Order cancelled by customer or admin

## Payment Flow

1. Customer places order
2. Estimated price calculated based on waste type and weight
3. Payment processed via Stripe
4. Final price adjusted based on actual weight
5. Driver and recycler receive their respective payments

## Security Features

- Supabase Authentication
- Secure payment processing with Stripe
- Role-based access control
- Data encryption at rest and in transit

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Support

For support, please contact support@wastelogistics.com

## Roadmap

- [ ] Push notifications for order updates
- [ ] In-app chat between customers and drivers
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Dark mode improvements
- [ ] Offline mode support
- [ ] Barcode/QR code scanning for waste identification
- [ ] Integration with recycling facility management systems
