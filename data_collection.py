from agno.agent import Agent
from agno.tools import tool
from agno.models.google import Gemini
from agno.tools.googlesearch import GoogleSearchTools
from agno.tools.yfinance import YFinanceTools
import finnhub

import httpx
import json
import os
from typing import Optional

assert os.getenv("GOOGLE_API_KEY"), "Please set the GOOGLE_API_KEY environment variable"


# class InsiderTradingActivity(BaseModel):
#     """
#     Model to represent insider trading activity.
#     """
#     executive: str = Field(..., description="Name of the executive")
#     executive_title: str = Field(..., description="Title of the executive")
#     transaction_date: str = Field(..., description="Date of the transaction")
#     transaction_type: str = Field(..., description="Type of transaction (Buy/Sell)")
#     security_type: str = Field(..., description="Type of security")
#     shares: int = Field(..., description="Number of shares traded")
#     share_price: float = Field(..., description="Price per share")


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
    provider: Optional[str] = "alpha_vantage",
) -> str:
    """
    Fetch insider trading activity for a given stock ticker within a date range.

    Args:
        ticker (str): The stock ticker symbol.
        start_date (str): Start date in YYYY-MM-DD format. Not required for Alpha Vantage.
        end_date (str): End date in YYYY-MM-DD format. Not required for Alpha Vantage.
        provider (str): The data provider to use. Default is "alpha_vantage". Alternatively, "finnhub" can be used.

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
    elif provider == "alpha_vantage":
        ALPHA_VANTAGE_API_KEY = os.getenv("ALPHA_VANTAGE_API_KEY")
        assert ALPHA_VANTAGE_API_KEY, (
            "Please set the ALPHA_VANTAGE_API_KEY environment variable"
        )
        url = f"https://www.alphavantage.co/query?function=INSIDER_TRANSACTIONS&symbol={ticker}&apikey={ALPHA_VANTAGE_API_KEY}"
        response = httpx.get(url).json()

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
    tools=[
        get_insider_trading_activity,
        get_insider_sentiment,
        YFinanceTools(company_news=True),
        GoogleSearchTools(),
    ],
    description="You gather insider trading activity",
    show_tool_calls=True,
    markdown=True,
    instructions=[
        "Display the results in a table format.",
        "If no press releases are found from Yahoo Finance, search the web for news articles.",
    ],
    debug_mode=True,
)
data_collector_agent.print_response(
    "Get latest (past 1 month) insider trading activity, insider sentiment and press releases for AAPL",
    stream=True,
)
