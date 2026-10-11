import { useLocalStorage } from '@vueuse/core'
import * as v from 'valibot'

import { IS_TAURI } from '@/constants'

/** Device state behind sharing, kept apart from preferences because people never edit it. */
export interface SharingState {
  /** Random ID made when the person agreed to usage stats, removed when they stop. */
  installId: string | null
  /** UTC day of the last delivered ping, so an install pings once a day. */
  lastPingDay: string | null
}

const SharingStateSchema = v.object({
  installId: v.fallback(v.nullable(v.pipe(v.string(), v.regex(/^[0-9a-f]{32}$/))), null),
  lastPingDay: v.fallback(v.nullable(v.pipe(v.string(), v.isoDate())), null)
})

export const sharingState = useLocalStorage<SharingState>(
  'open-pencil:sharing:v1',
  { installId: null, lastPingDay: null },
  {
    mergeDefaults: (stored) =>
      v.parse(
        v.fallback(SharingStateSchema, () => v.parse(SharingStateSchema, {})),
        stored
      )
  }
)

let disabledByEnvironment: Promise<boolean> | null = null

/** `OPENPENCIL_TELEMETRY=0` or `DO_NOT_TRACK` in the desktop app's environment turns sharing off. */
export function sharingDisabledByEnvironment(): Promise<boolean> {
  disabledByEnvironment ??= IS_TAURI
    ? import('@tauri-apps/api/core').then(({ invoke }) =>
        invoke<boolean>('sharing_disabled_by_env').catch(() => false)
      )
    : Promise.resolve(false)
  return disabledByEnvironment
}
