# How to retain a PV

## Steps to retain PersistentVolume

1. Save the `StatefulSet` and `PersistentVolumenClaim` as yaml file

    ```sh
    kubectl get sts <stsname> -o yaml > sts.yaml
    kubectl get pvc <pvcname> -o yaml > pvc.yaml
    ```

1. Patch the PersistentVolume persistentVolumeReclaimPolicy and set it to Retain

    ```sh
    kubectl patch pv <pvcname> -p "{\"spec\":{\"persistentVolumeReclaimPolicy\":\"Retain\"}}"
    ```

1. Delete the `StatefulSet` and `PersistentVolumeClaim`

    ```sh
    kubectl delete sts <stsname>
    kubectl delete pvc <pvcname>
    ```

    The status of the `PersistentVolume` will change to `Released` but you still won't be able to bind to it.

1. Now you have 2 options.

    * **Option 1.** Update the `volumeClaimTemplates` in the `StatefulSet` and set the `volumeName` to the name of the `PersistentVolume`.

    * **Option 2.** Update the `PersistentVolumeClaim` file (`pvc.yaml`) and set the `volumeName` to the name of the `PersistentVolume`.

    **Option 1**. Update the `StatefulSet`

      1. Update the `StatefulSet` file (`sts.yaml`) and set the `volumeName` field to the `PersistentVolume` name.

          ```sh
          kubectl patch -f sts.yaml -o yaml --dry-run=client --local=true --type=json -p '[{"op":"add","path":"/spec/volumeClaimTemplates/0/spec/volumeName","value":"<pvname>"}]' > sts-patched.yaml
          ```

      1. Deploy the StatefulSet

          ```sh
          kubectl apply -f sts-patched.yaml
          ```

          Status of the `PersistentVolume` will change to `Pending` but you still won't be able to bind to it until you remove the `claimRef`.

    **Option 2**. Update the `PersistentVolumeClaim`

      1. Update the `PersistentVolumeClaim` file (`pvc.yaml`) and set the `volumeName` field to the `PersistentVolume` name.

          ```sh
          kubectl patch -f pvc.yaml -o yaml --dry-run=client --local=true --type=json -p '[{"op":"add","path":"/spec/volumeName","value":"<pvname>"}]' > pvc-patched.yaml
          ```

      1. Deploy the `PersistentVolumeClaim`

          ```sh
          kubectl apply -f pvc-patched.yaml
          ```

          Status of the `PersistentVolume` will change to `Pending` but you still won't be able to bind to it until you remove the `claimRef`.

1. Patch the `PersistentVolume` to remove the `claimRef` from it

    ```sh
    kubectl patch pv <pvname> --type json -p '[{"op": "remove", "path": "/spec/claimRef"}]'
    ```

    Status of the `PersistentVolume` will change to `Bound`.
