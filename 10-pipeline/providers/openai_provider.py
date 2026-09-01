import os
from openai import OpenAI

from .base import Provider, GenerationResult

class OpenAIProvider(Provider):
    def __init__(self, model: str, max_output_tokens: int):
        self.model = model
        self.max_output_tokens = max_output_tokens
        self.client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

    def generate(self, prompt: str) -> GenerationResult:
        # Sem ferramentas e sem contexto externo. Uma única chamada.
        response = self.client.responses.create(
            model=self.model,
            input=prompt,
            max_output_tokens=self.max_output_tokens,
        )

        usage = {}
        if getattr(response, "usage", None):
            u = response.usage
            usage = {
                "input_tokens": getattr(u, "input_tokens", None),
                "output_tokens": getattr(u, "output_tokens", None),
                "total_tokens": getattr(u, "total_tokens", None),
            }

        return GenerationResult(
            text=response.output_text or "",
            model_requested=self.model,
            model_returned=getattr(response, "model", None),
            usage=usage,
            stop_reason=getattr(response, "status", None),
            raw_metadata={
                "response_id": getattr(response, "id", None),
                "api": "OpenAI Responses API",
                "reasoning_configuration": "provider/default unless overridden by model/API",
            },
        )
