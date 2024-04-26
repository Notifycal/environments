provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "localstack" {
  name = "localstack/localstack:${var.docker_version}"
}

resource "docker_container" "localstack" {
  image = docker_image.localstack.image_id
  name  = var.name
  ports {
    ip       = "127.0.0.1"
    external = "4566"
    internal = "4566"
  }
  dynamic "ports" {
    for_each = range(4510, 4560)
    content {
      ip       = "127.0.0.1"
      external = ports.value
      internal = ports.value
    }
  }
  env = [
    # LocalStack configuration: https://docs.localstack.cloud/references/configuration/ 
    "DEBUG=${var.debug}"
  ]
  mounts {
    source = "/var/run/docker.sock"
    target = "/var/run/docker.sock"
    type   = "bind"
  }
  mounts {
    source = pathexpand(var.volume_dir)
    target = "/var/lib/localstack"
    type   = "bind"
  }
  restart = "unless-stopped"
}