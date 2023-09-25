using System.Collections;
using System.Collections.Generic;
using Unity.Netcode;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ServerSceneManager : MonoBehaviour
{

    NetworkManager networkManager;


    private IEnumerator Start()
    {
        // wait for the network manager to be initialized
        while (NetworkManager.Singleton == null)
            yield return null;

        // prevent duplicates
        if (GetComponent<NetworkManager>() != NetworkManager.Singleton)
        {
            Debug.Log("Destroying this clone", gameObject);
            Destroy(gameObject, 5f);
        }

        networkManager = GetComponent<NetworkManager>();
    }

    // Update is called once per frame
    void Update()
    {
        // when the client is connected, load the scene
        if (networkManager.ConnectedClientsList.Count > 0 && SceneManager.GetActiveScene().buildIndex == 0)
        {
            SceneManager.LoadScene(1);
        }
        else if (SceneManager.GetActiveScene().buildIndex == 1 && networkManager.ConnectedClientsList.Count == 0)
        {
            SceneManager.LoadScene(0);
        }
    }
}
