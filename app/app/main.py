# Dependencies

# general
import os

# data
import numpy as np
import pandas as pd
from sqlalchemy import create_engine, URL

# viz
import dash
from dash import Dash, dash_table, dcc, html, Input, Output, ALL, callback

# Conn

url_object = URL.create(
    drivername = "postgresql+psycopg2",
    host = os.environ['POSTGRES_HOST'],
    port = os.environ['POSTGRES_PORT'],
    database = os.environ['POSTGRES_DB'],
    username = os.environ['POSTGRES_USER'],
    password = os.environ['POSTGRES_PASSWORD'],
)
engine = create_engine(url_object)

# Data

with open("./sql/obt.sql", "r") as f:
    sql_obt = f.read()
df_obt = pd.read_sql(sql_obt, engine)


with open("./sql/test.sql", "r") as f:
    sql = f.read()
df = pd.read_sql(sql, engine)

# Dash Helpers

cols_obt = sorted(list(df_obt.columns))
cols_metrics = [
    "points_actual",
    "points_projected",
]

def convert_df_to_dash(df):
    """
    Converts a pandas data frame to a format accepted by dash
    Returns columns and data in the format dash requires
    """

    # constants
    fmt_float = ".3f"

    # build cols
    cols = []
    ids = []
    for col in df.columns:

        # combine multi level columns
        if isinstance(col, str):
            col_clean = col
        elif isinstance(col, tuple):
            col_clean = ' / '.join([str(i) for i in col if i != ''])
        else:
            pass
        ids.append(col_clean)

        # build col
        d_col = {'name': col_clean, 'id': col_clean}
        if df[col].dtype.kind == "f":
            d_col['type'] = "numeric"
            d_col['format'] = {'specifier': fmt_float}
        cols.append(d_col)

    # build data
    data = [{k: v for k, v in zip(ids, row)} for row in df.values]

    return data, cols

# App

app = Dash(__name__)
server = app.server

# Layout

app.layout = html.Div([
    
    # header
    html.H1("Winner, Winner Chicken Dinner League"),
    html.H2("Self-Service Data"),

    # input

    ## rows
    html.H3("Rows"),
    dcc.Dropdown(cols_obt, value = ['season_id', 'scoring_period_id'], id="dropdown-rows", multi=True),

    ## columns
    html.H3("Columns"),
    dcc.Dropdown(cols_obt, id="dropdown-columns", multi=True),

    ## filters
    html.H3("Filters"),
    dcc.Dropdown(cols_obt, id="dropdown-filters", multi=True),
    html.Div(id="div-filters"),

    ## values
    html.H3("Values"),
    dcc.Dropdown(cols_metrics, value = cols_metrics[0], id="dropdown-values", multi=True),

    # output

    ## self service table
    html.H3("Self-Service"),
    dash.dash_table.DataTable(
        id='tbl-self-service',
        tooltip_delay = 0,
        tooltip_duration = None,
        page_size = 20,

        # TODO: test
        data = df.to_dict('records'), 
        columns = [{"name": i, "id": i} for i in df.columns]
    ),
])

# Callbacks

# update filters
@app.callback(
    Output('div-filters', 'children'),
    Input('dropdown-filters', 'value')
    )
def update_filters(col_filters):
    '''
    update the filters (i.e., for each column specified, create a new dropdown for that specific column)
    '''

    # check
    if not col_filters:
        return None

    def _build_input(col):
        '''
        create input based on the column's data type:
        
        https://dash.plotly.com/pattern-matching-callbacks?_gl=1*18pfnd*_ga*MTE5MzAyNzI1NC4xNjc2OTk5NDE0*_ga_6G7EE0JNSC*MTY4NzI3ODU3Ni4xMy4xLjE2ODcyODA1NDEuMC4wLjA.
        '''

        # create menu based on type
        kind = df_obt[col].dtype.kind
        
        # string dropdown
        if kind == "O":
            levels = sorted(list(df_obt[col].unique()))
            return dcc.Dropdown(
                levels, 
                levels[0], 
                multi=True,
                id={"type": "attribute-filters", "index": f"dropdown-{col}"}
            )

        # float dropdown
        elif kind == "f":
            min = df_obt[col].min()
            max = df_obt[col].max()
            midpoint = (min+max)/2
            # step = 0.01
            return dcc.RangeSlider(min, 
                                   max, 
                                   step=0.01,
                                   value=[min, midpoint, midpoint, max],
                                   id={"type": "attribute-filters", "index": f"dropdown-{col}"},
                                   marks=None,
                                   allowCross=False,
                                   tooltip={"placement": "bottom", "always_visible": True},
                                   updatemode='mouseup'
                                  )

        # integer dropdown
        elif kind == "i":
            min = df_obt[col].min()
            max = df_obt[col].max()
            # midpoint = round((min+max)/2, 0)
            return dcc.RangeSlider(min, 
                                   max, 
                                   step=1,
                                   # value=[min, midpoint, midpoint, max],
                                   value=[min, max],
                                   id={"type": "attribute-filters", "index": f"dropdown-{col}"},
                                   marks=None,
                                   allowCross=False,
                                   tooltip={"placement": "bottom", "always_visible": True},
                                   updatemode='mouseup'
                                  )
            
        # type not supported
        else:
            pass
    
    def _build_child(col):
        '''
        create input with title
        '''
        return [
            html.H4(col),
            _build_input(col)
        ]

    # get all children
    children = []
    for col in col_filters:
        children += _build_child(col)
    
    return children

# update self service table
@callback(
    # output
    Output("tbl-self-service", "data"),
    Output("tbl-self-service", "columns"),
    
    # input

    ## rows
    Input('dropdown-rows', 'value'),

    ## columns
    Input('dropdown-columns', 'value'),

    ## filters
    Input('dropdown-filters', 'value'),
    Input({"type": "attribute-filters", "index": ALL}, "value"),

    ## values
    Input('dropdown-values', 'value'),
    )
def update_self_service(
    rows,
    columns,
    col_filters, 
    col_filters_values,
    values,
    ):
    '''
    update the self service table
    '''

    # constants
    df_data = df_obt

    # parse
    rows = [] if rows is None else rows
    columns = [] if columns is None else columns
    col_filters = [] if col_filters is None else col_filters
    values = values if isinstance(values, list) else [values]

    # filter

    ## subset to necessary data
    df_data = df_data[rows + columns + values + col_filters]

    ## build mask
    mask_tbl = None  # mask for table
    if len(col_filters) > 0:
        for col, val in zip(col_filters, col_filters_values):
            
            # clean up val
            if not isinstance(val, list):
                val = [val]

            if val:
                mask_add = (df_data[col].isin(val))
            else:
                mask_add = None

            # update mask_tbl
            if mask_tbl is not None and mask_add is not None:
                mask_tbl = mask_tbl & mask_add
            else:
                mask_tbl = mask_add

    ## filter if necessary
    if mask_tbl is not None:
        df_tbl = df_data.loc[mask_tbl, :]
    else:
        df_tbl = df_data

    # subset to display data
    df_tbl = df_tbl[rows + columns + values]

    # group
    df_tbl = df_tbl.groupby(rows + columns).agg(
        **{v: pd.NamedAgg(column=v, aggfunc="sum") for v in values}
    )
    df_tbl.reset_index(inplace = True)

    # pivot
    df_tbl = df_tbl.pivot(index=rows, columns=columns, values=values)
    df_tbl.reset_index(inplace = True)

    # get data
    data, cols = convert_df_to_dash(df_tbl)

    return (data, cols)

if __name__ == '__main__':
    app.run(debug=True)