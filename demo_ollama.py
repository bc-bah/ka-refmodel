"""Demo script showing how to use Knowledge Assistant with local Ollama models.

This script demonstrates:
1. Setting up the OllamaLlmProvider
2. Getting embedding and generative models
3. Simple query and embedding examples
"""

from knowledge_assistant.llamaindex.local.models.ollama import OllamaLlmProvider


def main():
    print("=" * 60)
    print("Knowledge Assistant + Ollama Demo")
    print("=" * 60)
    
    # Initialize Ollama provider
    print("\n1. Initializing Ollama Provider...")
    provider = OllamaLlmProvider(
        base_url="http://localhost:11434",
        request_timeout=120.0
    )
    print("   [OK] Provider initialized")
    
    # Get embedding model
    print("\n2. Loading embedding model (nomic-embed-text-v2-moe)...")
    embed_model = provider.get_embed_model("nomic-embed-text-v2-moe")
    print("   [OK] Embedding model loaded")
    
    # Get generative model
    print("\n3. Loading generative model (qwen3:30b)...")
    llm = provider.get_generative_model("qwen3:30b")
    print("   [OK] Generative model loaded")
    
    # Test embedding
    print("\n4. Testing embeddings...")
    test_text = "Knowledge Assistant is a RAG chatbot using LlamaIndex"
    embedding = embed_model.get_text_embedding(test_text)
    print(f"   [OK] Generated embedding with {len(embedding)} dimensions")
    print(f"   First 5 values: {embedding[:5]}")
    
    # Test generation
    print("\n5. Testing text generation...")
    prompt = "Explain what Retrieval-Augmented Generation (RAG) is in one sentence."
    response = llm.complete(prompt)
    print(f"   Prompt: {prompt}")
    print(f"   Response: {response.text}")
    
    # Test streaming generation
    print("\n6. Testing streaming generation...")
    stream_prompt = "List 3 benefits of using local LLMs with Ollama:"
    print(f"   Prompt: {stream_prompt}")
    print("   Response (streaming): ", end="", flush=True)
    
    response_stream = llm.stream_complete(stream_prompt)
    full_response = ""
    for chunk in response_stream:
        try:
            print(chunk.delta, end="", flush=True)
            full_response += chunk.delta
        except UnicodeEncodeError:
            # Handle special characters that can't be displayed in Windows console
            print(chunk.delta.encode('ascii', 'replace').decode('ascii'), end="", flush=True)
            full_response += chunk.delta
    print()
    
    print("\n" + "=" * 60)
    print("Demo completed successfully!")
    print("=" * 60)
    
    print("\nNext Steps:")
    print("   - Use these models for RAG pipelines")
    print("   - Integrate with vector stores (OpenSearch, ChromaDB, etc.)")
    print("   - Build query engines and workflows")
    print("   - No AWS Bedrock required!")


if __name__ == "__main__":
    main()
