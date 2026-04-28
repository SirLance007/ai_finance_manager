String formatINR(double amount, {bool isCompact = false}) {
  double absAmount = amount.abs();
  String sign = amount < 0 ? '-' : '';

  if (isCompact) {
    if (absAmount >= 10000000) return '$sign${(absAmount / 10000000).toStringAsFixed(1)} Cr';
    if (absAmount >= 100000) return '$sign${(absAmount / 100000).toStringAsFixed(1)} L';
    if (absAmount >= 1000) return '$sign${(absAmount / 1000).toStringAsFixed(1)}k';
  }

  String numStr = absAmount.toStringAsFixed(0);
  if (numStr.length <= 3) return sign + numStr;

  String lastThree = numStr.substring(numStr.length - 3);
  String remaining = numStr.substring(0, numStr.length - 3);
  
  String result = '';
  while (remaining.length > 2) {
    result = ',${remaining.substring(remaining.length - 2)}$result';
    remaining = remaining.substring(0, remaining.length - 2);
  }
  
  return '$sign$remaining$result,$lastThree';
}
