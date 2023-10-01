using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class CloudSpawner : MonoBehaviour
{

    [SerializeField]
    private GameObject cloudPrefab;

    [SerializeField]
    private int maxClouds;

    [SerializeField]
    private float cloudSpawnHeight;

    [SerializeField]
    private float cloudHeightVariation;

    [SerializeField]
    private float cloudSpawnRadius;

    [SerializeField]
    private float cloudSpeed;

    [SerializeField]
    private float cloudSpeedVariation;

    [SerializeField]
    private float cloudScaleVariation;

    [SerializeField]
    private float despawnDistance;

    private Vector3 majorWindDirection;
    private Vector3 minorWindDirection;

    void Start()
    {
        majorWindDirection = new Vector3(Random.Range(-1f, 1f), 0, Random.Range(-1f, 1f)).normalized;
        minorWindDirection = new Vector3(Random.Range(-1f, 1f), 0, Random.Range(-1f, 1f)).normalized;
    }

    void Update()
    {
        DespawnClouds();
        SpawnClouds();

        majorWindDirection = Vector3.RotateTowards(majorWindDirection, new Vector3(Random.Range(-1f, 1f), 0, Random.Range(-1f, 1f)).normalized, 0.01f * Time.deltaTime, 0);
        minorWindDirection = Vector3.RotateTowards(minorWindDirection, new Vector3(Random.Range(-1f, 1f), 0, Random.Range(-1f, 1f)).normalized, 0.01f * Time.deltaTime, 0);
    }

    private void SpawnClouds()
    {
        for (int i = 0; i < maxClouds; i++)
        {

            if (transform.childCount < maxClouds)
            {
                GameObject cloud = Instantiate(cloudPrefab, transform);
                cloud.transform.position = new Vector3(Random.Range(-cloudSpawnRadius, cloudSpawnRadius), cloudSpawnHeight + Random.Range(-cloudHeightVariation, cloudHeightVariation), Random.Range(-cloudSpawnRadius, cloudSpawnRadius));

                cloud.transform.position = transform.position.normalized * cloudSpawnRadius + cloud.transform.position;
                cloud.transform.position = new Vector3(cloud.transform.position.x, cloudSpawnHeight + Random.Range(-cloudHeightVariation, cloudHeightVariation), cloud.transform.position.z);
                cloud.transform.localScale = Vector3.zero;
                StartCoroutine(ResizeCloud(cloud, Random.Range(0.5f, 1.5f), 5f));
                StartCoroutine(MoveCloud(cloud));
            }

        }

    }

    IEnumerator DespawnClouds()
    {
        for (int i = 0; i < transform.childCount; i++)
        {
            GameObject cloud = transform.GetChild(i).gameObject;
            if (cloud.transform.position.magnitude > despawnDistance)
            {
                StartCoroutine(ResizeCloud(cloud, 0, 1f));
                yield return new WaitForSeconds(1f);
                Destroy(cloud);
            }
        }
    }


    IEnumerator ResizeCloud(GameObject cloud, float targetScale, float duration)
    {
        float startScale = cloud.transform.localScale.x;
        float startTime = Time.time;
        while (Time.time < startTime + duration)
        {
            float t = (Time.time - startTime) / duration;
            cloud.transform.localScale = Vector3.one * Mathf.Lerp(startScale, targetScale, t);
            yield return new WaitForEndOfFrame();
        }
        cloud.transform.localScale = Vector3.one * targetScale;
    }

    IEnumerator MoveCloud(GameObject cloud)
    {
        while (true)
        {
            if (cloud == null)
            {
                break;
            }
            cloud.transform.position += (majorWindDirection + minorWindDirection * Mathf.Sin(Time.time * 0.5f)) * cloudSpeed * Time.deltaTime;
            yield return new WaitForEndOfFrame();
        }
    }


}
