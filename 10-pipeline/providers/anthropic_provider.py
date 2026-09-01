import os
import anthropic

from .base import Provider, GenerationResult

class AnthropicProvider(Provider):
    def __init__(self, model: str, max_output_tokens: int):
        self.model = model
        self.max_output_tokens = max_output_tokens
        self.client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

    def generate(self, prompt: str) -> GenerationResult:
        response = self.client.messages.create(
            model=self.model,
            max_tokens=self.max_output_tokens,
            messages=[{"role": "user", "content": prompt}],
        )

        text_parts = []
        for block in response.content:
            if getattr(block, "type", None) == "text":
                text_parts.append(block.text)

        usage = {
            "input_tokens": getattr(response.usage, "input_tokens", None),
            "output_tokens": getattr(response.usage, "output_tokens", None),
        }

        return GenerationResult(
            text="\n".join(text_parts),
            model_requested=self.model,
            model_returned=getattr(response, "model", None),
            usage=usage,
            stop_reason=getattr(response, "stop_reason", None),
            raw_metadata={
                "response_id": getattr(response, "id", None),
                "api": "Anthropic Messages API",
                "thinking_configuration": "provider/default",
            },
        )
