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
- Flask web application for interactive analysis
- Real-time metrics and KPI tracking
- Geographic and temporal pattern visualization

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
- **Python**: pandas, numpy, scikit-learn, plotly
- **Flask**: Web dashboard and API endpoints
- **HTML/CSS**: Frontend dashboard interface

## Project Structure

```
ecom/
├── app.py                    # Flask dashboard application
├── data/                     # Olist dataset files
├── project/sql_scripts/      # SQL analysis queries
├── reports/                  # Generated analysis results
├── templates/                # Dashboard HTML templates
└── requirements.txt          # Python dependencies
```

## Usage

1. Install dependencies: `pip install -r requirements.txt`
2. Start dashboard: `python app.py`
3. Access analysis at `http://localhost:5000`

## Results

The analysis provides quantified insights into cart abandonment patterns, identifies high-impact intervention opportunities, and delivers actionable recommendations to improve e-commerce conversion rates through data-driven decision making.
