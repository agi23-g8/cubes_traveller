
using UnityEngine;

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
