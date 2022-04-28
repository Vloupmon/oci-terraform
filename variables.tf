variable "tenancy_ocid" {
  type        = string
  description = "OCID of your tenancy. To get the value, see https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five"
}

variable "user_ocid" {
  type        = string
  description = "OCID of the user calling the API. To get the value, see https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five"
}

variable "private_key_path" {
  type        = string
  description = "The path (including filename) of the private key stored on your computer. Required if private_key is not defined. For details on how to create and configure keys see https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#two and https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#three"
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint for the key pair being used. To get the value, see https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#four"
}

variable "region" {
  type        = string
  description = "An OCI region. See https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm#top"
}

variable "compartment_ocid" {
  type = string
}

variable "config_file_profile" {
  type        = string
  description = "The profile name if you would like to use a custom profile in the OCI config file to provide the authentication credentials. See https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm#terraformproviderconfiguration_topic-SDK_and_CLI_Config_File"
}

variable "ssh_public_key" {
  type        = string
  description = "An SSH public key for use with a virtual machine."
}

variable "instance_shape" {
  type        = string
  description = "An OCI instance type."
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  type        = number
  description = "Number of vCPUs to use for a given instance."
  default     = 1
}

variable "instance_shape_config_memory_in_gbs" {
  type        = number
  description = "RAM quantity to assign to a given instance."
  default     = 6
}
