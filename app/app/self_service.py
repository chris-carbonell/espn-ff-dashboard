# # Overview
# # * self service table

# # Dependencies

# # data
# import numpy as np
# import pandas as pd

# # viz
# import plotly.graph_objects as go
# from plotly.offline import iplot
# from jupyter_dash import JupyterDash
# import dash
# from dash import dcc, html, Input, Output, ALL, callback

# # config
# from constants import *

# # Constants

# # viz
# threshold = 0.5  # conditional formatting threshold

# # Setup

# dash.register_page(__name__)

# # Get Data

# # kpi_forecasting
# df_kpi_forecasting = pd.read_csv(path_data_kpi_forecasting)

# # data_stats
# data_stats = pd.read_csv(path_data_stats)

# # the default of float64 made the dataset about 12 MB (`data_stats.info()`)
# # converting to float16 reduces it to around 6 MB but loses precision
# # converting to np.single reduces it to around 8 MB with enough precision to round
# for col in data_stats.columns:
#     if data_stats[col].dtype.kind == "f":
#         data_stats[col] = data_stats[col].round(4)  # round
#         data_stats[col] = data_stats[col].astype(np.single)  # reduce
#         # data_stats[col] = data_stats[col].map('{:,.4f}'.format)  # https://stackoverflow.com/questions/59559941/how-to-round-decimal-places-in-a-dash-table
#         # this formatting converts it to an object/str

# # Dash Helpers

# vars = sorted(list(df_kpi_forecasting['metric_name'].unique()))
# cols_data_stats = list(data_stats.columns)

# def convert_df_to_dash(df):
#     """
#     Converts a pandas data frame to a format accepted by dash
#     Returns columns and data in the format dash requires
#     """

#     # constants
#     fmt_float = ".3f"

#     # build cols
#     cols = []
#     ids = []
#     for col in df.columns:

#         # combine multi level columns
#         if isinstance(col, str):
#             col_clean = col
#         elif isinstance(col, tuple):
#             col_clean = ' / '.join([str(i) for i in col if i != ''])
#         else:
#             pass
#         ids.append(col_clean)

#         # build col
#         d_col = {'name': col_clean, 'id': col_clean}
#         if df[col].dtype.kind == "f":
#             d_col['type'] = "numeric"
#             d_col['format'] = {'specifier': fmt_float}
#         cols.append(d_col)

#     # build data
#     data = [{k: v for k, v in zip(ids, row)} for row in df.values]

#     return data, cols

# # Layout

# layout = html.Div([
    
#     # header
#     html.H1("KPI Forecasting"),
#     html.H2("EDA"),

#     # input
#     html.H3("Inputs"),
#     dcc.Dropdown(cols_data_stats, id="dropdown-filters", multi=True),
#     html.Div(id="div-filters"),

#     # output

#     ## self service table
#     html.H3("Self-Service"),
#     dash.dash_table.DataTable(
#         id='tbl-self-service',
#         tooltip_delay = 0,
#         tooltip_duration = None,
#         page_size = 20,
#         style_data_conditional = [
#             # positive above threshold
#             {
#                 'if': {
#                     'filter_query': f'{{{col}}} >= {threshold}',
#                     'column_id': col
#                 },
#                 'backgroundColor': color_emerald,
#                 'color': 'white'
#             }
#             for col in ['pearson_r', 'spearman_r', 'kendall_r']
#             ] + [
#             # negative below threshold
#             {
#                 'if': {
#                     'filter_query': f'{{{col}}} <= {-threshold}',
#                     'column_id': col
#                 },
#                 'backgroundColor': color_bright_pink,
#                 'color': 'white'
#             }
#             for col in ['pearson_r', 'spearman_r', 'kendall_r']
#         ]
#     ),
# ])

# # Callbacks

# # update self service table
# @callback(
#     # output

#     ## table
#     Output("tbl-self-service", "data"),
#     Output("tbl-self-service", "columns"),
#     # Output("tbl-self-service", "tooltip_data"),
    
#     # input

#     ## filters
#     Input('dropdown-filters', 'value'),
#     Input({"type": "attribute-filters", "index": ALL}, "value"),
#     )
# def update_self_service(col_filters, col_filters_values):
#     '''
#     update the self service table
#     '''

#     # constants
#     df_data = data_stats

#     # filter

#     ## build mask
#     mask_tbl = None  # mask for table
#     if col_filters:
#         print(col_filters)
#         print(col_filters_values)
#         print()
#         for col, val in zip(col_filters, col_filters_values):
            
#             # clean up val
#             if not isinstance(val, list):
#                 val = [val]

#             if val:
#                 mask_add = (df_data[col].isin(val))
#             else:
#                 mask_add = None

#             # update mask_tbl
#             if mask_tbl is not None and mask_add is not None:
#                 mask_tbl = mask_tbl & mask_add
#             else:
#                 mask_tbl = mask_add

#     ## filter if necessary
#     if mask_tbl is not None:
#         df_tbl = df_data.loc[mask_tbl, :]
#     else:
#         df_tbl = df_data

#     # get data
#     data, cols = convert_df_to_dash(df_tbl)

#     return (data, cols)