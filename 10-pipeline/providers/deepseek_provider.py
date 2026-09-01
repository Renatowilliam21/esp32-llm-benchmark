import os
from openai import OpenAI

from .base import Provider, GenerationResult


class DeepSeekProvider(Provider):
    def __init__(self, model: str, max_output_tokens: int):
        self.model = model
        self.max_output_tokens = max_output_tokens

        self.client = OpenAI(
            api_key=os.environ["DEEPSEEK_API_KEY"],
            base_url="https://api.deepseek.com",
        )

    def generate(self, prompt: str) -> GenerationResult:
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
            max_tokens=self.max_output_tokens,
        )

        text = ""
        stop_reason = None

        if response.choices:
            choice = response.choices[0]

            if choice.message and choice.message.content:
                text = choice.message.content

            stop_reason = getattr(
                choice,
                "finish_reason",
                None,
            )

        usage = {}

        if getattr(response, "usage", None):
            u = response.usage

            usage = {
                "input_tokens": getattr(
                    u,
                    "prompt_tokens",
                    None,
                ),
                "output_tokens": getattr(
                    u,
                    "completion_tokens",
                    None,
                ),
                "total_tokens": getattr(
                    u,
                    "total_tokens",
                    None,
                ),
            }

        return GenerationResult(
            text=text,
            model_requested=self.model,
            model_returned=getattr(
                response,
                "model",
                None,
            ),
            usage=usage,
            stop_reason=stop_reason,
            raw_metadata={
                "response_id": getattr(
                    response,
                    "id",
                    None,
                ),
                "api": "DeepSeek Chat Completions API",
                "reasoning_configuration": (
                    "provider/default unless overridden by model/API"
                ),
            },
        )