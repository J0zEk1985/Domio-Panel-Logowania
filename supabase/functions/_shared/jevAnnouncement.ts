/** Decision mapping for resident announcements. Jev does not write user-facing text. */

export const NOUL_YES = 0.75
export const NOUL_NO = 0.35
export const CHOICE_MIN_CONFIDENCE = 0.55

export const REJECTION_REASONS = ['NONE', 'SPAM', 'PROFANITY', 'PERSONAL_ATTACK', 'OFF_TOPIC'] as const
export const SUGGESTED_CATEGORIES = [
  'SPRZEDAM_ODDAM',
  'USLUGI',
  'PYTANIE_DO_SASIADOW',
  'KOMUNIKAT',
] as const

export type RejectionReason = (typeof REJECTION_REASONS)[number]
export type SuggestedCategory = (typeof SUGGESTED_CATEGORIES)[number]
export type HoldReason = 'uncertain' | 'jev_unavailable'
export type AnnouncementOutcome = 'blocked' | 'ready' | 'held'
export type SuggestedPostType = 'offer' | 'request' | 'general'

export type AnnouncementDecision = {
  is_safe: boolean
  rejection_reason: RejectionReason
  suggested_category: SuggestedCategory
  suggested_post_type: SuggestedPostType
  is_vague: boolean
  outcome: AnnouncementOutcome
  hold: HoldReason | null
  category_confidence: number
}

const CATEGORY_TO_POST: Record<SuggestedCategory, SuggestedPostType> = {
  SPRZEDAM_ODDAM: 'offer',
  USLUGI: 'offer',
  PYTANIE_DO_SASIADOW: 'request',
  KOMUNIKAT: 'general',
}

export function buildAnnouncementBody(title: string, content: string) {
  return {
    model: 'jev-latest',
    state: { title, content },
    questions: {
      is_safe: {
        type: 'noul',
        instructions:
          'Is this neighbor-board post safe to publish: not spam, not profanity, not a personal attack, and about estate life?',
        criteria: {
          true: 'Ordinary neighbor post a manager could leave on the board',
          false: 'Spam, profanity, personal attack, or clearly off-topic',
        },
      },
      rejection_reason: {
        type: 'choice',
        instructions: 'If the post should be blocked, why? Choose NONE when it is acceptable.',
        criteria: {
          NONE: 'Acceptable for the neighbor board',
          SPAM: 'Advertising spam or repetitive solicitation',
          PROFANITY: 'Profanity or obscene content',
          PERSONAL_ATTACK: 'Insult or attack aimed at a person',
          OFF_TOPIC: 'Not about estate or neighbor life',
        },
      },
      suggested_category: {
        type: 'choice',
        instructions: 'Which neighbor-board category fits the post?',
        criteria: {
          SPRZEDAM_ODDAM: 'Selling or giving away an item',
          USLUGI: 'Offering or seeking a service',
          PYTANIE_DO_SASIADOW: 'Question to neighbors',
          KOMUNIKAT: 'A short notice or announcement',
        },
      },
      is_vague: {
        type: 'noul',
        instructions: 'Is the post too short or missing details neighbors would need in order to respond?',
      },
    },
  }
}

type Answers = Record<string, { type?: string; noul?: number; choice?: string; confidence?: number }>

function noulValue(answers: Answers, key: string): number | null {
  const row = answers[key]
  if (!row || row.type !== 'noul' || typeof row.noul !== 'number' || Number.isNaN(row.noul)) return null
  return row.noul
}

function choiceValue<T extends string>(answers: Answers, key: string, allowed: readonly T[]): { value: T; confidence: number } | null {
  const row = answers[key]
  if (!row || row.type !== 'choice' || typeof row.choice !== 'string') return null
  if (!allowed.includes(row.choice as T)) return null
  const confidence = typeof row.confidence === 'number' && !Number.isNaN(row.confidence) ? row.confidence : 0
  return { value: row.choice as T, confidence }
}

export function heldDecision(hold: HoldReason): AnnouncementDecision {
  return {
    is_safe: false,
    rejection_reason: 'NONE',
    suggested_category: 'KOMUNIKAT',
    suggested_post_type: 'general',
    is_vague: false,
    outcome: 'held',
    hold,
    category_confidence: 0,
  }
}

export function mapAnnouncementResponse(payload: unknown): AnnouncementDecision {
  const answers = (payload as { answers?: Answers } | null)?.answers
  if (!answers || typeof answers !== 'object') return heldDecision('jev_unavailable')

  const safeP = noulValue(answers, 'is_safe')
  const vagueP = noulValue(answers, 'is_vague')
  const reason = choiceValue(answers, 'rejection_reason', REJECTION_REASONS)
  const category = choiceValue(answers, 'suggested_category', SUGGESTED_CATEGORIES)
  if (safeP === null || vagueP === null || !reason || !category) return heldDecision('jev_unavailable')

  const suggested = category.confidence >= CHOICE_MIN_CONFIDENCE ? category.value : 'KOMUNIKAT'
  const base = {
    suggested_category: suggested,
    suggested_post_type: CATEGORY_TO_POST[suggested],
    category_confidence: category.confidence,
    is_vague: false,
    hold: null as HoldReason | null,
  }

  if (safeP >= NOUL_YES) {
    return {
      ...base,
      is_safe: true,
      rejection_reason: 'NONE',
      is_vague: vagueP >= NOUL_YES,
      outcome: 'ready',
    }
  }

  if (safeP < NOUL_NO) {
    const rejection = reason.value !== 'NONE' ? reason.value : 'PROFANITY'
    return {
      ...base,
      is_safe: false,
      rejection_reason: rejection,
      outcome: 'blocked',
    }
  }

  return {
    ...base,
    is_safe: false,
    rejection_reason: 'NONE',
    outcome: 'held',
    hold: 'uncertain',
  }
}
