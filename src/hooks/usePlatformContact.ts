import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import {
  EMPTY_PLATFORM_CONTACT,
  PLATFORM_CONTACT_KEYS,
  parsePlatformContact,
  type PlatformContact,
} from '../lib/platformContact'

const CONTACT_KEYS = Object.values(PLATFORM_CONTACT_KEYS)

export function usePlatformContact(): { contact: PlatformContact; loading: boolean } {
  const [contact, setContact] = useState<PlatformContact>(EMPTY_PLATFORM_CONTACT)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false

    const load = async () => {
      try {
        const { data, error } = await supabase
          .from('page_content')
          .select('content_key, content_value')
          .in('content_key', CONTACT_KEYS)

        if (cancelled) return

        if (error) {
          console.error('[usePlatformContact] page_content:', error)
          setContact(EMPTY_PLATFORM_CONTACT)
          return
        }

        const map = (data ?? []).reduce<Record<string, string>>((acc, row) => {
          acc[row.content_key] = row.content_value ?? ''
          return acc
        }, {})
        setContact(parsePlatformContact(map))
      } catch (e) {
        console.error('[usePlatformContact] load:', e)
        if (!cancelled) setContact(EMPTY_PLATFORM_CONTACT)
      } finally {
        if (!cancelled) setLoading(false)
      }
    }

    void load()
    return () => {
      cancelled = true
    }
  }, [])

  return { contact, loading }
}
