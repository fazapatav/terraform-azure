resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ── Azure API Management ──────────────────────────────────────
resource "azurerm_api_management" "main" {
  name                = "apim-${var.environment}-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  sku_name = var.environment == "prod" ? "Premium_1" : "Developer_1"

  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = var.subnet_apim_id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ── API: Reportes regulatorios ────────────────────────────────
resource "azurerm_api_management_api" "reportes" {
  name                  = "api-reportes-regulatorios"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  display_name          = "Reportes Regulatorios"
  path                  = "reportes"
  protocols             = ["https"]
  subscription_required = true
  service_url           = "http://${var.api_service_url}/api"
}

# ── Operación: descargar reporte ──────────────────────────────
resource "azurerm_api_management_api_operation" "get_reporte" {
  operation_id        = "get-reporte"
  api_name            = azurerm_api_management_api.reportes.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  display_name        = "Obtener reporte por ID"
  method              = "GET"
  url_template        = "/reportes/{reporteId}"
  description         = "Retorna el archivo .avro.snappy.p7z del reporte regulatorio"

  template_parameter {
    name     = "reporteId"
    required = true
    type     = "string"
  }

  response {
    status_code = 200
    description = "Archivo de reporte"
  }
  response {
    status_code = 404
    description = "Reporte no encontrado"
  }
}

# ── Operación: estado de envío ────────────────────────────────
resource "azurerm_api_management_api_operation" "get_estado_envio" {
  operation_id        = "get-estado-envio"
  api_name            = azurerm_api_management_api.reportes.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  display_name        = "Consultar estado de envio"
  method              = "GET"
  url_template        = "/envios/{envioId}/estado"
  description         = "Retorna el estado actual del envio: pendiente, enviado, error"

  template_parameter {
    name     = "envioId"
    required = true
    type     = "string"
  }

  response { status_code = 200 }
  response { status_code = 404 }
}

# ── Operación: disparar envío ─────────────────────────────────
resource "azurerm_api_management_api_operation" "post_envio" {
  operation_id        = "crear-envio"
  api_name            = azurerm_api_management_api.reportes.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  display_name        = "Iniciar envio a entidad"
  method              = "POST"
  url_template        = "/envios"
  description         = "Inicia el proceso de envio de un reporte a la entidad de gobierno"

  response { status_code = 202 }
  response { status_code = 400 }
}

# ── Política global de APIM ───────────────────────────────────
resource "azurerm_api_management_api_policy" "reportes" {
  api_name            = azurerm_api_management_api.reportes.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <rate-limit calls="100" renewal-period="60" />
    <set-header name="Strict-Transport-Security" exists-action="override">
      <value>max-age=31536000; includeSubDomains</value>
    </set-header>
    <set-header name="X-Powered-By" exists-action="delete" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
    <set-header name="X-Content-Type-Options" exists-action="override">
      <value>nosniff</value>
    </set-header>
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
}
