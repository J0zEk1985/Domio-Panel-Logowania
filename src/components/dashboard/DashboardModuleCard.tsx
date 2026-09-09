import type { LucideIcon } from 'lucide-react'
import type { ModuleData } from '../../data/modules'

type Props = {
  catalog: ModuleData | undefined
  Icon: LucideIcon
  title: string
  description: string
  badgeLabel: string
  badgeClass: string
  planSummary: string | null
  onOpen: () => void
  onManagePlan?: () => void
}

export function DashboardModuleCard({
  catalog,
  Icon,
  title,
  description,
  badgeLabel,
  badgeClass,
  planSummary,
  onOpen,
  onManagePlan,
}: Props) {
  return (
    <div className="bento-card text-left">
      <div className="flex items-start justify-between mb-3">
        <div className={`p-2.5 rounded-xl bg-muted ${catalog?.color ?? 'text-primary'}`}>
          <Icon className="h-5 w-5" aria-hidden />
        </div>
        <span className={`inline-flex items-center rounded-md border px-2 py-0.5 text-xs font-medium ${badgeClass}`}>
          {badgeLabel}
        </span>
      </div>
      <h3 className="font-display font-semibold mb-1">{title}</h3>
      <p className="text-sm text-muted-foreground">{description}</p>
      {planSummary && <p className="mt-3 text-sm font-medium text-foreground">{planSummary}</p>}
      <div className="mt-4 flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={onOpen}
          className="inline-flex text-sm font-medium text-primary hover:underline"
        >
          Otwórz →
        </button>
        {onManagePlan && (
          <button
            type="button"
            onClick={onManagePlan}
            className="inline-flex text-sm font-medium text-muted-foreground hover:text-foreground"
          >
            Plan i rozliczenia
          </button>
        )}
      </div>
    </div>
  )
}
