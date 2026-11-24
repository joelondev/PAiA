import { describe, it, expect } from 'vitest'
import { isPaiaUrl, toPaiaUrl } from '../paia'

describe('PAiA single update source', () => {
  it('passes PAiA URLs through unchanged', () => {
    const url = 'https://updates.paia.example/catalog/models.json'
    expect(isPaiaUrl(url)).toBe(true)
    expect(toPaiaUrl(url)).toBe(url)
  })

  it('rewrites Hugging Face URLs to the PAiA mirror', () => {
    expect(
      toPaiaUrl('https://huggingface.co/api/models/org/repo?blobs=true')
    ).toBe('https://updates.paia.example/models/huggingface.co/api/models/org/repo?blobs=true')
  })

  it('blocks every other host', () => {
    for (const url of [
      'https://api.github.com/repos/janhq/jan/releases',
      'https://raw.githubusercontent.com/janhq/model-catalog/main/x.json',
      'https://apps.jan.ai/update-check',
      'https://huggingface.co.evil.com/x',
      'http://updates.paia.example/x',
    ]) {
      expect(() => toPaiaUrl(url)).toThrow(/Blocked/)
    }
  })
})
