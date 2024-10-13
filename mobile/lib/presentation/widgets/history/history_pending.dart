import 'package:flutter/material.dart';
import 'package:hotel_flutter/data/model/booking/booking_model.dart';
import 'package:hotel_flutter/presentation/widgets/history/history_pendingmodal.dart';
import 'package:intl/intl.dart';

class HistoryPendingBody extends StatelessWidget {
  final List<BookingModel> pendingBookings;
  final String userId; // Receive userId from HistoryScreen

  const HistoryPendingBody({
    super.key,
    required this.pendingBookings,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: pendingBookings.isNotEmpty
              ? ListView.builder(
                  itemCount: pendingBookings.length,
                  itemBuilder: (context, index) {
                    final booking = pendingBookings[index];

                    // Determine the display name
                    String displayName = (booking.restaurantName != null &&
                            booking.restaurantName!.isNotEmpty)
                        ? booking.restaurantName!
                        : '${booking.hotelName ?? ''} - ${booking.roomName ?? ''}';

                    return Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 10.0),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0, vertical: 4.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1C3473),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            child: const Text(
                                              'Status: Pending',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          'Check-in: ${booking.checkInDate.toLocal().toString().split(' ')[0]}',
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                        Text(
                                          'Check-out: ${booking.checkOutDate.toLocal().toString().split(' ')[0]}',
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                        Text(
                                          'Arrival Time: ${booking.timeOfArrival != null ? DateFormat.jm().format(booking.timeOfArrival!) : 'N/A'}',
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                        Text(
                                          'Departure Time: ${booking.timeOfDeparture != null ? DateFormat.jm().format(booking.timeOfDeparture!) : 'N/A'}',
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return PendingModal(
                                            booking: booking,
                                            userId: userId, // Pass userId here
                                          );
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1C3473),
                                    ),
                                    child: const Text('Options'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/icons/booknow.png', // Corrected the path
                        width: 100, // Adjust size as needed
                        height: 100,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Pending, yet!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Make a booking with CRYPTOTEL & enjoy your stay',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, '/homescreen'); // Navigate to homescreen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C3473),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Book Now'),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
