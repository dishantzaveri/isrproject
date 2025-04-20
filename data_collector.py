from agno.agent import Agent
from agno.tools import tool
from agno.models.google import Gemini
from agno.models.openai import OpenAIChat
from agno.tools.googlesearch import GoogleSearchTools
from agno.tools.yfinance import YFinanceTools
import finnhub

import httpx
import json
import os
from dotenv import load_dotenv
from typing import Optional

load_dotenv()

@tool(
    name="get_insider_trading_activity",
    cache_results=True,
    cache_dir="tmp/cache",
    cache_ttl=3600,
)
def get_insider_trading_activity(
    ticker: str,
    start_date: str = None,
    end_date: str = None,
    provider: Optional[str] = "finnhub"
) -> str:
    """
    Fetch insider trading activity for a given stock ticker within a date range.

    Args:
        ticker (str): The stock ticker symbol.
        start_date (str): Start date in YYYY-MM-DD format. Not required for Alpha Vantage.
        end_date (str): End date in YYYY-MM-DD format. Not required for Alpha Vantage.
        provider (str): The data provider to use. Default is "finnhub". Alternatively, "alpha_vantage" can be used.

    Returns:
        str: A formatted string containing insider trading activity.
    """
    if provider == "finnhub":
        FINNHUB_API_KEY = os.getenv("FINNHUB_API_KEY")
        assert FINNHUB_API_KEY, "Please set the FINNHUB_API_KEY environment variable"
        finnhub_client = finnhub.Client(api_key=FINNHUB_API_KEY)
        response = finnhub_client.stock_insider_transactions(
            ticker, start_date, end_date
        )
    elif provider == "alpha_vantage": # disable
        ALPHA_VANTAGE_API_KEY = os.getenv("ALPHA_VANTAGE_API_KEY")
        assert ALPHA_VANTAGE_API_KEY, (
            "Please set the ALPHA_VANTAGE_API_KEY environment variable"
        )
        url = f"https://www.alphavantage.co/query?function=INSIDER_TRANSACTIONS&symbol={ticker}&apikey={ALPHA_VANTAGE_API_KEY}"
        response = httpx.get(url).json()
        # truncate the response to 1000 characters
        response = json.loads(json.dumps(response)[:1000])

    if "error" in response:
        raise ValueError(f"Error fetching data: {response['error']}")
    if "data" not in response:
        raise ValueError("No data found for the given ticker.")

    return json.dumps(response)


@tool(
    name="get_insider_sentiment",
    cache_results=True,
    cache_dir="tmp/cache",
    cache_ttl=3600,
)
def get_insider_sentiment(ticker: str, start_date: str, end_date: str) -> str:
    """
    Fetch insider sentiment for a given stock ticker within a date range.

    Args:
        ticker (str): The stock ticker symbol.
        start_date (str): Start date in YYYY-MM-DD format.
        end_date (str): End date in YYYY-MM-DD format.

    Returns:
        str: A formatted string containing insider sentiment.
    """
    FINNHUB_API_KEY = os.getenv("FINNHUB_API_KEY")
    assert FINNHUB_API_KEY, "Please set the FINNHUB_API_KEY environment variable"
    finnhub_client = finnhub.Client(api_key=FINNHUB_API_KEY)
    response = finnhub_client.stock_insider_sentiment(ticker, start_date, end_date)

    if "error" in response:
        raise ValueError(f"Error fetching data: {response['error']}")
    if "data" not in response:
        raise ValueError("No data found for the given ticker.")

    return json.dumps(response)


data_collector_agent = Agent(
    model=Gemini(id="gemini-2.0-flash"),
    # model=OpenAIChat(id="o4-mini-2025-04-16"),
    name="data collector",
    role="Financial Data Collection",
    tools=[
        get_insider_trading_activity,
        get_insider_sentiment,
        YFinanceTools(company_news=True),
        GoogleSearchTools(),
    ],
    show_tool_calls=True,
    markdown=True,
    instructions=[
        "You help collect data for Insider Trading Detection team at SEC.",
        "You gather (1) insider trading activity, (2) insider sentiment and (3) company press releases for a given stock for the past 3 months.",
        "1. For insider trading activity, use FinnHub as the provider. The columns for insider trading activity table are:  Transaction Date, Insider Name, Shares Δ (delta), Price (USD), Filing Date",
        "2. For insider sentiment, use last 1 month of data if the user doesn't provide a date range.",
        "3. If less than 5 press releases are found from Yahoo Finance, search the web for more news articles. The columns for press releases table are:  Date, Title, Summary, Link.",
        "Display the results in a markdown table format.",
    ],
    debug_mode=True,
    add_datetime_to_instructions=True
)
