
### Key Characteristics
#### 1. Autonomous
AI system's ability to make decisions and take actions on its own to achieve a given goal, without step-by-step human instructions. Human-in-the-Loop (HITL) where AI asks human approval before high-risk actions.
#### 2. Goal Oriented
AI system operates with persistent objective in mind and directs its actions to achieve that objective. The goal should be saved in core memory which means the context awareness memory, agent should remember everything to make the plan and do the tasks. 
#### 3. Planning
Agent's ability to break down a high-level goal into a structured sequence of actions or subgoals, and decide the best path to achieve the desired outcome.
#### 4. Reasoning
Agentic AI interprets information, breaks down the goals, makes decisions, selects tool.   
#### 5. Adaptability
Agent's ability to modify its plan, strategies, or actions in response to unexpected condition, while aligning the goals. 
#### 6. Context Awareness
Agent's ability to understand, retain, and utilize relevant information from the ongoing task, past interactions, user preferences, and environment cues to make better decisions, which also refers to the agent's memory.


### Components
#### 1. Brain
Refers to LLM has the reasoning capability to make decisions. Functionalities: Goal interpretation, Planning, Reasoning, Tool selection.
#### 2. Orchestrator
AI agent implementation Framework that connects the LLM with tools, such as LangGraph, Autogen, N8N. Functionalities: Task sequencing, Conditional routing, Retry logic, Looping & iteration, Delegation.
#### 3. Tools
AI agent tools that were used by LLM to do tasks, such as search tool, calendar tool, etc. Functionalities: External actions, Knowledge base access.
#### 4. Memory
Memory should be integrated. Orchestrator framework provide different memory functions and databases. Functionalities: Short-term memory, Long-term memory, State tracking.
#### 5. Supervisor
Refers to HITL, which is interacting with the human for any guidance or feedback. Functionalities: Approval requests (HITL), Guardrails enforcement, Edge case escalation.


### Asynchronous Programming
Programming paradigm that allows code to handle multiple tasks concurrently without blocking the program's execution. It is primarily used for I/O-bound tasks (e.g., network requests, file I/O, database queries), allowing the program to perform other operations while waiting for slow external events to complete.

#### Subroutine function
Function that follows a strict hierarchical "caller-callee" relationship. It always enters at the first line of code and exits at a `return` statement or the end of the block. Waiting for the previous execution to be completed, then the remaining code will be executed.
#### Co-routine function
Async function that is designed for **cooperative multitasking** and asynchronous operations. It can pause itself using keywords like `yield` or `await`, giving control back to the caller while saving its current state. While waiting for the async function execution, it will execute the remaining code after the function.

#### Synchronous programming
``` python
import time

def fetch_weather():
	print("Fetching weather data...")
	time.sleep(4)
	print("Weather data fetched.")
	
def fetch_news():
	print("Fetching news data...")
	time.sleep(2)
	print("News data fetched.")
	
def main():
	start_time =  time.time()
	fetch_weather()
	fetch_news()
	end_time = time.time()
	
	print(f"Total tike taken: {end_time - start_time} seconds")
	
main()
```

#### Asynchronous programming
``` python
import asyncio
import time

async def fetch_weather():
	print("Fetching weather data...")
	await asyncio.sleep(4)
	print("Weather data fetched.")
	
async def fetch_news():
	print("Fetching news data...")
	await asyncio.sleep(2)
	print("News data fetched.")
	
async def main():
	start_time =  time.time()
	await asyncio.gather(fetch_weather(), fetch_news())
	end_time = time.time()
	
	print(f"Total tike taken: {end_time - start_time} seconds")

await main()
```

#### Parallelism
Running multiple tasks simultaneously using multiple threads or processes.
#### Concurrency
Managing multiple tasks that can start, run and finish with overlapping time.
