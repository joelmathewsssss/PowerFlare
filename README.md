# PowerFlare

PowerFlare is a Flutter application that helps users find and share power sources around them, with solar power forecasting capabilities.

## Data Persistence with SharedPreferences

The application uses SharedPreferences for data persistence, which provides:

1. **Simplicity**: Easy to implement and use for storing key-value pairs.
2. **Quick Access**: Fast access to stored data.
3. **Built-in Support**: Native support in Flutter without additional dependencies.
4. **Lightweight**: Minimal overhead for storing application data.

### Data Storage

The application stores the following data using SharedPreferences:

#### User Data
- User credentials (username, email, password)
- Login status

#### Power Sources
- Location information (latitude, longitude)
- Source details (name, description, type)
- Availability information (free or paid)

#### Chat Messages
- Message content
- Sender information
- Timestamp

## Features

- User authentication (login/registration)
- Map-based power source discovery
- Adding and managing power sources
- Chat functionality for each power source
- Solar power forecasting based on weather data
- Weekly solar power predictions

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Create a `.env` file with your API keys:
   ```
   OPENWEATHERMAP_API_KEY=your_api_key_here
   ```
4. Run the app with `flutter run`

## Dependencies

- flutter_dotenv: For environment variables
- google_maps_flutter: For map functionality
- http: For API requests
- shared_preferences: For data storage
- path: For file path operations
- intl: For date formatting
- logging: For application logging
