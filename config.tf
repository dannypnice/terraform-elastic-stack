# Configure the Docker provider
provider "docker" {
  host = "tcp://127.0.0.1:2375/"
}

variable "elasticsearch_rest_ports" {
  default = {
    "0" = "9200"
    "1" = "9201"
    "2" = "9202"
  }
}

variable "elasticsearch_transport_ports" {
  default = {
    "0" = "9300"
    "1" = "9301"
    "2" = "9302"
  }
}

variable "elasticsearch_hostnames" {
  default = {
    "0" = "elasticsearch01"
    "1" = "elasticsearch02"
    "2" = "elasticsearch03"
  }
}

resource "docker_network" "private_network" {
  name = "elastic_network"
}

# Create ES Cluster
resource "docker_container" "elasticsearch" {
  count        = 3
  image        = "docker.elastic.co/elasticsearch/elasticsearch:6.2.4"
  name         = "${lookup(var.elasticsearch_hostnames, count.index)}"
  network_mode = "bridge"
  networks     = ["${docker_network.private_network.name}"]

  env = [
    "cluster.name=nicemonitoring",
    "discovery.zen.minimum_master_nodes=2",
    "ELASTIC_PASSWORD=MagicWord",
    "discovery.zen.ping.unicast.hosts=${lookup(var.elasticsearch_hostnames, 0)},${lookup(var.elasticsearch_hostnames, 1)},${lookup(var.elasticsearch_hostnames, 2)}",
  ]

  ports = [
    {
      internal = 9200
      external = "${lookup(var.elasticsearch_rest_ports, count.index)}"
    },
    {
      internal = 9300
      external = "${lookup(var.elasticsearch_transport_ports, count.index)}"
    },
  ]
}

resource "docker_container" "kibana" {
  image        = "docker.elastic.co/kibana/kibana:6.2.4"
  name         = "kibana"
  network_mode = "bridge"
  networks     = ["${docker_network.private_network.name}"]

  env = [
    "ELASTICSEARCH_URL=http://${lookup(var.elasticsearch_hostnames, 0)}:9200",
  ]

  ports = [
    {
      internal = 5601
      external = 5601
    },
  ]
}
