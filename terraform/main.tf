module "data_platform_dev" {
    source = "./data_platform_module"
    
    environment = "dev"
    company     = "handytec"
    project     = "data_platform"
}