from agno.agent import Agent
from agno.tools import tool
from agno.models.google import Gemini
from agno.tools.yfinance import YFinanceTools

import httpx
import json
import os
from dotenv import load_dotenv

load_dotenv()


@tool(
    name="get_stock_price_daily",
    cache_results=True,
    cache_dir="tmp/cache",
    cache_ttl=3600,
)
def get_stock_price_daily(ticker: str) -> str:
    """
    Fetch daily stock prices for a given stock ticker within a date range.

    Args:
        ticker (str): The stock ticker symbol.

    Returns:
        str: A formatted string containing daily stock prices.
    """

    ALPHA_VANTAGE_API_KEY = os.getenv("ALPHA_VANTAGE_API_KEY")
    assert ALPHA_VANTAGE_API_KEY, (
        "Please set the ALPHA_VANTAGE_API_KEY environment variable"
    )
    url = f"https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol={ticker}&apikey={ALPHA_VANTAGE_API_KEY}&outputsize=compact&datatype=json"
    response = httpx.get(url).json()

    if "error" in response:
        raise ValueError(f"Error fetching data: {response['error']}")
    if "Time Series (Daily)" not in response:
        raise ValueError("No data found for the given ticker.")

    return json.dumps(response)


stock_tracker_agent = Agent(
    name="stock tracker",
    model=Gemini(id="gemini-2.0-flash"),
    tools=[get_stock_price_daily, YFinanceTools(stock_price=True)],
    role="Share price tracking",
    show_tool_calls=True,
    markdown=True,
    instructions="Gather daily share price data for the past 3 months for a given stock. The columns should be: date, open, high, low, close, volume. Display the results in a markdwon table format.",
    add_datetime_to_instructions=True,
    debug_mode=True,
)
