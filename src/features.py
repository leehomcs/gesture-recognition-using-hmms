import numpy as np

########################################################
# Utility functions for extracting features            #
########################################################
# Mean
def mean(df):
  x = df['x-axis'].mean(axis=0)
  y = df['y-axis'].mean(axis=0)
  z = df['z-axis'].mean(axis=0)
  return x, y, z

# Standard deviation
def stddev(df):
  x = df['x-axis'].std(axis=0)
  y = df['y-axis'].std(axis=0)
  z = df['z-axis'].std(axis=0)
  return x, y, z

# Dicrete fast fourier transform
def dfft(df):
  x = np.fft.fft(df['x-axis'])
  y = np.fft.fft(df['y-axis'])
  z = np.fft.fft(df['z-axis'])
  return x, y, z

# Energy
def energy(df):
  x, y, z = dfft(df)
  x = np.mean(np.square(x))
  y = np.mean(np.square(y))
  z = np.mean(np.square(z))
  return x, y, z

# Correlation between axes
def correlation(df):
  covxy = np.cov(df['x-axis'], df['y-axis'])[0][1]
  covyz = np.cov(df['y-axis'], df['z-axis'])[0][1]
  covxz = np.cov(df['x-axis'], df['z-axis'])[0][1]
  return covxy, covyz, covxz

