"""
Flask Web Application for Cart Abandonment Analysis Dashboard
Localhost hosting for the E-Commerce analysis project
"""

from flask import Flask, render_template, jsonify, send_from_directory, send_from_directory
import pandas as pd
import json
import os
from pathlib import Path
import plotly.graph_objs as go
import plotly.utils
from datetime import datetime

app = Flask(__name__)

class DashboardData:
    def __init__(self):
        self.project_root = Path(__file__).parent.absolute()
        self.reports_dir = self.project_root / "reports"
        self.data_dir = self.project_root / "data"
        self.analysis_data = None
        self.load_analysis_data()
    
    def load_analysis_data(self):
        """Load the latest analysis dataset"""
        try:
            # Find the most recent analysis dataset
            csv_files = list(self.reports_dir.glob("analysis_dataset_*.csv"))
            if csv_files:
                latest_file = max(csv_files, key=os.path.getctime)
                self.analysis_data = pd.read_csv(latest_file)
                print(f"Loaded analysis data: {latest_file}")
            else:
                print("No analysis dataset found. Please run the analysis first.")
        except Exception as e:
            print(f"Error loading analysis data: {e}")
    
    def get_summary_stats(self):
        """Get summary statistics for the dashboard"""
        if self.analysis_data is None:
            print("No analysis data available")
            return {}
        
        try:
            # Clean the data first
            df = self.analysis_data.copy()
            
            # Handle NaN values
            df['is_abandoned'] = df['is_abandoned'].fillna(0)
            df['is_completed'] = df['is_completed'].fillna(0)
            df['cart_value'] = df['cart_value'].fillna(0)
            
            total_orders = len(df)
            abandoned_orders = int(df['is_abandoned'].sum())
            completed_orders = int(df['is_completed'].sum())
            abandonment_rate = abandoned_orders / total_orders if total_orders > 0 else 0
            
            # Revenue calculations with NaN handling
            completed_df = df[df['is_completed'] == 1]
            abandoned_df = df[df['is_abandoned'] == 1]
            
            total_revenue = float(completed_df['cart_value'].sum())
            lost_revenue = float(abandoned_df['cart_value'].sum())
            avg_cart_value = float(df['cart_value'].mean())
            
            result = {
                'total_orders': int(total_orders),
                'abandoned_orders': int(abandoned_orders),
                'completed_orders': int(completed_orders),
                'abandonment_rate': float(abandonment_rate),
                'total_revenue': float(total_revenue),
                'lost_revenue': float(lost_revenue),
                'avg_cart_value': float(avg_cart_value),
                'potential_recovery_10pct': float(lost_revenue * 0.10)
            }
            
            return result
            
        except Exception as e:
            print(f"Error calculating summary stats: {e}")
            return {}
    
    def get_category_analysis(self):
        """Get category-wise abandonment analysis"""
        if self.analysis_data is None:
            return []
        
        category_stats = self.analysis_data.groupby('product_category_name_english').agg({
            'is_abandoned': ['count', 'sum', 'mean'],
            'cart_value': ['sum', 'mean']
        }).round(3)
        
        category_stats.columns = ['total_orders', 'abandoned_orders', 'abandonment_rate', 'total_revenue', 'avg_cart_value']
        category_stats = category_stats[category_stats['total_orders'] >= 50]
        category_stats = category_stats.sort_values('abandonment_rate', ascending=False)
        
        return category_stats.head(10).to_dict('index')
    
    def get_payment_analysis(self):
        """Get payment method analysis"""
        if self.analysis_data is None:
            return []
        
        payment_stats = self.analysis_data.groupby('payment_type').agg({
            'is_abandoned': ['count', 'sum', 'mean'],
            'cart_value': ['sum', 'mean']
        }).round(3)
        
        payment_stats.columns = ['total_orders', 'abandoned_orders', 'abandonment_rate', 'total_revenue', 'avg_cart_value']
        return payment_stats.to_dict('index')
    
    def get_state_analysis(self):
        """Get state-wise analysis"""
        if self.analysis_data is None:
            return []
        
        state_stats = self.analysis_data.groupby('customer_state').agg({
            'is_abandoned': ['count', 'sum', 'mean'],
            'cart_value': ['sum', 'mean']
        }).round(3)
        
        state_stats.columns = ['total_orders', 'abandoned_orders', 'abandonment_rate', 'total_revenue', 'avg_cart_value']
        state_stats = state_stats[state_stats['total_orders'] >= 100]
        state_stats = state_stats.sort_values('abandonment_rate', ascending=False)
        
        return state_stats.head(10).to_dict('index')

# Initialize dashboard data
dashboard_data = DashboardData()

@app.route('/')
def index():
    """Main dashboard page"""
    summary = dashboard_data.get_summary_stats()
    current_time = datetime.now().strftime('%Y-%m-%d %H:%M')
    return render_template('dashboard.html', summary=summary, current_time=current_time)

@app.route('/about')
def about():
    """About page"""
    return render_template('about.html')

@app.route('/test')
def simple_test():
    """Simple test page"""
    summary = dashboard_data.get_summary_stats()
    current_time = datetime.now().strftime('%Y-%m-%d %H:%M')
    return render_template('test.html', summary=summary, current_time=current_time)

@app.route('/api/summary')
def api_summary():
    """API endpoint for summary statistics"""
    return jsonify(dashboard_data.get_summary_stats())

@app.route('/api/categories')
def api_categories():
    """API endpoint for category analysis"""
    return jsonify(dashboard_data.get_category_analysis())

@app.route('/api/payments')
def api_payments():
    """API endpoint for payment analysis"""
    return jsonify(dashboard_data.get_payment_analysis())

@app.route('/api/states')
def api_states():
    """API endpoint for state analysis"""
    return jsonify(dashboard_data.get_state_analysis())

@app.route('/api/charts/abandonment_pie')
def abandonment_pie_chart():
    """Generate pie chart for abandonment rate"""
    summary = dashboard_data.get_summary_stats()
    
    if not summary:
        return jsonify({})
    
    fig = go.Figure(data=[go.Pie(
        labels=['Completed Orders', 'Abandoned Orders'],
        values=[summary['completed_orders'], summary['abandoned_orders']],
        marker=dict(colors=['#2ecc71', '#e74c3c']),
        textinfo='label+percent'
    )])
    
    fig.update_layout(
        title="Order Completion vs Abandonment",
        font=dict(size=14)
    )
    
    return json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)

@app.route('/api/charts/category_bar')
def category_bar_chart():
    """Generate bar chart for top categories by abandonment"""
    categories = dashboard_data.get_category_analysis()
    
    if not categories:
        return jsonify({})
    
    category_names = list(categories.keys())[:8]
    abandonment_rates = [categories[cat]['abandonment_rate'] for cat in category_names]
    
    fig = go.Figure([go.Bar(
        x=[name[:20] + '...' if len(name) > 20 else name for name in category_names],
        y=abandonment_rates,
        marker_color='coral'
    )])
    
    fig.update_layout(
        title="Top Categories by Abandonment Rate",
        xaxis_title="Product Category",
        yaxis_title="Abandonment Rate",
        font=dict(size=12)
    )
    
    return json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)

@app.route('/api/charts/payment_bar')
def payment_bar_chart():
    """Generate bar chart for payment methods"""
    payments = dashboard_data.get_payment_analysis()
    
    if not payments:
        return jsonify({})
    
    payment_types = list(payments.keys())
    abandonment_rates = [payments[pt]['abandonment_rate'] for pt in payment_types]
    
    fig = go.Figure([go.Bar(
        x=payment_types,
        y=abandonment_rates,
        marker_color='lightblue'
    )])
    
    fig.update_layout(
        title="Abandonment Rate by Payment Method",
        xaxis_title="Payment Method",
        yaxis_title="Abandonment Rate",
        font=dict(size=12)
    )
    
    return json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)

@app.route('/reports/<filename>')
def serve_reports(filename):
    """Serve files from reports directory"""
    return send_from_directory('reports', filename)

if __name__ == '__main__':
    print("Starting Cart Abandonment Analysis Dashboard...")
    print("Dashboard will be available at: http://localhost:5000")
    print("API endpoints available at: http://localhost:5000/api/")
    
    app.run(debug=True, host='localhost', port=5000)
