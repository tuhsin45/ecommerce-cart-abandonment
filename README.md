# E-Commerce Cart Abandonment Analysis

## Case Study Overview

This project analyzes cart abandonment patterns in Brazilian e-commerce using the Olist dataset. The analysis identifies factors that lead customers to abandon their carts and provides data-driven recommendations to improve conversion rates.

## Business Problem

Cart abandonment is a critical challenge in e-commerce, with significant revenue impact. This analysis quantifies abandonment rates, identifies key drivers, and develops actionable strategies to reduce abandonment and increase checkout conversion.

## Dataset

The analysis uses the Olist Brazilian E-Commerce Public Dataset, consisting of:
- 100,000+ orders from 2016-2018
- Customer demographics and geography
- Product catalog with categories
- Order payment and shipping details
- Customer reviews and ratings

## Technical Approach

### Data Processing
- SQL scripts for data cleaning and preparation
- Python-based analysis pipeline using pandas and numpy
- Feature engineering for cart abandonment modeling

### Analytics Methods
- Descriptive statistics and exploratory data analysis
- Statistical significance testing
- Predictive modeling using machine learning algorithms
- Interactive visualizations with Plotly

### Dashboard
- Streamlit web application for interactive analysis
- Real-time metrics and KPI tracking
- Geographic and temporal pattern visualization
- Live deployment available at: https://ecommerce-cart-abandonment.streamlit.app/

## Key Findings

### Cart Abandonment Metrics
- Overall abandonment rate analysis across customer segments
- Revenue impact quantification
- Product category performance comparison
- Payment method effectiveness evaluation

### Critical Insights
- High-value carts show increased abandonment tendency
- Geographic variations in abandonment patterns
- Payment installment options impact conversion
- Seasonal and temporal abandonment trends

## Business Recommendations

### Immediate Actions
- Implement cart abandonment email campaigns
- Optimize mobile checkout experience
- Deploy exit-intent retention strategies

### Strategic Initiatives
- Enhance payment flexibility and options
- Develop category-specific retention tactics
- Create predictive abandonment models

## Technology Stack

- **SQL**: Database operations and core analytics
- **Python**: pandas, numpy, plotly for data analysis and visualization
- **Streamlit**: Interactive web dashboard framework
- **GitHub**: Version control and project hosting

## Project Structure

```
ecom/
├── streamlit_app.py          # Interactive Streamlit dashboard
├── data/                     # Olist dataset files
├── project/sql_scripts/      # SQL analysis queries
├── reports/                  # Generated analysis results
└── requirements.txt          # Python dependencies
```

## Live Dashboard

**Interactive Analysis Dashboard:** https://ecommerce-cart-abandonment.streamlit.app/

The dashboard features:
- Executive summary with key performance indicators
- Interactive category and payment method analysis
- Geographic performance insights
- Detailed data exploration capabilities

## Local Development

1. Clone repository: `git clone https://github.com/tuhsin45/ecommerce-cart-abandonment.git`
2. Install dependencies: `pip install -r requirements.txt`
3. Run locally: `streamlit run streamlit_app.py`

## Results

The analysis provides quantified insights into cart abandonment patterns, identifies high-impact intervention opportunities, and delivers actionable recommendations to improve e-commerce conversion rates through data-driven decision making.
