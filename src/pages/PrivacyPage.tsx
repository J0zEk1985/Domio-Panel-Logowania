import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';

const PrivacyPage = () => {
  return (
    <div className="min-h-screen bg-[#1a1f2c] text-white p-8">
      <div className="max-w-3xl mx-auto">
        <Link to="/signup" className="flex items-center text-gray-400 hover:text-white mb-8 transition-colors">
          <ArrowLeft className="w-4 h-4 mr-2" /> Powrót do rejestracji
        </Link>
        
        <h1 className="text-3xl font-bold mb-6">Polityka Prywatności i RODO</h1>
        <p className="text-gray-400 mb-8">Obowiązuje od: 13.01.2026</p>

        <section className="space-y-6 text-gray-300">
          <div>
            <h2 className="text-xl font-semibold text-white mb-2">1. Administrator Danych</h2>
            <p>Administratorem danych osobowych jest DOMIO Sp. z o.o. Kontakt w sprawach ochrony danych możliwy jest drogą elektroniczną.</p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-2">2. Zakres zbieranych danych</h2>
            <ul className="list-disc ml-6 space-y-2">
              <li>Adres e-mail (do logowania i komunikacji).</li>
              <li>Adres IP (zbierany podczas rejestracji dla celów audytu i bezpieczeństwa).</li>
              <li>Dane personelu: Imię, nazwisko, numer telefonu (wprowadzane ręcznie przez Administratorów Firm).</li>
              <li>Dane lokalizacji (w tym współrzędne geograficzne pobierane przez Google Places API).</li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-2">3. Cel przetwarzania</h2>
            <p>Dane są przetwarzane w celu świadczenia usługi SaaS, zapewnienia bezpieczeństwa (logi systemowe) oraz, za opcjonalną zgodą, w celach marketingowych.</p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-2">4. Prawa Użytkownika</h2>
            <p>Każdy użytkownik ma prawo do wglądu w swoje dane, ich poprawiania, usunięcia ("prawo do bycia zapomnianym") oraz wycofania zgód marketingowych w dowolnym momencie.</p>
          </div>
        </section>
      </div>
    </div>
  );
};

export default PrivacyPage;