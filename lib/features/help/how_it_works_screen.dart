import 'package:flutter/material.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jak to działa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              icon: Icons.app_registration,
              title: 'Rejestracja',
              steps: [
                'Wchodzisz na stronę i podajesz swój email.',
                'Otrzymujesz magic link na maila - klikasz i jesteś zalogowany.',
                'Nie musisz pamiętać hasła. Jeden klik i wchodzisz.',
                'Po zalogowaniu uzupełnij profil: imię, budynek, numer mieszkania.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              icon: Icons.local_parking,
              title: 'Dodawanie miejsca parkingowego',
              steps: [
                'Wejdź w "Moje miejsca" i kliknij "+" aby dodać swoje miejsce.',
                'Podaj numer miejsca (1-999). System zapisze go jako 3 cyfry (np. 1 → 001, 42 → 042).',
                'Podaj budynek i opcjonalnie poziom garażu.',
                'Twoje miejsce jest gotowe do udostępniania.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              icon: Icons.share,
              title: 'Udostępnianie miejsca',
              steps: [
                'Wejdź w "Moje miejsca" i kliknij menu (⋮) → "Udostępnij".',
                'Wybierz szybką opcję (2h, 4h, 6h, 8h, 12h) lub ustaw własny zakres dat i godzin.',
                'Po udostępnieniu wszyscy użytkownicy dostaną powiadomienie push: "Nowe wolne miejsce!"',
                'Możesz anulować udostępnienie w każdej chwili.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              icon: Icons.search,
              title: 'Szukanie wolnego miejsca',
              steps: [
                'Wejdź w "Szukaj miejsca" aby zobaczyć listę dostępnych miejsc.',
                'Możesz filtrować po budynku i zakresie dat.',
                'Każde miejsce pokazuje: budynek, poziom, godziny dostępności i właściciela.',
                'Kliknij "Zarezerwuj" aby wysłać prośbę.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              icon: Icons.shield_outlined,
              title: 'Prywatność numeru miejsca',
              color: Colors.amber[700]!,
              steps: [
                'Twój pełny numer miejsca jest chroniony.',
                'Przed rezerwacją inni widzą tylko pierwszą cyfrę i gwiazdki (np. 1** zamiast 142).',
                'Pełny numer zostaje ujawniony dopiero po zaakceptowaniu rezerwacji przez właściciela.',
                'Dzięki temu nikt nie zaparkuje na Twoim miejscu bez Twojej zgody.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              icon: Icons.calendar_today,
              title: 'Rezerwacje',
              steps: [
                'Wysyłasz prośbę o rezerwację - właściciel dostaje powiadomienie push.',
                'Właściciel akceptuje lub odrzuca Twoją prośbę.',
                'Po akceptacji widzisz pełny numer miejsca i możesz napisać na chacie.',
                'Po odrzuceniu szukaj innego wolnego miejsca.',
                'Zawsze możesz anulować swoją rezerwację.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              icon: Icons.chat_bubble_outline,
              title: 'Chat',
              steps: [
                'Po zaakceptowaniu rezerwacji otwiera się chat między Tobą a właścicielem.',
                'Ustalcie szczegóły: kiedy dokładnie przyjeżdżasz, jak długo zostaniesz.',
                'Chat działa w czasie rzeczywistym - wiadomości pojawiają się natychmiast.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              icon: Icons.notifications_active,
              title: 'Powiadomienia push',
              steps: [
                'Włącz powiadomienia na ekranie głównym (banner "Włącz powiadomienia").',
                'Dostajesz powiadomienie gdy: ktoś udostępni miejsce, ktoś chce zarezerwować Twoje miejsce, Twoja rezerwacja została zaakceptowana lub odrzucona.',
                'Powiadomienia działają nawet gdy przeglądarka jest zamknięta.',
                'Na telefonie: kliknij "Udostępnij" → "Dodaj do ekranu głównego" aby działało jak apka.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              icon: Icons.lightbulb_outline,
              title: 'Opinie i pomysły',
              steps: [
                'Wejdź w "Opinie i pomysły" na ekranie głównym.',
                'Zaproponuj nową funkcję lub zmianę.',
                'Inni mieszkańcy mogą głosować (👍) na Twoje pomysły.',
                'Pomysły z największą liczbą głosów będą wdrażane w pierwszej kolejności.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              icon: Icons.phone_android,
              title: 'Instalacja na telefonie',
              color: const Color(0xFF2563EB),
              steps: [
                'Android (Chrome): Menu (⋮) → "Dodaj do ekranu głównego" → "Zainstaluj".',
                'iPhone (Safari): Udostępnij (↑) → "Dodaj do ekranu głównego".',
                'Apka pojawi się na ekranie jak normalna aplikacja.',
                'Nie potrzebujesz App Store ani Google Play.',
              ],
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'ParkShareG181',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dziel się miejscem parkingowym z sąsiadami',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> steps,
    Color color = const Color(0xFF2563EB),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: Colors.grey[200]),
    );
  }
}
