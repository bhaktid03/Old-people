# main.py

import os
import uvicorn
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional
import tempfile
import shutil
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
    context: Optional[str] = None

class STTResponse(BaseModel):
    text: str
    language: Optional[str] = None
    durationSec: Optional[float] = None
    confidence: Optional[float] = None

class VoiceInterpretResponse(BaseModel):
    transcript: str
    language: Optional[str] = None
    llmReply: str
    meta: dict

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
model = ChatGoogleGenerativeAI(model="gemini-1.5-flash", 
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

# ---------------- Whisper (local) STT ----------------
WHISPER_MODEL = os.getenv("WHISPER_MODEL", "base")  # e.g., tiny, base, small, medium, large-v2
WHISPER_DEVICE = os.getenv("WHISPER_DEVICE", "cpu")  # cpu or cuda

_whisper_model = None

def _get_whisper():
    global _whisper_model
    if _whisper_model is None:
        try:
            # Prefer faster-whisper if available, otherwise fallback to openai-whisper
            from faster_whisper import WhisperModel  # type: ignore
            _whisper_model = ("faster", WhisperModel(WHISPER_MODEL, device=WHISPER_DEVICE))
        except Exception:
            import whisper  # type: ignore
            _whisper_model = ("openai", whisper.load_model(WHISPER_MODEL, device=WHISPER_DEVICE))
    return _whisper_model


@app.post("/stt/transcribe", response_model=STTResponse)
async def stt_transcribe(
    file: UploadFile = File(...),
    language: Optional[str] = Form(None),
):
    # Save upload to temp file
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".m4a") as tmp:
            with file.file as fsrc:
                shutil.copyfileobj(fsrc, tmp)
            temp_path = tmp.name
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to save upload: {e}")

    engine, model_obj = _get_whisper()
    try:
        if engine == "faster":
            segments, info = model_obj.transcribe(temp_path, language=language)
            text_parts = []
            avg_prob = []
            for seg in segments:
                text_parts.append(seg.text)
                if hasattr(seg, "avg_logprob") and seg.avg_logprob is not None:
                    avg_prob.append(seg.avg_logprob)
            text = " ".join([t.strip() for t in text_parts]).strip()
            conf = float(sum(avg_prob) / len(avg_prob)) if avg_prob else None
            return STTResponse(text=text, language=info.language, durationSec=info.duration, confidence=conf)
        else:
            # openai-whisper
            result = model_obj.transcribe(temp_path, language=language)
            text = (result.get("text") or "").strip()
            lang = result.get("language")
            return STTResponse(text=text, language=lang)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"STT failed: {e}")


# --------------- LLM respond (generic) ----------------
@app.post("/llm/respond")
async def llm_respond(payload: TranscriptPayload):
    try:
        summary = await summarize_chain.ainvoke({"transcript": payload.transcript})
        return {"reply": summary.strip()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM failed: {e}")


# --------------- Combined: STT then LLM ----------------
@app.post("/voice/interpret", response_model=VoiceInterpretResponse)
async def voice_interpret(
    file: UploadFile = File(...),
    language: Optional[str] = Form(None),
):
    stt = await stt_transcribe(file=file, language=language)
    try:
        reply = await summarize_chain.ainvoke({"transcript": stt.text})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM failed: {e}")
    return VoiceInterpretResponse(
        transcript=stt.text,
        language=stt.language,
        llmReply=reply.strip(),
        meta={"provider": "whisper+gemini", "model": WHISPER_MODEL},
    )

# --- 5. Run the Server ---
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)