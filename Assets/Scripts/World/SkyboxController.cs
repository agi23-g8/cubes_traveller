using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SkyboxController : MonoBehaviour
{
    public Light sun;
    public Light moon;

    [SerializeField, Range(0, 24)]
    private float timeOfDay = 9.0f;

    [SerializeField, Range(1.0f, 3600.0f)]
    private float timeScale = 1.0f;

    [SerializeField, Range(0.0f, 10.0f)]
    private float sunIntensity = 1.0f;

    [SerializeField, Range(0.0f, 10.0f)]
    private float moonIntensity = 1.0f;

    public AnimationCurve sunCurve;
    public AnimationCurve moonCurve;

    public bool dayNightCycleEnabled = true;

    private void Start()
    {
        // update once to set initial values
        UpdateSunAndMoon();
    }

    private void Update()
    {
        if (!dayNightCycleEnabled)
        {
            return;
        }

        UpdateSunAndMoon();
    }

    private void UpdateSunAndMoon()
    {
        timeOfDay += Time.deltaTime * timeScale / 3600;
        timeOfDay %= 24;

        // normalize timeOfDay to 0..1
        float n_time = timeOfDay / 24;

        sun.transform.localRotation = Quaternion.Euler(new Vector3(n_time * 360f - 90f, -30f, 0));
        moon.transform.localRotation = Quaternion.Euler(new Vector3(n_time * 360f + 90f, -30f, 0));

        sun.intensity = sunCurve.Evaluate(n_time) * sunIntensity;
        moon.intensity = moonCurve.Evaluate(n_time) * moonIntensity;
    }
}
