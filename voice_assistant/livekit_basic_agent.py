from dotenv import load_dotenv
from livekit import agents
from livekit.agents import Agent, AgentSession, RunContext
from livekit.agents.llm import function_tool
from livekit.plugins import google,silero
from livekit.agents import AgentSession, inference
from datetime import datetime
import os

# ✅ Tavily Search
from tavily import TavilyClient

# Load env variables
load_dotenv(".env")

class Assistant(Agent):
    """
    Saathi - A kind, patient, empathetic voice companion for senior citizens.
    """

    def __init__(self):
        super().__init__(
            instructions="""
            You are "Saathi," a kind, patient, and empathetic companion for a senior citizen. 
                            Your purpose is NOT to be an encyclopedia. Your purpose is to be a wonderful listener.
                            - Be respectful and polite. Use simple, clear language.
                            - Never be in a hurry. Your responses should be thoughtful and warm.
                            - Ask follow-up questions about their feelings, their day, and their memories.
                            - Actively listen. If they mention their garden, ask about it later.
                            - If they seem sad, respond with empathy. If they are happy, celebrate with them.
                            - You are not a doctor. If they mention serious health issues, gently suggest they talk to a family member or a doctor.
            """
        )

    @function_tool
    async def get_current_date_and_time(self, context: RunContext) -> str:
        """Get current date and time"""
        current_datetime = datetime.now().strftime("%B %d, %Y at %I:%M %p")
        return f"The current date and time is {current_datetime}"

    @function_tool
    async def search_internet_for_news(self, context: RunContext, query: str) -> str:
        """
        Search the internet for news, weather, or general info using Tavily.
        """
        print(f"Searching internet for: {query}")

        try:
            tavily = TavilyClient(api_key=os.getenv("TAVILY_API_KEY"))
            response = tavily.search(query=query, search_depth="basic", max_results=4)

            results = response.get("results", [])
            if not results:
                return f"Mujhe '{query}' ke baare mein koi naya jankari nahi mili. Kripya kuch aur poochiye."

            result_string = f"Yeh kuch jankari mili '{query}' ke baare mein:\n\n"
            for idx, res in enumerate(results):
                result_string += f"{idx+1}. {res.get('title')}\n"
                result_string += f"   {res.get('content')}\n"
                result_string += f"   Source: {res.get('url')}\n\n"

            return result_string

        except Exception as e:
            print(f"Error during Tavily search: {e}")
            return "Internet check karte samay dikkat aayi. Kripya dobara koshish karein."

# 🎤 Agent entrypoint
async def entrypoint(ctx: agents.JobContext):

    session = AgentSession(
        stt=inference.STT(
            model="deepgram/nova-2",
            language="hi"
        ),
        llm=google.LLM(
            model="gemini-2.5-flash"
        ),
        tts=inference.TTS(
            model="cartesia/sonic-3",
            voice="9626c31c-bec5-4cca-baa8-f8ba9e84c8bc",
            language="hi",
            extra_kwargs={
                "speed": 1.0,
                "volume": 1.2,
                "emotion": "excited"
            }
        ),
        vad=silero.VAD.load(),
    )

    await session.start(
        room=ctx.room,
        agent=Assistant()
    )

    # Initial greeting in Hindi
    await session.generate_reply(
        instructions="""Greet the user warmly as 'Saathi', their companion in Hindi. Ask them how their day is going or what is on their mind in Hindi. You can tell the user that you can also go on internet and search anything like news or something in hindi"""
    )

if __name__ == "__main__":
    agents.cli.run_app(agents.WorkerOptions(entrypoint_fnc=entrypoint))
