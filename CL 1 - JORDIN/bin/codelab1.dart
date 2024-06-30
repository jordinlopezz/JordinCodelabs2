// Seguridad de nulls en Dart

// Clase genérica con parámetro de tipo no anulable.
class Caja<T> {
  final T objeto;
  Caja(this.objeto);
}

// Clase genérica con parámetro de tipo potencialmente anulable.
class CajaAnulable<T> {
  T? objeto;
  CajaAnulable.vacia();
  CajaAnulable.llena(this.objeto);

  T desempaquetar() => objeto as T;
}

// Clase genérica con límite no anulable.
class Intervalo<T extends num> {
  T minimo, maximo;

  Intervalo(this.minimo, this.maximo);

  bool get estaVacio => maximo <= minimo;
}

// Clase genérica con límite anulable.
class IntervaloAnulable<T extends num?> {
  T minimo, maximo;

  IntervaloAnulable(this.minimo, this.maximo);

  bool get estaVacio {
    var minimoLocal = minimo;
    var maximoLocal = maximo;

    // No hay mínimo o máximo significa un intervalo sin fin.
    if (minimoLocal == null || maximoLocal == null) return false;
    return maximoLocal <= minimoLocal;
  }
}

void main() {
  // Demostración de varios aspectos de la seguridad de nulls y genéricos.

  // Instanciación de la clase Caja con un parámetro de tipo no anulable.
  var cajaString = Caja<String>('una cadena');
  print('Caja de String: ${cajaString.objeto}');

  // Instanciación de la clase Caja con un parámetro de tipo anulable.
  var cajaIntNulo = Caja<int?>(null);
  print('Caja de int? con valor nulo: ${cajaIntNulo.objeto}');

  // Instanciación de la clase CajaAnulable con un parámetro de tipo anulable.
  var cajaAnulable = CajaAnulable<int?>.llena(null);
  print('CajaAnulable desempaquetar: ${cajaAnulable.desempaquetar()}');

  // Instanciación de la clase Intervalo con un parámetro de tipo no anulable.
  var intervalo = Intervalo(1, 10);
  print('Intervalo está vacío: ${intervalo.estaVacio}');

  // Instanciación de la clase IntervaloAnulable con un parámetro de tipo anulable.
  var intervaloAnulable = IntervaloAnulable<int?>(null, 10);
  print('Intervalo anulable está vacío: ${intervaloAnulable.estaVacio}');

  // Uso de un mapa con un tipo de retorno anulable.
  var mapa = {'llave': 'valor'};
  print(
      'Longitud del valor en el mapa: ${mapa['llave']?.length}'); // Acceso seguro con el operador ?.

  // Uso del constructor List.empty para crear una lista vacía de un tipo.
  var lista = List<int>.empty();
  print('Longitud de la lista: ${lista.length}');

  // Ejemplo de uso de Iterator.
  var iterador = [1, 2, 3].iterator;
  while (iterador.moveNext()) {
    print('Elemento actual: ${iterador.current}');
  }
}
