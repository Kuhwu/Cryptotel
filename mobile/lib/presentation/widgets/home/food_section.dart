import 'package:flutter/material.dart';
import 'image_with_text.dart'; // Update with the correct path if necessary

class FoodSection extends StatelessWidget {
  const FoodSection({super.key});
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 380,
          child: ImageWithText(
            imagePath: 'assets/images/foods/food.png',
            text: 'List of Foods',
            height: 129.0,
            width: 380.0,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150.0,
              child: ImageWithText(
                imagePath: 'assets/images/foods/special_food.png',
                text: 'Special Food',
                height: 116.0,
                width: 150.0,
              ),
            ),
            SizedBox(
              width: 230,
              child: ImageWithText(
                imagePath: 'assets/images/foods/service_food.png',
                text: 'Service Food',
                height: 116.0,
                width: 230.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
