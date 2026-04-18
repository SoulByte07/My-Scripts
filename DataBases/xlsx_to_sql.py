"""
This script reads an Excel file, cleans the data, and imports it into a SQLite database.
requirements:
- uv (for managing dependencies)
- pandas
- sqlalchemy
- openpyxl (for reading Excel files)
- sqlite3 (comes with Python)
To run:
1. Ensure you have the required libraries installed:
    1.1 init the folder with uv
        `uv init` 
    2.2 install dependencies
        `uv add pandas sqlalchemy openpyxl`
2. Place your Excel file (e.g., 'Retail.xlsx') in the 'DataSet
3. Run the script:
    `uv run xlsx_to_sql.py`

"""


import pandas as pd
from sqlalchemy import create_engine
from pathlib import Path

def excel_to_db(file_name, db_name, table_name):
    # Get the directory where THIS script is located (the 'Scripts' folder)
    base_path = Path(__file__).resolve().parent
    
    # Navigate to the root (one level up)
    root_path = base_path.parent
    
    # Define absolute paths based on the project structure
    excel_path = root_path / "DataSet" / file_name
    db_path = root_path / f"{db_name}.db"

    # 1. Read the Excel file
    df = pd.read_excel(excel_path)

    # 2. Data Cleaning
    df.columns = [c.lower().replace(' ', '_') for c in df.columns]

    # 3. Push to SQL
    # We use .absolute() to ensure SQLAlchemy doesn't get confused
    engine = create_engine(f'sqlite:///{db_path.absolute()}')
    df.to_sql(table_name, engine, if_exists='replace', index=False)
    
    print(f"Success! Imported {len(df)} rows.")
    print(f"Database created at: {db_path.absolute()}")

if __name__ == "__main__":
    excel_to_db('Retail.xlsx', 'Retail', 'products')
