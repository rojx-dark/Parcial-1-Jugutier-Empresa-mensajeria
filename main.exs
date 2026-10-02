# Integrante: Juan Manuel Rojas
#
# Descripción: Archivo principal del sistema de mensajería.
# Carga todos los módulos y orquesta el flujo completo:
# carga de datos → validación → interacción → reportes → comprobante → investigación.

Code.require_file("Util2.ex", __DIR__)
Code.require_file("datos.exs", __DIR__)
Code.require_file("validacion.exs", __DIR__)
Code.require_file("calculos.exs", __DIR__)
Code.require_file("reportes.exs", __DIR__)
Code.require_file("interaccion.exs", __DIR__)
Code.require_file("investigacion.exs", __DIR__)

defmodule Main do
  # Punto de entrada del programa.
  # Orquesta paso a paso la carga de datos, validación, interacción con el usuario,
  # generación de reportes, impresión del comprobante y ejecución de la investigación.
  def main do
    repartidores = Datos.repartidores()
    zonas = Datos.zonas()
    servicios = Datos.servicios()

    # ── Validación ──────────────────────────────────────────────────────────
    resultados = Enum.map(servicios, fn s -> Validacion.validar(s, repartidores, zonas) end)

    validos =
      resultados
      |> Enum.filter(fn {estado, _} -> estado == :ok end)
      |> Enum.map(fn {:ok, s} -> s end)

    # Se conserva cada servicio junto a su motivo para que R1 pueda listarlos.
    rechazados =
      servicios
      |> Enum.zip(resultados)
      |> Enum.filter(fn {_servicio, {estado, _}} -> estado == :error end)
      |> Enum.map(fn {servicio, {:error, motivo}} -> {servicio, motivo} end)

    # ── Interacción (servicio adicional) ────────────────────────────────────
    {validos, rechazados} =
      Interaccion.agregar_servicio_adicional(validos, rechazados, repartidores, zonas)

    # ── Cálculos previos a los reportes ────────────────────────────────────
    liquidaciones = Calculos.calcular_liquidacion_todos(repartidores, validos)

    # ── Reportes ────────────────────────────────────────────────────────────
    Reportes.r1(rechazados)
    Reportes.r2(validos, zonas)
    # solo imprime; no retorna datos
    Reportes.r3(validos)
    Reportes.r4(liquidaciones)
    Reportes.r5(validos, repartidores)
    Reportes.r6(validos, repartidores)
    Reportes.r7(liquidaciones)
    Reportes.r8(validos, repartidores, zonas)

    # ── Interacción (comprobante) ────────────────────────────────────────────
    Interaccion.mostrar_comprobante(validos, repartidores)

    # ── Investigación C1: ranking/2 con Keyword Lists ───────────────────────
    Util2.mostrar("\n--- Investigacion C1: ranking/2 ---", :mensaje)

    Util2.mostrar("Top 5 por kilometros (opciones por defecto):", :mensaje)

    liquidaciones
    |> Investigacion.ranking()
    |> Enum.each(fn liq -> Util2.mostrar("  #{liq.nombre}: #{liq.kilometros} km", :mensaje) end)

    Util2.mostrar("Top 3 por neto [campo: :neto, limite: 3]:", :mensaje)

    liquidaciones
    |> Investigacion.ranking(campo: :neto, limite: 3)
    |> Enum.each(fn liq -> Util2.mostrar("  #{liq.nombre}: $#{round(liq.neto)}", :mensaje) end)

    Util2.mostrar("3 con menos kilometros [orden: :asc, limite: 3]:", :mensaje)

    liquidaciones
    |> Investigacion.ranking(orden: :asc, limite: 3)
    |> Enum.each(fn liq -> Util2.mostrar("  #{liq.nombre}: #{liq.kilometros} km", :mensaje) end)

    # ── Investigación C2: Map.merge/3 ───────────────────────────────────────
    Util2.mostrar("\n--- Investigacion C2 ---", :mensaje)
    empresa_aliada = %{1 => 580.5, 2 => 430, 3 => 510, 5 => 625, 7 => 180}
    # datos de R3 sin imprimir
    km_diarios_propios = Reportes.km_diarios(validos)
    mapa_combinado = Investigacion.combinar_km_diarios(km_diarios_propios, empresa_aliada)

    IO.inspect(mapa_combinado, label: "Mapa combinado con empresa aliada")

    # ── Investigación C3: :timer.tc ─────────────────────────────────────────
    Investigacion.medir_tiempos(validos, repartidores, zonas)
  end
end

Main.main()
