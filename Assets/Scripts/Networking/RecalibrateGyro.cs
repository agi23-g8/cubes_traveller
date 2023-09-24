using System.Collections;
using System.Collections.Generic;
using Unity.Netcode;
using UnityEngine;

public class RecalibrateGyro : MonoBehaviour
{
    [SerializeField]
    NetworkManager networkManager;

    public void RecalibrateGyroButton()
    {
        Debug.Log("Gyro recalibration button pressed");
        if (NetworkManager.Singleton.IsClient)
        {
            FindObjectOfType<UpdateGyro>().RecalibrateGyroServerRpc();
        }
    }
}
