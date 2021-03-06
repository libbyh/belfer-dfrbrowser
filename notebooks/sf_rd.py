#!/usr/bin/env python
# coding: utf-8

# In[1]:


#load csv into dataframe
import pandas as pd
from collections import Counter
import numpy as np
import random
import csv
from pandarallel import pandarallel

pandarallel.initialize()

processed_dir = '/home/libbyh/belfer/data/processed/'
browser_data_dir = '/home/libbyh/belfer-dfrbrowser/data/'


# In[2]:


#filename = '/Users/saralafia/Documents/belfer/data/processed/sf_rd_sample_with_ids.txt'

filename = processed_dir + 'sf_rd_with_ids.txt.gz'
df = pd.read_csv(filename, sep='\t', header=None, encoding="utf-8")
df.columns = ["idx", "source", "post_text", "date"]
df.head()

# df.shape[0] #793776
# stormfront.shape[0] #276252
# reddit.shape[0] #517524


# In[3]:


# optionally sample for testing
df = df.sample(n=25, replace=False, random_state=1)


# In[4]:


#sample csv, drop rows = [‘deleted’], [‘removed’]
# n = sum(1 for line in open(filename)) - 1 #number of records in file (excludes header)
# s = 10000 #desired sample size
# skip = sorted(random.sample(range(1,n+1),n-s)) #the 0-indexed header will not be included in the skip list
# df = pd.read_csv(filename, skiprows=skip)

df.drop(df[df.post_text == "[deleted]"].index)
df.drop(df[df.post_text == "[removed]"].index)
# df.post_text.replace({r'[^ -\x7F]+':''}, regex=True, inplace=True) #clean text
# df['post_text'].replace('', np.nan, inplace=True)
df = df.dropna(subset=['post_text'], inplace=True) #drop empty post_text
print(df.head())

# df.shape[0] #778410


# In[5]:


#reformat metadata, create dataframe, write to csv
column_names = ["id", "title", "author", "journal", "volume", "issue", "pubdate", "pages"]
meta = pd.DataFrame(columns = column_names)
meta["id"] = df["idx"]
meta["title"] = df["post_text"]
meta["journal"] = df["source"]
#meta['publication date']= pd.to_datetime(df['date']).dt.strftime('%Y-%m-%dT%H:%M%:%SZ')
meta["pubdate"] = df["date"].astype(str)
meta.set_index("id")
print(meta.head())
# meta.to_csv('/Users/saralafia/Documents/belfer/data/processed/sf_rd_sample_with_ids_meta_sample.tsv', sep='\t', header=False, index=False)
meta.to_csv(browser_data_dir + 'sf_rd_sample_meta.csv',
    sep=',',
    columns=column_names,
    header=False,
    quoting = csv.QUOTE_ALL,
    index=False,
    encoding = 'utf-8')

# meta_10 = meta[10:110]
# meta_10.to_csv('/Users/saralafia/Documents/belfer/data/sf_rd_sample_with_ids_meta_sample.csv', sep=',', header=True, index=False, quotechar='"')

# meta.set_index('DOI')
# print(meta.head())


# In[ ]:


# generate word frequency files for each post
i = 0

freqs = meta['title'].str.split().parallel_apply(pd.value_counts)
print(freqs.head())
print(freqs.dtypes)
freqs = freqs.fillna(0)
freqs = freqs.astype('int8')
print(freqs.head())
print(freqs.dtypes)
for index, row in freqs.iterrows():
    if i > len(df):
        break
    else:
        filename = browser_data_dir + 'frequency_files/' + str(index + 1) + '.tsv'
        row.dropna(inplace=True)
    with open(filename, 'w') as f:
        f.write(row.to_csv(sep='\t'))
    i+=1
