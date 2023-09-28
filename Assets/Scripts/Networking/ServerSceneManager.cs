using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using Unity.Netcode;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class ServerSceneManager : MonoBehaviour
{
    NetworkManager networkManager;

    public Image fadeOutUIImage;
    public float fadeSpeed = 0.8f;

    private bool isLoadingScene = false;

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
        if (networkManager.IsServer && networkManager.ConnectedClientsList.Count > 0 && SceneManager.GetActiveScene().buildIndex == 0)
        {
            if (!isLoadingScene)
            {
                StartCoroutine(FadeAndLoadScene(1));
            }

        }
        else if (SceneManager.GetActiveScene().buildIndex == 1 && networkManager.ConnectedClientsList.Count == 0)
        {
            if (!isLoadingScene)
            {
                StartCoroutine(FadeAndLoadScene(0));
            }
        }
    }

    public enum FadeDirection
    {
        In, //Alpha = 1
        Out // Alpha = 0
    }

    private IEnumerator Fade(FadeDirection fadeDirection)
    {
        float alpha = (fadeDirection == FadeDirection.Out) ? 0 : 1;
        if (fadeDirection == FadeDirection.Out)
        {
            fadeOutUIImage.enabled = true;
            while (alpha <= 1)
            {
                alpha += Time.deltaTime * (1.0f / fadeSpeed);
                fadeOutUIImage.color = new Color(fadeOutUIImage.color.r, fadeOutUIImage.color.g, fadeOutUIImage.color.b, alpha);
                yield return null;
            }
        }
        else
        {
            while (alpha > 0)
            {
                alpha -= Time.deltaTime * (1.0f / fadeSpeed);
                fadeOutUIImage.color = new Color(fadeOutUIImage.color.r, fadeOutUIImage.color.g, fadeOutUIImage.color.b, alpha);
                yield return null;
            }
            fadeOutUIImage.enabled = false;

        }

    }

    public IEnumerator FadeAndLoadScene(int sceneToLoad)
    {
        isLoadingScene = true;
        AsyncOperation async = SceneManager.LoadSceneAsync(sceneToLoad);
        async.allowSceneActivation = false;
        yield return Fade(FadeDirection.Out);
        while (!async.isDone && fadeOutUIImage.color.a < 1)
        {
            yield return null;
        }
        async.allowSceneActivation = true;
        yield return new WaitForSeconds(1);
        yield return Fade(FadeDirection.In);
        isLoadingScene = false;
    }

}
