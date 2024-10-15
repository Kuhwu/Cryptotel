import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hotel_flutter/data/model/booking/booking_model.dart';
import 'package:hotel_flutter/logic/bloc/booking/booking_bloc.dart';
import 'package:hotel_flutter/logic/bloc/booking/booking_event.dart';
import 'package:hotel_flutter/logic/bloc/booking/booking_state.dart';
import 'package:intl/intl.dart';
import '../widgets/admin/admin_modal.dart';
import '../widgets/admin/admin_header.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? handleId;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  // Function to fetch bookings using Flutter Secure Storage
  Future<void> _fetchBookings() async {
    try {
      handleId = await _secureStorage.read(key: 'handleId');
      if (handleId != null) {
        context.read<BookingBloc>().add(FetchBookings(userId: handleId!));
      }
    } catch (e) {
      print('Error fetching ID from secure storage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Column(
          children: [
            AdminHeader(),
            const TabBar(
              tabs: [
                Tab(text: 'Rooms', icon: Icon(Icons.hotel)),
                Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
                Tab(text: 'Accepted', icon: Icon(Icons.check_circle)),
                Tab(text: 'Rejected', icon: Icon(Icons.cancel)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRoomsTab(context), // The "Rooms" tab content
                  _buildBookingList(_filterBookings(context, 'pending')),
                  _buildBookingList(_filterBookings(context, 'accepted')),
                  _buildBookingList(_filterBookings(context, 'rejected')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the "Rooms" tab
  Widget _buildRoomsTab(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        // Check if there are no hotels or restaurants created by the user
        if (state is BookingSuccess && state.bookings.isNotEmpty) {
          // Determine if there is any hotel or restaurant created
          final hasHotelOrResto = state.bookings.any((booking) =>
              (booking.hotelName?.isNotEmpty == true ||
                  booking.restaurantName?.isNotEmpty == true));

          if (!hasHotelOrResto) {
            // Show HotelorResto widget if no hotel or restaurant exists
            return const Hotelorresto();
          } else {
            // If hotel or restaurant exists, show the list of bookings
            return _buildBookingList(state.bookings);
          }
        } else {
          // If there are no bookings, show the default message
          return const Center(
            child: Text('No bookings available.'),
          );
        }
      },
    );
  }

  // Filter bookings based on status
  List<BookingModel> _filterBookings(BuildContext context, String status) {
    final state = context.read<BookingBloc>().state;
    if (state is BookingSuccess) {
      return state.bookings
          .where((b) => b.status?.toLowerCase() == status)
          .toList();
    }
    return [];
  }

  // Widget to build a list of bookings
  Widget _buildBookingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings available.'));
    }
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];

        // Determine which venue to display (Hotel or Restaurant)
        final venueName = booking.hotelName?.isNotEmpty == true
            ? 'Hotel: ${booking.hotelName ?? ''}'
            : 'Restaurant: ${booking.restaurantName ?? ''}';

        // Determine which detail to display (Room or Table Number)
        final venueDetail = booking.hotelName?.isNotEmpty == true
            ? 'Room: ${booking.roomName ?? 'N/A'}'
            : 'Table Number: ${booking.tableNumber ?? 'N/A'}';

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AdminModal(
                    booking: booking,
                    userId: handleId!,
                  );
                },
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15.0, top: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C3473),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'Status: ${booking.status?.capitalize() ?? 'Pending'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0, top: 5),
                  child: Text(
                    'User: ${booking.fullName}',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'Venue: $venueName',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    venueDetail,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'Check-in: ${DateFormat.yMMMd().format(booking.checkInDate)}',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'Check-out: ${DateFormat.yMMMd().format(booking.checkOutDate)}',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'Arrival Time: ${booking.timeOfArrival != null ? DateFormat.jm().format(booking.timeOfArrival!) : 'N/A'}',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0, bottom: 10),
                  child: Text(
                    'Departure Time: ${booking.timeOfDeparture != null ? DateFormat.jm().format(booking.timeOfDeparture!) : 'N/A'}',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class Hotelorresto extends StatelessWidget {
  const Hotelorresto({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Button for Hotel
            ElevatedButton(
              onPressed: () {
                // Add your logic here for Hotel button press
                print('Hotel button pressed');
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: const Color(0xFF1C3473), // Button color
              ),
              child: const Text(
                'Hotel',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20), // Space between buttons

            // Button for Resto
            ElevatedButton(
              onPressed: () {
                // Add your logic here for Resto button press
                print('Resto button pressed');
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: const Color(0xFF1C3473), // Button color
              ),
              child: const Text(
                'Resto',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
