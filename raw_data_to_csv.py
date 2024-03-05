import pandas as pd
import numpy as np

mda = pd.read_csv("C:/Users/Vickiepedia/Desktop/mda.csv")
vol = pd.read_csv("C:/Users/Vickiepedia/Desktop/vol.csv")

#print(mda.isnull().sum())
#print(vol.isnull().sum())

#print(mda.head(2))
print(vol.head(2))

##############################################################
############### mda ##########################################
##############################################################

#convert quarter to month in mda
def quarter_to_month(quarter_str):
    year, qtr = quarter_str.split('-')
    month_map = {'Q1': '03', 'Q2': '06', 'Q3': '09', 'Q4': '12'}
    return f"{year}-{month_map[qtr]}"

mda['Date'] = mda['Time'].apply(quarter_to_month)
mda = mda.drop('Time', axis=1)

mda['Date'] = pd.to_datetime(mda['Date'])
mda = mda[mda['Date'].dt.year != 2023]

mda['Date'] = mda['Date'].dt.strftime('%Y-%m')
print(mda.tail(2))

# Convert column names       
# Mapping old column names to new column names
new_column_names = {
    'AMERICAN EXPRESS CO': 'AXP',
    'BANK OF AMERICA CORP DE': 'BAC',
    'CAPITAL ONE FINANCIAL CORP': 'COF',
    'CHEVRON CORP': 'CVX',
    'EXXON MOBIL CORP': 'XOM',
    'MARATHON OIL CORP': 'MRO'
}

# Rename the columns
mda.rename(columns=new_column_names, inplace=True)

#print(mda.columns)

##############################################################
############### vol ##########################################
##############################################################

# convert date from y-m-d to y-m in vol
vol['Date'] = pd.to_datetime(vol['Date'])
vol = vol[vol['Date'].dt.year != 2023]
vol['Date'] = vol['Date'].dt.strftime('%Y-%m')
print(vol.tail(2))

##############################################################
############### merge vol and mda together ###################
##############################################################

mda_long = mda.melt(id_vars=['Date'], var_name='stock', value_name='mda')
vol_long = vol.melt(id_vars=['Date'], var_name='stock', value_name='vol_lag')

combined_df = pd.merge(mda_long, vol_long, on=['Date', 'stock'])

#combined_df.tail(2)

combined_df['industry'] = np.where(combined_df['stock'].isin(['BAC', 'AXP', 'COF']), 'finance', 'energy')
combined_df.tail(2)
print(combined_df.isnull().sum())
combined_df = combined_df.dropna(subset=['vol_lag'])
combined_df.to_csv('combined_data.csv', index=False)






