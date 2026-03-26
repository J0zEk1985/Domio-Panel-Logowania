const modules = [
  {
    slug: 'serwis',
    name: 'Domio Serwis',
    description: 'Obsługa zgłoszeń, usterek i prac technicznych w jednym miejscu.',
  },
  {
    slug: 'cleaning',
    name: 'Domio Cleaning',
    description: 'Planowanie i kontrola usług porządkowych dla nieruchomości.',
  },
  {
    slug: 'fleet',
    name: 'Domio Fleet',
    description: 'Zarządzanie flotą, przebiegami i harmonogramami pojazdów.',
  },
]

export function BentoGrid() {
  return (
    <section id="ecosystem" className="py-24 px-4">
      <div className="container mx-auto max-w-6xl">
        <div className="text-center mb-16">
          <h2 className="font-display text-3xl md:text-5xl font-bold mb-4">
            Ekosystem <span className="gradient-brand-text">DOMIO</span>
          </h2>
          <p className="text-muted-foreground text-lg max-w-md mx-auto">Modularna platforma, którą dopasowujesz do swoich potrzeb.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {modules.map((mod) => (
            <article key={mod.slug} className="bento-card">
              <h3 className="font-display font-semibold text-lg mb-2">{mod.name}</h3>
              <p className="text-sm text-muted-foreground">{mod.description}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}
