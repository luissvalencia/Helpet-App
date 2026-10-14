import os

# US-15: coincidencias por debajo de este valor no se guardan ni se muestran.
# Umbral de mejor F1 sobre el conjunto de validación del benchmark por
# rescatista (pares del mismo animal vs. animales distintos de la misma
# raza/color). La escala es propia del modelo
# afinado: mismo animal ~0.28 en promedio, animal parecido ~0.10, distinto ~0.
# Se prefiere recall porque un falso negativo es permanente (el matching solo
# corre al crear el reporte) y un falso positivo se descarta con un tap (US-24).
SIMILARITY_THRESHOLD = 0.145

# Solo gatos: si la luminosidad del pelaje (L* de 0 a 100, ver
# app/models/fur_color.py) de los dos reportes difiere más que esto, no se
# guarda la coincidencia aunque supere el umbral (un gato negro no puede ser
# uno claro). Elegido en validación del benchmark: entre los cortes con mejor
# F1, el que menos detección sacrifica. Si a alguno de los dos no se le pudo
# medir el pelaje, no se aplica.
MAX_DIFERENCIA_LUMINOSIDAD_GATOS = 30.0

# Sprint 4 (US-19): backend Node/Express, para avisar cuando se guarda una coincidencia.
BACKEND_URL = os.environ.get("BACKEND_URL", "http://localhost:3000")

# Debe coincidir con INTERNAL_API_KEY en backend/.env.
INTERNAL_API_KEY = os.environ.get("INTERNAL_API_KEY", "")
