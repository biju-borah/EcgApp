import 'package:ecgapp/graph_data.dart';
import 'package:iirjdart/butterworth.dart';

void main() {
  List<double> dataToFilter = GraphData().values;
  Butterworth butterworth = Butterworth();
  butterworth.bandPass(4, 250, 0.5, 50);

  List<double> filteredData = [];
  for (var v in dataToFilter) {
    filteredData.add(butterworth.filter(v));
  }

  print(filteredData);
}
