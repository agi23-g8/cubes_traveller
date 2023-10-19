using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class LightFlicker : MonoBehaviour
{
    public float minIntensity = 0.5f; // Minimum intensity of the light
    public float maxIntensity = 1.0f; // Maximum intensity of the light
    public float flickerSpeed = 1.0f; // Flicker speed
    private Light lightComponent;
    private float originalIntensity;

    void Start()
    {
        lightComponent = GetComponent<Light>();
        originalIntensity = lightComponent.intensity;
        StartCoroutine(Flicker());
    }

    IEnumerator Flicker()
    {
        while (true)
        {
            float randomIntensity = Random.Range(minIntensity, maxIntensity);
            float currentIntensity = lightComponent.intensity;
            float t = 0;

            while (t < 1)
            {
                t += Time.deltaTime * flickerSpeed;
                lightComponent.intensity = Mathf.Lerp(currentIntensity, originalIntensity * randomIntensity, t);
                yield return null;
            }

            yield return new WaitForSeconds(Random.Range(0.1f, 0.5f)); // Add a short delay between flickers
        }
    }
}
