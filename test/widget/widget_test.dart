import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/widgets/my_button.dart';
import 'package:nivaas/widgets/my_textfield.dart';
import 'package:nivaas/features/auth/presentation/pages/login_page.dart';
import 'package:nivaas/features/auth/presentation/pages/signup_page.dart';
import 'package:nivaas/features/auth/presentation/view_model/auth_state.dart';
import 'package:nivaas/features/auth/presentation/providers/auth_provider.dart';
import 'package:nivaas/features/explore/data/models/accommodation_model.dart';
import 'package:nivaas/features/explore/data/models/experience_model.dart';
import 'package:nivaas/features/trips/data/models/booking_model.dart';
import 'package:nivaas/core/error/failures.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget wrapMaterial(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

Widget wrapRiverpod(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: child),
  );
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1: MyButton widget tests (4 tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('MyButton widget', () {
    // TEST 1
    testWidgets('renders the provided text label', (tester) async {
      await tester.pumpWidget(wrapMaterial(
        const MyButton(text: 'Continue'),
      ));

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    // TEST 2
    testWidgets('calls onPressed callback when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapMaterial(
        MyButton(text: 'Tap', onPressed: () => pressed = true),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    // TEST 3
    testWidgets('button is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(wrapMaterial(
        const MyButton(text: 'Disabled'),
      ));

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    // TEST 4
    testWidgets('has full-width layout with 50px height', (tester) async {
      await tester.pumpWidget(wrapMaterial(
        const MyButton(text: 'Full Width'),
      ));

      final sizedBox = tester.widget<SizedBox>(find.ancestor(
        of: find.byType(ElevatedButton),
        matching: find.byType(SizedBox),
      ));
      expect(sizedBox.width, double.infinity);
      expect(sizedBox.height, 50);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2: MyTextfield widget tests (4 tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('MyTextfield widget', () {
    // TEST 5
    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(wrapMaterial(
        const MyTextfield(hintText: 'Enter email'),
      ));

      expect(find.text('Enter email'), findsOneWidget);
    });

    // TEST 6
    testWidgets('applies obscureText and shows prefix icon', (tester) async {
      await tester.pumpWidget(wrapMaterial(
        const MyTextfield(
          hintText: 'Password',
          obscureText: true,
          icon: Icons.lock,
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    // TEST 7
    testWidgets('accepts text input via controller', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(wrapMaterial(
        MyTextfield(hintText: 'Type here', controller: controller),
      ));

      await tester.enterText(find.byType(TextField), 'Hello');
      expect(controller.text, 'Hello');
    });

    // TEST 8
    testWidgets('no icon renders no prefix icon', (tester) async {
      await tester.pumpWidget(wrapMaterial(
        const MyTextfield(hintText: 'No icon'),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.prefixIcon, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3: LoginPage widget tests (4 tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('LoginPage widget', () {
    // TEST 9
    testWidgets('renders email and password fields with login button',
        (tester) async {
      await tester.pumpWidget(wrapRiverpod(const LoginPage()));

      expect(find.text('Login'), findsWidgets); // AppBar + Button
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    // TEST 10
    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(wrapRiverpod(const LoginPage()));

      // Tap login without filling fields
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    // TEST 11
    testWidgets('shows validation error for invalid email', (tester) async {
      await tester.pumpWidget(wrapRiverpod(const LoginPage()));

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    // TEST 12
    testWidgets('has sign up navigation text button', (tester) async {
      await tester.pumpWidget(wrapRiverpod(const LoginPage()));

      expect(
        find.text("Don't have an account? Sign up"),
        findsOneWidget,
      );
      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4: SignupPage widget tests (4 tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('SignupPage widget', () {
    // TEST 13
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(wrapRiverpod(const SignupPage()));

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign Up'), findsWidgets); // AppBar + button
      // Name, Email, Phone, Password, Confirm Password = 5 fields
      expect(find.byType(TextFormField), findsNWidgets(5));
    });

    // TEST 14
    testWidgets('validates empty name field', (tester) async {
      await tester.pumpWidget(wrapRiverpod(const SignupPage()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    // TEST 15
    testWidgets('validates password too short', (tester) async {
      await tester.pumpWidget(wrapRiverpod(const SignupPage()));

      // Fill name and email to pass their validation
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test User'); // Name
      await tester.enterText(fields.at(1), 'test@email.com'); // Email
      await tester.enterText(fields.at(2), '9800000000'); // Phone
      await tester.enterText(fields.at(3), '123'); // Password (too short)
      await tester.enterText(fields.at(4), '123'); // Confirm

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    // TEST 16
    testWidgets('validates password mismatch', (tester) async {
      await tester.pumpWidget(wrapRiverpod(const SignupPage()));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), 'test@email.com');
      await tester.enterText(fields.at(2), '9800000000');
      await tester.enterText(fields.at(3), 'password1');
      await tester.enterText(fields.at(4), 'password2');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5: Accommodation card rendering tests (2 tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Accommodation card rendering', () {
    final testAccommodation = Accommodation(
      id: 'acc1',
      hostId: 'h1',
      title: 'Mountain Retreat',
      location: 'Pokhara, Nepal',
      price: 5000,
      maxGuests: 4,
      bedrooms: 2,
      beds: 3,
      bathrooms: 1,
      amenities: ['Wi-Fi', 'Pool', 'Parking'],
      images: ['/img1.jpg'],
    );

    // TEST 17
    testWidgets('renders accommodation title and location', (tester) async {
      await tester.pumpWidget(wrapMaterial(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(testAccommodation.title),
            Text(testAccommodation.location),
            Text('Rs. ${testAccommodation.price.toInt()} / night'),
            Text('${testAccommodation.maxGuests} guests · '
                '${testAccommodation.bedrooms} bedrooms · '
                '${testAccommodation.beds} beds'),
          ],
        ),
      ));

      expect(find.text('Mountain Retreat'), findsOneWidget);
      expect(find.text('Pokhara, Nepal'), findsOneWidget);
      expect(find.text('Rs. 5000 / night'), findsOneWidget);
      expect(find.text('4 guests · 2 bedrooms · 3 beds'), findsOneWidget);
    });

    // TEST 18
    testWidgets('renders amenity chips from accommodation', (tester) async {
      await tester.pumpWidget(wrapMaterial(
        Wrap(
          spacing: 8,
          children: testAccommodation.amenities
              .map((a) => Chip(label: Text(a)))
              .toList(),
        ),
      ));

      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.text('Pool'), findsOneWidget);
      expect(find.text('Parking'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(3));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6: Booking card rendering tests (2 tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Booking card rendering', () {
    // TEST 19
    testWidgets('renders stay booking card with correct details',
        (tester) async {
      final booking = Booking(
        id: 'b1',
        userId: 'u1',
        accommodationId: 'acc1',
        startDate: '2026-03-10',
        endDate: '2026-03-15',
        totalPrice: 25000,
        status: 'confirmed',
        accommodation: {
          '_id': 'acc1',
          'title': 'Lake House',
          'location': 'Pokhara',
          'images': ['/lake.jpg'],
        },
      );

      await tester.pumpWidget(wrapMaterial(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.itemTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(booking.itemLocation),
                const SizedBox(height: 8),
                Text('${booking.startDate} → ${booking.endDate}'),
                Text('Rs. ${booking.totalPrice.toInt()}'),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(booking.status.toUpperCase()),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Lake House'), findsOneWidget);
      expect(find.text('Pokhara'), findsOneWidget);
      expect(find.text('2026-03-10 → 2026-03-15'), findsOneWidget);
      expect(find.text('Rs. 25000'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
    });

    // TEST 20
    testWidgets('renders experience booking with pending status',
        (tester) async {
      final booking = Booking(
        id: 'b2',
        userId: 'u1',
        experienceId: 'exp1',
        startDate: '2026-04-01',
        endDate: '2026-04-01',
        totalPrice: 3000,
        status: 'pending',
        experience: {
          '_id': 'exp1',
          'title': 'Everest Base Camp Trek',
          'location': 'Solukhumbu',
          'images': ['/trek.jpg'],
        },
      );

      await tester.pumpWidget(wrapMaterial(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.itemTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(booking.itemLocation),
                Text('Rs. ${booking.totalPrice.toInt()}'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(booking.status.toUpperCase()),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Everest Base Camp Trek'), findsOneWidget);
      expect(find.text('Solukhumbu'), findsOneWidget);
      expect(find.text('Rs. 3000'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
    });
  });
}
