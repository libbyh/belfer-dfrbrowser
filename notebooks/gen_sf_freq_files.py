#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
from collections import Counter
import numpy as np
import random
import csv

from pandarallel import pandarallel

pandarallel.initialize(progress_bar=False)


processed_dir = '/home/libbyh/belfer-dtm/data/'
browser_data_dir = '/home/libbyh/belfer-dfrbrowser/data/'


# In[2]:


filename = processed_dir + 'stormfront_post_data_processed.json.gz'

df = pd.read_json(filename, orient = "index")
df.reset_index(inplace=True)
df.head()


# In[3]:


# optionally sample for testing
df = df.sample(n=25000, replace=False, random_state=1)
print(len(df))


# In[4]:


#reformat metadata, create dataframe, write to csv
column_names = ["id", "title", "author", "journal", "volume", "issue", "pubdate", "pages"]
meta = df[['index', 'processed', 'post_author', 'thread_forum', 'post_date']]
meta.rename(columns={'index': 'id', 'processed': 'title', 'post_author': 'author', 'thread_forum': 'journal',
                    'post_date': 'pubdate'}, inplace=True)
meta['volume'] = ''
meta['issue'] = ''
meta['pages'] = ''

meta.set_index("id", inplace=True)

print(meta.head())


# In[5]:


meta.to_csv(browser_data_dir + 'sf_meta.csv', 
    sep=',', 
    quoting = csv.QUOTE_ALL, 
    encoding = 'utf-8')


# In[6]:


# generate word frequency files for each post
i = 0

freqs = meta['title'].str.split().parallel_apply(pd.value_counts)

freqs = freqs.fillna(0)
freqs = freqs.astype('int8')

for index, row in freqs.iterrows():
    if i > len(df):
        break
    else:
        filename = browser_data_dir + 'freq/' + str(index) + '.tsv'
        row.dropna(inplace=True)
    with open(filename, 'w') as f:
        f.write(row.to_csv(sep='\t'))
    i+=1


# In[ ]:





