using System.Collections;
using System.Collections.Generic;
using Unity.Netcode;
using UnityEngine;

public class ServerBrowser : MonoBehaviour
{
    [SerializeField]
    NetworkManager networkManager;

    [SerializeField]
    private GameObject[] seenDuringBrowser;

    [SerializeField]
    private GameObject[] seenDuringGame;


    void Update()
    {
        foreach (GameObject obj in seenDuringBrowser)
        {
            obj.SetActive(!networkManager.IsConnectedClient);
        }

        foreach (GameObject obj in seenDuringGame)
        {
            obj.SetActive(networkManager.IsConnectedClient);
        }
    }
}
