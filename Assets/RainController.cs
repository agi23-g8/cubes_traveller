using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class RainController : MonoBehaviour
{

    [SerializeField]
    Transform cubeTransform;

    [SerializeField]
    Collider[] shouldRainAbove;

    [SerializeField]
    int maxRateOverTime = 100;

    private ParticleSystem rainParticleSystem;
    void Start()
    {
        rainParticleSystem = GetComponent<ParticleSystem>();
    }

    // Update is called once per frame
    void Update()
    {
        var emission = rainParticleSystem.emission;

        // raycast from the particle system to the cube origin
        // if we hit one of the colliders, we should rain above the cube
        float closestDistance = float.MaxValue;
        Vector3 normal = Vector3.zero;
        Vector3 rayDir = cubeTransform.position - transform.position;
        RaycastHit[] hits = Physics.RaycastAll(transform.position, rayDir, rayDir.magnitude);
        Debug.DrawRay(transform.position, rayDir, Color.red);
        foreach (var hit in hits)
        {
            // if collider is in the list of colliders we should rain above
            if (System.Array.IndexOf(shouldRainAbove, hit.collider) != -1)
            {
                // if the distance is smaller than the closest distance we have seen so far
                if (hit.distance < closestDistance)
                {
                    // update the closest distance and the normal of the face we hit
                    closestDistance = hit.distance;
                    normal = hit.normal;
                }
            }
        }


        if (normal != Vector3.zero)
        {
            // rain above the cube
            // depending on the dot product between the vector from the particle system to the cube origin and the normal of the face we hit
            // we can determine the amount of rain we should spawn
            float dot = Vector3.Dot(-rayDir.normalized, normal);
            int rainCount = (int)(dot * maxRateOverTime);

            emission.rateOverTime = rainCount;
        }
        else
        {
            // don't rain
            emission.rateOverTime = 0;
        }

    }
}
