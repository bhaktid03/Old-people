# LiveKit Voice Agent

A LiveKit-powered voice AI agent framework that demonstrates how to build realtime conversational AI with MCP (Model Context Protocol) server integration.

## Features

- 🎤 Natural voice conversations with low latency
- 🔄 Real-time voice interaction with interruption handling
- 🛠️ Tool integration via MCP servers
- 🎯 Multiple provider options (OpenAI, Deepgram, Cartesia, etc.)
- 🔌 Extensible architecture for custom tools and agents

## Prerequisites

- Python 3.9 or later
- API Keys:
  - OpenAI API key
  - Deepgram API key
  - LiveKit credentials (optional - only if deploying to LiveKit Cloud)

## Quick Start

### 1. Install Dependencies

```bash
# Install dependencies using UV
uv sync
```

### 2. Set Up Environment Variables

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

**Required variables:**
- `OPENAI_API_KEY` - OpenAI API key
- `DEEPGRAM_API_KEY` - Deepgram API key

**Optional for LiveKit Cloud deployment:**
- `LIVEKIT_URL` - LiveKit server URL
- `LIVEKIT_API_KEY` - LiveKit API key
- `LIVEKIT_API_SECRET` - LiveKit API secret

### 3. Download Required Model Files

Before first run, download the required model files (Silero VAD, turn detector):

```bash
# Download model files for basic agent
uv run python livekit_basic_agent.py download-files

# Download model files for MCP agent
uv run python livekit_mcp_agent.py download-files
```

### 4. Run the Agent

```bash
# Basic agent (minimal configuration)
uv run python livekit_basic_agent.py console

# MCP agent (with MCP server integration)
uv run python livekit_mcp_agent.py console

# Development mode (connects to LiveKit - optional)
uv run python livekit_basic_agent.py dev

# Production mode
uv run python livekit_basic_agent.py start
```

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   LiveKit   │──b─▶│ Voice Agent  │───▶│ MCP Servers │
│   Client    │     │              │     │   (Tools)   │
└─────────────┘     └──────────────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    │             │
              ┌─────▼────┐  ┌────▼─────┐
              │ Deepgram │  │  OpenAI  │
              │   STT    │  │ LLM/TTS  │
              └──────────┘  └──────────┘
```

## Project Files

### Basic Agent

**`livekit_basic_agent.py`** - The simplest possible LiveKit voice agent
- Minimal configuration with only essential components
- Great for learning and testing basic functionality
- Requires only OpenAI and Deepgram API keys
- Includes example tool: `get_current_date_and_time`

### MCP Agent

**`livekit_mcp_agent.py`** - Full-featured voice agent with:
- Configurable speech-to-text, LLM, and text-to-speech providers
- MCP server integration for tool calling
- Multilingual turn detection
- Event handling and state management
- Logging and metrics support

## Voice Pipeline Configuration

The agent uses a modular voice pipeline with swappable components:

### Speech-to-Text (STT)
- **Default**: Deepgram Nova-2 (highest accuracy)
- Alternatives: AssemblyAI, Azure Speech, Whisper

### Large Language Model (LLM)
- **Default**: OpenAI GPT-4.1-mini (fast, cost-effective)
- Alternatives: Anthropic Claude, Google Gemini, Groq

### Text-to-Speech (TTS)
- **Default**: OpenAI Echo voice (natural, versatile)
- Alternatives: Cartesia (fastest), ElevenLabs (highest quality)

### Voice Activity Detection (VAD)
- **Default**: Silero VAD (reliable voice detection)

### Turn Detection
- **Default**: Multilingual Model (natural conversation flow)
- Alternatives: Semantic model, VAD-based

## MCP Server Integration

The agent supports integration with MCP (Model Context Protocol) servers for extending functionality with custom tools.

### Configuring MCP Servers

In `livekit_mcp_agent.py`:

```python
session = AgentSession(
    # ... other config ...
    mcp_servers=[
        mcp.MCPServerHTTP(url="http://localhost:8089/mcp")
    ]
)
```

### Adding Custom Tools

You can also add tools directly to your agent using the `@function_tool` decorator:

```python
from livekit.agents import function_tool, RunContext
from datetime import datetime

class Assistant(Agent):
    @function_tool
    async def get_current_time(self, context: RunContext) -> str:
        """Get the current time."""
        return datetime.now().strftime("%I:%M %p")
```

## Development

### Project Structure

```
livekit-agent/
├── livekit_basic_agent.py   # Basic example agent
├── livekit_mcp_agent.py     # MCP-enabled agent
├── pyproject.toml           # Dependencies
├── .env.example             # Environment template
├── Dockerfile               # Container deployment
└── README.md
```

### Installing Additional Providers

```bash
# Additional TTS providers
uv add livekit-plugins-cartesia livekit-plugins-elevenlabs

# Additional LLM providers
uv add livekit-plugins-anthropic livekit-plugins-google livekit-plugins-groq

# Additional STT providers
uv add livekit-plugins-assemblyai livekit-plugins-azure
```

## Deploy to LiveKit Cloud

Once you've tested your agent locally, deploy it to LiveKit Cloud for production use:

### 1. Create a LiveKit Cloud Account

Sign up at [LiveKit Cloud](https://cloud.livekit.io/)

### 2. Install the LiveKit CLI

Choose the installation method for your platform:

**Windows:**
```bash
winget install LiveKit.LiveKitCLI
```

**Mac:**
```bash
brew install livekit
```

**Linux:**
```bash
curl -sSL https://get.livekit.io/ | bash
```

### 3. Authenticate with LiveKit Cloud

Open a new terminal and authenticate:

```bash
lk cloud auth
```

### 4. Configure Environment Variables

Set up your environment variables for the cloud:

```bash
lk app env -w
```

This will write your LiveKit credentials to `.env.local`

### 5. Start Your Agent

Run your agent connected to LiveKit Cloud:

```bash
uv run python livekit_basic_agent.py start
```

### 6. Create an Agent in LiveKit Cloud

In a separate terminal, register your agent:

```bash
lk agent create
```

### 7. Test in the Playground

Visit the [LiveKit Agents Playground](https://agents-playground.livekit.io/) and sign in with your LiveKit organization to test your agent in the browser.

### 8. Telephony Integration (Optional)

To integrate your agent with phone calling systems, see the [LiveKit Telephony documentation](https://docs.livekit.io/agents/start/telephony/)

## Performance Optimization

### Reduce Latency
- Use regional deployments close to users
- Choose faster providers (Deepgram for STT, Cartesia for TTS)
- Use streaming where possible

### Scale Efficiently
- Set appropriate prewarm counts in `livekit.toml` for production
- Use connection pooling for external API calls
- Implement caching for frequently accessed data

## Console Mode Testing

Console mode lets you test your agent locally without needing a LiveKit server:

```bash
# Test the basic agent
uv run python livekit_basic_agent.py console

# Test the MCP agent
uv run python livekit_mcp_agent.py console
```

This will start an interactive console where you can speak to your agent using your microphone and speakers.

## Troubleshooting

### Python Version
Ensure you're using Python 3.9 or later:
```bash
python --version
```

### Model Downloads
TTS models may download on first use, which can take time. The Docker image pre-downloads Silero VAD to speed up startup.

### API Key Issues
- Verify all required API keys are set in `.env`
- Check that API keys are valid and have sufficient credits
- Ensure no extra whitespace in environment variable values

### Audio Issues in Console Mode
- Check microphone/speaker permissions
- Verify audio devices are correctly configured
- Try adjusting VAD sensitivity if voice detection is problematic

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENAI_API_KEY` | Yes | OpenAI API key for LLM/TTS |
| `DEEPGRAM_API_KEY` | Yes | Deepgram API key for STT |
| `LIVEKIT_URL` | No | LiveKit server URL (for deployment) |
| `LIVEKIT_API_KEY` | No | LiveKit API key (for deployment) |
| `LIVEKIT_API_SECRET` | No | LiveKit API secret (for deployment) |
| `LLM_CHOICE` | No | Model selection (default: gpt-4.1-mini) |
| `LOG_LEVEL` | No | Logging level (default: INFO) |

## Resources

- [LiveKit Agents Documentation](https://docs.livekit.io/agents/)
- [LiveKit Python SDK](https://github.com/livekit/agents)
