import pyreadr

result = pyreadr.read_r('mexico/regional-summary/summary_table.rds') # also works for RData
df = result[None]

df.columns = ['Estado', 'Nuevos casos confirmados por fecha de síntomas', 'Cambio esperado en nuevos casos', 'Número de reproducción efectiva', 'Tiempo de duplicación / reducción a la mitad (días)']
df['Cambio esperado en nuevos casos'] = df['Cambio esperado en nuevos casos'].replace(['Likely increasing', 'Increasing', 'Unsure', 'Decreasing', 'Likely decreasing'], ['Probablemente aumentando', 'Aumentando', 'Incierto', 'Disminuyendo', 'Probablemente disminuyendo'])

f = open('summary_table.txt', 'w')
f.write(df.set_index('Estado').to_markdown())
f.close()
