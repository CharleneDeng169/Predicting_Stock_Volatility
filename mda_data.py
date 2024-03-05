#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Nov 29 22:11:52 2023

@author: charlenedeng
"""

import pandas as pd
import os
import re
from datetime import datetime, timedelta

# folder and file
base_folder = '/Users/charlenedeng/Desktop/Computer Simulations/group project/edgar_mda'
all_files = os.listdir(base_folder)

# Create a dataframe to store all the txt
df = pd.DataFrame(columns=['Company Name', 'Time', 'Text'])

# Go through each file
for file_name in all_files:
    file_path = os.path.join(base_folder, file_name)
    if file_name.endswith('.txt'):
        stock_cik = file_name.split('_')[0]

        # read content
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()

            # extract information from txt
            company_name_match = re.search(r'Company Name: (.+)', content)
            filing_date_match = re.search(r'Filing Date: (\d{4}-\d{2}-\d{2})', content)
            accession_number_match = re.search(r'Accession Number: (.+)', content)

            if all([company_name_match, filing_date_match, accession_number_match]):
                company_name = company_name_match.group(1).strip()
                filing_date_str = filing_date_match.group(1)
                filing_date_obj = datetime.strptime(filing_date_str, '%Y-%m-%d')
                filing_date_formatted = filing_date_obj.strftime('%Y-%m')
                accession_number = accession_number_match.group(1).strip()

                # Find the position of the Accession Number
                accession_index = content.find(accession_number)
                text = content[accession_index + len(accession_number):].strip()
                
                # Add to dataframe
                df.loc[len(df)] = [company_name, filing_date_formatted, text]


df.set_index('Time', inplace=True)
df = df.pivot(columns='Company Name', values='Text')
df = df.sort_index()

# index of original data
# df.index

# Mapping function
def map_index(idx):
    year, month = idx.split('-')
    if month in ['04','05']:
        return f"{year}-Q1"
    elif month in ['07','08']:
        return f"{year}-Q2"
    elif month in ['10', '11']:
        return f"{year}-Q3"
    elif month in ['01', '02','03']:
        return f"{int(year)-1}-Q4"
    else:
        return idx

# index with orginized season
df.index = df.index.map(map_index)
# df.index

# remove 2012
df = df[1:]
# df.index


# Combine rows with the same index
df_joined = df.groupby(df.index).apply(lambda x: x.ffill().bfill().iloc[0])
print(df_joined.index.tolist())

# To see null value
df_joined.isnull().sum()

# output file
df_joined.to_csv('/Users/charlenedeng/Desktop/Computer Simulations/group project/reports_df.csv')














