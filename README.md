# Insider Trading Detection System

This project leverages agentic AI (using the Agno framework) to detect suspicious insider trading activity by analyzing insider transactions, stock prices, sentiment, and public announcements.

## Features

- **Data Collection Agent:** Gathers insider trading activity, sentiment, and press releases using APIs like Finnhub and Alpha Vantage.
- **Stock Tracking Agent:** Tracks and fetches daily stock prices.
- **Insider Trading Detector Agent:** Flags suspicious insider transactions that occur before public announcements and are irregular in volume.
- **Streamlit Web App:** User-friendly interface to analyze companies or tickers for potential illegal insider trading.

## How It Works

1. **Data Collection:** The agent collects insider trades, sentiment, and news for a given ticker.
2. **Stock Tracking:** The agent fetches historical stock prices.
3. **Detection:** The detector agent analyzes the data and flags suspicious trades (e.g., large trades by insiders before major announcements).
4. **User Interface:** The Streamlit app allows users to input a company or ticker and view the analysis.

## Setup

1. **Clone the repository**
2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```
3. **Set up environment variables**
   - Create a `.env` file in the project root with your API keys:
     ```
     FINNHUB_API_KEY=your_finnhub_key
     ALPHA_VANTAGE_API_KEY=your_alpha_vantage_key
     GOOGLE_API_KEY=your_google_api_key
     ```
4. **Run the Streamlit app**
   ```bash
   streamlit run app.py
   ```

## File Structure

- `app.py` - Streamlit web interface
- `data_collection.py` - Data collection agent
- `stock_tracking.py` - Stock tracking agent
- `insider_trading_detector.py` - Insider trading detection agent

## Example Usage

- Enter a ticker in the web app to get an analysis of recent insider trading activity and potential suspicious trades.

## License

MIT License

