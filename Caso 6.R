setwd('/Users/alvarosalgado/Documents/Modelo de Negocios/Caso 6')

install.packages(c("tidyverse", "lme4", "ggplot2", "sjPlot"))
library(tidyverse)
library(lme4)
library(ggplot2)
library(sjPlot)
library(dplyr)

data <- read.csv("Airbnb.csv")

data$room_type <- as.factor(data$room_type)
data$property_type <- as.factor(data$property_type)
data$neighbourhood <- as.factor(data$neighbourhood)
data$city <- as.factor(data$city)
data$cancellation_policy <- as.factor(data$cancellation_policy)

# Convertir log_price a precio normal
data$price <- exp(data$log_price)
data<- na.omit(data)

top_neigh <- data %>%
  count(neighbourhood, sort = TRUE) %>%
  slice_head(n = 5) %>%
  pull(neighbourhood)

data_filtered <- data %>%
  filter(neighbourhood %in% top_neigh)

data_filtered <- na.omit(data_filtered)



modelo <- lmer(price ~ room_type + accommodates + bathrooms +
                 (1 + accommodates | neighbourhood), data = data_filtered, REML = FALSE)

# Resumen del modelo
summary(modelo)

# Evaluar los efectos aleatorios
ranef(modelo)

# Extraer efectos aleatorios
random_effects <- ranef(modelo)$neighbourhood

# Convertir a dataframe
random_df <- data.frame(
  neighbourhood = rownames(random_effects),
  effect = random_effects[,1]
)

# Graficar efectos aleatorios
ggplot(random_df, aes(x = reorder(neighbourhood, effect), y = effect)) +
  geom_point(color = "blue", size = 4) +
  geom_errorbar(aes(ymin = effect - 0.1, ymax = effect + 0.1), width = 0.3, color = "red") +
  coord_flip() +
  labs(title = "Efectos Aleatorios por Vecindario (Top 10)", 
       x = "Vecindario", 
       y = "Efecto Aleatorio") +
  theme_minimal()

# Generar predicciones del modelo
data_filtered$pred <- predict(modelo, re.form = ~(1 | neighbourhood))

# Graficar el precio real vs. el estimado con líneas por vecindario
ggplot(data_filtered, aes(x = accommodates, y = price, color = neighbourhood)) +
  geom_point(alpha = 0.6) +  # Puntos de datos reales
  geom_line(aes(y = pred, group = neighbourhood), size = 1.2) +  # Línea de predicción
  labs(title = "Regresión por vecindario (Top 10)",
       x = "Número de huéspedes",
       y = "Precio (USD)",
       color = "Vecindario") +
  theme_minimal()



# Ajustar el modelo lineal mixto
modelo <- lmer(price ~ accommodates + (1 + accommodates | neighbourhood), 
               data = data_filtered, REML = FALSE)

# Obtener predicciones
data_filtered$pred <- predict(modelo, re.form = ~(1 + accommodates | neighbourhood))

# Graficar los valores observados
ggplot(data_filtered, aes(x = accommodates, y = price)) +
  geom_point(aes(color = neighbourhood), alpha = 0.6, size = 2) +  # Puntos observados
  geom_line(aes(y = pred, group = neighbourhood), color = "gray70", linetype = "dashed") +  # Líneas de efectos aleatorios
  geom_smooth(method = "lm", se = FALSE, color = "black", size = 1) +  # Línea global
  labs(title = "Modelo Lineal Mixto: Precio vs. Capacidad",
       x = "Número de huéspedes",
       y = "Precio (USD)") +
  theme_minimal()

# Ajustar el modelo con SOLO interceptos aleatorios
modelo <- lmer(price ~ accommodates + (1 | neighbourhood), 
               data = data_filtered, REML = FALSE)


# Obtener predicciones
data_filtered$pred <- predict(modelo, re.form = ~(1 | neighbourhood))

# Graficar el modelo
ggplot(data_filtered, aes(x = accommodates, y = price)) +
  geom_point(aes(color = neighbourhood), alpha = 0.6, size = 2) +  # Puntos observados
  geom_line(aes(y = pred, group = neighbourhood), color = "gray70", linetype = "dashed") +  # Líneas de efectos aleatorios
  geom_smooth(method = "lm", se = FALSE, color = "black", size = 1) +  # Línea global
  labs(title = "Modelo Lineal Mixto: Precio vs. Capacidad (Interceptos Aleatorios)",
       x = "Número de huéspedes",
       y = "Precio (USD)") +
  theme_minimal()


# Crear las predicciones con solo el efecto fijo (línea de tendencia)
data_filtered$fixed_pred <- predict(modelo, re.form = NA)

# Crear las predicciones con los efectos aleatorios (interceptos aleatorios por vecindario)
data_filtered$random_pred <- predict(modelo, re.form = ~ (1 | neighbourhood))

# Guardar el dataset con las predicciones
write.csv(data_filtered, "predicciones_modelo.csv", row.names = FALSE)


# Convertir a formato largo
df_long <- data_filtered %>%
  pivot_longer(cols = c(fixed_pred, random_pred),
               names_to = "Tipo_Predicción",
               values_to = "Predicción")

# Exportar a CSV
write.csv(df_long, "predicciones_long.csv", row.names = FALSE, fileEncoding = "UTF-8")
