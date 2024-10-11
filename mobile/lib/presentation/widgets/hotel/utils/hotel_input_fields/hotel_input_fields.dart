import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hotel_flutter/logic/bloc/booking/booking_bloc.dart';
import 'package:hotel_flutter/logic/bloc/booking/booking_event.dart';
import 'package:hotel_flutter/logic/bloc/booking/booking_state.dart';
import 'package:hotel_flutter/data/model/booking/booking_model.dart';
import 'package:hotel_flutter/presentation/widgets/hotel/utils/hotel_input_fields/date_time_helper.dart';
import 'package:hotel_flutter/presentation/widgets/hotel/utils/hotel_input_fields/input_field_helpers.dart';
import 'package:hotel_flutter/presentation/widgets/utils_widget/custom_dialog.dart'; // Import the CustomDialog widget

class HotelInputFields extends StatefulWidget {
  final String hotelId;
  final String roomId;
  final int capacity;

  const HotelInputFields({
    super.key,
    required this.hotelId,
    required this.roomId,
    required this.capacity,
  });

  @override
  State<HotelInputFields> createState() => _HotelInputFieldsState();
}

class _HotelInputFieldsState extends State<HotelInputFields> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController =
      TextEditingController(text: "+63 ");
  final TextEditingController addressController = TextEditingController();
  final TextEditingController checkInDateController = TextEditingController();
  final TextEditingController checkOutDateController = TextEditingController();
  final TextEditingController adultsController = TextEditingController();
  final TextEditingController childrenController = TextEditingController();
  final TextEditingController timeOfArrivalController = TextEditingController();
  final TextEditingController timeOfDepartureController =
      TextEditingController();

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  bool isBookButtonEnabled = false;
  String? userId;
  bool isLoading = false; // For button loading state

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkFieldsFilled();
  }

  Future<void> _loadUserData() async {
    userId = await secureStorage.read(key: 'userId');
    String? firstName = await secureStorage.read(key: 'firstName') ?? '';
    String? lastName = await secureStorage.read(key: 'lastName') ?? '';
    String? storedEmail = await secureStorage.read(key: 'email') ?? '';
    String? storedPhoneNumber =
        await secureStorage.read(key: 'phoneNumber') ?? '+63 ';

    setState(() {
      fullNameController.text = '$firstName $lastName'.trim();
      emailController.text = storedEmail;
      phoneNumberController.text = storedPhoneNumber;
    });

    _checkFieldsFilled();
  }

  void _checkFieldsFilled() {
    setState(() {
      isBookButtonEnabled = fullNameController.text.isNotEmpty &&
          emailController.text.isNotEmpty &&
          phoneNumberController.text.length >= 11 &&
          checkInDateController.text.isNotEmpty &&
          checkOutDateController.text.isNotEmpty &&
          adultsController.text.isNotEmpty &&
          childrenController.text.isNotEmpty;
    });
  }

  // Dialog to show when the check-in date is the same as the check-out date
  void _showDateErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return CustomDialog(
          title: 'Invalid Date Selection',
          description:
              'The check-in date cannot be the same as the check-out date. Please select valid dates to proceed.',
          buttonText: 'OK',
          secondButtonText: '',
          onButtonPressed: () {
            Navigator.of(context).pop();
          },
          onSecondButtonPressed: () {},
        );
      },
    );
  }

  void _showBookingSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return CustomDialog(
          title: 'Booking Successful',
          description:
              'Your booking has been successfully submitted and is currently being processed. You will be notified once it is confirmed.',
          buttonText: 'OK',
          secondButtonText: '',
          onButtonPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacementNamed('/homescreen');
          },
          onSecondButtonPressed: () {},
        );
      },
    );
  }

  void _showCapacityErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: 'Guest Limit Exceeded',
          description:
              'You have exceeded the maximum guest capacity for this room. Please reduce the number of guests to proceed.',
          buttonText: 'Close',
          onButtonPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          secondButtonText: '', // No second button needed
          onSecondButtonPressed: () {}, // No action
        );
      },
    );
  }

  void _createBooking(BuildContext context) {
    DateTime? checkInDate = DateTime.tryParse(checkInDateController.text);
    DateTime? checkOutDate = DateTime.tryParse(checkOutDateController.text);

    // Check if the check-in date is the same as the check-out date
    if (checkInDate != null &&
        checkOutDate != null &&
        checkInDate.isAtSameMomentAs(checkOutDate)) {
      _showDateErrorDialog(context);
      return; // Do not proceed if the date validation fails
    }

    DateTime? arrivalDateTime = combineDateAndTime(
        checkInDateController.text, timeOfArrivalController.text);
    DateTime? departureDateTime = combineDateAndTime(
        checkOutDateController.text, timeOfDepartureController.text);

    if (checkInDate != null &&
        checkOutDate != null &&
        arrivalDateTime != null &&
        departureDateTime != null &&
        userId != null) {
      final int totalGuests = (int.tryParse(adultsController.text) ?? 1) +
          (int.tryParse(childrenController.text) ?? 0);

      // Check if the total number of guests exceeds room capacity
      if (totalGuests > widget.capacity) {
        _showCapacityErrorDialog(context); // Show error dialog
        return; // Do not proceed with booking
      }

      final booking = BookingModel(
        bookingType: 'HotelBooking',
        hotelId: widget.hotelId,
        roomId: widget.roomId,
        fullName: fullNameController.text,
        email: emailController.text,
        phoneNumber: phoneNumberController.text,
        address: addressController.text,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        timeOfArrival: arrivalDateTime,
        timeOfDeparture: departureDateTime,
        adult: int.tryParse(adultsController.text) ?? 1,
        children: int.tryParse(childrenController.text) ?? 0,
      );

      setState(() {
        isLoading = true; // Show loading spinner
      });

      context.read<BookingBloc>().add(CreateBooking(
            booking: booking,
            userId: userId!,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingCreateSuccess) {
          setState(() {
            isLoading = false; // Hide loading spinner
          });
          _showBookingSuccessDialog(context);
        } else if (state is BookingFailure) {
          setState(() {
            isLoading = false; // Hide loading spinner
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create booking: ${state.error}')),
          );
        }
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: buildDatePickerField(checkInDateController,
                    'Check-in Date', context, 'Check-in date', () {
                  selectDate(context, checkInDateController);
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildDatePickerField(checkOutDateController,
                    'Check-out Date', context, 'Check-out date', () {
                  selectDate(context, checkOutDateController);
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: buildTimePickerField(
                    timeOfArrivalController, 'Time of Arrival', context, () {
                  selectTime(context, timeOfArrivalController);
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildTimePickerField(
                    timeOfDepartureController, 'Time of Departure', context,
                    () {
                  selectTime(context, timeOfDepartureController);
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: buildLabelledTextField(fullNameController, 'Full Name',
                    Icons.person, 'Juan Dela Cruz', _checkFieldsFilled),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildLabelledTextField(emailController, 'Email Address',
                    Icons.email, 'example@email.com', _checkFieldsFilled),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: buildLabelledTextField(
                    phoneNumberController,
                    'Phone Number',
                    Icons.phone,
                    '+63 9123456789',
                    _checkFieldsFilled),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildLabelledTextField(addressController, 'Address',
                    Icons.home, '123 Main St', _checkFieldsFilled),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: buildLabelledNumericTextField(adultsController,
                    'Adults (Pax)', Icons.people, '0', _checkFieldsFilled),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildLabelledNumericTextField(
                    childrenController,
                    'Children (Pax)',
                    Icons.child_care,
                    '0',
                    _checkFieldsFilled),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isBookButtonEnabled && !isLoading
                  ? () {
                      _createBooking(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isBookButtonEnabled && !isLoading
                    ? const Color.fromARGB(255, 29, 53, 115)
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}