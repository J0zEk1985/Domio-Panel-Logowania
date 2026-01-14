
import { Link } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';

const TermsPage = () => {
  return (
    <div className="min-h-screen bg-[#1a1f2c] text-white p-8">
      <div className="max-w-3xl mx-auto">
        <Link to="/signup" className="flex items-center text-gray-400 hover:text-white mb-8 transition-colors">
          <ArrowLeft className="w-4 h-4 mr-2" /> Powrót do rejestracji
        </Link>
        
        <h1 className="text-3xl font-bold mb-6">Regulamin świadczenia usług drogą elektroniczną</h1>
        <p className="text-gray-400 mb-8">Ostatnia aktualizacja: 13.01.2026 (Wersja 1.0)</p>

        <section className="space-y-6 text-gray-300">
          <div>
            <h2 className="text-xl font-semibold text-white mb-2">1. Postanowienia ogólne</h2>
            <p>Właścicielem serwisu DOMIO jest spółka DOMIO Sp. z o.o. z siedzibą w Polsce. Serwis działa w modelu SaaS (Software as a Service) i służy do zarządzania organizacjami, personelem oraz lokalizacjami.</p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-2">2. Rodzaje i zakres usług</h2>
            <p>DOMIO świadczy usługi w zakresie udostępniania platformy Hub do autentykacji, zarządzania subskrypcjami aplikacji dedykowanych (np. sprzątanie, technika) oraz prowadzenia centralnego rejestru lokalizacji.</p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-2">3. Rejestracja i Bezpieczeństwo</h2>
            <p>Użytkownik zobowiązany jest do podania prawdziwych danych podczas rejestracji. System odnotowuje adres IP oraz wersję zaakceptowanego regulaminu w celu audytu bezpieczeństwa.</p>
            <p className="mt-2 font-semibold">Izolacja danych:</p>
            <p>Każda organizacja posiada osobną strukturę danych, co gwarantuje poufność informacji między różnymi subskrybentami serwisu.</p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-2">4. Odpowiedzialność</h2>
            <p>DOMIO Sp. z o.o. dokłada wszelkich starań w celu zapewnienia ciągłości działania serwisu i monitorowania zasobów. Firma nie odpowiada za treść danych wprowadzanych przez użytkowników końcowych.</p>
          </div>
        </section>
      </div>
    </div>
  );
};

export default TermsPage;