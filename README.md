Generative Texting
This mod integrates open-source language models to allow real-time, personalized texting with NPCs like Panam Palmer and Judy Alvarez.

Features
Dynamic Conversations: Engage in real-time text exchanges with NPCs that allow the player to say whatever they want, with responses generated in-character and at runtime by a language model.
Character Selection: Choose between supported NPCs (currently Panam and Judy).
Relationship Context: Customize the nature of your relationship (e.g., romantic or platonic) to influence the tone and content of the conversations.
Immersive UI Integration: Seamlessly integrated into the game's phone interface, maintaining the aesthetic and functionality of the original design.
Customizable Sampler Settings: Adjust sampling parameters like temperature, top_k, top_p, and more to fine-tune the responsiveness and creativity of NPC replies.

Planned Features
Support for multiple LLMs that can be selected by the player (GPT, Claude, etc.)
Support for more NPCs (eventually all of them)
Support for more than one active NPC at a time

How It Works
Generative Texting implements RedHttpClient﻿ to make post requests to the AI Horde﻿ API. AI Horde is a crowdsourced distributed cluster of image generation workers and text generation workers. It allows the mod to generate text anonymously and completely for free from open-source models tuned for RP. 

In game, after players have specified the NPC they want to chat with (Panam by default), they can navigate to the contacts page to find an additional input hint prompting them to open the custom chat UI. This UI is a 1:1 recreation of the original texting UI that allows the mod to render conversations independently from Cyberpunk's dialogue and localization system. Players are then prompted to interact with the text input field, allowing them to type any text message and send it to the NPC.

This triggers a post request, followed by get requests that retrieve the status of the generation until it's completed. If the custom chat UI is not open when a message is received, the player will get an SMS notification just like the normal texting system, allowing the player to send a text and continue to play while waiting for a response.

How To Use
﻿1. Navigate to Mod Settings and adjust the settings as needed.
﻿2. Open the contacts list by holding T, scroll to the selected NPC, and press T to open the chat window.
﻿3. Left click to begin typing, then press enter to send your message.
﻿4. Press R to reset the conversation as needed. This clears your conversation history in the prompt as well (the NPC will forget the conversation)

How To Install
Extract the zip to your game folder so the files end up in Cyberpunk 2077\r6\scripts\GenerativeTexting.

Compatibility
This mod creates a new chat system independent of existing systems and therefore should not have compatibility issues with any mod unless they modify the UI widgets related to the contacts list.

AI Horde
As previously mentioned, AI Horde provides an avenue for generating text using LLMs anonymously and for free. That being said, it is a crowdsources solution that operates based on users volunteering their GPUs to fulfill requests. As such, it's important to be aware that while the generations are anonymous, they are being fulfilled by another user and can technically be viewed by someone other than you (though they fulfill thousands of requests per hour so I personally don't worry about privacy issues). Additionally, the speed of request fulfillment depends on worker availability and user traffic, so the in-game response times will vary greatly, sometimes taking less than 20 seconds, but rarely more than a few minutes (or as I like to say, an intentional simulation of how texting works in real life!). You can increase response times by registering an account and using a specific API key and replacing the default in GenerativeTextingUtilities.reds.

Read more about AI Horde here﻿.

Disclaimer
The nature of prompting LLMs comes with inherent issues and limitations related to formatting, breaking character, hallucination, etc. I did the best I could with the system prompts, but you will no doubt encounter and have to accept the occasional jank interaction (e.g. in testing, Panam would often completely unprompted bring up Jackie as if he was alive, or make up locations and missions). I also did not spend much time testing or trying to prevent prompt injection or jailbreaking. Ultimately, the purpose of the mod is twofold:

﻿1. Provide a dynamic and immersive new way to interact with the game for people to enjoy.
﻿2. Explore a use case for RedHttpClient and LLMs in Cyberpunk for people to learn from/reference.

On the topic of immersion, this mod gives you the option to enable romantic interactions. From a roleplay perspective, this of course assumes that you have reached that relationship status with the NPC you're interacting with. I didn't add any conditions that enable or disable the mod or this setting, so it's up to you to use it however you like for your own purposes. That being said, the system prompts do currently assume V's gender, so Panam will assume you are male and a romanced Judy will assume you are female. Feel free to tweak the system prompts to suit your needs.

Development
If you are anyone interested in making a feature request or bug report, you can get in touch with me through the Cyberpunk Modding Discord﻿ or message me directly @jmtokx. If you are a modder interested in this kind of functionality, you can find the source code here﻿. I would love to continue iterating on this mod and making it better, so if you build new features or improve existing ones, I will happily merge them and continue collaborating.

Known Bugs
There is a bugged state of the game that is sometimes triggered by using the in game scanner in which most of the player's HUD disappears. If you try to open the custom UI when in this bugged state, you'll hear the sound effect but nothing will happen. If you try to press C to close the menu, the game will crash. To avoid this, ensure your UI is not bugged before trying to access the chat UI. If you notice it happen but the game hasn't crashed yet, you can salvage your game client by opening the CET ink inspector and removing the root widget at this path:
﻿1. Name Path: Root/HUDMiddleWidget/Root/contact_list_slot/Root
﻿2. Index Path: inkVirtualWindow[0]/inkCanvasWidget[53]/inkCanvasWidget[0]/inkCanvasWidget[9]/inkCanvasWidget[0]