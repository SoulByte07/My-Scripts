def clean_lab_text(client, model_id, raw_text):
    """Stage 1: Extracts technical facts from raw lab text."""
    prompt = "Extract technical steps only. Remove all UI navigation and grading fluff."
    response = client.models.generate_content(
        model=model_id,
        contents=f"{prompt}\n\n{raw_text}"
    )
    return response.text
