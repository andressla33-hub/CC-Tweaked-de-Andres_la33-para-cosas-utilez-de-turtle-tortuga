# Mineria inteligente para CC:Tweaked

Este paquete contiene `minero_turtle.lua` para cada turtle y `minero_pc.lua` para la computadora de control. Se comunican por `rednet` usando modems compatibles y el protocolo `minero_inteligente_v1`.

## Instalacion

1. Copia `minero_turtle.lua` a cada turtle y `minero_pc.lua` a la computadora.
2. Coloca un modem en cada turtle y en la PC. Para comunicacion sin cables, usa modems inalambricos dentro de su alcance.
3. En cada turtle, coloca carbon en la ranura 16. Pon un cofre frente al punto de inicio para recibir lo minado.
4. Ejecuta `minero_turtle.lua` en cada turtle y `minero_pc.lua` en la computadora.
5. Toca una turtle en la lista, ajusta el objetivo con `+64`/`-64` o `+1`/`-1`, y pulsa `Iniciar`.

La interfaz muestra los bloques y minerales picados en el trabajo actual, los acumulados reportados por cada turtle, el combustible restante, el carbon de la ranura 16 y el estado. `Detener` pide regresar al inicio. Tras alcanzar el objetivo o detenerse, la turtle intenta volver por el tunel, descarga las ranuras 1 a 15 en el cofre que tiene delante, espera cinco segundos y queda lista para otra orden. La ranura 16 nunca se descarga.

## Comportamiento y ajustes

El objetivo inicial es de 640 bloques (10 stacks). El conteo representa bloques que la turtle picó, no la cantidad de objetos que esos bloques dejaron caer. La exploracion de vetas reconoce bloques cuyo nombre termina en `_ore` y `minecraft:ancient_debris`; sigue recursivamente los bloques conectados en las seis direcciones configuradas. Para terminar una veta completa, el total del trabajo puede superar el objetivo por el tamano de esa veta.

Las variables al inicio de `minero_turtle.lua` permiten modificar el protocolo, objetivo inicial, ranura de combustible, intervalo de reportes, profundidad maxima de una veta, descarga automatica y las direcciones que revisa. El panel permite cambiar el objetivo de cada turtle mientras espera o trabaja. Los reportes se transmiten por broadcast; por tanto, usa la misma red de modems para todas las turtles y la PC.

La turtle solo puede descargar objetos si hay un cofre directamente frente a ella al regresar. Si no encuentra combustible suficiente, tiene el camino de retorno bloqueado o no puede descargar, reporta el problema en la PC. El regreso no puede recuperar una turtle si se queda sin energia durante una excursion o si una obstruccion no se puede picar. No cierres el programa ni reinicies la turtle durante un trabajo: el objetivo y los acumulados se guardan, pero la posicion de una excavacion interrumpida requiere recuperacion manual.
