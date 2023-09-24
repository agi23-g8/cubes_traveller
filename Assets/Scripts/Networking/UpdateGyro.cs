using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using Unity.Netcode;
using UnityEngine;

public class UpdateGyro : NetworkBehaviour
{

    NetworkObject networkObject;

    public override void OnNetworkSpawn()
    {
        if (IsClient)
        {
            Input.gyro.enabled = true;
            RecalibrateGyroServerRpc();
        }
    }

    void Start()
    {
        if (!IsClient)
        {
            networkObject = GetComponent<NetworkObject>();
            networkObject.Spawn();
        }

    }

    void Update()
    {
        if (IsClient)
        {
            // send the gyro data to the server
            UpdateGyroServerRpc(Input.gyro.attitude);
        }
    }

    [ServerRpc(RequireOwnership = false)]
    public void UpdateGyroServerRpc(Quaternion gyro, ServerRpcParams rpcParams = default)
    {
        transform.rotation = gyro;
    }

    [ServerRpc(RequireOwnership = false)]
    public void RecalibrateGyroServerRpc()
    {
        Debug.Log("Recalibrating gyro requested");
        FindObjectOfType<GyroscopeController>().RecalibrateGyro();
    }

}
