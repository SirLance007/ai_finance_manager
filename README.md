# 💸 AI Finance Manager

AI Finance Manager is a next-generation personal finance tracking and optimization app powered by **Google Gemini AI**. It goes beyond simple expense tracking by providing intelligent, data-driven insights, investment strategies, and personalized financial tips to help users master their money.

---

## 🌟 Key Features

### 🧠 AI-Powered Intelligence
- **AI Smart Tips**: Personalized, actionable financial advice generated based on your monthly income, EMI commitments, and spending patterns.
- **Financial Insights**: Deep-dive analysis of your spending across categories like Food, Shopping, and Transport, with specific recommendations for credit cards and apps to maximize savings.
- **AI Investment Planner**: Intelligent suggestions for SIPs, Stocks, and ETFs based on your risk profile and net savings.

### 📊 Comprehensive Financial Tracking
- **Portfolio Management**: Track your assets including Cash, Bank balances, Stocks, and Mutual Funds in one place.
- **Expense Logging**: Effortlessly log daily expenses with categorization.
- **Goal Tracking**: Set and monitor financial goals (e.g., Buying a car, Emergency fund) with progress visualization.
- **Visual Analytics**: Beautiful, interactive charts powered by `fl_chart` to visualize spending trends and asset distribution.

### 🔐 Secure & Seamless Experience
- **Google Authentication**: Quick and secure login via Google Sign-In.
- **Firebase Backend**: Real-time data synchronization across devices using Cloud Firestore.
- **Onboarding**: A smooth introduction to the app's core features.

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Cross-platform UI)
- **AI Engine**: [Google Gemini AI](https://deepmind.google/technologies/gemini/) (via `google_generative_ai`)
- **Backend**: [Firebase](https://firebase.google.com/) (Auth & Firestore)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Charts**: [FL Chart](https://pub.dev/packages/fl_chart)
- **Icons**: [Lucide Icons](https://pub.dev/packages/lucide_icons)
- **Typography**: [Google Fonts (Inter)](https://fonts.google.com/specimen/Inter)

---

## 🎨 Design Aesthetic
The app follows a **Natural & Trustworthy** design philosophy:
- **Primary Palette**: Deep Emerald and Forest Greens (`0xFF1B4332`, `0xFF2D6A4F`) to evoke feelings of growth and financial stability.
- **Background**: Soft off-white (`0xFFF9F7F3`) for a clean, premium paper-like feel.
- **Typography**: Clean and modern **Inter** font for maximum readability.
- **Components**: Glassmorphic cards, subtle gradients, and pill-shaped interactive elements.

---

## 📂 Project Structure

```text
lib/
├── main.dart             # App entry point & theme configuration
├── screens/              # UI Screens
│   ├── home_screen.dart       # Main dashboard with overview
│   ├── ai_insights_screen.dart # AI-driven card & app recommendations
│   ├── ai_invest_screen.dart   # AI investment strategy planner
│   ├── ai_tips_screen.dart     # Personalized financial tips
│   ├── portfolio_screen.dart   # Asset management UI
│   ├── goals_screen.dart       # Financial goals overview
│   └── login_screen.dart       # Authentication UI
├── services/             # Business Logic & APIs
│   ├── ai_service.dart        # Gemini AI integration & prompt engineering
│   └── finance_api_service.dart # Financial data handling
└── theme/                # Design System & Colors
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed (`flutter doctor` should be green)
- A Firebase project set up
- A Google Gemini API Key from [Google AI Studio](https://aistudio.google.com/)

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd ai_finance_manager
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.

4. **Add Gemini API Key**:
   - Locate `lib/services/ai_service.dart` and update the `_apiKey` constant with your key.

5. **Run the app**:
   ```bash
   flutter run
   ```

---

## 💡 AI Implementation Details

The app uses advanced Prompt Engineering to guide Gemini in providing structured financial advice.
- **Caching**: AI responses are cached in Firestore based on the user's total spending. New insights are only generated when spending changes, saving API tokens.
- **Context-Aware**: The AI is fed real data (Salary, EMIs, Category Spends) to ensure tips are relevant and not generic.

---

## 🛣 Future Roadmap
- [ ] Automated SMS expense parsing.
- [ ] Multi-currency support.
- [ ] Shared family budgets.
- [ ] Real-time stock market tracking.

---

Developed with ❤️ for the future of Personal Finance.
