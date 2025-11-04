# main.py

import os
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv

# --- LangChain Imports ---
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

# --- 1. Load Environment Variables ---
# This loads your "GOOGLE_API_KEY" from the .env file
load_dotenv()

# --- 2. Setup (FastAPI & LangChain) ---
app = FastAPI()

# This is the Pydantic model for your request body
# It ensures the Flutter app sends: {"transcript": "some text..."}
class TranscriptPayload(BaseModel):
    transcript: str

# --- 3. Build Your LangChain Chain ---

# 3a. Define the Prompt Template
prompt_template = """
You are a community assistant for a senior citizen app.
Read the following transcript.
Your task is to write a single, 1-sentence "headline" for this post (max 15 words).

Transcript:
"{transcript}"

Return *only* the summary headline and nothing else.
"""

prompt = ChatPromptTemplate.from_template(prompt_template)

# 3b. Initialize your LLM (Gemini)
model = ChatGoogleGenerativeAI(model="gemini-2.5-flash", 
                             temperature=0.3)

# 3c. Initialize the Output Parser
output_parser = StrOutputParser()

# 3d. Combine everything into a single "Chain"
summarize_chain = prompt | model | output_parser


# --- 4. The API Endpoint (Using the Chain) ---

@app.post("/summarize")
async def summarize_transcript(payload: TranscriptPayload):
    """
    Receives a transcript from the Flutter app, sends it to the 
    LangChain chain for summarization, and returns the summary.
    """
    
    input_data = {"transcript": payload.transcript}
    
    try:
        # 5. Call the LangChain chain asynchronously
        summary = await summarize_chain.ainvoke(input_data)
        
        # 6. Send the result back to Flutter
        return {"summary": summary.strip()}

    except Exception as e:
        print(f"Error invoking LangChain: {e}")
        raise HTTPException(status_code=500, detail="LLM summarization failed")

# --- 5. Run the Server ---
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)