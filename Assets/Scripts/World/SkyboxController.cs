using System;
using UnityEditor.EditorTools;
using UnityEngine;

[ExecuteAlways]
public class SkyboxController : MonoBehaviour
{
    public Material skybox;

    public bool dayNightCycleEnabled = true;

    [SerializeField, Range(0.0f, 1.0f)]
    [Tooltip("0.0f = midnight, 0.5f = noon, 1.0f = midnight")]
    private float timeOfDay = 0.5f;

    [SerializeField, Range(1.0f, 120f)]
    [Tooltip("The number of seconds per day (realtime seconds)")]
    private float timeScale = 30.0f;
    public Gradient skyColor;
    public Gradient fogColor;

    [Header("Sun Settings")]

    public Light sun;
    public float sunIntensityFactor = 1.5f;
    public int sunNoonTemperature = 6500;
    public int sunSetTemperature = 2000;

    [Tooltip("The angle of the sun at noon (0 = straight up, 90 = on the horizon)")]
    public float sunAngle = 20.0f;

    [Tooltip("The path of the sun in the sky (0 = rises in the east, 90 = rises in the north)")]
    public float sunPath = 0f;

    [Header("Moon Settings")]
    public Light moon;
    public float moonIntensityFactor = 1.5f;

    private void Update()
    {

        skybox.SetColor("_SkyColor", skyColor.Evaluate(timeOfDay));
        skybox.SetColor("_FogColor", fogColor.Evaluate(timeOfDay));
        UpdateSun();
        UpdateMoon();

        // set main light to the strongest light source
        if (sun.intensity >= moon.intensity)
        {
            RenderSettings.sun = sun;
        }
        else
        {
            RenderSettings.sun = moon;
        }

        if (!dayNightCycleEnabled || !Application.isPlaying)
        {
            return;
        }
        // timeScale = 60.0f means 1 minute per in-game day
        // timeScale = 1.0f means 1 second per in-game day
        timeOfDay += Time.deltaTime / timeScale;

        if (timeOfDay > 1.0f)
        {
            timeOfDay -= 1.0f;
        }
    }

    private void UpdateSun()
    {
        float rotation = (timeOfDay - 0.5f) * 360.0f + 90.0f;
        sun.transform.rotation = Quaternion.Euler(rotation, sunPath, sunAngle);
        sun.intensity = (Vector3.Dot(sun.transform.forward, Vector3.down) + 0.5f) * sunIntensityFactor;
        sun.intensity = Mathf.Max(sun.intensity, 0.0f);
        sun.colorTemperature = Mathf.Lerp(sunSetTemperature, sunNoonTemperature, sun.intensity);
    }

    private void UpdateMoon()
    {
        float moonAngle = (timeOfDay - 0.5f) * 360.0f - 90.0f;
        moon.transform.localRotation = Quaternion.Euler(moonAngle, 0.0f, 0.0f);
        moon.intensity = Vector3.Dot(moon.transform.forward, Vector3.down) * moonIntensityFactor;
        moon.intensity = Mathf.Max(moon.intensity, 0.0f);
    }


}
