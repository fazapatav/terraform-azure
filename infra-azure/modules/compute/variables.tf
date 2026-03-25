variable "environment" {
  description = "Nombre del ambiente (dev, prod)"
  type        = string
}

variable "location" {
  description = "Región de Azure"
  type        = string
}

variable "resource_group_name" {
  description = "RG donde se crea el cluster"
  type        = string
}

variable "subnet_private_id" {
  description = "ID de la subred privada — viene del módulo networking"
  type        = string
}

variable "node_count" {
  description = "Número inicial de nodos en el system pool"
  type        = number
  default     = 2
}

variable "node_min_count" {
  description = "Mínimo de nodos para el autoscaler"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Máximo de nodos para el autoscaler"
  type        = number
  default     = 5
}

variable "node_vm_size" {
  description = "Tamaño de VM para los nodos"
  type        = string
  default     = "Standard_D2s_v3"
}
