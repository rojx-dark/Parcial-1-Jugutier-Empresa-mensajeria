# Integrante: Juan Manuel Rojas
#
# Descripción: Módulo de investigación del sistema de mensajería.
# Explora tres conceptos adicionales exigidos por el parcial:
#   - Keyword Lists para configurar la función ranking/2.
#   - Map.merge/3 para combinar kilómetros de dos empresas sumando claves repetidas.
#   - :timer.tc/1 para medir el tiempo de ejecución de operaciones costosas.

defmodule Investigacion do
  # Ordena y limita una colección según opciones configurables mediante Keyword List.
  # Opciones disponibles:
  #   - campo:  campo del mapa por el que se ordena (por defecto :kilometros)
  #   - orden:  :asc o :desc (por defecto :desc)
  #   - limite: cantidad máxima de elementos a retornar (por defecto 5)
  def ranking(coleccion, opciones \\ []) do
    campo = Keyword.get(opciones, :campo, :kilometros)
    orden = Keyword.get(opciones, :orden, :desc)
    limite = Keyword.get(opciones, :limite, 5)

    coleccion
    |> Util2.ordenar(orden, fn item -> Map.get(item, campo) end)
    |> Enum.take(limite)
  end

  # Combina el mapa de kilómetros diarios propios con el de una empresa aliada.
  # Cuando un día aparece en ambos mapas, los kilómetros se suman usando Map.merge/3.
  # Los días que solo existen en uno de los mapas se conservan tal como están.
  def combinar_km_diarios(km_por_dia, empresa_aliada) do
    Map.merge(km_por_dia, empresa_aliada, fn _dia, km1, km2 -> km1 + km2 end)
  end

  # Mide el tiempo de ejecución en microsegundos de las dos operaciones más costosas
  # del sistema (validación y cálculo de liquidaciones) usando :timer.tc/1 de Erlang.
  def medir_tiempos(servicios_validos, repartidores, zonas) do
    Util2.mostrar("\n--- Investigacion C3: Mediciones ---", :mensaje)

    {tiempo1, _resultado1} =
      :timer.tc(fn ->
        Enum.map(Datos.servicios(), fn servicio ->
          Validacion.validar(servicio, repartidores, zonas)
        end)
      end)

    Util2.mostrar("Tiempo en validar todos los servicios: #{tiempo1} microsegundos", :mensaje)

    {tiempo2, _resultado2} =
      :timer.tc(fn ->
        Calculos.calcular_liquidacion_todos(repartidores, servicios_validos)
      end)

    Util2.mostrar("Tiempo en calcular liquidaciones: #{tiempo2} microsegundos", :mensaje)
  end
end
