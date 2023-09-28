using System.Collections;
using System.Collections.Generic;
using Unity.Netcode;
using UnityEditor.UIElements;
using UnityEngine;
using UnityEngine.Video;

public class CameraMenuRotation : MonoBehaviour
{
    [SerializeField]
    private Transform cube;

    [SerializeField]
    private float rotationSpeed = 10f;

    void FixedUpdate()
    {
        transform.RotateAround(cube.position, Vector3.up, -rotationSpeed * Time.fixedDeltaTime);
    }
}
