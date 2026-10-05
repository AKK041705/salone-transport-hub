# Salone Transport Hub (Assignment 1 prototype)

PROG 202 - Software Engineering, Limkokwing University of Creative Technology, Sierra Leone.

A Dart console prototype for a Sierra Leone public transport information platform.

## Run

```
dart pub get
dart run
```

## What it does
- Register and log in as Passenger or Driver (Administrator account is pre-made).
- View and compare fares (published fares plus clearly labelled simulated estimates).
- Passenger requests transport: choose type, number of people and extra seats to keep free.
- Driver accepts or declines; the passenger then accepts or rejects that driver.
- Administrator verifies drivers, updates fares and reviews fare issue reports.
- Notifications: actions by one user are visible to another user after refresh/login.

## Demo accounts
- Administrator: `admin` / `admin123`
- Drivers (password `1234`): `rider1` (Okada), `kekeh1` (Kekeh), `taxi1` and `taxi2` (Taxi), `van1` (Private vehicle), `poda1` (Poda-poda), `bus1` (Bus)

## Notes
- No database: everything is in memory and is lost when the program closes.
- Passwords are plain text because this is only a prototype.
- Fares marked "Simulated estimate" are not official.
- Driver and vehicle records are fictional sample data.
- Not connected to, or endorsed by, any government body or union.
- Not implemented (future stages): Flutter UI, Supabase, GPS, payments, real notifications.
