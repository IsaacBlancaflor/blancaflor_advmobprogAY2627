# firstapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

LAB 3
Cart model, service, and screen interaction: Cart and CartProduct in models/cart.dart mirror the JSON shape returned by the dummyjson Carts API, with fromJson factories converting raw API data into typed Dart objects and toJson for outgoing requests. CartService (services/cart_service.dart) wraps the HTTP calls: getCartByUserId hits GET /carts/user/{userId} to fetch a single user's cart, and addToCart hits POST /carts/add with a userId and a list of {id, quantity} product maps. cart_screen.dart calls CartService().getCartByUserId() inside initState, stores the resulting Future<Cart?>, and renders it through a FutureBuilder, keeping loading/error/empty/data states cleanly separated. Since ProductDetailsScreen only needs a subset of product fields, cart_screen.dart converts each CartProduct into a minimal Product object so the same details screen used from the product grid can be reused for cart items too — avoiding a duplicate details screen.

Updated design pattern: This activity extends the same Provider-based state management from Lab 2 but adds a service layer separation between two parallel domains (Product and Cart), each with its own model, service, and screen, while still sharing common UI components (CustomText, ProductDetailsScreen). The FloatingActionButton for chat is now conditionally rendered based on _selectedIndex in home_screen.dart, showing how UI chrome (not just page content) can respond to navigation state.

Using getById-style lookup at the Cart endpoint: Rather than fetching all carts with GET /carts and filtering client-side, getCartByUserId uses GET /carts/user/{userId}, which is the API doing the filtering server-side. This is more efficient and mirrors REST-style resource lookup by identifier (like getById), just scoped to a foreign key (userId) instead of the cart's own id. It returns a list (a user could theoretically have multiple carts in this API), so the code takes the first result via cartsJson.first.

LAB4
User model, service, and screen interaction: User (in models/user.dart) mirrors the shape of dummyjson's /auth/login response, with a fromJson factory that also supports either an accessToken or a generic token key depending on API version. UserService (services/user_service.dart) wraps the login POST request, and on success calls saveUserData() to persist each field individually into SharedPreferences. splash_screen.dart calls UserService.isLoggedIn() on startup to check for a saved token, then routes to /home (passing along the saved user data) or /signin accordingly — this is the persistent authentication flow. signin_screen.dart calls UserService.loginUser() with the form's credentials, saves the response, then navigates to Home. profile_screen.dart calls UserService.getUser() to reconstruct a User object from SharedPreferences, renders it, and then uses that user's id to call CartService.getCartByUserId(), rendering that specific user's cart inline on the same screen.

Updated design pattern: This activity introduces a persistent local storage layer (SharedPreferences) alongside the existing HTTP service layer, giving the app two data sources: transient API calls and durable local state that survives app restarts. The splash screen acts as an authentication gate, checking local state before deciding which route to push, a common mobile pattern for handling session persistence without re-authenticating on every launch.

Using saved data to render the cart by userId: Rather than hardcoding a user ID, profile_screen.dart first resolves the currently logged-in User from SharedPreferences (via getUser()), then passes that user.id into CartService.getCartByUserId(user.id). This chains local persisted identity into a live API call, ensuring the cart shown always belongs to whoever is actually logged in, rather than a static test value.

LAB5
DummyJSON vs Firebase workflow, from signIn to signUp: The app supports two parallel authentication paths through a single UserService. The DummyJSON path (loginUser) posts credentials to a REST endpoint and manually persists the response into SharedPreferences field-by-field. The Firebase path uses the firebase_auth SDK directly: signIn() calls signInWithEmailAndPassword, and createAccount() (used by signup_screen.dart) calls createUserWithEmailAndPassword. Firebase manages the session and token refresh internally through its SDK, while the app mirrors a few fields (email, display name, a loginType flag) into SharedPreferences so the UI renders consistently regardless of which backend authenticated the user. signin_screen.dart inspects the input: an email address routes to Firebase's signIn(), anything else falls back to DummyJSON's loginUser().

Main idea of the UserService implementation: UserService acts as a single abstraction layer over two different auth backends, exposing one consistent interface (isLoggedIn, getUserData, logout, etc.) regardless of which provider authenticated the user. This decouples the UI layer (splash, sign-in, profile, settings) from backend-specific details — screens call the same methods either way, and loginType in the saved data is the only branch point the UI needs to check to render provider-specific fields or actions.

Benefits of the Firebase implementation over the current lab: Unlike DummyJSON, Firebase Auth is a real, production-grade provider: it manages secure token issuance and refresh automatically, hashes and stores passwords server-side, and supports genuine account-level operations (password reauth, account deletion, display name updates) that DummyJSON's mock API can't truly perform (its login always succeeds against fixed fake test users, and nothing persists). Firebase Auth also integrates with Firebase's broader ecosystem for future scaling, whereas DummyJSON exists purely as a stateless testing/demo API.