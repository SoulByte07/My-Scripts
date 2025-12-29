def generate_readme(client, model_id, cleaned_text, prompt_path):
    """Stage 2: Transforms facts into a professional README."""
    with open(prompt_path, "r") as f:
        custom_prompt = f.read().strip()
    
    response = client.models.generate_content(
        model=model_id,
        contents=f"{custom_prompt}\n\nTechnical Input:\n{cleaned_text}"
    )
    return response.text
