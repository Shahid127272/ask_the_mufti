import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../core/categories_data.dart';
import '../../providers/font_provider.dart';
import '../feeds/feeds_screen.dart';

class SubCategoriesScreen extends StatelessWidget {
  final String category;
  final String title;

  const SubCategoriesScreen({
    super.key,
    required this.category,
    required this.title,
  });

  // =========================================================
  // 📚 SUB-CATEGORY ICONS
  // =========================================================

  static const Map<String, IconData> subCategoryIcons = {
    // =======================================================
    // ☪️ AQAAID
    // =======================================================

    'Tauheed': Icons.star_rounded,
    'Risalat': Icons.mosque_rounded,
    'Farishtay': Icons.air_rounded,
    'Aasmaani Kitaabein': Icons.menu_book_rounded,
    'Aakhirat': Icons.nightlight_round,
    'Taqdeer': Icons.timeline_rounded,
    'Sahaba-e-Kiraam': Icons.groups_rounded,
    'Ahl-e-Bait': Icons.family_restroom_rounded,
    'Ahle Sunnat ke Aqaaid': Icons.verified_rounded,
    'Kufr-o-Shirk ke Masaail':
    Icons.warning_amber_rounded,

    // =======================================================
    // 🕌 IBAADAAT
    // =======================================================

    'Namaz': Icons.accessibility_new_rounded,
    'Roza': Icons.nightlight_rounded,
    'Zakaat': Icons.volunteer_activism_rounded,
    'Hajj': Icons.location_on_rounded,
    'Umrah': Icons.mosque_rounded,
    'Qurbani': Icons.pets_rounded,
    'Itikaaf': Icons.self_improvement_rounded,
    'Taraweeh': Icons.nights_stay_rounded,
    'Nafl Ibaadaat': Icons.favorite_rounded,
    'Dua aur Wazaaif': Icons.auto_awesome_rounded,

    // =======================================================
    // 💍 MUNAKAHAAT
    // =======================================================

    'Nikah': Icons.favorite_rounded,
    'Mahr': Icons.card_giftcard_rounded,
    'Walima': Icons.restaurant_rounded,
    'Talaaq': Icons.link_off_rounded,
    'Khula': Icons.handshake_rounded,
    'Faskh-e-Nikah': Icons.gavel_rounded,
    'Rujoo': Icons.undo_rounded,
    'Iddat': Icons.calendar_month_rounded,
    'Zihar': Icons.warning_amber_rounded,
    'Miyaan-Biwi ke Huqooq':
    Icons.family_restroom_rounded,

    // =======================================================
    // 🤝 MUAMALAAT
    // =======================================================

    'Qarza': Icons.account_balance_wallet_rounded,
    'Amanat': Icons.lock_rounded,
    'Karobari Muamalaat':
    Icons.business_center_rounded,
    'Khareed-o-Farokht':
    Icons.shopping_cart_rounded,
    'Kiraya': Icons.home_work_rounded,
    'Partnership': Icons.handshake_rounded,
    'Udhaar': Icons.receipt_long_rounded,
    'Soodee Muamalaat': Icons.money_off_rounded,
    'Jhoot aur Dhoka':
    Icons.visibility_off_rounded,
    'Huqooq-ul-Ibaad':
    Icons.people_alt_rounded,

    // =======================================================
    // 🧎 IMAMAT
    // =======================================================

    'Imamat ke Sharaait': Icons.rule_rounded,
    'Imam ke Masaail': Icons.person_rounded,
    'Muqtadi ke Masaail': Icons.groups_rounded,
    'Iqtida': Icons.follow_the_signs_rounded,
    'Jamaat': Icons.groups_rounded,
    'Jummah': Icons.calendar_today_rounded,
    'Eidain': Icons.celebration_rounded,
    'Taraweeh ki Imamat':
    Icons.nights_stay_rounded,
    'Masbooq ke Masaail':
    Icons.directions_run_rounded,
    'Sajda-e-Sahw':
    Icons.accessibility_new_rounded,

    // =======================================================
    // 💧 TAHAARAAT
    // =======================================================

    'Wuzu': Icons.water_drop_rounded,
    'Ghusl': Icons.shower_rounded,
    'Tayammum': Icons.landscape_rounded,
    'Istinja': Icons.water_drop_outlined,
    'Najasat': Icons.dirty_lens_rounded,
    'Paak aur Napaak Kapde':
    Icons.checkroom_rounded,
    'Haiz': Icons.calendar_month_rounded,
    'Nifaas': Icons.child_friendly_rounded,
    'Istihaza': Icons.water_drop_rounded,
    'Tahaarat ke Dusre Masaail':
    Icons.clean_hands_rounded,

    // =======================================================
    // 📖 QUR'AN-O-TAFSEER
    // =======================================================

    "Tilawat-e-Qur'an": Icons.menu_book_rounded,
    'Tajweed': Icons.record_voice_over_rounded,
    "Qur'an Padhne ke Masaail":
    Icons.auto_stories_rounded,
    'Tafseer': Icons.search_rounded,
    "Tarjuma-e-Qur'an": Icons.translate_rounded,
    'Sajda-e-Tilawat':
    Icons.accessibility_new_rounded,
    "Hifz-e-Qur'an": Icons.psychology_rounded,
    "Qur'an ki Fazaa'il":
    Icons.auto_awesome_rounded,
    "Qur'an se Mutalliq Ahkaam":
    Icons.rule_rounded,
    "Qur'an ki Qasam":
    Icons.menu_book_rounded,

    // =======================================================
    // ﷺ HADEES-O-SEERAT
    // =======================================================

    'Hadees ke Masaail':
    Icons.menu_book_rounded,
    'Hadees ki Tashreeh':
    Icons.chrome_reader_mode_rounded,
    'Seerat-un-Nabi ﷺ':
    Icons.mosque_rounded,
    'Shamaail-e-Mustafa ﷺ':
    Icons.star_rounded,
    'Ghazwaat': Icons.shield_rounded,
    'Meraj': Icons.flight_rounded,
    "Shafa'at":
    Icons.volunteer_activism_rounded,
    'Nabi ﷺ ke Huqooq':
    Icons.favorite_rounded,
    'Sahaba ki Seerat':
    Icons.groups_rounded,
    'Islami Tareekh':
    Icons.history_edu_rounded,

    // =======================================================
    // ❤️ AKHLAAQ-O-AADAAB
    // =======================================================

    'Walidain ke Huqooq':
    Icons.elderly_rounded,
    'Rishtedaron ke Huqooq':
    Icons.family_restroom_rounded,
    'Padosiyon ke Huqooq':
    Icons.people_alt_rounded,
    'Sach aur Jhoot':
    Icons.balance_rounded,
    'Gheebat':
    Icons.chat_bubble_outline_rounded,
    'Chughli':
    Icons.record_voice_over_rounded,
    'Hasad':
    Icons.visibility_rounded,
    'Takabbur':
    Icons.trending_up_rounded,
    'Husn-e-Akhlaq':
    Icons.favorite_rounded,
    'Salam aur Muashrati Adaab':
    Icons.waving_hand_rounded,

    // =======================================================
    // ⚖️ WIRASAT-O-WASIYYAT
    // =======================================================

    'Wirasat':
    Icons.account_balance_rounded,
    'Wariseen ke Huqooq':
    Icons.groups_rounded,
    'Hissa-e-Wirasat':
    Icons.pie_chart_rounded,
    'Wasiyyat':
    Icons.edit_note_rounded,
    'Hiba':
    Icons.card_giftcard_rounded,
    'Waqf':
    Icons.mosque_rounded,
    'Taraka':
    Icons.inventory_2_rounded,
    'Wirasat ki Taqseem':
    Icons.call_split_rounded,
    'Maal-e-Mutawaffa':
    Icons.account_balance_wallet_rounded,
    'Wirasat ke Dusre Masaail':
    Icons.balance_rounded,

    // =======================================================
    // 🕊️ JANAIZ-O-MASAIL
    // =======================================================

    'Marne ke Waqt ke Masaail':
    Icons.hourglass_bottom_rounded,
    'Ghusl-e-Mayyit':
    Icons.water_drop_rounded,
    'Kafan':
    Icons.layers_rounded,
    'Namaz-e-Janaza':
    Icons.mosque_rounded,
    'Dafn':
    Icons.landscape_rounded,
    "Ta'ziyat":
    Icons.volunteer_activism_rounded,
    'Qabristan ke Adaab':
    Icons.local_florist_rounded,
    'Qabar ke Masaail':
    Icons.account_balance_rounded,
    'Isaal-e-Sawab':
    Icons.auto_awesome_rounded,
    'Fateha aur Dua':
    Icons.front_hand_rounded,
  };

  // =========================================================
  // 🔹 GET SUB-CATEGORY ICON
  // =========================================================

  static IconData getSubCategoryIcon(
      String subCategory,
      ) {
    return subCategoryIcons[subCategory] ??
        Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // =========================================================
    // 📚 SUB-CATEGORIES
    // =========================================================

    final list = kCategories[category] ?? [];

    return AppScaffold(
      notificationCount: 0,
      body: Container(
        color: colorScheme.surface,
        child: list.isEmpty
            ? Center(
          child: Text(
            'No subcategories found',
            style: theme.textTheme.bodyMedium,
          ),
        )
            : GridView.builder(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          itemCount: list.length,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final sub = list[index];

            final icon =
            getSubCategoryIcon(sub);

            return _SubCategoryCard(
              title: sub,
              icon: icon,
              onTap: () {
                // =========================================
                // 📖 QUESTIONS OPEN KARO
                // =========================================

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FeedsScreen(
                          category: category,
                          subCategory: sub,
                        ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// =============================================================
// 🟢 SUB-CATEGORY CARD
// =============================================================

class _SubCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SubCategoryCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final fonts = context.watch<FontProvider>();

    final uiFontFamily =
    fonts.resolveFontFamily(
      fonts.uiFont,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color:
            colorScheme.surfaceContainerHighest,
            borderRadius:
            BorderRadius.circular(18),
            boxShadow:
            theme.brightness ==
                Brightness.dark
                ? null
                : [
              BoxShadow(
                color: colorScheme.shadow
                    .withValues(
                  alpha: 0.06,
                ),
                blurRadius: 8,
                offset:
                const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              // ===============================================
              // 🔹 SUB-CATEGORY ICON
              // ===============================================

              Icon(
                icon,
                size: 52,
                color: colorScheme.primary,
              ),

              const SizedBox(height: 18),

              // ===============================================
              // 🔹 SUB-CATEGORY TITLE
              // ===============================================

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow:
                  TextOverflow.ellipsis,
                  style: textTheme.titleMedium
                      ?.copyWith(
                    fontFamily:
                    uiFontFamily,
                    fontSize:
                    fonts.fontSize,
                    fontWeight:
                    fonts.fontWeight,
                    fontStyle: fonts.isItalic
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color:
                    colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}