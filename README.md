# ucarp-docker

Share a virtual IP with hosts running docker.

## Environment variables

| Name | Required | Default value | Description
|---|---|---|---|
| VIP | Yes |  | The virtual IP shared by the hosts. |
| HOST_IP | Yes |  | The IP of the host's interface on the same network as the VIP. |
| VHID | NO | 10 | The ID of the virtual server advertised by CARP. |
| PASSWORD | NO | ucarp | The password to protect CARP from rogue advertisements. |
| DEV_NAME | NO |  | The interface name where the VIP is configured. This is identified using HOST_IP. |
| CIDR | NO |  | The CIDR of the network where the VIP is configured. This is identified using HOST_IP. |

## Deploy with docker swarm

See `docker-compose.yml` for example deployment.

Docker swarm does not support privileged capabilities to be added to the deployment. Therefore each container in the deployment has a mount to `/var/run/docker.sock` and launches another with container with the required `NET_ADMIN` capabilities.

`node1` and `node2` correspond to nodes in a docker swarm. Assign each node a label to ensure the container is deployed to the correct system.

```bash
docker node update --label-add ucarp=node1 node1
docker node update --label-add ucarp=node2 node2
```

Then start the stack.
```bash
docker stack deploy -c docker-compose.yml ucarp
```

You will see two containers running on each node. One for the swarm stack and another launched with the required capabilities to configure with the hosts interfaces. This second container runs the ucarp process and will be removed when the swarm service is stopped or removed.

```bash
docker service ls
```

```
ID             NAME                 MODE      REPLICAS   IMAGE                          PORTS
tcmhhhhrt44b   ucarp_node1        global    1/1        nickadam/ucarp-docker:v1.0.0
h226xr2en0d1   ucarp_node2        global    1/1        nickadam/ucarp-docker:v1.0.0
```

```bash
docker ps
```

```
# node 1
CONTAINER ID   IMAGE                                 COMMAND                  CREATED          STATUS          PORTS     NAMES
1d801cde3dd9   nickadam/ucarp-docker:v1.0.0          "tini -- ucarp --int…"   25 minutes ago   Up 25 minutes             ucarp-node1-10
ef2497b32081   nickadam/ucarp-docker:v1.0.0          "tini /docker-entryp…"   25 minutes ago   Up 25 minutes             ucarp_node1.xuce688r805f8viybfeb5uw8f.7t56s7j9yr1irga78frnsgy3b

# node 2
CONTAINER ID   IMAGE                                 COMMAND                  CREATED          STATUS          PORTS     NAMES
733383fb8f9c   nickadam/ucarp-docker:v1.0.0          "tini -- ucarp --int…"   24 minutes ago   Up 24 minutes             ucarp-node2-10
3959d5e482e5   nickadam/ucarp-docker:v1.0.0          "tini /docker-entryp…"   24 minutes ago   Up 24 minutes             ucarp_node2.80w0yvnwt53t24albji65xicu.27xhwxkj53yqz4d98g9xyfl3k
```

## Or just run ucarp

Alernatively, this is a container with ucarp and some scripts, so you can just run ucarp direcly on whatever docker hosts you want. Just keep in mind you need the required `NET_ADMIN` capability to make changes to interfaces.

```bash
# node 1
docker run -d --rm \
  --network=host \
  --cap-add=NET_ADMIN \
  --entrypoint tini \ # override entrypoint to prevent script from running
  --env CIDR=24 \     # your networks CIDR
  nickadam/ucarp-docker:v1.0.0 \
  -- ucarp --interface=eth0 \ # your host's interface name
    --srcip=10.10.10.10 \     # your host's IP address
    --vhid=10 \               # the virtual server ID
    --pass=password \         # the shared password for CARP advertisements
    --addr=10.10.10.12 \      # the shared virtual IP
    --upscript=/vip-up.sh \
    --downscript=/vip-down.sh \
    --shutdown

# node 2
docker run -d --rm \
  --network=host \
  --cap-add=NET_ADMIN \
  --entrypoint tini \ # override entrypoint to prevent script from running
  --env CIDR=24 \     # your networks CIDR
  nickadam/ucarp-docker:v1.0.0 \
  -- ucarp --interface=eth0 \ # your host's interface name
    --srcip=10.10.10.11 \     # your host's IP address
    --vhid=10 \               # the virtual server ID
    --pass=password \         # the shared password for CARP advertisements
    --addr=10.10.10.12 \      # the shared virtual IP
    --upscript=/vip-up.sh \
    --downscript=/vip-down.sh \
    --shutdown
```
