import os
import pandas as pd
import plotly.graph_objects as go
import dash
from dash import dcc, html

# دالة ذكية لتحديد المسار الصحيح للملفات تلقائياً
def find_file(filename):
    # الفحص في المجلد الحالي (Dashboard)
    if os.path.exists(filename):
        return filename
    # الفحص في المجلد الأب (DataWarhouse)
    elif os.path.exists(os.path.join('..', filename)):
        return os.path.join('..', filename)
    else:
        raise FileNotFoundError(f"لم يتم العثور على الملف {filename} لا في المجلد الحالي ولا المجلد الأب.")

# 1. تحميل البيانات وتجهيزها ديناميكياً
try:
    fact_visits = pd.read_csv(find_file('fact_visits.csv'))
    dim_website = pd.read_csv(find_file('dim_website.csv'))
    dim_user = pd.read_csv(find_file('dim_user.csv'))
    dim_date = pd.read_csv(find_file('dim_date.csv'))
except FileNotFoundError:
    # حل بديل باستخدام ملف التاريخ المنظف مباشرة
    fact_visits = pd.read_csv(find_file('cleaned_browsing_history.csv'))
    dim_website = fact_visits[['website_id', 'website_name', 'category']].drop_duplicates()
    dim_user = fact_visits[['user_id', 'user_name']].drop_duplicates()

# دمج الجداول لحساب الإحصائيات بناءً على الـ Star Schema الخاص بكِ
if 'website_name' not in fact_visits.columns:
    df_merged = fact_visits.merge(dim_website, on='website_id', how='left')
    df_merged = df_merged.merge(dim_user, on='user_id', how='left')
else:
    df_merged = fact_visits

# حساب المؤشرات الرئيسية (KPIs) المطابقة لبياناتكِ الحقيقية
total_visits = len(fact_visits)
total_users = df_merged['user_id'].nunique() if 'user_id' in df_merged.columns else df_merged['user_name'].nunique()
total_websites = df_merged['website_id'].nunique() if 'website_id' in df_merged.columns else df_merged['website_name'].nunique()
active_days = fact_visits['date_id'].nunique() if 'date_id' in fact_visits.columns else fact_visits['visit_date'].nunique()

# تجهيز رسم أعلى 6 مواقع زيارة (Bar Chart)
top_websites = df_merged['website_name'].value_counts().reset_index()
top_websites.columns = ['Website', 'Visits']
top_6_websites = top_websites.head(6)

bar_colors = ['#c084fc', '#f472b6', '#4ade80', '#fef08a', '#f97316', '#22d3ee']

fig_bar = go.Figure(data=[go.Bar(
    x=top_6_websites['Website'],
    y=top_6_websites['Visits'],
    marker_color=bar_colors,
    hovertemplate="<b>%{x}</b><br>Visits: %{y}<extra></extra>"
)])

fig_bar.update_layout(
    plot_bgcolor='rgba(0,0,0,0)',
    paper_bgcolor='rgba(0,0,0,0)',
    font_color='#ffffff',
    margin=dict(l=20, r=20, t=20, b=20),
    yaxis=dict(gridcolor='#334155', title=''),
    xaxis=dict(title='')
)

# تجهيز رسم توزيع الزيارات حسب المستخدم (Donut Chart)
user_visits = df_merged['user_name'].value_counts().reset_index()
user_visits.columns = ['User', 'Visits']

user_color_map = {
    'Sara': '#a78bfa',
    'Noor': '#f472b6',
    'Shahd': '#34d399',
    'Bayan': '#fb7185',
    'Leen': '#fb923c'
}
donut_colors = [user_color_map.get(user, '#ffffff') for user in user_visits['User']]

fig_donut = go.Figure(data=[go.Pie(
    labels=user_visits['User'],
    values=user_visits['Visits'],
    hole=0.6,
    marker=dict(colors=donut_colors),
    hovertemplate="<b>%{label}</b><br>Visits: %{value} (%{percent})<extra></extra>"
)])

fig_donut.update_layout(
    plot_bgcolor='rgba(0,0,0,0)',
    paper_bgcolor='rgba(0,0,0,0)',
    font_color='#ffffff',
    margin=dict(l=20, r=20, t=20, b=20),
    legend=dict(orientation="h", yanchor="bottom", y=-0.2, xanchor="center", x=0.5)
)

# 2. بناء الواجهة الرسومية (Dashboard Layout)
app = dash.Dash(__name__)

app.layout = html.Div(style={'backgroundColor': '#0f172a', 'fontFamily': 'sans-serif', 'padding': '24px', 'color': '#ffffff'}, children=[
    
    # صف الـ Cards الأساسية
    html.Div(style={'display': 'flex', 'justifyContent': 'space-between', 'marginBottom': '24px', 'gap': '16px'}, children=[
        html.Div(style={'flex': '1', 'backgroundColor': '#1e293b', 'padding': '20px', 'borderRadius': '12px'}, children=[
            html.P("Total Visits", style={'color': '#94a3b8', 'margin': '0', 'fontSize': '14px', 'fontWeight': '500'}),
            html.H2(f"{total_visits:,}", style={'margin': '8px 0 0 0', 'fontSize': '32px', 'fontWeight': '700'})
        ]),
        html.Div(style={'flex': '1', 'backgroundColor': '#1e293b', 'padding': '20px', 'borderRadius': '12px'}, children=[
            html.P("Total Users", style={'color': '#94a3b8', 'margin': '0', 'fontSize': '14px', 'fontWeight': '500'}),
            html.H2(f"{total_users}", style={'margin': '8px 0 0 0', 'fontSize': '32px', 'fontWeight': '700'})
        ]),
        html.Div(style={'flex': '1', 'backgroundColor': '#1e293b', 'padding': '20px', 'borderRadius': '12px'}, children=[
            html.P("Total Websites", style={'color': '#94a3b8', 'margin': '0', 'fontSize': '14px', 'fontWeight': '500'}),
            html.H2(f"{total_websites}", style={'margin': '8px 0 0 0', 'fontSize': '32px', 'fontWeight': '700'})
        ]),
        html.Div(style={'flex': '1', 'backgroundColor': '#1e293b', 'padding': '20px', 'borderRadius': '12px'}, children=[
            html.P("Active Days", style={'color': '#94a3b8', 'margin': '0', 'fontSize': '14px', 'fontWeight': '500'}),
            html.H2(f"{active_days}", style={'margin': '8px 0 0 0', 'fontSize': '32px', 'fontWeight': '700'})
        ]),
    ]),
    
    # صف الرسومات والمنحنيات البيانية
    html.Div(style={'display': 'flex', 'gap': '24px'}, children=[
        html.Div(style={'flex': '1.5', 'backgroundColor': '#1e293b', 'padding': '24px', 'borderRadius': '12px'}, children=[
            html.H3("Top Visited Websites", style={'margin': '0 0 16px 0', 'fontSize': '18px', 'fontWeight': '600'}),
            dcc.Graph(figure=fig_bar, config={'displayModeBar': False})
        ]),
        html.Div(style={'flex': '1', 'backgroundColor': '#1e293b', 'padding': '24px', 'borderRadius': '12px'}, children=[
            html.H3("Visits by User", style={'margin': '0 0 16px 0', 'fontSize': '18px', 'fontWeight': '600'}),
            dcc.Graph(figure=fig_donut, config={'displayModeBar': False})
        ]),
    ])
])

if __name__ == '__main__':
    app.run(debug=True, port=8050)