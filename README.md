# Chess Tournament Manager

A comprehensive desktop application for managing chess tournaments, built with Python and QML.

## Features

- **Tournament Management**: Create and manage Swiss and Round Robin tournaments.
- **Player Management**: Add, edit, delete, and withdraw players. Import/Export player lists.
- **Pairing Engine**: Automated pairing for Swiss (Dutch) and Round Robin systems. Support for manual pairing adjustments.
- **Results & Standings**: Record match results, calculate points/tie-breaks (Buchholz, Sonneborn-Berger), and view real-time standings.
- **Reporting**: Generate PDF reports for pairings, standings, and player lists.
- **Database**: Robust data persistence using SQLite.

## Requirements

- Python 3.8+
- PyQt5
- ReportLab

## Installation

1. Clone the repository or download the source code.
2. Install the required dependencies:

   ```bash
   pip install -r requirements.txt
   ```

## Usage

1. Run the application:

   ```bash
   python main.py
   ```

2. **Dashboard**: Create a new tournament or load an existing one.
3. **Players**: Add players manually or import them.
4. **Pairings**: Start rounds, enter results, and proceed through the tournament.
5. **Standings**: View current rankings and export reports.

## Project Structure

- `backend/`: Core logic for database, matchmaking, and reports.
- `ui/`: QML files for the user interface.
- `bridge.py`: Interface between the Python backend and QML frontend.
- `main.py`: Entry point of the application.

## License

[License Name/Type]
