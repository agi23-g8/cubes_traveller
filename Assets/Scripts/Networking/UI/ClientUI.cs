using System.Collections;
using System.Collections.Generic;
using Unity.Netcode;
using UnityEngine;

public class ServerBrowser : MonoBehaviour
{
    [SerializeField]
    NetworkManager networkManager;

    [SerializeField]
    private GameObject serverBrowser;

    [SerializeField]
    private GameObject disconnectButton;


    void Update()
    {
        serverBrowser.SetActive(!networkManager.IsConnectedClient);
        disconnectButton.SetActive(networkManager.IsConnectedClient);
    }
}
