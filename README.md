# REM Buddy 🎯

**Remember Everything Manager** - A smart reminder app that helps you never forget what to take with you!

## Features ✨

- 📅 **Calendar Integration**: Automatically syncs with Google Calendar and Apple Calendar
- 🤖 **AI-Powered Reminders**: Uses Gemini AI to intelligently suggest items you need based on your events
- 🔔 **Smart Notifications**: Get reminded at your preferred time before events
- 🎨 **Modern UI**: Beautiful, animated interface with smooth transitions
- 🌓 **Dark Mode**: Fully supports light and dark themes
- ⚙️ **Customizable**: Choose your reminder timing preferences

## Screenshots & Features

### Onboarding Screen
- Welcome screen with gradient background
- Choose your preferred reminder timing (15, 30, 45, or 60 minutes before events)
- Smooth animations on entry

### Home Screen
- List of upcoming events with smart reminders
- Beautiful category-based color coding
- Refresh button to sync calendar

### Settings Screen
- Adjust reminder timing
- View integration status for Calendar and AI
- Clean, organized settings layout

### Reminder Cards
Each reminder card shows:
- Event title and time
- Category icon (Shopping, Gym, Work, Health, Travel, Dining)
- List of items to remember (with relevant icons)
- Completion toggle
- Time-sensitive highlighting

## Tech Stack 🛠️

- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **device_calendar**: Calendar integration
- **google_generative_ai**: Gemini AI integration
- **flutter_local_notifications**: Push notifications
- **flutter_animate**: Smooth animations
- **google_fonts**: Beautiful typography (Poppins)
- **font_awesome_flutter**: Rich icon set
- **shared_preferences**: Local data storage

## Setup Instructions 📝

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode for mobile development
- Dart SDK

### Installation

1. **Clone or navigate to the project:**
   ```bash
   cd rem-buddy
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on your device:**
   ```bash
   # For Android
   flutter run

   # For iOS (Mac only)
   flutter run -d ios

   # For Chrome (Web)
   flutter run -d chrome
   ```

### Optional: Gemini AI Setup

For real AI-powered suggestions (mock data works without this):

1. Get a Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. In `lib/providers/reminder_provider.dart`, initialize the Gemini service:
   ```dart
   _geminiService.initialize('YOUR_API_KEY_HERE');
   ```

## How It Works 🔄

1. **First Launch**: User selects preferred reminder timing (15-60 minutes)
2. **Calendar Sync**: App fetches upcoming events from device calendar
3. **AI Analysis**: Gemini AI analyzes each event and generates relevant items to remember
4. **Notifications**: Scheduled notifications are created based on user preferences
5. **User Interaction**: Users can mark reminders as complete and adjust settings

## Mock Data 📊

The app includes comprehensive mock data for demonstration:

### Sample Events:
- Grocery Shopping at Whole Foods
- Gym Workout
- Work Meeting
- Doctor Appointment
- Dinner with Friends

### AI Suggestions:
The app intelligently suggests items based on event type:
- **Shopping**: Wallet, Shopping bags, Shopping list, Phone, Keys, Loyalty cards
- **Gym**: Gym bag, Water bottle, Towel, Headphones, Phone, Keys
- **Work**: Laptop, Phone, Charger, Notebook, Pen, ID badge, Keys
- **Doctor**: Insurance card, ID, Phone, Wallet, Medications, Keys
- And many more...

## Permissions 🔐

### Android
- Internet access
- Calendar read/write
- Notifications
- Exact alarms
- Boot completed (for persistent notifications)

### iOS
- Calendar access
- Notifications
- Background fetch

## Project Structure 📁

```
lib/
├── main.dart                      # App entry point
├── models/
│   ├── calendar_event.dart        # Calendar event model
│   └── reminder_item.dart         # Reminder item model
├── providers/
│   └── reminder_provider.dart     # State management
├── screens/
│   ├── home_screen.dart           # Main app screen
│   ├── onboarding_screen.dart     # First launch setup
│   └── settings_screen.dart       # App settings
├── services/
│   ├── calendar_service.dart      # Calendar integration
│   ├── gemini_service.dart        # AI service
│   └── notification_service.dart  # Push notifications
└── widgets/
    └── reminder_card.dart         # Reminder display widget
```

## Future Enhancements 🚀

- [ ] Custom item addition/editing
- [ ] Recurring event support
- [ ] Weather-based suggestions
- [ ] Location-based reminders
- [ ] Share reminders with family
- [ ] Apple Watch / Wear OS support
- [ ] Widget support

## Troubleshooting 🔧

**Calendar not syncing?**
- Ensure calendar permissions are granted
- Check that you have events in your calendar
- Try the refresh button

**Notifications not appearing?**
- Check notification permissions in system settings
- Ensure "Do Not Disturb" is off
- Verify battery optimization allows background notifications

**AI suggestions not working?**
- App works with mock data by default
- For real AI, add Gemini API key
- Mock suggestions cover common event types

## License 📄

This project is created for demonstration purposes.

## Credits 👏

- UI inspired by modern material design principles
- Icons from Font Awesome
- Fonts from Google Fonts (Poppins)
- Animations powered by flutter_animate

---

**Made with ❤️ using Flutter**

*Never forget anything again!* 🎯
