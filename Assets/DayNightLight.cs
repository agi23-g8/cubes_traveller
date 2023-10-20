using UnityEngine;

[ExecuteAlways]
public class DayNightLight : MonoBehaviour
{
    public Light sun;
    public Light lampLight;

    void Start()
    {
        lampLight = GetComponent<Light>();
    }

    void Update()
    {
        bool isNight = IsNightTime();

        if (isNight)
        {
            lampLight.enabled = true;
        }
        else
        {
            lampLight.enabled = false;
        }
    }

    bool IsNightTime()
    {
        float angle = Vector3.Dot(sun.transform.forward, Vector3.down);
        if (angle < 0.06)
        {
            return true;
        }
        else return false;
    }
}
