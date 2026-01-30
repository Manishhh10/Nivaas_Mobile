# Nivaas Backend

Backend API for Nivaas app built with Node.js, Express, and MongoDB.

## Features

- User registration and login with JWT authentication
- Password hashing with bcrypt
- Rate limiting and security middleware
- MongoDB for data storage

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up environment variables in `config/config.env`:
   ```
   NODE_ENV=development
   PORT=3000
   MONGO_URI=mongodb://localhost:27017/nivaas
   JWT_SECRET=your_jwt_secret_key_here
   JWT_EXPIRE=30d
   JWT_COOKIE_EXPIRE=30
   ```
4. Start MongoDB
5. Run the server:
   ```bash
   npm run dev
   ```

## API Endpoints

### Authentication
- POST `/api/v1/auth/register` - Register a new user
- POST `/api/v1/auth/login` - Login user

### Health Check
- GET `/api/v1/health` - Check API status

## Usage

The API is now ready to be used by the Flutter app.