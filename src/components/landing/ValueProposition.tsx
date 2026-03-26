export function ValueProposition() {
  return (
    <section className="py-24 px-4">
      <div className="container mx-auto max-w-5xl">
        <div className="grid md:grid-cols-2 gap-6">
          <article id="residents" className="bento-card relative overflow-hidden group">
            <div className="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full blur-2xl group-hover:bg-primary/10 transition-colors" />
            <div className="relative">
              <h3 className="font-display text-2xl font-bold mb-3">Dla Mieszkańców</h3>
              <p className="text-muted-foreground mb-6">
                Zarządzaj swoim mieszkaniem, zgłaszaj usterki, rezerwuj usługi - wszystko w jednej aplikacji. Prostota, która oszczędza Twój czas.
              </p>
            </div>
          </article>

          <article id="business" className="bento-card relative overflow-hidden group">
            <div className="absolute top-0 right-0 w-32 h-32 bg-accent/5 rounded-full blur-2xl group-hover:bg-accent/10 transition-colors" />
            <div className="relative">
              <h3 className="font-display text-2xl font-bold mb-3">Dla Firm</h3>
              <p className="text-muted-foreground mb-6">
                Skaluj swoje usługi, zarządzaj zespołami i klientami. Gotowe moduły biznesowe, które rosną razem z Tobą.
              </p>
            </div>
          </article>
        </div>
      </div>
    </section>
  )
}
