using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.Netcode;
using UnityEngine;

public class HostUI : MonoBehaviour
{
    [SerializeField]
    GameObject startHostDialog;

    [SerializeField]
    GameObject waitingForClientDialog;

    [SerializeField]
    TMP_InputField serverNameInput;

    [SerializeField]
    ServerNetworkDiscovery networkDiscovery;

    [SerializeField]
    NetworkManager networkManager;




    void Update()
    {
        startHostDialog.SetActive(!networkManager.IsServer);
        waitingForClientDialog.SetActive(networkManager.IsServer && networkManager.ConnectedClients.Count == 0);

        if (Input.GetButton("Interact"))
        {
            StartDiscovery();
        }

    }

    public void StartDiscovery()
    {
        // start the network discovery
        networkDiscovery.ServerName = serverNameInput.text;
        networkManager.StartServer();
    }

    public void CancelDiscovery()
    {
        networkDiscovery.StopDiscovery();
        networkManager.Shutdown();
    }
}
