# Kierstein Chelsea T. Yabut
### INF233
### CTADMOBL Advanced Mobile Programming

A Flutter project that focuses on advance topics. Covering the web to mobile transactions.

## Lab Activity Instance
### Laboratory List
**Lab 1 - Theme [Dark/Light Mode]:**
I have learned that there is a big difference between the use of setState and Provider in flutter. Since setState is a built-in method in flutter, it is just mostly used in updating a state of a widget, unlike Provider, which is a third party package, it rebuilds the entire widget tree since it allows the state to be shared across multiple widgets even those in the other parts of the present widget trees in the application.  This shows that Provider is more scalable, maintainable and efficient in state management in applications rather than the setState since it is limited to the widget where it is just used.

**Lab 2 - Utilizing 3rd Party API for Rapid Development**

In the followed architecture, I’ve learned that the service handles the retrieval of raw data from the internet by sending an asynchronous HTTP GET request to the API and decoding the acquired response body into dart structures. After that the model then acts as a data blueprint which takes the raw data and organizes it into the typed Dart objects so it will be clean and safe to use. Following the model’s function, the screen will call the service and invoking it inside the futurebuilder to smoothly handle the loading, error, and success states. I also learned about the provider pattern, instead of manually passing the variables between the screens, it centralizes global theme state management using change notifier so any screen can listen and automatically update whenever a theme is toggled or turned on. This layered pattern and architechture keeps the code clean, organized, and easy to maintain.

**Lab 3 - Cart Endpoint Integration and Dynamic UI State Management**
In this activity, the CartService handles the HTTP GET request to fetch raw cart data and decodes the JSON response, while the Cart and CartProduct models parse this data into structured Dart objects. The CartScreen calls the service through a FutureBuilder to render the user's specific cart items, making each product card clickable to pass data and navigate to the reused DetailScreen. In this activity, the design pattern was updated by embedding the cart directly into the central bottom navigation while dynamically controlling the chat FloatingActionButton's visibility based on the selected tab index. Furthermore, using getCartByUserId allows us to target /carts/user/{id} at the Cart endpoint so that only the specific logged-in user's cart products and totals are retrieved and displayed.

**Lab 4 – Endpoint Integration**
In this activity, the UserService handles authentication by sending the HTTP POST request to the login endpoint and persisting the response to SharedPreferences, while the User model parses this saved data into a structured Dart object for use throughout the app. The SplashScreen checks this persisted session on launch and forwards the resolved user data to HomeScreen, which then resolves the actual logged-in userId instead of relying on a fixed value, and passes it down to both the ProfileScreen and CartScreen. The design pattern was updated by separating authentication state resolution into HomeScreen itself, ensuring both tabs render data belonging to the same verified user rather than each screen independently guessing which user is logged in.
