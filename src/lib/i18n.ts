import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'

const resources = {
  pl: {
    translation: {
      translate: 'Przetłumacz',
      autoTranslation: 'Tłumaczenie automatyczne',
      translating: 'Tłumaczenie...',
      translationError: 'Błąd tłumaczenia',
    },
  },
  ua: {
    translation: {
      translate: 'Перекласти',
      autoTranslation: 'Автоматичний переклад',
      translating: 'Переклад...',
      translationError: 'Помилка перекладу',
    },
  },
}

i18n.use(initReactI18next).init({
  resources,
  lng: 'pl', // default language
  fallbackLng: 'pl',
  interpolation: {
    escapeValue: false,
  },
})

export default i18n
