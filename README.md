# 💼 Insider Surveillance & Reporting (ISR) Project

A full-stack investigative dashboard and analytics pipeline for detecting **potential insider trading activities**. This project combines **real-time market surveillance**, **visual insights**, **AI-powered fraud detection**, and **interactive dashboards** using **Shiny (R)** and **Python**. It is designed to assist regulatory bodies or compliance analysts in identifying unusual trading behavior through a visually immersive interface.

## 📽️ Demo

🎥 [Watch the Walkthrough Video](https://www.youtube.com/watch?v=GEdgE4XvqRs&t=2s)

## 🌐 Live Deployment

> Currently deployed locally or via ShinyApps.io (instructions below to run or deploy)

---

## 🧠 Key Highlights

- **📊 Network Graphs for Insider–Company Links**  
  Visualizes insider connections using Neo4j-style relationship graphs powered by `visNetwork`.

- **📈 Market Anomaly Detection with Prophet**  
  Predicts expected market behavior for top S&P 50 companies and flags anomalous trading days.

- **🤖 AI-Powered GPT-3.5 Fraud Reasoning**  
  Integrates OpenAI's API to generate investigative reasoning on suspected trades using real-world news.

- **📥 Real-Time News Scraping**  
  News articles are pulled using `apilayer` or `yahoo_fin` based on date and ticker metadata.

- **📁 Modular Architecture**  
  Codebase organized into Shiny modules (`src/components/modules`) and pages (`src/pages/`) for full maintainability.

---

## 🧭 Project Structure

```plaintext
isrproject/
│
├── db/                         # Data directory
│   ├── NASDAQ/                # Insider CSVs and metadata
│   ├── clustering/data/       # Preprocessed clustering outputs
│   └── pickle/                # Trained Prophet models (.pkl)
│
├── src/
│   ├── components/            # Shiny modules and custom layouts
│   ├── pages/                 # Page-level UI/server files
│   └── widgets/               # Custom widgets like chat, cards
│
├── www/                       # Static assets (CSS/JS)
├── train.py                  # Python script to train Prophet model per stock
├── app.R / global.R          # Shiny entrypoint
└── README.md
