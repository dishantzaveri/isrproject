from analyst import analyst_agent

import streamlit as st
import finnhub

from dotenv import load_dotenv
import os

load_dotenv()
finnhub_client = finnhub.Client(api_key=os.getenv("FINNHUB_API_KEY"))
stocks = [stock['symbol'] for stock in finnhub_client.stock_symbols('US')]
stocks.sort()


st.set_page_config(page_title="Detect illegal Insider Trading", page_icon="🤖")
st.title("🤖 Insider Trading Analyst")

ticker = st.selectbox(
    "Select a company or ticker:",
    options=stocks,
    placeholder="Type to search...",
    key="ticker_input"
)

analyze_button = st.button("Analyze insider trading activity", key="analyze_button")

if ticker and analyze_button:
    with st.spinner("🧠 Analyzing ..."):
        st.subheader(f"Analysis for: {ticker}")
        response_stream = analyst_agent.run(ticker, stream=True)
        st.write_stream(item.content for item in response_stream)

