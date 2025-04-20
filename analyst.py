from data_collector import data_collector_agent
from stock_tracker import stock_tracker_agent

from agno.team.team import Team
from agno.models.google import Gemini
from agno.playground import Playground, serve_playground_app


analyst_agent = Team(
    name="Insider Trading Analyst",
    model=Gemini(id="gemini-2.0-flash"),
    description="You are an insider trading analyst who helps detect illegal insider trading (from past 3 months).",
    markdown=True,
    instructions=[
        "Illegal insider trading activities can be detected by identifying unusual market movements, such as sudden volume spikes, unexplained price changes, and abnormal patterns before major announcements. They act as important red flags and often indicate someone is acting on confidential information before it becomes public.",
        "The user will provide you with a stock ticker.",
        "First, ask the data collector agent to collect insider trading data.",
        "Then, ask the stock tracker agent to collect stock prices.",
        "Finally, analyze the data and provide insights on potential insider trading activities.",
        "Explain your reasoning clearly, and provide a summary of your findings."],
    enable_agentic_context=True,
    show_members_responses=True,
    members=[data_collector_agent, stock_tracker_agent],
    reasoning=True,
    # debug_mode=True,
    # show_tool_calls=True,
    add_datetime_to_instructions=True
)

app = Playground(agents=[data_collector_agent, stock_tracker_agent], teams=[analyst_agent]).get_app()

if __name__ == "__main__":
    serve_playground_app("analyst:app", reload=True)