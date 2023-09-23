using System.Collections;
using System.Collections.Generic;
using Unity.Netcode;
using UnityEngine;

public class UpdateGyro : NetworkBehaviour
{
    public override void OnNetworkSpawn()
    {
        if (IsClient)
        {
            Input.gyro.enabled = true;
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

}
