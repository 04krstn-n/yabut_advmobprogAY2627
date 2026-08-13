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