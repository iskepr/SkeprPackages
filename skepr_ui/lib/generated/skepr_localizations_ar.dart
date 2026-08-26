// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'skepr_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class SkeprLocalizationsAr extends SkeprLocalizations {
  SkeprLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get codeBySkepr => 'بَرْمَجَة مُحَمّد سِيّد';

  @override
  String hoursCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعة',
      many: '$count ساعة',
      few: '$count ساعات',
      two: 'ساعتين',
      one: 'ساعة',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String minutesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقيقة',
      many: '$count دقيقة',
      few: '$count دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get and => 'و';

  @override
  String get notSpecified => 'لم يحدد';

  @override
  String get nothing => 'لا يوجد';

  @override
  String get search => 'بحث';

  @override
  String get confirm => 'تأكيد';

  @override
  String get edit => 'تعديل';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get areYouSure => 'هل انت متاكد؟';

  @override
  String get done => 'تم';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get refresh => 'تحديث';
}
