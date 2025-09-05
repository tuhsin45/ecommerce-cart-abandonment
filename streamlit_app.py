"""
Streamlit Dashboard for E-Commerce Cart Abandonment Analysis
Interactive data visualization and business insights
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pathlib import Path
import numpy as np
from datetime import datetime

    # Page configuration
st.set_page_config(
    page_title="E-Commerce Cart Abandonment Analysis",
    layout="wide",
    initial_sidebar_state="expanded"
)@st.cache_data
def load_analysis_data():
    """Load the latest analysis dataset"""
    try:
        project_root = Path(__file__).parent.absolute()
        reports_dir = project_root / "reports"
        
        # Find the most recent analysis dataset
        csv_files = list(reports_dir.glob("analysis_dataset_*.csv"))
        if csv_files:
            latest_file = max(csv_files, key=lambda x: x.stat().st_ctime)
            df = pd.read_csv(latest_file)
            return df, str(latest_file)
        else:
            st.error("No analysis dataset found in reports folder.")
            return None, None
    except Exception as e:
        st.error(f"Error loading analysis data: {e}")
        return None, None

def calculate_summary_stats(df):
    """Calculate summary statistics"""
    if df is None:
        return {}
    
    # Clean the data
    df = df.copy()
    df['is_abandoned'] = df['is_abandoned'].fillna(0)
    df['is_completed'] = df['is_completed'].fillna(0)
    df['cart_value'] = df['cart_value'].fillna(0)
    
    total_orders = len(df)
    abandoned_orders = int(df['is_abandoned'].sum())
    completed_orders = int(df['is_completed'].sum())
    abandonment_rate = abandoned_orders / total_orders if total_orders > 0 else 0
    
    # Revenue calculations
    completed_df = df[df['is_completed'] == 1]
    abandoned_df = df[df['is_abandoned'] == 1]
    
    total_revenue = float(completed_df['cart_value'].sum())
    lost_revenue = float(abandoned_df['cart_value'].sum())
    avg_cart_value = float(df['cart_value'].mean())
    
    return {
        'total_orders': total_orders,
        'abandoned_orders': abandoned_orders,
        'completed_orders': completed_orders,
        'abandonment_rate': abandonment_rate,
        'total_revenue': total_revenue,
        'lost_revenue': lost_revenue,
        'avg_cart_value': avg_cart_value,
        'potential_recovery_10pct': lost_revenue * 0.10
    }

def main():
    # Header
    st.title("E-Commerce Cart Abandonment Analysis")
    st.markdown("---")
    
    # Load data
    df, file_path = load_analysis_data()
    
    if df is None:
        st.stop()
    
    # Sidebar
    st.sidebar.header("Dashboard Controls")
    
    # Analysis options
    analysis_type = st.sidebar.selectbox(
        "Select Analysis View:",
        ["Executive Summary", "Category Analysis", "Payment Analysis", "Geographic Analysis", "Detailed Data"]
    )
    
    # Calculate summary stats
    summary = calculate_summary_stats(df)
    
    if analysis_type == "Executive Summary":
        show_executive_summary(summary, df)
    elif analysis_type == "Category Analysis":
        show_category_analysis(df)
    elif analysis_type == "Payment Analysis":
        show_payment_analysis(df)
    elif analysis_type == "Geographic Analysis":
        show_geographic_analysis(df)
    elif analysis_type == "Detailed Data":
        show_detailed_data(df)

def show_executive_summary(summary, df):
    """Display executive summary dashboard"""
    st.header("Executive Summary")
    
    # KPI Metrics
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric(
            label="Total Orders",
            value=f"{summary['total_orders']:,}",
            delta=None
        )
    
    with col2:
        st.metric(
            label="Abandonment Rate",
            value=f"{summary['abandonment_rate']:.1%}",
            delta=None
        )
    
    with col3:
        st.metric(
            label="Lost Revenue",
            value=f"${summary['lost_revenue']:,.0f}",
            delta=None
        )
    
    with col4:
        st.metric(
            label="Potential Recovery (10%)",
            value=f"${summary['potential_recovery_10pct']:,.0f}",
            delta=None
        )
    
    # Charts
    col1, col2 = st.columns(2)
    
    with col1:
        # Pie chart for completion vs abandonment
        fig_pie = go.Figure(data=[go.Pie(
            labels=['Completed Orders', 'Abandoned Orders'],
            values=[summary['completed_orders'], summary['abandoned_orders']],
            marker=dict(colors=['#2ecc71', '#e74c3c'])
        )])
        fig_pie.update_layout(title="Order Completion vs Abandonment")
        st.plotly_chart(fig_pie, use_container_width=True)
    
    with col2:
        # Cart value distribution
        fig_hist = px.histogram(
            df, 
            x='cart_value', 
            nbins=30,
            title="Cart Value Distribution",
            labels={'cart_value': 'Cart Value ($)', 'count': 'Number of Orders'}
        )
        st.plotly_chart(fig_hist, use_container_width=True)

def show_category_analysis(df):
    """Display category-wise analysis"""
    st.header("Product Category Analysis")
    
    # Category stats
    category_stats = df.groupby('product_category_name_english').agg({
        'is_abandoned': ['count', 'sum', 'mean'],
        'cart_value': ['sum', 'mean']
    }).round(3)
    
    category_stats.columns = ['total_orders', 'abandoned_orders', 'abandonment_rate', 'total_revenue', 'avg_cart_value']
    category_stats = category_stats[category_stats['total_orders'] >= 50]
    category_stats = category_stats.sort_values('abandonment_rate', ascending=False)
    
    # Top categories by abandonment rate
    top_categories = category_stats.head(10)
    
    fig_bar = px.bar(
        x=top_categories.index,
        y=top_categories['abandonment_rate'],
        title="Top 10 Categories by Abandonment Rate",
        labels={'x': 'Product Category', 'y': 'Abandonment Rate'}
    )
    fig_bar.update_xaxes(tickangle=45)
    st.plotly_chart(fig_bar, use_container_width=True)
    
    # Category data table
    st.subheader("Category Performance Details")
    st.dataframe(category_stats, use_container_width=True)

def show_payment_analysis(df):
    """Display payment method analysis"""
    st.header("Payment Method Analysis")
    
    payment_stats = df.groupby('payment_type').agg({
        'is_abandoned': ['count', 'sum', 'mean'],
        'cart_value': ['sum', 'mean']
    }).round(3)
    
    payment_stats.columns = ['total_orders', 'abandoned_orders', 'abandonment_rate', 'total_revenue', 'avg_cart_value']
    
    # Payment method chart
    fig_payment = px.bar(
        x=payment_stats.index,
        y=payment_stats['abandonment_rate'],
        title="Abandonment Rate by Payment Method",
        labels={'x': 'Payment Method', 'y': 'Abandonment Rate'}
    )
    st.plotly_chart(fig_payment, use_container_width=True)
    
    # Payment method data
    st.subheader("Payment Method Performance")
    st.dataframe(payment_stats, use_container_width=True)

def show_geographic_analysis(df):
    """Display geographic analysis"""
    st.header("Geographic Analysis")
    
    state_stats = df.groupby('customer_state').agg({
        'is_abandoned': ['count', 'sum', 'mean'],
        'cart_value': ['sum', 'mean']
    }).round(3)
    
    state_stats.columns = ['total_orders', 'abandoned_orders', 'abandonment_rate', 'total_revenue', 'avg_cart_value']
    state_stats = state_stats[state_stats['total_orders'] >= 100]
    state_stats = state_stats.sort_values('abandonment_rate', ascending=False)
    
    # State analysis chart
    top_states = state_stats.head(15)
    
    fig_states = px.bar(
        x=top_states.index,
        y=top_states['abandonment_rate'],
        title="Top 15 States by Abandonment Rate",
        labels={'x': 'State', 'y': 'Abandonment Rate'}
    )
    st.plotly_chart(fig_states, use_container_width=True)
    
    # State data table
    st.subheader("State Performance Details")
    st.dataframe(state_stats, use_container_width=True)

def show_detailed_data(df):
    """Display detailed data exploration"""
    st.header("Detailed Data Exploration")
    
    # Data overview
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Dataset Overview")
        st.write(f"**Total Records:** {len(df):,}")
        st.write(f"**Columns:** {len(df.columns)}")
        st.write(f"**Date Range:** {df['order_purchase_timestamp'].min()} to {df['order_purchase_timestamp'].max()}")
    
    with col2:
        st.subheader("Data Quality")
        missing_data = df.isnull().sum()
        missing_pct = (missing_data / len(df)) * 100
        quality_df = pd.DataFrame({
            'Missing Values': missing_data,
            'Missing %': missing_pct.round(2)
        })
        st.dataframe(quality_df[quality_df['Missing Values'] > 0])
    
    # Sample data
    st.subheader("Sample Data")
    st.dataframe(df.head(100), use_container_width=True)
    
    # Download option
    csv = df.to_csv(index=False)
    st.download_button(
        label="Download Full Dataset",
        data=csv,
        file_name="cart_abandonment_analysis.csv",
        mime="text/csv"
    )

if __name__ == "__main__":
    main()
