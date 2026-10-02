# Integrante: Juan Manuel Rojas
#
# Descripción: Módulo de validación de servicios.
# Define como atributos de módulo los parámetros que delimitan un servicio válido
# y expone las reglas que determinan si un servicio es aceptado o rechazado.
# Utiliza `with` para encadenar las verificaciones en el orden exigido.

defmodule Validacion do
  # Parámetros de validación definidos como atributos del módulo.
  @dias_operacion 1..6
  @max_km_servicio 45
  @retraso_minimo -30
  @retraso_maximo 180

  # Encadena las cinco verificaciones en el orden exigido mediante `with`.
  # Retorna {:ok, servicio} si pasa todas, o {:error, motivo} al primer fallo.
  def validar(servicio, repartidores, zonas) do
    with {:ok, _} <- verificar_repartidor(servicio, repartidores),
         {:ok, _} <- verificar_zona(servicio, zonas),
         {:ok, _} <- verificar_dia(servicio),
         {:ok, _} <- verificar_kilometros(servicio),
         {:ok, _} <- verificar_retraso(servicio) do
      {:ok, servicio}
    end
  end

  # Comprueba que el código del repartidor exista en la lista de repartidores registrados.
  defp verificar_repartidor(servicio, repartidores) do
    coincidencias =
      Enum.filter(repartidores, fn repartidor -> repartidor.codigo == servicio.repartidor end)

    if length(coincidencias) > 0 do
      {:ok, servicio}
    else
      {:error, :repartidor_desconocido}
    end
  end

  # Comprueba que la zona del servicio exista en la lista de zonas de cobertura.
  defp verificar_zona(servicio, zonas) do
    coincidencias = Enum.filter(zonas, fn zona -> zona.id == servicio.zona end)

    if length(coincidencias) > 0 do
      {:ok, servicio}
    else
      {:error, :zona_desconocida}
    end
  end

  # Comprueba que el día sea un entero válido dentro de los días de operación (1 a 6).
  defp verificar_dia(servicio) do
    if is_integer(servicio.dia) and servicio.dia in @dias_operacion do
      {:ok, servicio}
    else
      {:error, :dia_invalido}
    end
  end

  # Comprueba que los kilómetros sean un número positivo y no superen el máximo permitido de 45 km.
  defp verificar_kilometros(servicio) do
    if is_number(servicio.kilometros) and servicio.kilometros > 0 and
         servicio.kilometros <= @max_km_servicio do
      {:ok, servicio}
    else
      {:error, :kilometros_fuera_de_rango}
    end
  end

  # Comprueba que el retraso esté dentro del rango permitido (-30 a 180 minutos).
  defp verificar_retraso(servicio) do
    if is_number(servicio.retraso) and servicio.retraso >= @retraso_minimo and
         servicio.retraso <= @retraso_maximo do
      {:ok, servicio}
    else
      {:error, :retraso_invalido}
    end
  end

  # Funciones de acceso público a los parámetros del módulo.
  def dias_operacion, do: @dias_operacion
  def max_km_servicio, do: @max_km_servicio
end
