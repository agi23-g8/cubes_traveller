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

    private Quaternion initialRotation;
    private Quaternion initialGyroRotation;

    private Quaternion targetRotation;

    void Start()
    {
        Input.gyro.enabled = true;
        initialRotation = transform.rotation;
        initialGyroRotation = GyroToUnity(Input.gyro.attitude);
        Input.gyro.updateInterval = 0.001f;
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

        // Read data from gyroscope
        Quaternion gyroAttitude = Input.gyro.attitude;
        gyroAttitude = initialRotation * Quaternion.Inverse(initialGyroRotation) * GyroToUnity(gyroAttitude);

        // make it camera relative
        gyroAttitude = Camera.main.transform.rotation * gyroAttitude;
        gyroAttitude = gyroAttitude * Quaternion.Inverse(Camera.main.transform.rotation);
        targetRotation = gyroAttitude;
        transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * rotationSpeed);

    }

    private static Quaternion GyroToUnity(Quaternion q)
    {
        return new Quaternion(q.x, q.z, q.y, -q.w);
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