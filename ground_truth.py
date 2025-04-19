import os
import pandas as pd
import random

def assign_random_value():
    values = ['Not insider trade', 'Low', 'Medium', 'High'] 
    return random.choice(values) # Random assignment of the ground truth 

# Define paths here
base_folder = r"path/to/folder" # Folder containing the Py file and the original CSV data folder
input_folder = os.path.join(base_folder, "original_csvs")  # Folder containing the CSV files
output_folder = os.path.join(base_folder, "processed_csvs")  # Output folder for processed files

if not os.path.exists(input_folder):
    raise FileNotFoundError(f"Input folder not found: {input_folder}")

os.makedirs(output_folder, exist_ok=True) # Create output folder if it doesn't exist

for filename in os.listdir(input_folder):
    if filename.endswith(".csv"):
        input_file_path = os.path.join(input_folder, filename)
        output_file_path = os.path.join(output_folder, filename)
        
        df = pd.read_csv(input_file_path)
        
        # Adding the column here
        df['Trade Classification'] = [assign_random_value() for _ in range(len(df))]
        
        df.to_csv(output_file_path, index=False)
        print(f"Processed file: {filename}")

print(f"All files have been processed and saved to '{output_folder}'.")