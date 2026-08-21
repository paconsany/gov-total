import { render, screen } from '@testing-library/react'
import { App } from './App'

describe('App', () => {
  it('apresenta a fundação sem simular funcionalidades', () => {
    render(<App />)

    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('GOV TOTAL')
    expect(screen.getByRole('heading', { name: 'Escopo atual' })).toBeInTheDocument()
    expect(screen.getByText(/IA assistiva, sempre sob revisão humana/i)).toBeInTheDocument()
  })
})
