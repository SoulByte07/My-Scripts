import streamlit as st
import json
import os
from google.genai import Client

# --- Cache Setup ---
CACHE_FILE = "aws_cache.json"

if 'data' not in st.session_state:
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, "r") as f:
            st.session_state['data'] = json.load(f)
    else:
        st.session_state['data'] = {}

def save_cache():
    with open(CACHE_FILE, "w") as f:
        json.dump(st.session_state['data'], f)

# --- Model Detection ---
def get_best_model(client):
    """Checks the API for available models and picks the best Flash variant."""
    available_models = [m.name for m in client.models.list()]
    
    # Priority List for Dec 2025
    priorities = [
        "models/gemini-3-flash-preview", # Newest
        "models/gemini-3-flash",         # Stable (if released)
        "models/gemini-2.5-flash",       # Reliable fallback
        "models/gemini-1.5-flash"        # Legacy fallback
    ]
    
    for model_id in priorities:
        if model_id in available_models:
            return model_id
            
    return "gemini-1.5-flash" # Absolute fallback

# --- UI Layout ---
st.set_page_config(page_title="AWS Documentation AI", layout="wide")
st.title("🚀 AWS Lab → GitHub Project README")

api_key = st.sidebar.text_input("Gemini API Key", type="password")

if api_key:
    client = Client(api_key=api_key)
    
    # Auto-detect best model
    MODEL_ID = get_best_model(client)
    st.sidebar.info(f"Using Model: {MODEL_ID}")
    
    uploaded_file = st.file_uploader("Upload Lab Instructions (.txt)", type="txt")

    if uploaded_file:
        raw_text = uploaded_file.read().decode("utf-8")
        
        # STAGE 1: THE CLEANER
        if st.button("Stage 1: Remove Fluff"):
            if 'cleaned' not in st.session_state['data']:
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

            # STAGE 2: THE ARCHITECT
            if st.button("Stage 2: Architect README"):
                if 'readme' not in st.session_state['data']:
                    with st.spinner("Building Professional Documentation..."):
                        response = client.models.generate_content(
                            model=MODEL_ID,
                            contents=f"Convert these steps into a high-quality GitHub README. Use 'Project' instead of 'Lab'. Add Architecture, Steps, and Clean-up sections:\n\n{cleaned_text}"
                        )
                        st.session_state['data']['readme'] = response.text
                        save_cache()

        # FINAL ACTIONS
        if 'readme' in st.session_state['data']:
            st.subheader("Generated README.md")
            final_md = st.text_area("Edit Final Version:", st.session_state['data']['readme'], height=400)
            st.download_button("Download README.md", final_md, file_name="README.md")

    if st.sidebar.button("Clear AI Cache"):
        if os.path.exists(CACHE_FILE): os.remove(CACHE_FILE)
        st.session_state['data'] = {}
        st.rerun()
