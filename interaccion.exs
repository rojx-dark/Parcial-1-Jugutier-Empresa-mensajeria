# Integrante: Juan Manuel Rojas
#
# Descripción: Módulo de interacción con el usuario del sistema de mensajería.
# Gestiona la entrada de un servicio adicional antes de los reportes y la
# impresión del comprobante de pago personalizado de cada repartidor.
# Los valores monetarios se formatean con fmt/1 para evitar notación científica.

defmodule Interaccion do
  # ---------------------------------------------------------------
  # Función auxiliar de formato de números
  # ---------------------------------------------------------------

  # Convierte un número a texto con máximo dos decimales y sin notación científica.
  # Si el valor redondea a entero, lo muestra sin punto decimal.
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
  # Servicio adicional
  # ---------------------------------------------------------------

  # Solicita al usuario un servicio adicional en formato CSV separado por punto y coma.
  # Si el usuario presiona Enter sin escribir nada, el paso se omite.
  # Si se ingresa datos, delega el procesamiento a procesar_entrada/5.
  # Retorna la tupla {servicios_validos, rechazados} actualizada.
  def agregar_servicio_adicional(servicios_validos, rechazados, repartidores, zonas) do
    Util2.mostrar("\n--- Servicio Adicional ---", :mensaje)

    Util2.mostrar(
      "Ingrese un servicio adicional (repartidor;zona;dia;kilometros;retraso)",
      :mensaje
    )

    entrada = Util2.ingresar("o Enter para omitir: ", :texto)

    if entrada == "" do
      Util2.mostrar("No se ingreso ningun servicio (se presiono Enter).", :mensaje)
      {servicios_validos, rechazados}
    else
      procesar_entrada(entrada, servicios_validos, rechazados, repartidores, zonas)
    end
  end

  # Intenta parsear la entrada y, si tiene formato válido, aplica las reglas de validación.
  # Un servicio aceptado se agrega a los válidos; uno rechazado por una regla se agrega
  # a los rechazados para que aparezca en R1. Un error de formato no es un servicio,
  # por lo que solo se informa al usuario.
  defp procesar_entrada(entrada, servicios_validos, rechazados, repartidores, zonas) do
    case parsear_servicio(entrada) do
      {:error, :formato_invalido} ->
        Util2.mostrar("Rechazado por formato: {:error, :formato_invalido}", :error)
        {servicios_validos, rechazados}

      {:ok, servicio_raw} ->
        case Validacion.validar(servicio_raw, repartidores, zonas) do
          {:ok, servicio_valido} ->
            Util2.mostrar("Servicio agregado.", :mensaje)
            {[servicio_valido | servicios_validos], rechazados}

          {:error, motivo} ->
            Util2.mostrar("Rechazado por validacion: #{motivo}", :error)
            {servicios_validos, rechazados ++ [{servicio_raw, motivo}]}
        end
    end
  end

  # Divide la cadena por punto y coma, verifica que tenga exactamente cinco campos
  # y convierte cada campo al tipo de dato correspondiente.
  # Retorna {:ok, mapa_servicio} o {:error, :formato_invalido}.
  defp parsear_servicio(entrada) do
    partes = String.split(entrada, ";")

    if length(partes) != 5 do
      {:error, :formato_invalido}
    else
      [rep, zona, dia_str, km_str, ret_str] = Enum.map(partes, fn parte -> String.trim(parte) end)

      dia_parse = Integer.parse(dia_str)
      km_parse = Float.parse(km_str)
      km_parse = if km_parse == :error, do: Integer.parse(km_str), else: km_parse
      ret_parse = Float.parse(ret_str)
      ret_parse = if ret_parse == :error, do: Integer.parse(ret_str), else: ret_parse

      if dia_parse == :error or km_parse == :error or ret_parse == :error do
        {:error, :formato_invalido}
      else
        {dia, resto_dia} = dia_parse
        {km, resto_km} = km_parse
        {ret, resto_ret} = ret_parse

        if resto_dia != "" or resto_km != "" or resto_ret != "" do
          {:error, :formato_invalido}
        else
          {:ok, %{repartidor: rep, zona: zona, dia: dia, kilometros: km, retraso: ret}}
        end
      end
    end
  end

  # ---------------------------------------------------------------
  # Comprobante del repartidor
  # ---------------------------------------------------------------

  # Solicita el código de un repartidor y, si existe, imprime su comprobante detallado
  # con el resumen financiero de la semana: días trabajados, kilómetros, valores y neto a pagar.
  def mostrar_comprobante(servicios_validos, repartidores) do
    Util2.mostrar("\n--- Comprobante ---", :mensaje)
    codigo = Util2.ingresar("Ingrese el codigo del repartidor: ", :texto)

    repartidores_filtrados =
      Enum.filter(repartidores, fn repartidor -> repartidor.codigo == codigo end)

    if length(repartidores_filtrados) == 0 do
      Util2.mostrar("Repartidor no encontrado.", :error)
    else
      [repartidor_encontrado] = repartidores_filtrados
      detalle = Calculos.calcular_detalle_por_dia(repartidor_encontrado, servicios_validos)
      liq = Calculos.calcular_liquidacion(repartidor_encontrado, servicios_validos)

      Util2.mostrar(
        "\nNombre: #{repartidor_encontrado.nombre} (#{repartidor_encontrado.codigo})",
        :mensaje
      )

      Util2.mostrar(
        "Bicicleta: #{if repartidor_encontrado.bicicleta, do: "Si", else: "No"}",
        :mensaje
      )

      Util2.mostrar("Dias trabajados:", :mensaje)

      Enum.each(detalle, fn detalle_dia ->
        Util2.mostrar(
          "  Dia #{detalle_dia.dia}: #{detalle_dia.kilometros} km | " <>
            "Serv: $#{fmt(detalle_dia.valor_servicios)} | Bonif: $#{fmt(detalle_dia.bonificacion)}",
          :mensaje
        )
      end)

      Util2.mostrar("Suma servicios:      $#{fmt(liq.valor_servicios)}", :mensaje)
      Util2.mostrar("Suma bonificaciones: $#{fmt(liq.bonificaciones)}", :mensaje)
      Util2.mostrar("Alquiler bicicleta: -$#{fmt(liq.alquiler)}", :mensaje)
      Util2.mostrar("Total a pagar:       $#{fmt(liq.neto)}", :mensaje)
    end
  end
end
