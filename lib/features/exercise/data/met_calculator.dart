class MetCalculator {
  static double metFor({required String category, String type = '', String intensity = ''}) {
    if (category == 'Cardio') {
      if (type.contains('Caminhada')) return 3.8;
      if (type.contains('Corrida')) return 8.0;
      if (type.contains('Ciclismo')) return 6.8;
      if (type.contains('Natação')) return 7.0;
      return 5;
    } else {
      if (intensity == 'Leve') return 3.5;
      if (intensity == 'Moderada') return 3.5;
      return 6.0;
    }
  }

  static int kcals(double met, double weightKg, int minutes) =>
      (met * weightKg * (minutes / 60)).round();
}