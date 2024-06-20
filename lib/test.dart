import 'package:ecgapp/filtered_data.dart';

List<int> detectQRS(List<double> ecgData) {
  List<int> qrsPeaks = [];

  // 1. Differentiation
  List<double> diff = [];
  for (int i = 1; i < ecgData.length; i++) {
    diff.add(ecgData[i] - ecgData[i - 1]);
  }

  // 2. Squaring
  List<double> squared = [];
  for (double value in diff) {
    squared.add(value * value);
  }

  // 3. Integration (moving window)
  List<double> integrated = [];
  int windowSize = 7; // Adjust window size as needed
  for (int i = 0; i < squared.length - windowSize + 1; i++) {
    double sum = 0;
    for (int j = 0; j < windowSize; j++) {
      sum += squared[i + j];
    }
    integrated.add(sum);
  }

  // 4. Dynamic Thresholding
  double threshold = 0.5 * getMax(integrated); // Adjust threshold as needed

  // 5. Peak Detection
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

  // Find Q and S peaks
  List<int> qPeaksIndices = [];
  List<int> rPeaksIndices = qrsPeaks;
  List<int> sPeaksIndices = [];

  for (int rPeakIndex in qrsPeaks) {
    var qPeakIndex, sPeakIndex;
    // Find Q peak index
    for (int i = rPeakIndex - 1; i >= 0; i--) {
      if (ecgData[i] < ecgData[i + 1]) {
        qPeakIndex = i;
        break;
      }
    }
    // Find S peak index
    for (int i = rPeakIndex + 1; i < ecgData.length - 1; i++) {
      if (ecgData[i] < ecgData[i - 1] && ecgData[i] < ecgData[i + 1]) {
        sPeakIndex = i;
        break;
      }
    }
    if (qPeakIndex != null) qPeaksIndices.add(qPeakIndex);
    if (sPeakIndex != null) sPeaksIndices.add(sPeakIndex);
  }

  print("Q Peaks Indices: $qPeaksIndices");
  print("R Peaks Indices: $rPeaksIndices");
  print("S Peaks Indices: $sPeaksIndices");
}
