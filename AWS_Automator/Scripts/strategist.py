def generate_problem_statement(client, model_id, cleaned_text, prompt_path):
    """Stage 3: Generates high-level business context."""
    with open(prompt_path, "r") as f:
        custom_prompt = f.read().strip()
    
    response = client.models.generate_content(
        model=model_id,
        contents=f"{custom_prompt}\n\nTechnical Input:\n{cleaned_text}"
    )
    return response.text
