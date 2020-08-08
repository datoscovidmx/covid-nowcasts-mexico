import geopandas as geopd
import pandas as pd
import datetime
import pdb

geo_df = geopd.read_file("https://datoscovidmx.s3-us-west-2.amazonaws.com/mexican_states.geojson")
geo_df.admin_name = geo_df.admin_name.str.upper()
geo_df = geo_df[['admin_name', 'geometry']]
geo_df.columns = ['estado', 'geometry']
geo_df = geo_df.sort_values(by='estado')
geo_df = geo_df.reset_index()
del geo_df['index']

df = pd.read_csv("https://datoscovidmx.s3-us-west-2.amazonaws.com/latest.csv")
df.date = pd.to_datetime(df.date)

temp = df[df.date == df.date.max()].copy()
temp['cases'] = df.groupby('region')['cases'].cumsum()
del temp['import_status']
del temp['date']
temp.columns = ['estado', 'cases']
temp = temp.reset_index()
del temp['index']

geo_df['estado'] = geo_df['estado'].replace(["AGUASCALIENTES", "BAJA CALIFORNIA", "BAJA CALIFORNIA SUR", "CAMPECHE", "CHIAPAS", "CHIHUAHUA", "COAHUILA", "COLIMA", "DISTRITO FEDERAL", "DURANGO", "GUANAJUATO", "GUERRERO", "HIDALGO", "JALISCO", "MEXICO", "MICHOACAN", "MORELOS", "NAYARIT", "NUEVO LEON", "OAXACA", "PUEBLA", "QUERETARO", "QUINTANA ROO", "SAN LUIS POTOSI", "SINALOA", "SONORA", "TABASCO", "TAMAULIPAS", "TLAXCALA", "VERACRUZ", "YUCATAN", "ZACATECAS"],
                    ["AGUASCALIENTES", "BAJA CALIFORNIA", "BAJA CALIFORNIA SUR", "CAMPECHE", "CHIAPAS", "CHIHUAHUA", "COAHUILA", "COLIMA", "CIUDAD DE MÉXICO", "DURANGO", "GUANAJUATO", "GUERRERO", "HIDALGO", "JALISCO", "MÉXICO", "MICHOACÁN", "MORELOS", "NAYARIT", "NUEVO LEÓN", "OAXACA", "PUEBLA", "QUERETARO", "QUINTANA ROO", "SAN LUIS POTOSÍ", "SINALOA", "SONORA", "TABASCO", "TAMAULIPAS", "TLAXCALA", "VERACRUZ", "YUCATÁN", "ZACATECAS"])

geo_df = geo_df.merge(temp, on='estado')

summary = pd.read_csv('summary_table.csv')
summary = summary[['Estado', 'Cambio esperado en nuevos casos', 'Número de reproducción efectiva']]
summary.columns = ['estado', 'cambio', 'reproducción efectiva']

pdb.set_trace()

summary['reproducción efectiva'] = summary['reproducción efectiva'].str.split(' ', expand=True)[0]

geo_df = geo_df.merge(summary, on='estado')

geo_df.to_file("casos_mexico.geojson", driver='GeoJSON')
