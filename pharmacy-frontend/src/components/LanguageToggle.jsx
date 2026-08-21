import { useLanguage } from '../i18n/LanguageContext.jsx'

export default function LanguageToggle({ variant = 'light' }) {
  const { lang, setLang } = useLanguage()

  return (
    <div className={`lang-toggle lang-toggle-${variant}`}>
      <button
        className={lang === 'en' ? 'active' : ''}
        onClick={() => setLang('en')}
        type="button"
      >
        English
      </button>
      <button
        className={lang === 'ur' ? 'active' : ''}
        onClick={() => setLang('ur')}
        type="button"
      >
        اردو
      </button>
    </div>
  )
}
