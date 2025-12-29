import streamlit as st
import json
import os
from google.genai import Client

# --- File Paths ---
CACHE_FILE = "aws_cache.json"
API_KEY_FILE = "api_key.txt"
PROMPT_FILE = "DOC_PROMPT.md"

# --- Initialization ---
if 'data' not in st.session_state:
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, "r") as f:
            st.session_state['data'] = json.load(f)
    else:
        st.session_state['data'] = {}

def save_cache():
    with open(CACHE_FILE, "w") as f:
        json.dump(st.session_state['data'], f)

def load_external_file(filepath, default_content=""):
    """Helper to read local files (API key or Prompts)."""
    if os.path.exists(filepath):
        with open(filepath, "r") as f:
            return f.read().strip()
    return default_content

# --- Model Detection ---
def get_best_model(client):
    """Checks the API for available models and picks the best Flash variant."""
    available_models = [m.name for m in client.models.list()]
    priorities = [
        "models/gemini-3-flash-preview", 
        "models/gemini-3-flash",         
        "models/gemini-2.5-flash",       
        "models/gemini-1.5-flash"        
    ]
    for model_id in priorities:
        if model_id in available_models:
            return model_id
    return "gemini-1.5-flash"

# --- UI Layout ---
st.set_page_config(page_title="AWS Documentation AI", layout="wide")
st.title("🚀 AWS Lab → GitHub Project README")

# 1. API Key Logic (File-based with UI fallback)
saved_key = load_external_file(API_KEY_FILE)
api_key = st.sidebar.text_input("Gemini API Key", value=saved_key, type="password")

if api_key:
    client = Client(api_key=api_key)
    MODEL_ID = get_best_model(client)
    st.sidebar.info(f"Using Model: {MODEL_ID}")
    
    uploaded_file = st.file_uploader("Upload Lab Instructions (.txt)", type="txt")

    if uploaded_file:
        raw_text = uploaded_file.read().decode("utf-8")
        
        # --- STAGE 1: THE CLEANER ---
        if st.button("Stage 1: Remove Fluff"):
            with st.spinner(f"Cleaning using {MODEL_ID}..."):
                response = client.models.generate_content(
                    model=MODEL_ID,
                    contents=f"Extract technical steps only. Remove all UI navigation and grading fluff:\n\n{raw_text}"
                )
                st.session_state['data']['cleaned'] = response.text
                save_cache()
            st.success("Cleaned content ready!")

        if 'cleaned' in st.session_state['data']:
            cleaned_text = st.text_area("Technical Steps (Review):", st.session_state['data']['cleaned'], height=200)
            
            # New Download Button for Stage 1
            st.download_button(
                label="📥 Download Cleaned Steps",
                data=st.session_state['data']['cleaned'],
                file_name="cleaned_steps.txt",
                mime="text/plain"
            )

            st.divider()

            # --- STAGE 2: THE ARCHITECT ---
            # Load custom prompt from DOC_PROMPT.md
            custom_prompt_base = load_external_file(PROMPT_FILE, "Convert these steps into a professional GitHub README. Use 'Project' instead of 'Lab'.")
            
            if st.button("Stage 2: Architect README"):
                with st.spinner("Building Professional Documentation..."):
                    # Combine the file-based prompt with the cleaned text
                    full_prompt = f"{custom_prompt_base}\n\nTechnical Input:\n{cleaned_text}"
                    
                    response = client.models.generate_content(
                        model=MODEL_ID,
                        contents=full_prompt
                    )
                    st.session_state['data']['readme'] = response.text
                    save_cache()

        # --- FINAL ACTIONS ---
        if 'readme' in st.session_state['data']:
            st.subheader("Generated README.md")
            final_md = st.text_area("Edit Final Version:", st.session_state['data']['readme'], height=400)
            st.download_button("Download README.md", final_md, file_name="README.md")

    if st.sidebar.button("Clear AI Cache"):
        if os.path.exists(CACHE_FILE): os.remove(CACHE_FILE)
        st.session_state['data'] = {}
        st.rerun()
