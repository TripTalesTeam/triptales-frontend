# TripTales

TripTales is a Swift application that allows users to share and explore travel experiences.

## 📋 Prerequisites

- Xcode 14.0+
- iOS 15.0+
- Swift 5.5+
- CocoaPods or Swift Package Manager

## 🔧 Installation

### Step 1: Clone the repository

```bash
git clone https://github.com/TripTalesTeam/triptales-frontend.git
cd triptales-frontend
```

### Step 2: Install dependencies

Using CocoaPods:

```bash
pod install
```

or using Swift Package Manager:

1. Open the project in Xcode
2. Go to File > Swift Packages > Add Package Dependency
3. Enter the Cloudinary SDK URL: `https://github.com/cloudinary/cloudinary_ios.git`
4. Follow the prompts to complete the installation

### Step 3: Configure environment variables

Create a `.env` file inside the TripTales folder with the following content:

```
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
BACKEND_URL=your_backend_url
```

Replace the placeholder values with your actual Cloudinary credentials and backend URL.

## ⚙️ Configuration

### Cloudinary Setup

1. Create a [Cloudinary account](https://cloudinary.com/users/register/free) if you don't have one
2. Navigate to your Cloudinary Dashboard
3. Copy your Cloud Name, API Key, and API Secret
4. Add these values to your `.env` file

## 🚀 Running the App

1. Open `TripTales.xcworkspace` (if using CocoaPods) or `TripTales.xcodeproj` (if using SPM)
2. Select your target device/simulator
3. Click the Run button or press `Cmd + R`

## 🔒 Environment Variables

This project uses environment variables to manage sensitive information. Make sure your `.env` file is added to `.gitignore` to prevent committing sensitive credentials.

---

Made with ❤️
