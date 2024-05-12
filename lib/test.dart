import 'package:ecgapp/filtered_data.dart';

List<int> detectQRS(List<double> ecgData) {
  List<int> qrsPeaks = [];

  // 1. Bandpass Filtering (not implemented here, assume pre-filtered data)

  // 2. Differentiation
  List<double> diff = [];
  for (int i = 1; i < ecgData.length; i++) {
    diff.add(ecgData[i] - ecgData[i - 1]);
  }

  // 3. Squaring
  List<double> squared = [];
  for (double value in diff) {
    squared.add(value * value);
  }

  // 4. Integration (moving window)
  List<double> integrated = [];
  int windowSize = 7; // Adjust window size as needed
  for (int i = 0; i < squared.length - windowSize; i++) {
    double sum = 0;
    for (int j = 0; j < windowSize; j++) {
      sum += squared[i + j];
    }
    integrated.add(sum);
  }

  // 5. Dynamic Thresholding
  double threshold = 0.5 * getMax(integrated); // Adjust threshold as needed

  // 6. Peak Detection
  for (int i = 1; i < integrated.length - 1; i++) {
    if (integrated[i] > integrated[i - 1] &&
        integrated[i] > integrated[i + 1] &&
        integrated[i] > threshold) {
      qrsPeaks.add(i);
    }
  }

  return qrsPeaks;
}

double getMax(List<double> list) {
  double max = list[0];
  for (int i = 1; i < list.length; i++) {
    if (list[i] > max) {
      max = list[i];
    }
  }
  return max;
}

void main() {
  List<double> ecgData = FilteredData().ecgData;

  List<int> qrsPeaks = detectQRS(ecgData);

  print("QRS Peaks: $qrsPeaks");
}
