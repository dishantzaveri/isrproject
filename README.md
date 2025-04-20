
Prompt:

I am trying to build a team of AI agents to detect insider trading. Here's my team of agents: 
1. The 'data collector' agent will be responsible collecting data from various sources such as FinHub API (ie: https://www.finnhub.io/docs/api/insider-transactions), Yahoo Finance API for company press releases and other information.
2. The 'stock tracker' agent will collect real-time and historical stock price data. 
3. The 'insider trading detective' agent will analyze data from the 'data collector' and 'stock tracker' agents detect suspicious trading activity by company insiders (such as buying/selling stocks, bonds, options and other securities derivatives of that company or related companies) prior to some company-related market-moving news. Insider trading, at its core, is the use of material, nonpublic information to trade in the securities of a company prior to a material market-moving news event.

Does this make sense to you? Let me know if I should change/add/remove something? Share your thoughts on this agentic system workflow?

--------

Response (by o3-mini):

Your proposed multi-agent system has a solid overall structure for tackling the complex process of detecting insider trading. Here are some thoughts and suggestions for improvement:

#### **Overall Workflow**
- **Modular Approach:**  
  Splitting the functionality into distinct agents (data collection, stock tracking, anomaly detection, and journalism/reporting) is a strong design approach. This modularization allows each component to be developed, maintained, and potentially upgraded independently. It also mirrors best practices in AI-driven systems, where clarity of roles can help in debugging and performance optimization.

#### **Data Collector Agent**
- **Diverse Data Sources:**  
  Collecting data from multiple sources like the FinHub API, Yahoo Finance is crucial. Make sure to:
  - **Normalize Data:** Data from different sources often comes in various formats, so a robust normalization process is essential.
  - **Monitor Data Quality:** Develop methodologies to assess data reliability, perhaps even including meta-data regarding the source to weigh its trust level.
- **Additional Sources:**  
  Consider including alternative data streams, such as regulatory filings and social media sentiment, which can sometimes offer early signals or deeper context regarding market-moving events.

#### **Stock Tracker Agent**
- **Real-Time and Historical Data:**  
  Integrating both real-time and historical price data is important for context.  
  - **Data Granularity:** Define the timeframes clearly for both short-term fluctuations and longer-term trends, to help the analysis agent differentiate between noise and meaningful patterns.
  - **Integration with News:** While primarily focused on stock movements, linking some price movements with timestamps of reported news may help improve correlation analysis in later stages.

#### **Insider Trading Detective Agent**
- **Suspicious Activity Analysis:**  
  This is the core intelligence of your system. A few considerations:
  - **Criteria and Algorithms:** Develop and refine criteria to flag trades as suspicious (e.g., abnormal trading volumes, significant deviations from historical patterns, or trades conducted just before major announcements). Machine learning models or statistical anomaly detection methods could be very effective.
  - **Legal and Regulatory Aspects:** Since the legal boundaries around insider trading are nuanced, it might be beneficial to have a legal expert’s guidelines or even integrate some form of a compliance check within this agent.
  - **Contextual Analysis:** Analyze not just the raw data from the data collector but also consider market sentiment and external events. This can help avoid false positives and ensure that benign insider activity (which might be legally compliant) isn’t mistakenly flagged as malicious.


Overall, your workflow is well thought out, and with some refinements in data integration, legal considerations, and communication protocols, it should form a very robust base for detecting suspicious insider trading activities. Good luck with your project!