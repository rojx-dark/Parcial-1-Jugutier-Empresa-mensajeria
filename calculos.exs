# Integrante: Juan Manuel Rojas
#
# Descripción: Módulo de cálculos financieros del sistema de mensajería.
# Contiene toda la lógica matemática para determinar el valor de cada servicio,
# las bonificaciones por productividad, el descuento por alquiler de bicicleta
# y la liquidación neta de cada repartidor.

defmodule Calculos do
  @moduledoc """
  Módulo de cálculos matemáticos puros para liquidación.
  """

  # Parámetros económicos definidos como atributos del módulo que los utiliza.
  @tarifa_base 2500
  @km_bonificacion 80
  @bonificacion_dia 15000
  @alquiler_bicicleta 10000

  # Determina el factor multiplicador del valor del servicio según los minutos de retraso.
  # Entregas anticipadas o a tiempo reciben un bonus; las tardías reciben descuento.
  defp factor_puntualidad(retraso) do
    cond do
      # Anticipado o exacto: +8%
      retraso <= 0 -> 1.08
      # Hasta 10 min tarde: sin ajuste
      retraso <= 10 -> 1.00
      # Hasta 30 min tarde: -10%
      retraso <= 30 -> 0.90
      # Más de 30 min: -25%
      true -> 0.75
    end
  end

  # Calcula el valor final de un servicio multiplicando los kilómetros por la tarifa base
  # y aplicando el factor de puntualidad según el retraso registrado.
  def calcular_valor_servicio(servicio) do
    valor_base = servicio.kilometros * @tarifa_base
    valor_base * factor_puntualidad(servicio.retraso)
  end

  # Determina si un repartidor merece bonificación por productividad en un día.
  # Si la suma de kilómetros de los servicios del día alcanza 80 km, retorna $15.000; si no, 0.
  def calcular_bonificacion_dia(servicios_del_dia) do
    km_totales =
      servicios_del_dia
      |> Enum.map(fn servicio -> servicio.kilometros end)
      |> Enum.sum()

    if km_totales >= @km_bonificacion do
      @bonificacion_dia
    else
      0
    end
  end

  # Calcula el descuento total por alquiler de bicicleta eléctrica en la semana.
  # Solo aplica a repartidores con bicicleta; se cobra $10.000 por cada día con al menos un servicio válido.
  def calcular_alquiler(repartidor, servicios_validos) do
    if repartidor.bicicleta do
      dias_trabajados =
        servicios_validos
        |> Enum.filter(fn servicio -> servicio.repartidor == repartidor.codigo end)
        |> Enum.group_by(fn servicio -> servicio.dia end)
        |> Map.keys()
        |> length()

      dias_trabajados * @alquiler_bicicleta
    else
      0
    end
  end

  # Genera el detalle financiero día a día para un repartidor:
  # kilómetros recorridos, valor total de servicios y bonificación de cada día trabajado.
  def calcular_detalle_por_dia(repartidor, servicios_validos) do
    servicios_validos
    |> Enum.filter(fn servicio -> servicio.repartidor == repartidor.codigo end)
    |> Enum.group_by(fn servicio -> servicio.dia end)
    |> Enum.map(fn {dia, servicios_dia} ->
      km_dia = servicios_dia |> Enum.map(fn servicio -> servicio.kilometros end) |> Enum.sum()

      valor_servicios_dia =
        servicios_dia
        |> Enum.map(fn servicio -> calcular_valor_servicio(servicio) end)
        |> Enum.sum()

      bonif_dia = calcular_bonificacion_dia(servicios_dia)

      %{
        dia: dia,
        kilometros: km_dia,
        valor_servicios: valor_servicios_dia,
        bonificacion: bonif_dia
      }
    end)
    |> Util2.ordenar(:asc, fn detalle -> detalle.dia end)
  end

  # Consolida todos los ingresos y descuentos de un repartidor durante la semana
  # y retorna un mapa con el resumen financiero completo, incluyendo el neto a pagar.
  def calcular_liquidacion(repartidor, servicios_validos) do
    servicios_rep =
      Enum.filter(servicios_validos, fn servicio -> servicio.repartidor == repartidor.codigo end)

    servicios_por_dia = Enum.group_by(servicios_rep, fn servicio -> servicio.dia end)

    km_totales = servicios_rep |> Enum.map(fn servicio -> servicio.kilometros end) |> Enum.sum()

    total_servicios =
      servicios_rep
      |> Enum.map(fn servicio -> calcular_valor_servicio(servicio) end)
      |> Enum.sum()

    total_bonificaciones =
      servicios_por_dia
      |> Enum.map(fn {_dia, servicios_dia} -> calcular_bonificacion_dia(servicios_dia) end)
      |> Enum.sum()

    alquiler = calcular_alquiler(repartidor, servicios_validos)
    neto = total_servicios + total_bonificaciones - alquiler

    %{
      codigo: repartidor.codigo,
      nombre: repartidor.nombre,
      kilometros: km_totales,
      valor_servicios: total_servicios,
      bonificaciones: total_bonificaciones,
      alquiler: alquiler,
      neto: neto
    }
  end

  # Aplica `calcular_liquidacion/2` a cada repartidor de la empresa
  # y retorna la lista completa de liquidaciones, incluidos los que tuvieron cero servicios.
  def calcular_liquidacion_todos(repartidores, servicios_validos) do
    Enum.map(repartidores, fn repartidor ->
      calcular_liquidacion(repartidor, servicios_validos)
    end)
  end
end
