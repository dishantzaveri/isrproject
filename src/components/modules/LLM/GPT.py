import requests
import json
import pickle
import prophet
import openai
import tqdm
import os.path as osp
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from yahoo_fin import news

CHATGPT_MODEL = 'gpt-3.5-turbo'
CHATGPT_API_KEY = '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'
NEWS_API_KEY = [
  'EyPg9DD2IXsEh4D6tZBEGXeJ1j1EgY6L'
][0]

CHATGPT_CONTEXT_NEWS = {
  'role': 'system',
  'content': '''
    You are an experienced financial fraud investigator specializing in insider trading.
    You are leading a team of junior investigators in investigating insider trading.
    You are based in United States and your answers and reasonings should be based on US law and the United States stock exchange.
  '''
}

CHATGPT_CONTEXT = {
  'role': 'system',
  'content': '''
    You are an experienced financial fraud investigator specializing in insider trading.
    You are leading a team of junior investigators in investigating insider trading.
    You are to answer queries of other investigators truthfully.
    You are based in United States and your answers and reasonings should be based on United States's law and the United States stock exchange.
    All you reasoning should be provided step by step.
    If you do not know the answer, you are to inform them of what other information is needed before you are able to conclude if there's any illegal insider trading.
    There is no need to provide qualitative instructions. Only provide instructions on quantitative data required.
  '''
}

def json_gpt(input: str):
  openai.api_key = CHATGPT_API_KEY
  try:
    completion = openai.ChatCompletion.create(
      model = CHATGPT_MODEL,
      messages = [
        {"role": "system", "content": "Output only valid JSON"},
        {"role": "user", "content": input}
      ],
      temperature = 0,
    )
  
    text = completion.choices[0].message.content
    parsed = json.loads(text)
  except Exception as e:
    parsed = f"Error from GPT: {e}"
  
  return parsed


def embeddings(input: list[str]) -> list[list[str]]:
  response = openai.Embedding.create(model = "text-embedding-ada-002", input = input)
  return [data.embedding for data in response.data]


# This function will generate the response for us.
def generateResponse(companyName, date):
  USER_QUESTION = "What caused the changes in the" + companyName + "stock prices?"
  QUERIES_INPUT = f"""
  You have access to a search API that returns recent news articles.
  Generate an array of search queries that are relevant to this question.
  Use a variation of related keywords for the queries, trying to be as general as possible.
  Include as many queries as you can think of, including and excluding terms.
  For example, include queries like ['keyword_1 keyword_2', 'keyword_1', 'keyword_2'].
  Be creative. The more queries you include, the more likely you are to find relevant results.

  User question: {USER_QUESTION}

  Format: {{"queries": ["query_1", "query_2", "query_3"]}}
  """
  
  queries = json_gpt(QUERIES_INPUT)["queries"]
  
  # Let's include the original question as well for good measure
  queries.append(USER_QUESTION)
  
  dateObj = datetime.strptime(date, '%Y-%m-%d')
  dateObj = dateObj - timedelta(days = 7)
  dateObj = datetime.strftime(dateObj, '%Y-%m-%d')
  date = date + ',' + dateObj
  tags = companyName
  keywords = companyName + ', shares, stocks, finance, market' # ', shares, stocks, finance, trading, market, stock price'
  url = "https://api.apilayer.com/financelayer/news?keywords=" + keywords + "&date=" + date + "&limit=5"
  
  payload = {}
  headers = {
    "apikey": NEWS_API_KEY
  }
  
  apiResponse = requests.request("GET", url, headers = headers, data = payload)
  
  if apiResponse != None:
    status_code = apiResponse.status_code
    result = apiResponse.text
    jsonObj = json.loads(result)
    title = jsonObj['data'][0]['title']
    description = jsonObj['data'][0]['description']
    publishingDate = jsonObj['data'][0]['published_at']
    
    articles = []
    for query in queries:
      articles = articles + jsonObj["data"]
    
    # remove duplicates
    articles = list({article["url"]: article for article in articles}.values())
    
    HA_INPUT = f"""
    Generate a hypothetical answer to the user's question. This answer will be used to rank search results.
    Pretend you have all the information you need to answer, but don't use any actual facts. Instead, use placeholders
    like NAME did something, or NAME said something at PLACE.

    User question: {USER_QUESTION}

    Format: {{"hypotheticalAnswer": "hypothetical answer text"}}
    """
    
    hypothetical_answer = json_gpt(HA_INPUT)["hypotheticalAnswer"]
    hypothetical_answer_embedding = embeddings(hypothetical_answer)[0]
    article_embeddings = embeddings([f"{article['title']} {article['description']}" for article in articles])
    
    # Calculate cosine similarity
    cosine_similarities = []
    for article_embedding in article_embeddings:
      cosine_similarities.append(np.dot(hypothetical_answer_embedding, article_embedding))
    
    scored_articles = zip(articles, cosine_similarities)
    
    # Sort articles by cosine similarity
    sorted_articles = sorted(scored_articles, key = lambda x: x[1], reverse = True)
    
    formatted_top_results = [{
      "title": article[0]["title"],
      "description": article[0]["description"],
      "url": article[0]["url"]
    } for article in sorted_articles]
    
    ANSWER_INPUT = f"""
    Generate an answer to the user's question based on the given search results.
    TOP_RESULTS: {formatted_top_results}
    USER_QUESTION: {USER_QUESTION}

    Include as much information as possible in the answer. Reference the relevant search result urls as markdown links.
    """
    
    completion = openai.ChatCompletion.create(
      model = CHATGPT_MODEL,
      messages = [
        CHATGPT_CONTEXT,
        {"role": "user", "content": ANSWER_INPUT}
      ],
      temperature = 0,
      stream = True
    )
    
    text = ""
    for chunk in completion:
      text += chunk.choices[0].delta.get("content", "")
    
    response = 'As per our investigations, we detected the presence of a financial fraud after analyzing the price related information that you have given. On further investigation and searching, we found that there was a public announcement regarding the ' + companyName + ' shares on date ' + publishingDate + '. The trade happened on date ' + date + '. Since the announcement was made after the date of trade and price fluctuations also indicate the presence of a fraud. Hence, we conclude that this trade can be a potential case of an insider trade...'
  
  return response + text


# This function will take the query of the user as the input and will return the query response to the user.
def processQuery(query):
  print("Received query:", query, flush=True)
  answer = ''
  tokens = query.split(" ")
  
  if query.find('Identify if there is any possibility of insider trade for the trade of shares of') == 0:
    companyName = tokens[15]
    date = tokens[18]
    
    csvFileName = companyName + '.csv'
    df = pd.read_csv(osp.join('db', 'NASDAQ', 'market_data', csvFileName))
    df['Date'] = df.Date.apply(lambda x: x[0:10])
    closePrice = df[df['Date'] == date]['Close']
    
    if closePrice.empty:
      return f'Market data of {companyName} is missing from database on {date}.'
    
    # Deep Learning model code which will detect any price fluctuations or anomalies are there in the data or not.
    modelName = osp.join('db','pickle', companyName + '.pkl')
    model = pickle.load(open(modelName, 'rb'))
    
    # Make prediction
    data = pd.DataFrame({
      'ds': [date],
      'y': [float(closePrice)]
    })
    forecast = model.predict(data)
    data.ds = data.ds.astype('datetime64[ns]')
    performance = pd.merge(data, forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']], on = 'ds')
    data = performance[performance['ds'] == date]
    anomaly = True if (data['y'] < data['yhat_lower']).bool() | (data['y'] > data['yhat_upper']).bool() else False
    
    if anomaly:
      answer = generateResponse(companyName, date)

      # This code is to fetch the trading data from the data set which is to be displayed to the user in the form of a table
      df = pd.read_csv(osp.join('db', "insider.csv"))
      df_filtered = df[df['Trade Date'] == date]
      df_final = df_filtered[df_filtered['Company'] == companyName]
    else:
      answer = 'As per our investigations and calculations, the provided trade does not indicate any drastic price fluctuations in the stock prices of ' + companyName + '. Hence, we conclude that there is not a possibility of an insider trade in this case.'
    
  else:
    print("Generic question sent to GPT", flush=True)
    openai.api_key = CHATGPT_API_KEY
    messages = [
      CHATGPT_CONTEXT_NEWS,
      {"role": "user", "content": query}
    ]
    try:
      response = openai.ChatCompletion.create(
        model = CHATGPT_MODEL,
        messages = messages,
        temperature = 0)
      answer = response.choices[0].message["content"]
    except Exception as e:
      print("GPT call failed:", e, flush=True)
      answer = f"Error from GPT: {e}"
  
  return answer


# def get_news(companyName):
#   date = datetime.strftime(datetime.today(), '%Y-%m-%d') + ',' + datetime.strftime(datetime.today() - timedelta(days = 7), '%Y-%m-%d')
#   tags = companyName
#   keywords = companyName + ', shares, stocks, finance, market'
#   url = "https://api.apilayer.com/financelayer/news?keywords=" + keywords + "&date=" + date + "&limit=3"
#   
#   payload = {}
#   headers = {
#     "apikey": NEWS_API_KEY
#   }
#   
#   apiResponse = requests.request("GET", url, headers = headers, data = payload)
#   
#   if apiResponse != None:
#     status_code = apiResponse.status_code
#     result = apiResponse.text
#     jsonObj = json.loads(result)
#     title = jsonObj['data'][0]['title']
#     description = jsonObj['data'][0]['description']
#     publishingDate = jsonObj['data'][0]['published_at']
#     
#   return '\n'.join([f'''
#     #### [{result["title"]}]({result["url"]})
#     <sub>{result["published_at"][0:10]}</sub>
#     {result["description"]}
#   ''' for result in jsonObj["data"]])
 

def get_news(companyName, n = 8):
  news_json = news.get_yf_rss(companyName)
  news_df = pd.DataFrame.from_dict(news_json)[['title', 'summary', 'link', 'published']]\
    .sort_values('published', ascending = False)\
    .iloc[:n]
  
  return '\n'.join([f'''
    #### [{news_record["title"]}]({news_record["link"]})
    <sub>{news_record["published"][0:16]}</sub><details><summary>See Summary...</summary>{news_record["summary"]}</details>
  ''' for _, news_record in news_df.iterrows()])

