/** Comment moderation. Same confidence bands as announcement checks in jevAnnouncement.ts. */

export const NOUL_YES = 0.75
export const NOUL_NO = 0.35
export const CHOICE_MIN_CONFIDENCE = 0.55

export const COMMENT_REJECTION_REASONS = ['NONE', 'PROFANITY', 'PERSONAL_ATTACK'] as const

export type CommentRejectionReason = (typeof COMMENT_REJECTION_REASONS)[number]
export type CommentOutcome = 'blocked' | 'ready' | 'unavailable'

export type CommentDecision = {
  is_safe: boolean
  rejection_reason: CommentRejectionReason
  outcome: CommentOutcome
}

/**
 * Unambiguous profanity stems. Personal insults without these words are left to the classifier.
 * Match is equality, prefix, or (for stems of 4+ letters, plus "jeb") a substring.
 * "huj" is prefix-only so "thuja" is not flagged.
 */
const STEMS = [
  'kurw',
  'chuj',
  'huj',
  'jeb',
  'pierdol',
  'pierdal',
  'pierdz',
  'pizd',
  'cipa',
  'cipk',
  'kutas',
  'fiut',
  'cwel',
  'dziwk',
  'sukinsyn',
  'gowno',
  'gowna',
  'gownie',
  'gownem',
  'gowien',
  'zjeb',
  'pojeb',
  'wjeb',
  'najeb',
  'ujeb',
  'dojeb',
  'rozjeb',
  'zajeb',
  'wyjeb',
  'odjeb',
  'podjeb',
  'przyjeb',
  'przejeb',
  'fuck',
  'shit',
  'bitch',
  'asshole',
  'cunt',
  'motherfuck',
  'nigger',
  'nigga',
  'faggot',
  'whore',
  'slut',
] as const

/** Whole tokens only — prefixes would hit innocent words (suki → sukienka). */
const EXACT_TOKENS = new Set(['suka', 'suki', 'suko', 'suke', 'sucz'])

type Answers = Record<string, { type?: string; noul?: number; choice?: string; confidence?: number }>

function noulValue(answers: Answers, key: string): number | null {
  const row = answers[key]
  if (!row || row.type !== 'noul' || typeof row.noul !== 'number' || Number.isNaN(row.noul)) return null
  return row.noul
}

function choiceValue<T extends string>(
  answers: Answers,
  key: string,
  allowed: readonly T[],
): { value: T; confidence: number } | null {
  const row = answers[key]
  if (!row || row.type !== 'choice' || typeof row.choice !== 'string') return null
  if (!allowed.includes(row.choice as T)) return null
  const confidence = typeof row.confidence === 'number' && !Number.isNaN(row.confidence) ? row.confidence : 0
  return { value: row.choice as T, confidence }
}

function foldLetters(text: string): string {
  return text
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .replace(/ł/g, 'l')
    .replace(/Ł/g, 'l')
    .toLowerCase()
    .replace(/0/g, 'o')
    .replace(/1|!/g, 'i')
    .replace(/3/g, 'e')
    .replace(/4|@/g, 'a')
    .replace(/5|\$/g, 's')
    .replace(/7/g, 't')
}

function squeeze(token: string): string {
  return token.replace(/(.)\1+/g, '$1')
}

function stemHits(token: string, stem: string): boolean {
  if (token === stem || token.startsWith(stem)) return true
  if (stem.length >= 4 || stem === 'jeb') return token.includes(stem)
  return false
}

export function containsProfanity(text: string): boolean {
  const folded = foldLetters(text)
  const rawTokens = folded.split(/[^a-z]+/).filter(Boolean).map(squeeze)
  const candidates = new Set<string>(rawTokens)

  let letters = ''
  for (const token of rawTokens) {
    if (token.length === 1) {
      letters += token
      continue
    }
    if (letters.length >= 4) candidates.add(letters)
    letters = ''
  }
  if (letters.length >= 4) candidates.add(letters)

  for (let i = 0; i < rawTokens.length - 1; i += 1) {
    const left = rawTokens[i]
    const right = rawTokens[i + 1]
    if (left.length <= 3 && right.length <= 3) candidates.add(left + right)
  }

  for (const token of candidates) {
    if (EXACT_TOKENS.has(token)) return true
    if (STEMS.some((stem) => stemHits(token, stem))) return true
  }
  return false
}

export function blockedComment(reason: Exclude<CommentRejectionReason, 'NONE'>): CommentDecision {
  return { is_safe: false, rejection_reason: reason, outcome: 'blocked' }
}

export function readyComment(): CommentDecision {
  return { is_safe: true, rejection_reason: 'NONE', outcome: 'ready' }
}

export function unavailableComment(): CommentDecision {
  return { is_safe: false, rejection_reason: 'NONE', outcome: 'unavailable' }
}

export function buildCommentBody(content: string) {
  return {
    model: 'jev-latest',
    state: { content },
    questions: {
      is_safe: {
        type: 'noul',
        instructions:
          'Is this neighbor-board comment safe to publish: no profanity, no obscenity, no slurs, and no insult aimed at a person? Disagreement and criticism of a situation are safe. Short replies such as thanks or agreement are safe.',
        criteria: {
          true: 'Ordinary neighbor comment without profanity or a personal insult',
          false: 'Profanity, obscenity, a slur, or an insult aimed at a person',
        },
      },
      rejection_reason: {
        type: 'choice',
        instructions: 'If the comment should be blocked, why? Choose NONE when it is acceptable.',
        criteria: {
          NONE: 'Acceptable neighbor comment',
          PROFANITY: 'Profanity, obscenity, or a slur',
          PERSONAL_ATTACK: 'Insult or attack aimed at a person',
        },
      },
    },
  }
}

export function mapCommentResponse(payload: unknown): CommentDecision {
  const answers = (payload as { answers?: Answers } | null)?.answers
  if (!answers || typeof answers !== 'object') return unavailableComment()

  const safeP = noulValue(answers, 'is_safe')
  const reason = choiceValue(answers, 'rejection_reason', COMMENT_REJECTION_REASONS)
  if (safeP === null || !reason) return unavailableComment()

  if (safeP >= NOUL_YES) return readyComment()

  const flagged = reason.value === 'PROFANITY' || reason.value === 'PERSONAL_ATTACK'
  if (safeP < NOUL_NO) return blockedComment(flagged ? reason.value : 'PROFANITY')
  if (flagged && reason.confidence >= CHOICE_MIN_CONFIDENCE) return blockedComment(reason.value)
  return readyComment()
}

export function decideComment(content: string, classifierPayload: unknown | null): CommentDecision {
  if (containsProfanity(content)) return blockedComment('PROFANITY')
  if (classifierPayload === null) return unavailableComment()
  return mapCommentResponse(classifierPayload)
}
