using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SkyboxController : MonoBehaviour
{
    public Material skybox;

    public Light sun;
    public Light moon;

    public Transform sunAndMoon;

    [SerializeField, Range(0, 24)]
    private float timeOfDay = 9.0f;

    [SerializeField, Range(1.0f, 3600.0f)]
    private float timeScale = 1.0f;

    public bool dayNightCycleEnabled = true;

    public Gradient skyColor;
    public Gradient fogColor;
    public Gradient sunColor;

    public int sunNoonTemperature = 6500;
    public int sunSetTemperature = 2000;

    public AnimationCurve sunIntensity;

    [Header("Debug")]

    [SerializeField]
    private float n_time = 0.5f;

    private void Start()
    {
        // update once to set initial values
        UpdateSky();
    }

    private void Update()
    {
        if (!dayNightCycleEnabled)
        {
            return;
        }

        UpdateSky();
    }

    private void UpdateSky()
    {
        timeOfDay += Time.deltaTime * timeScale / 3600;
        timeOfDay %= 24;

        // normalize timeOfDay to 0..1
        // n_time | day/night
        // 0      | night
        // 0.25   | morning
        // 0.5    | noon
        // 0.75   | evening
        // 1      | night
        n_time = timeOfDay / 24;

        Color sky = skyColor.Evaluate(n_time);
        Color fog = fogColor.Evaluate(n_time);
        skybox.SetColor("_SkyColor", sky);
        skybox.SetColor("_FogColor", fog);

        UpdateSunAndMoon(n_time);
    }

    private void UpdateSunAndMoon(float n_time)
    {
        // n_time | rotation
        // 0      | 180
        // 0.25   | 90
        // 0.5    | 0
        // 0.75   | -90
        // 1      | -180
        sunAndMoon.rotation = Quaternion.Euler(180 - n_time * 360, 0, 0);

        float si = sunIntensity.Evaluate(n_time);
        sun.intensity = si;
    }
}
