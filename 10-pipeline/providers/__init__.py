from .openai_provider import OpenAIProvider
from .deepseek_provider import DeepSeekProvider
from .anthropic_provider import AnthropicProvider

from config import PROVIDERS


def build_provider(provider_name: str):
    cfg = PROVIDERS[provider_name]

    if provider_name == "openai":
        return OpenAIProvider(
            model=cfg.model,
            max_output_tokens=cfg.max_output_tokens,
        )

    if provider_name == "deepseek":
        return DeepSeekProvider(
            model=cfg.model,
            max_output_tokens=cfg.max_output_tokens,
        )

    if provider_name == "anthropic":
        return AnthropicProvider(
            model=cfg.model,
            max_output_tokens=cfg.max_output_tokens,
        )

    raise ValueError(
        f"Provedor desconhecido: {provider_name}"
    )