import pandas as pd
import requests
import datetime
import json
import ast


headers = {'content-type': 'application/json','encoding':'utf-8'}
url = 'https://covid19.sinave.gob.mx/Graficasconfirmados.aspx/'


def get_estados():
    # Estados
    r = requests.post(url + 'Estados', headers=headers)
    estados = pd.DataFrame(ast.literal_eval(r.json()['d']))
    estados.columns = ['Estado', 'Region']
    estados['Region'] = estados['Region'].astype(int)
    return(estados)


def get_datos(url_ext, estados):
    # Datos
    r = requests.post(url + url_ext, headers=headers)
    datos = pd.DataFrame(ast.literal_eval(r.json()['d']))
    datos.columns = ['Region', 'ToDrop', 'ToDrop', 'Acumulados', 'ToDrop', 'Fecha', 'ToDrop']
    datos = datos.drop(['ToDrop'], axis=1)
    datos['Fecha'] = pd.to_datetime(datos['Fecha'], dayfirst=True)
    datos['Acumulados'] = datos['Acumulados'].astype(int)
    datos['Region'] = datos['Region'].astype(int)
    datos = datos.merge(estados, on='Region')
    datos = datos.set_index(['Region', 'Fecha']).sort_index(level=('Region', 'Fecha'))
    datos['Anterior'] = datos.groupby('Estado')['Acumulados'].shift()
    datos["Casos"] = datos["Acumulados"] - datos["Anterior"]
    return datos


def lambda_handler(event, context=None):
    estados = get_estados()
    datos = get_datos('Datos', estados)
    datos2 = get_datos('Datos2', estados)

    datos = datos.append(datos2)
    datos = datos[datos["Estado"] != "NACIONAL"]

    casos = pd.DataFrame()
    casos = datos[["Estado", "Casos"]].copy()
    casos.reset_index(inplace=True)
    casos.dropna(inplace=True)
    
    casos.rename(columns={"Region": "Region_ID",
                          "Estado": "region", 
                          "Casos": "cases",
                          "Fecha": "date"}, inplace=True)
    
    casos.drop(columns={"Region_ID"}, inplace=True)
    casos["import_status"] = "local"
    today = datetime.date.today().strftime('%d%m%y')

    print(casos.head())

    casos.to_csv('s3://datoscovidmx/casos_%s.txt' % today, index=False)
    casos.to_csv('s3://datoscovidmx/latest.csv' % today, index=False)

    return True


if __name__ == "__main__":
    lambda_handler(event={})
