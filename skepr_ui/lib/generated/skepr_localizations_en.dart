// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'skepr_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SkeprLocalizationsEn extends SkeprLocalizations {
  SkeprLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get codeBySkepr => 'Code By Skepr';

  @override
  String hoursCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String minutesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get and => 'and';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get nothing => 'Nothing';

  @override
  String get search => 'Search';

  @override
  String get confirm => 'Confirm';

  @override
  String get edit => 'Edit';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get done => 'Done';

  @override
  String get sortBy => 'Sort By';

  @override
  String get refresh => 'Refresh';
}
