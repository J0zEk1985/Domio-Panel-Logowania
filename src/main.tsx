import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App.tsx'
import { CookieConsentRoot } from './components/cookie-consent/CookieConsentRoot'
import './index.css'
import '@fontsource-variable/inter/index.css'
import '@fontsource-variable/space-grotesk/index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <CookieConsentRoot appSource="hub" policyUrl="/polityka-cookies" />
      <App />
    </BrowserRouter>
  </StrictMode>,
)
