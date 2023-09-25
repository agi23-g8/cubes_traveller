using System.Collections;
using System.Collections.Generic;
using Unity.Netcode;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ServerSceneManager : MonoBehaviour
{
    NetworkManager networkManager;


    void Awake()
    {
        // prevent duplicates
        if (FindObjectsOfType<ServerSceneManager>().Length > 1)
        {
            Debug.Log("Destroying this clone", gameObject);
            Destroy(gameObject);
        }
        else
        {
            DontDestroyOnLoad(gameObject);
        }
    }

    void Start()
    {
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
