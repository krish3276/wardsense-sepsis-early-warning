# WardSense – Trend-Based Early Sepsis Deterioration Assistant

## 🏥 Overview

**WardSense** is a Flutter mobile application designed to assist healthcare professionals in detecting early signs of sepsis by analyzing trends in intermittently collected vital signs. Built for general hospital wards where continuous monitoring isn't available, WardSense provides **explainable, trend-based risk assessment** to support clinical decision-making.

> **Hackathon Project**: Built for healthcare innovation with a focus on practical utility, clinical safety, and explainability.

---

## 🎯 Problem Statement

Sepsis is a life-threatening condition where early detection is critical. In general hospital wards:
- Vital signs are collected intermittently (every 4-8 hours)
- Clinical deterioration patterns may be missed between observations
- Nurses and doctors need decision support, not replacement
- Complex AI systems lack transparency for clinical trust

**WardSense addresses these challenges** by providing transparent, trend-based analysis that healthcare workers can understand and trust.

---

## ✨ Key Features

### For Nurses
- **Quick Vital Entry**: Streamlined form for entering patient vitals with validation
- **At-a-Glance Risk Overview**: Color-coded patient list sorted by risk level
- **Actionable Alerts**: Clear, explainable alerts with recommended actions
- **Offline-First**: Works without internet connectivity

### For Doctors
- **Trend Analysis**: Visual charts showing vital sign patterns over time
- **Critical Patient Dashboard**: Focus on high-risk patients requiring attention
- **Pattern Recognition**: Detection of sepsis-indicative deterioration patterns
- **Escalation Guidance**: Evidence-based recommendations for clinical action

### Clinical Decision Support
- **NEWS Score Calculation**: National Early Warning Score for standardized assessment
- **Explainable Alerts**: Every alert includes clear reasoning factors
- **Risk Level Categorization**: Green → Yellow → Orange → Red progression
- **Trend Detection**: Linear regression analysis of vital sign trajectories

---

## 🏗️ Architecture

### Clean Architecture Pattern
```
lib/
├── core/                    # Shared utilities, constants, theme
│   ├── constants/           # Clinical thresholds, risk levels
│   ├── theme/               # Material 3 theming
│   └── utils/               # Formatting, validation
├── data/                    # Data layer
│   ├── datasources/         # Hive local storage
│   ├── models/              # Database models with adapters
│   └── repositories/        # Data access implementations
├── domain/                  # Business logic
│   ├── entities/            # Core domain objects
│   └── services/            # Trend analysis engine
└── presentation/            # UI layer
    ├── providers/           # Riverpod state management
    ├── screens/             # Feature screens
    └── widgets/             # Reusable components
```

### Technology Stack
- **Flutter** (Dart) - Cross-platform mobile framework
- **Riverpod** - State management with dependency injection
- **Hive** - Fast, lightweight local database
- **FL Chart** - Beautiful, responsive charts
- **Flutter Animate** - Smooth UI animations
- **Material 3** - Modern, accessible design system

---

## 📊 Clinical Logic

### Trend Analysis Engine

The core innovation is the **Trend Analysis Engine** which:

1. **Collects Recent Vitals**: Analyzes last N readings (configurable, default 5)
2. **Calculates Trends**: Uses linear regression to detect rising/falling patterns
3. **Computes NEWS Score**: Standardized scoring based on vital sign thresholds
4. **Detects Sepsis Patterns**: Identifies characteristic deterioration patterns

### Sepsis Pattern Detection

A patient may show a sepsis pattern when **3 or more** of the following occur:
- ↑ Heart Rate trending upward
- ↓ Blood Pressure trending downward  
- ↑ Respiratory Rate trending upward
- Temperature abnormal (fever or hypothermia)

### Risk Level Thresholds

| Level | NEWS Score | Monitoring | Action |
|-------|------------|------------|--------|
| 🟢 Green | 0-2 | Every 4-8 hours | Routine care |
| 🟡 Yellow | 3-4 | Every 2-4 hours | Increased vigilance |
| 🟠 Orange | 5-6 | Every 1-2 hours | Senior nurse review |
| 🔴 Red | ≥7 or sepsis pattern | Continuous if possible | Immediate escalation |

### Explainability

Every alert includes:
- **Contributing Factors**: Which vitals are concerning
- **Trend Information**: Direction and magnitude of changes
- **Recommended Actions**: Evidence-based clinical guidance
- **Confidence Level**: Based on data quality and pattern strength

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (≥3.5.0)
- Dart (≥3.5.0)
- Android Studio / VS Code

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd wardsense-sepsis-early-warning

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Demo Mode

The app initializes with **6 demo patients** across all risk levels:
- 2 Green (stable)
- 2 Yellow (watch closely)
- 1 Orange (concerning trends)
- 1 Red (critical, sepsis pattern detected)

---

## 🎨 User Interface

### Role Selection
- **Nurse View**: Optimized for quick vitals entry and alert management
- **Doctor View**: Comprehensive analytics and trend visualization

### Color Coding
- Uses clinically intuitive traffic-light colors
- Risk indicators visible at all times
- Dark mode support for night shifts

### Accessibility
- Material 3 design guidelines
- High contrast for clinical environments
- Large touch targets for gloved operation

---

## ⚠️ Limitations & Disclaimers

### This is a Decision Support Tool, NOT a Diagnostic Device

- **Not a replacement for clinical judgment**
- **Not FDA/CE approved medical device software**
- **Designed for educational/demonstration purposes**
- **Should be validated before any clinical deployment**

### Technical Limitations
- Offline-only (no cloud sync in current version)
- Demo data only (no real patient integration)
- Simplified scoring models for hackathon scope

### Clinical Limitations
- Does not account for patient comorbidities
- Limited to vital signs (no lab values, medications)
- Trend analysis requires minimum 3 readings

---

## 🔮 Future Enhancements

### Near-term
- [ ] Cloud synchronization with end-to-end encryption
- [ ] Integration with hospital EMR systems
- [ ] Push notifications for critical alerts
- [ ] Shift handover summary reports

### Medium-term
- [ ] Machine learning model for personalized baselines
- [ ] Lab value integration (lactate, WBC, procalcitonin)
- [ ] Medication awareness for vital sign interpretation
- [ ] Multi-ward dashboard for charge nurses

### Long-term
- [ ] Regulatory pathway for medical device certification
- [ ] Clinical validation studies
- [ ] Integration with bedside monitors
- [ ] Predictive analytics with probabilistic forecasting

---

## 👥 Team

Built with ❤️ for improving patient safety through technology.

---

## 📄 License

This project is provided for educational and demonstration purposes.

---

## 🙏 Acknowledgments

- **NEWS Score**: Based on Royal College of Physicians guidelines
- **qSOFA Criteria**: Adapted from Sepsis-3 definitions
- **Flutter Community**: For excellent packages and documentation

---

*"Technology should augment clinical expertise, not replace it."*