import { cors } from 'hono/cors'

/**
 * Pages allowed to call the service: the web app, the website's waitlist form, and the desktop
 * app's webview on macOS and Linux (`tauri://localhost`) and on Windows (`http://tauri.localhost`).
 */
export const ALLOWED_ORIGINS = [
  'https://app.openpencil.dev',
  'https://openpencil.dev',
  'tauri://localhost',
  'http://tauri.localhost'
]

export const allowOpenPencilOrigins = cors({
  origin: ALLOWED_ORIGINS,
  allowMethods: ['POST'],
  allowHeaders: ['Content-Type'],
  maxAge: 86400
})
