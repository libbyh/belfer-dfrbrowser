import pandas as pd
import csv
import numpy as np
from pandarallel import pandarallel

pandarallel.initialize()
browser_data_dir = '/home/libbyh/belfer-dfrbrowser/data/'

df = pd.read_csv('/home/libbyh/belfer-dfrbrowser/data/sf_rd_sample_meta.csv')
column_names = ["id", "title", "author", "journal", "volume", "issue", "pubdate", "pages"]

df.columns = column_names

# optionally sample
df = df.sample(n=25000)

i = 1

freqs = df['title'].str.split().parallel_apply(pd.value_counts)
print(freqs.head())

for index, row in freqs.iterrows():
    if i > len(df):
        break
    else:
        filename = browser_data_dir + 'sf_rd_sample_frequencies/' + str(i) + '.tsv'
        row.dropna(inplace=True)
        with open(filename, 'w') as f:
            f.write(row.to_string())
        i+=1
