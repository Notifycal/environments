resource "docker_image" "nginx" {
  count = var.expose_frontend ? 1 : 0
  name  = "nginx:stable-alpine"
}

resource "docker_container" "nginx" {
  count = var.expose_frontend ? 1 : 0
  image = docker_image.nginx[0].image_id
  name  = "frontend_reverse_proxy"
  ports {
    external = "5173"
    internal = "5173"
  }
  volumes {
    host_path      = abspath("${path.module}/config/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
  }
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.localstack_network.name
  }
  restart = "unless-stopped"
  lifecycle {
    ignore_changes = [
      ports # To avoid forced replacement. Mind, if you are planning to change the port, make sure you comment out this from here.
    ]
  }
}
