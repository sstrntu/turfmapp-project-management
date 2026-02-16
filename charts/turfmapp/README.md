# TURFMAPP Helm Chart

[TURFMAPP](https://github.com/turfmapp/turfmapp) is a project management application, and this is a Helm Chart to make it easier to deploy to K8s.

## Issues

By using the Bitnami chart for PostgreSQL, there is an issue where once deployed, if trying to use a different password then it will be ignored as the Persistant Volume (PV) will already exist with the previous password. See warning from Bitnami below:

> **Warning!** Setting a password will be ignored on new installation in the case when previous Posgresql release was deleted through the helm command. In that case, old PVC will have an old password, and setting it through helm won't take effect. Deleting persistent volumes (PVs) will solve the issue. Refer to [issue 2061](https://github.com/bitnami/charts/issues/2061) for more details

If you want to fully uninstall this chart including the data, follow [these steps](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/README.md#uninstalling-the-chart) from the Bitnami Chart's docs.

## Usage

## Local Building and Using the Chart

The basic usage of the chart can be found below:

```bash
git clone https://github.com/turfmapp/turfmapp.git
cd turfmapp/charts/turfmapp
helm dependency build
export SECRETKEY=$(openssl rand -hex 64)
helm install turfmapp . --set secretkey=$SECRETKEY  \
--set admin_email="demo@demo.demo"  \
--set admin_password="demo"  \
--set admin_name="Demo Demo" \
--set admin_username="demo"
```

> **NOTE:** The command `openssl rand -hex 64` is needed to create a random hexadecimal key for TURFMAPP. On Windows you can use Git Bash to run that command.

To access TURFMAPP you can port forward using the following command:

```bash
kubectl port-forward $POD_NAME 3000:1337
```

### Accessing Externally

To access TURFMAPP externally you can use the following configuration

```bash
# HTTP only
helm install turfmapp . --set secretkey=$SECRETKEY \
--set admin_email="demo@demo.demo"  \
--set admin_password="demo"  \
--set admin_name="Demo Demo" \
--set admin_username="demo" \
--set ingress.enabled=true \
--set ingress.hosts[0].host=turfmapp.example.dev \

# HTTPS
helm install turfmapp . --set secretkey=$SECRETKEY \
--set admin_email="demo@demo.demo"  \
--set admin_password="demo"  \
--set admin_name="Demo Demo" \
--set admin_username="demo" \
--set ingress.enabled=true \
--set ingress.hosts[0].host=turfmapp.example.dev \
--set ingress.tls[0].secretName=turfmapp-tls \
--set ingress.tls[0].hosts[0]=turfmapp.example.dev \
```

or create a values.yaml file like:

```yaml
secretkey: "<InsertSecretKey>"
# The admin section needs to be present for new instances of TURFMAPP, after the first start you can remove the lines starting with admin_. If you want the admin user to be unchangeable admin_email: has to stay
# After changing the config you have to run ```helm upgrade  turfmapp . -f values.yaml```

# Admin user
admin_email: "demo@demo.demo" # Do not remove if you want to prevent this user from being edited/deleted
admin_password: "demo"
admin_name: "Demo Demo"
admin_username: "demo"
# Admin user

# Ingress
ingress:
  enabled: true
  hosts:
    - host: turfmapp.example.dev
      paths:
        - path: /
          pathType: ImplementationSpecific

# Needed for HTTPS
  tls:
   - secretName: turfmapp-tls # existing TLS secret in k8s
     hosts:
       - turfmapp.example.dev
```

```bash
helm install turfmapp . -f values.yaml
```

### Things to consider if production hosting

If you want to host TURFMAPP for more than just playing around with, you might want to do the following things:

- Create a `values.yaml` with your config, as this will make applying upgrades much easier in the future.
- Create your `secretkey` once and store it either in a secure vault, or in your `values.yaml` file so it will be the same for upgrading in the future.
- Specify a password for `postgresql.auth.password` as there have been issues with the postgresql chart generating new passwords locking you out of the data you've already stored. (see [this issue](https://github.com/bitnami/charts/issues/2061))
