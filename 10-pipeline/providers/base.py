from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any

@dataclass
class GenerationResult:
    text: str
    model_requested: str
    model_returned: str | None
    usage: dict[str, Any]
    stop_reason: str | None
    raw_metadata: dict[str, Any]

class Provider(ABC):
    @abstractmethod
    def generate(self, prompt: str) -> GenerationResult:
        raise NotImplementedError
