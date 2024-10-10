const User = require('../models/User');
const Restaurant = require('../models/Restaurant');
const Booking = require('../models/Booking');
const { uploadEveryImage } = require('../middleware/imageUpload');
const { calculateAveragePrice } = require('../middleware/averageCalculator');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');

const average = async() => {
    console.log('Fetching all restaurants to calculate average price...');
    const restaurants = await Restaurant.find(); // Fetch all restaurants
    if (!restaurants.length) {
        console.log('No restaurants found. Returning average price as 0.');
        return 0; // If no restaurants exist, return 0
    }

    // Calculate total price
    const totalPrice = restaurants.reduce((sum, restaurant) => sum + restaurant.price, 0);
    const averagePrice = totalPrice / restaurants.length; // Calculate average
    console.log(`Calculated average price: ${averagePrice}`);
    return averagePrice;
};

// Get a restaurant by ID or all restaurants
exports.getRestaurant = catchAsync(async(req, res, next) => {
    const restaurantId = req.params.id;
    let restaurant;

    console.log(`Fetching restaurant with ID: ${restaurantId}`);

    if (restaurantId) {
        restaurant = await Restaurant.findById(restaurantId).populate('ratings');
        if (!restaurant) {
            console.log('Restaurant not found.');
            return next(new AppError('Restaurant not found with this ID.', 404));
        }
        console.log('Restaurant found:', restaurant);
    } else {
        restaurant = await Restaurant.find(); // Get all restaurants if no ID is provided
        console.log('All restaurants fetched:', restaurant);
    }

    res.status(200).json({
        status: 'success',
        data: {
            restaurant,
        },
    });
});

// Create a restaurant
exports.createRestaurant = catchAsync(async(req, res, next) => {
    const { tableNumber, name, price, capacity, ratingId } = req.body;

    console.log('Creating restaurant with data:', { tableNumber, name, price, capacity, ratingId });

    let restaurantImage = undefined;

    // Handle image upload if a file is provided
    if (req.file) {
        try {
            restaurantImage = await uploadEveryImage(req);
            console.log('Image uploaded successfully:', restaurantImage);
        } catch (uploadErr) {
            console.error('Image upload error:', uploadErr);
            return res.status(500).json({
                status: 'error',
                message: 'Image upload failed',
                error: uploadErr.message || uploadErr,
            });
        }
    } else {
        console.log('No image file provided for the restaurant.');
    }

    // Calculate the average price for all restaurants
    // const averagePrice = await average();
    console.log('Calculated average price for new restaurant:', averagePrice);

    // Create the restaurant with multiple ratingIds (if provided, otherwise null)
    const newRestaurant = await Restaurant.create({
        tableNumber,
        restaurantImage: restaurantImage || undefined, // Assign image if available
        name,
        price,
        capacity,
        ratings: ratingId && ratingId.length ? ratingId : [], // Assign multiple ratingIds or an empty array
        averagePrice, // Include average price in the new restaurant data
    });

    console.log('New restaurant created:', newRestaurant);

    // Respond with the new restaurant data and the updated average price
    res.status(201).json({
        status: 'success',
        data: {
            restaurant: newRestaurant,
            averagePrice,
        },
    });

    console.log('Response sent with new restaurant data and average price.');
});

// Update a restaurant by ID
exports.updateRestaurant = catchAsync(async(req, res, next) => {
    const restaurantId = req.params.id;

    console.log(`Updating restaurant with ID: ${restaurantId}`);

    // Check if the restaurant exists
    const restaurant = await Restaurant.findById(restaurantId);
    if (!restaurant) {
        console.log('Restaurant not found for update.');
        return next(new AppError('Restaurant not found with this ID.', 404));
    }

    let restaurantImage = undefined;

    // Handle image upload if a file is provided
    if (req.file) {
        try {
            restaurantImage = await uploadEveryImage(req);
            console.log('Restaurant image updated:', restaurantImage);
            req.body.restaurantImage = restaurantImage; // Add image to update body
        } catch (uploadErr) {
            console.error('Image upload error:', uploadErr);
            return res.status(500).json({
                status: 'error',
                message: 'Image upload failed',
                error: uploadErr.message || uploadErr,
            });
        }
    }

    // Update the restaurant
    const updatedRestaurant = await Restaurant.findByIdAndUpdate(restaurantId, req.body, {
        new: true,
        runValidators: true,
    });

    if (!updatedRestaurant) {
        console.log('Failed to update restaurant. Not found.');
        return next(new AppError('Restaurant not found with this ID.', 404));
    }

    // Update the average price of restaurants
    const averagePrice = await calculateAveragePrice();
    console.log('Updated average price for restaurants:', averagePrice);

    res.status(200).json({
        status: 'success',
        data: {
            restaurant: updatedRestaurant,
        },
    });
});

// Delete a restaurant by ID
exports.deleteRestaurant = catchAsync(async(req, res, next) => {
    const restaurantId = req.params.id;

    console.log(`Deleting restaurant with ID: ${restaurantId}`);

    const restaurant = await Restaurant.findById(restaurantId);
    if (!restaurant) {
        console.log('Restaurant not found for deletion.');
        return next(new AppError('Restaurant not found with this ID.', 404));
    }

    await Restaurant.findByIdAndDelete(restaurantId);
    console.log('Restaurant deleted successfully.');

    // Update average price after restaurant deletion
    const averagePrice = await calculateAveragePrice();
    console.log('Updated average price after restaurant deletion:', averagePrice);

    res.status(204).json({
        status: 'success',
        data: null,
    });
});