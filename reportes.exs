# Integrante: Juan Manuel Rojas
#
# Descripción: Módulo de reportes estadísticos del sistema de mensajería.
# Genera los ocho reportes requeridos (R1–R8) usando Util2 para la salida.
# La meta diaria se define como atributo; los días de operación se toman de Validacion.
# Los valores monetarios se formatean con la función privada `fmt/1` para evitar
# notación científica y mostrar máximo dos decimales con aproximación.

defmodule Reportes do
  # Meta diaria de kilómetros de la empresa, usada en R3.
  @meta_diaria_km 500

  # ---------------------------------------------------------------
  # Función auxiliar de formato de números
  # ---------------------------------------------------------------

  # Convierte un número a texto con máximo dos decimales y sin notación científica.
  # Si el valor es entero (o redondea a entero), se muestra sin decimales.
  defp fmt(n) when is_integer(n), do: Integer.to_string(n)

  defp fmt(n) do
    r = Float.round(n * 1.0, 2)

    if r - Float.floor(r) == 0.0 do
      Integer.to_string(trunc(r))
    else
      :erlang.float_to_binary(r, decimals: 2)
    end
  end

  # ---------------------------------------------------------------
  # Función auxiliar de datos para R3
  # ---------------------------------------------------------------

  # Construye el mapa {dia => km_totales} para los 6 días de operación,
  # sin imprimir nada. Es usado internamente por r3/1 y públicamente por km_diarios/1.
  defp construir_mapa_km_diarios(servicios_validos) do
    servicios_por_dia = Enum.group_by(servicios_validos, fn servicio -> servicio.dia end)

    lista_tuplas =
      Enum.map(Validacion.dias_operacion(), fn dia ->
        servicios = Map.get(servicios_por_dia, dia, [])
        km = servicios |> Enum.map(fn servicio -> servicio.kilometros end) |> Enum.sum()
        {dia, km}
      end)

    Map.new(lista_tuplas)
  end

  # Retorna el mapa {dia => km_totales} sin imprimir nada.
  # Permite que main.exs obtenga los datos de R3 sin depender del retorno del reporte.
  def km_diarios(servicios_validos) do
    construir_mapa_km_diarios(servicios_validos)
  end

  # ---------------------------------------------------------------
  # Reportes
  # ---------------------------------------------------------------

  # R1: Imprime cada servicio rechazado con su motivo y, al final,
  # la cantidad de rechazos agrupados por motivo.
  # Recibe una lista de tuplas {servicio, motivo}.
  def r1(rechazados) do
    Util2.mostrar("\n--- R1: Servicios rechazados ---", :mensaje)

    Enum.each(rechazados, fn {servicio, motivo} ->
      Util2.mostrar(
        "- Rep: #{servicio.repartidor} | Zona: #{servicio.zona} | Dia: #{servicio.dia} | " <>
          "Km: #{servicio.kilometros} | Retraso: #{servicio.retraso} -> #{motivo}",
        :mensaje
      )
    end)

    Util2.mostrar("Cantidad de rechazos por motivo:", :mensaje)

    rechazados
    |> Enum.map(fn {_servicio, motivo} -> motivo end)
    |> Enum.frequencies()
    |> Enum.each(fn {motivo, cantidad} ->
      Util2.mostrar("  #{motivo}: #{cantidad}", :mensaje)
    end)
  end

  # R2: Muestra los kilómetros recorridos en cada zona y su densidad (km/área),
  # ordenado de mayor a menor densidad.
  def r2(servicios_validos, zonas) do
    Util2.mostrar("\n--- R2: Kilometros y densidad por zona ---", :mensaje)
    servicios_por_zona = Enum.group_by(servicios_validos, fn servicio -> servicio.zona end)

    zonas
    |> Enum.map(fn zona ->
      servicios_de_zona = Map.get(servicios_por_zona, zona.id, [])
      km = servicios_de_zona |> Enum.map(fn servicio -> servicio.kilometros end) |> Enum.sum()
      densidad = km / zona.area
      %{id: zona.id, nombre: zona.nombre, area: zona.area, kilometros: km, densidad: densidad}
    end)
    |> Util2.ordenar(:desc, fn zona -> zona.densidad end)
    |> Enum.each(fn zona ->
      Util2.mostrar(
        "#{zona.id} - #{zona.nombre}: #{zona.kilometros} km, Densidad: #{fmt(zona.densidad)}",
        :mensaje
      )
    end)
  end

  # R3: Imprime los kilómetros totales de la empresa por día e indica si se alcanzó
  # la meta de 500 km. Al final informa si se cumplió todos los días y al menos un día.
  # Esta función solo imprime; para obtener el mapa de km use km_diarios/1.
  def r3(servicios_validos) do
    Util2.mostrar("\n--- R3: Kilometros por dia ---", :mensaje)
    mapa = construir_mapa_km_diarios(servicios_validos)
    meta = @meta_diaria_km

    resultados =
      Enum.map(Validacion.dias_operacion(), fn dia ->
        km = Map.get(mapa, dia, 0)
        {dia, km, km >= meta}
      end)

    Enum.each(resultados, fn {dia, km, alcanzo?} ->
      estado = if alcanzo?, do: "Si alcanzo", else: "No alcanzo"
      Util2.mostrar("Dia #{dia}: #{km} km (#{estado} la meta)", :mensaje)
    end)

    todos? = Enum.all?(resultados, fn {_dia, _km, alcanzo?} -> alcanzo? end)
    alguno? = Enum.any?(resultados, fn {_dia, _km, alcanzo?} -> alcanzo? end)

    Util2.mostrar("¿Alcanzo la meta todos los dias?: #{todos?}", :mensaje)
    Util2.mostrar("¿Alcanzo la meta al menos un dia?: #{alguno?}", :mensaje)
  end

  # R4: Muestra la liquidación completa de todos los repartidores, numerada y ordenada
  # de mayor a menor neto. Incluye kilómetros, valor de servicios, bonificaciones, alquiler y neto.
  # Los repartidores sin servicios aparecen con valores en cero.
  def r4(liquidaciones) do
    Util2.mostrar("\n--- R4: Liquidacion de repartidores ---", :mensaje)

    liquidaciones_numeradas =
      liquidaciones
      |> Util2.ordenar(:desc, fn liquidacion -> liquidacion.neto end)
      |> Enum.with_index(1)

    Enum.each(liquidaciones_numeradas, fn {liquidacion, posicion} ->
      texto =
        "#{posicion}. #{liquidacion.nombre} (#{liquidacion.codigo}) | Km: #{liquidacion.kilometros} | Serv: $#{fmt(liquidacion.valor_servicios)} | Bonif: $#{fmt(liquidacion.bonificaciones)} | Alq: -$#{fmt(liquidacion.alquiler)} | Neto: $#{fmt(liquidacion.neto)}"

      Util2.mostrar(texto, :mensaje)
    end)
  end

  # R5: Identifica el repartidor con más kilómetros cada día, manejando empates.
  # Al final indica quién ocupó el primer lugar en la mayor cantidad de días.
  def r5(servicios_validos, repartidores) do
    Util2.mostrar("\n--- R5: Repartidor con mas km cada dia ---", :mensaje)
    servicios_por_dia = Enum.group_by(servicios_validos, fn servicio -> servicio.dia end)

    ganadores_por_dia =
      Enum.map(Validacion.dias_operacion(), fn dia ->
        servicios_dia = Map.get(servicios_por_dia, dia, [])

        km_por_rep =
          servicios_dia
          |> Enum.group_by(fn servicio -> servicio.repartidor end)
          |> Enum.map(fn {codigo, servicios_rep} ->
            km = servicios_rep |> Enum.map(fn servicio -> servicio.kilometros end) |> Enum.sum()
            {codigo, km}
          end)

        max_km =
          if length(km_por_rep) == 0 do
            0
          else
            km_por_rep |> Enum.map(fn {_codigo, km} -> km end) |> Enum.max()
          end

        empatados =
          km_por_rep
          |> Enum.filter(fn {_codigo, km} -> km == max_km and km > 0 end)
          |> Enum.map(fn {codigo, km} ->
            [rep] = Enum.filter(repartidores, fn repartidor -> repartidor.codigo == codigo end)
            {rep.nombre, km, codigo}
          end)

        {dia, empatados}
      end)

    Enum.each(ganadores_por_dia, fn {dia, empatados} ->
      if length(empatados) == 0 do
        Util2.mostrar("Dia #{dia}: Sin servicios", :mensaje)
      else
        Util2.mostrar("Dia #{dia}:", :mensaje)

        Enum.each(empatados, fn {nombre, km, _codigo} ->
          Util2.mostrar("  - #{nombre} con #{km} km", :mensaje)
        end)
      end
    end)

    listas_de_codigos =
      Enum.map(ganadores_por_dia, fn {_dia, empatados} ->
        Enum.map(empatados, fn {_nombre, _km, codigo} -> codigo end)
      end)

    todos_los_codigos = List.flatten(listas_de_codigos)

    frecuencias = Enum.frequencies(todos_los_codigos)

    if map_size(frecuencias) > 0 do
      max_veces = frecuencias |> Map.values() |> Enum.max()

      lideres =
        frecuencias
        |> Enum.filter(fn {_codigo, veces} -> veces == max_veces end)
        |> Enum.map(fn {codigo, veces} ->
          [rep] = Enum.filter(repartidores, fn repartidor -> repartidor.codigo == codigo end)
          "#{rep.nombre} (#{veces} dias)"
        end)

      Util2.mostrar("Primer lugar en mas dias:", :mensaje)
      Enum.each(lideres, fn texto -> Util2.mostrar("  - #{texto}", :mensaje) end)
    else
      Util2.mostrar("No hay ganadores.", :mensaje)
    end
  end

  # R6: Calcula la puntualidad ponderada por kilómetros de cada repartidor con al menos
  # 3 servicios válidos y muestra al que obtuvo el menor retraso promedio ponderado.
  def r6(servicios_validos, repartidores) do
    Util2.mostrar("\n--- R6: Mejor puntualidad ponderada ---", :mensaje)

    candidatos =
      servicios_validos
      |> Enum.group_by(fn servicio -> servicio.repartidor end)
      |> Enum.filter(fn {_codigo, servicios_rep} -> length(servicios_rep) >= 3 end)
      |> Enum.map(fn {codigo, servicios_rep} ->
        suma_ponderada =
          servicios_rep
          |> Enum.map(fn servicio -> servicio.retraso * servicio.kilometros end)
          |> Enum.sum()

        suma_km = servicios_rep |> Enum.map(fn servicio -> servicio.kilometros end) |> Enum.sum()
        promedio = suma_ponderada / suma_km
        [rep] = Enum.filter(repartidores, fn repartidor -> repartidor.codigo == codigo end)
        %{repartidor: rep, promedio: promedio}
      end)

    if length(candidatos) == 0 do
      Util2.mostrar("Nadie tiene 3 o mas servicios validos.", :mensaje)
    else
      ganador =
        candidatos
        |> Util2.ordenar(:asc, fn candidato -> candidato.promedio end)
        |> hd()

      Util2.mostrar(
        "Mejor: #{ganador.repartidor.nombre} con promedio ponderado de #{fmt(ganador.promedio)}",
        :mensaje
      )
    end
  end

  # R7: Muestra el total pagado a todos los repartidores en la semana
  # y el costo promedio por kilómetro recorrido.
  def r7(liquidaciones) do
    Util2.mostrar("\n--- R7: Total y promedio ---", :mensaje)
    total_pagado = liquidaciones |> Enum.map(fn liquidacion -> liquidacion.neto end) |> Enum.sum()

    km_totales =
      liquidaciones |> Enum.map(fn liquidacion -> liquidacion.kilometros end) |> Enum.sum()

    promedio =
      if km_totales > 0 do
        total_pagado / km_totales
      else
        0
      end

    Util2.mostrar("Total pagado: $#{fmt(total_pagado)}", :mensaje)
    Util2.mostrar("Costo promedio por km: $#{fmt(promedio)}", :mensaje)
  end

  # R8: Lista los repartidores que realizaron al menos un servicio válido en cada una
  # de las cuatro zonas de cobertura durante la semana.
  def r8(servicios_validos, repartidores, zonas) do
    Util2.mostrar("\n--- R8: Repartidores en todas las zonas ---", :mensaje)

    ids_zonas = Enum.map(zonas, fn zona -> zona.id end)
    total_zonas = length(ids_zonas)

    cumplen =
      servicios_validos
      |> Enum.group_by(fn servicio -> servicio.repartidor end)
      |> Enum.filter(fn {_codigo, servicios_rep} ->
        zonas_cubiertas =
          servicios_rep
          |> Enum.group_by(fn servicio -> servicio.zona end)
          |> Map.keys()

        length(zonas_cubiertas) == total_zonas
      end)
      |> Enum.map(fn {codigo, _servicios_rep} ->
        [rep] = Enum.filter(repartidores, fn repartidor -> repartidor.codigo == codigo end)
        rep
      end)

    if length(cumplen) == 0 do
      Util2.mostrar("Nadie visito todas las zonas.", :mensaje)
    else
      Enum.each(cumplen, fn repartidor ->
        Util2.mostrar("- #{repartidor.nombre} (#{repartidor.codigo})", :mensaje)
      end)
    end
  end
end
