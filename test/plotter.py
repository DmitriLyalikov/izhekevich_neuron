"""
import matplotlib.pyplot as plt

We have a text file called test.txt, 
Interesting lines are of form:
251008120000.00ns INFO     cocotb.tb                          40 ('Intrinsically-Bursting', 0.02, 0.02, -55, 4) 23
251008130000.00ns INFO     cocotb.tb                          40 ('Intrinsically-Bursting', 0.02, 0.02, -55, 4) -29
251008140000.00ns INFO     cocotb.tb                          40 ('Intrinsically-Bursting', 0.02, 0.02, -55, 4) -29

We want to plot the last number in each line against the time for each distinct type of neuron.

Parse file and generate plots for each type of neuron
"""

import matplotlib.pyplot as plt

import pandas as pd
import matplotlib.pyplot as plt

data = {
        'Regular-Spiking': [],
        'Intrinsically-Bursting': [],
        'Chattering': [],
        'Fast-Spiking': [],
        'Thalamo-Cortical': [],
        'Resonator': [],
        'LTS': []
        
    }

# Define a function to parse the file and extract relevant data
def parse_file(filename):
    with open(filename, 'r') as file:
        for line in file:
            # break the line into words
            words = line.split()
            #print(words)
            if 'Regular-Spiking' in line:
                print(line)
                data['Regular-Spiking'].append(int(words[-1]))
            elif 'Intrinsically-Bursting' in line:
                data['Intrinsically-Bursting'].append(int(words[-1]))
            elif 'Chattering' in line:
                data['Chattering'].append(int(words[-1]))
            elif 'Fast-Spiking' in line:    
                data['Fast-Spiking'].append(int(words[-1]))
            elif 'Thalamo-Cortical' in line:
                data['Thalamo-Cortical'].append(int(words[-1]))
            elif 'Resonator' in line:
                data['Resonator'].append(int(words[-1]))
            elif 'LTS' in line:
                data['LTS'].append(int(words[-1]))


filename = '6_Run tests.txt'
parse_file(filename)
print(data)


# ITerate over the data and plot the data lists
for key, value in data.items():
    plt.plot([i for i in range(len(value))], value, label=key)
    plt.title(key)
    plt.show()