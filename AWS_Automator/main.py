import streamlit as st
import json
import os
from google.genai import Client
from Scripts.cleaner import clean_lab_text
from Scripts.architect import generate_readme
from Scripts.strategist import generate_problem_statement

# --- Updated Path Configuration ---
PATHS = {
    "cache": "Cache/AWS_cache.json",
    "api": "API/api_key.txt",
    "doc_prompt": "Prompts/doc.md",
    "prob_prompt": "Prompts/problem.md"
}

# Create missing directories automatically
for folder in ["Cache", "API", "Prompts", "Scripts"]:
    os.makedirs(folder, exist_ok=True)

# --- State Management ---
if 'data' not in st.session_state:
    if os.path.exists(PATHS["cache"]):
        with open(PATHS["cache"], "r") as f:
            st.session_state['data'] = json.load(f)
    else:
        st.session_state['data'] = {}

def save_cache():
    with open(PATHS["cache"], "w") as f:
        json.dump(st.session_state['data'], f)

# --- UI Setup ---
st.set_page_config(page_title="AWS Project Automator", layout="wide")
st.title("🚀 AWS Lab → Portfolio Pipeline")

# Load API Key from file
saved_key = ""
if os.path.exists(PATHS["api"]):
    with open(PATHS["api"], "r") as f:
        saved_key = f.read().strip()

api_key = st.sidebar.text_input("Gemini API Key", value=saved_key, type="password")

if api_key:
    client = Client(api_key=api_key)
    MODEL_ID = "gemini-2.0-flash" 

    uploaded_file = st.file_uploader("Upload Lab Instructions (.txt)", type="txt")

    if uploaded_file:
        raw_text = uploaded_file.read().decode("utf-8")
        
        # --- STAGE 1: CLEAN ---
        if st.button("Step 1: Clean Lab Instructions"):
            with st.spinner("Cleaning..."):
                st.session_state['data']['cleaned'] = clean_lab_text(client, MODEL_ID, raw_text)
                save_cache()

        if 'cleaned' in st.session_state['data']:
            c_text = st.text_area("Technical Facts:", st.session_state['data']['cleaned'], height=150)
            st.download_button("📥 Download Cleaned Text", c_text, file_name="cleaned_lab.txt")
            st.divider()

            # --- STAGE 2 & 3: ARCHITECT & STRATEGIST ---
            col1, col2 = st.columns(2)
            
            with col1:
                st.subheader("Architect (README)")
                if st.button("Generate README.md"):
                    st.session_state['data']['readme'] = generate_readme(client, MODEL_ID, c_text, PATHS["doc_prompt"])
                    save_cache()
                if 'readme' in st.session_state['data']:
                    st.download_button("💾 Download README.md", st.session_state['data']['readme'], file_name="README.md")

            with col2:
                st.subheader("Strategist (Problem Statement)")
                if st.button("Generate Problem.md"):
                    st.session_state['data']['problem'] = generate_problem_statement(client, MODEL_ID, c_text, PATHS["prob_prompt"])
                    save_cache()
                if 'problem' in st.session_state['data']:
                    st.download_button("📝 Download Problem.md", st.session_state['data']['problem'], file_name="Problem_Statement.md")
