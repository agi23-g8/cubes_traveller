using System;
using UnityEngine;

public class SkyboxController : MonoBehaviour
{
    public Material skybox;

    public bool dayNightCycleEnabled = true;

    [SerializeField, Range(1.0f, 20.0f)]
    private float timeScale = 1.0f;

    [Header("Sun Settings")]

    public Light sun;
    public Gradient skyDayColor;
    public Gradient fogDayColor;

    public float sunIntensityFactor = 1.5f;

    public int sunNoonTemperature = 6500;
    public int sunSetTemperature = 2000;

    [Header("Moon Settings")]

    public Light moon;
    public Gradient skyNightColor;
    public Gradient fogNightColor;

    public float moonIntensityFactor = 1.5f;

    [Header("Debug (do not edit)")]

    [SerializeField] private float n_time;
    [SerializeField] private bool day;
    [SerializeField] private bool night;

    [SerializeField] private float s_intensity;
    [SerializeField] private float m_intensity;

    private void Update()
    {
        if (!dayNightCycleEnabled)
        {
            return;
        }

        UpdateSunAndMoon();

        if (day)
        {
            n_time = sun.transform.rotation.eulerAngles.x / 90f;
            n_time = Mathf.Clamp(n_time, 0, 1);
            UpdateSkyDayColor();
        }
        else if (night)
        {
            n_time = moon.transform.rotation.eulerAngles.x / 90f;
            n_time = Mathf.Clamp(n_time, 0, 1);
            UpdateSkyNightColor();
        }
    }

    private void UpdateSunAndMoon()
    {
        sun.transform.Rotate(Time.deltaTime * timeScale, 0, 0);
        moon.transform.Rotate(Time.deltaTime * timeScale, 0, 0);

        if (sun.transform.rotation.eulerAngles.x < 90)
        {
            day = true;
            night = false;

            float theta = sun.transform.rotation.eulerAngles.x;
            s_intensity = Mathf.Sin(Mathf.Deg2Rad * theta) * sunIntensityFactor;
            sun.intensity = s_intensity;

            float temperature = sunSetTemperature + (sunNoonTemperature - sunSetTemperature) * s_intensity;
            sun.colorTemperature = temperature;
        }

        if (moon.transform.rotation.eulerAngles.x < 90)
        {
            day = false;
            night = true;

            float theta = moon.transform.rotation.eulerAngles.x;
            m_intensity = Mathf.Clamp(Mathf.Sin(Mathf.Deg2Rad * theta), 0, 0.5f) * moonIntensityFactor;
            moon.intensity = m_intensity;
        }
    }

    private void UpdateSkyDayColor()
    {
        Color sky = skyDayColor.Evaluate(n_time);
        Color fog = fogDayColor.Evaluate(n_time);
        skybox.SetColor("_SkyColor", sky);
        skybox.SetColor("_FogColor", fog);
    }

    private void UpdateSkyNightColor()
    {
        Color sky = skyNightColor.Evaluate(n_time);
        Color fog = fogNightColor.Evaluate(n_time);
        skybox.SetColor("_SkyColor", sky);
        skybox.SetColor("_FogColor", fog);
    }
}
