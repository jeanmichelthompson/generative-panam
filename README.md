# Generative Texting

This mod integrates open-source language models to allow real-time, personalized texting with NPCs like Panam Palmer and Judy Alvarez.

## Features

- **Dynamic Conversations**: Engage in real-time text exchanges with NPCs that allow the player to say whatever they want, with responses generated in-character and at runtime by a language model.
- **Character Selection**: Choose between supported NPCs (currently Panam and Judy).
- **Relationship Context**: Customize the nature of your relationship (e.g., romantic or platonic) to influence the tone and content of the conversations.
- **Immersive UI Integration**: Seamlessly integrated into the game's phone interface, maintaining the aesthetic and functionality of the original design.
- **Customizable Sampler Settings**: Adjust sampling parameters like temperature, top_k, top_p, and more to fine-tune the responsiveness and creativity of NPC replies.

### Planned Features

- Support for multiple LLMs that can be selected by the player (GPT, Claude, etc.)
- Support for more NPCs (eventually all of them)
- Support for more than one active NPC at a time

## How It Works

Generative Texting implements `RedHttpClient` to make post requests to the [AI Horde](https://aihorde.net) API. AI Horde is a crowdsourced distributed cluster of image generation and text generation workers. It allows the mod to generate text anonymously and completely for free from open-source models tuned for RP. 

In game, after players have specified the NPC they want to chat with (Panam by default), they can navigate to the contacts page to find an additional input hint prompting them to open the custom chat UI. This UI is a 1:1 recreation of the original texting UI that allows the mod to render conversations independently from Cyberpunk's dialogue and localization system. Players can then type any text message and send it to the NPC.

This triggers a post request, followed by get requests that retrieve the status of the generation until it's completed. If the custom chat UI is not open when a message is received, the player will get an SMS notification just like the normal texting system.

## Usage Instructions

1. Navigate to Mod Settings and adjust the settings as needed
2. Open the contacts list by holding T, scroll to the selected NPC, and press T to open the chat window
3. Left click to begin typing, then press enter to send your message
4. Press R to reset the conversation as needed (this clears your conversation history)

## Installation

Extract the zip to your game folder so the files end up in `Cyberpunk 2077\r6\scripts\GenerativeTexting`.

## Compatibility

This mod creates a new chat system independent of existing systems and should not have compatibility issues with any mod unless they modify the UI widgets related to the contacts list.

## AI Horde Details

AI Horde provides anonymous and free LLM text generation through crowdsourced GPU workers. Please note:

- Generations are anonymous but technically viewable by workers
- Response times vary based on worker availability (20 seconds to few minutes)
- You can improve response times by registering for an API key

[Learn more about AI Horde](https://aihorde.net)

## Disclaimer

The nature of prompting LLMs comes with inherent limitations:
- Occasional formatting issues and character breaks
- Possible hallucinations (e.g. NPCs referencing non-existent locations)
- Basic prompt injection protection

The mod aims to:
1. Provide dynamic and immersive NPC interactions
2. Demonstrate RedHttpClient and LLM integration for reference

## Development

- For feature requests/bug reports: Contact through [Cyberpunk Modding Discord](https://discord.gg/Cyberpunk2077Modding) or @jmtokx
- Source code available on GitHub
- Contributions welcome!

## Known Issues

There is a UI bug that can occur when using the scanner:
- HUD elements may disappear
- Custom UI won't open properly
- Game may crash when pressing C

To fix if encountered, use CET ink inspector to remove the root widget at:
- Name Path: `Root/HUDMiddleWidget/Root/contact_list_slot/Root`
- Index Path: `inkVirtualWindow[0]/inkCanvasWidget[53]/inkCanvasWidget[0]/inkCanvasWidget[9]/inkCanvasWidget[0]`
