using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GyroscopeController : MonoBehaviour
{
    private bool isPositionLocked = false;
    private Vector2 touchStartPosition;
    public float rotationSpeed = 1.0f;
    public Transform rotationAnchor;

    private float lastTapTime = 0;
    private int lastTapFingerId = -1;

    void Start()
    {
        // Activate the gyroscope
        Input.gyro.enabled = true;
    }

    void Update()
    {
        // If we touch the screen
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);

            if (touch.phase == TouchPhase.Began) 
            {
                if (IsDoubleTap(touch.fingerId))
                {
                    isPositionLocked = !isPositionLocked;
                }
            }
        }

        if (isPositionLocked)
        {
            return;
        }

        // Read data for gyroscope
        Vector3 gyroRotationRate = Input.gyro.rotationRate;
        // Vector3 gyroAcceleration = Input.gyro.userAcceleration;

        // Example of a rotation
        transform.Rotate(-gyroRotationRate.x, -gyroRotationRate.z, -gyroRotationRate.y);
    }

    private bool IsDoubleTap(int fingerId)
    {
        float currentTime = Time.time;

        if (fingerId == lastTapFingerId && (currentTime - lastTapTime) < 0.5f)
        {
            lastTapTime = 0;
            lastTapFingerId = -1;
            return true;
        }

        lastTapTime = currentTime;
        lastTapFingerId = fingerId;
        return false;
    }
}