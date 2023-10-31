using UnityEditor;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
[ExecuteAlways]
public class CubeGravity : MonoBehaviour
{
    public float gravityMultplier = 1.0f;

    [Header("Main Cube transform")]
    public Transform cubeTransform;

    public LayerMask layerMask;

    private Rigidbody rb;

    private Vector3 currentNormal;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();

        if (cubeTransform == null)
        {
            Debug.Log("CubeGravity: cubeTransform is null, using parent transform");
            cubeTransform = transform.parent;
        }
    }

    private void FixedUpdate()
    {
        ApplyCubeGravity();
    }

    private void ApplyCubeGravity()
    {
        Vector3 rayDir = cubeTransform.position - transform.position;
        Vector3 normal = transform.up;

        Debug.DrawRay(transform.position, rayDir, Color.blue);

        RaycastHit hit;
        if (Physics.Raycast(transform.position, rayDir, out hit, Mathf.Infinity, layerMask))
        {
            normal = hit.normal;
            Debug.DrawRay(hit.point, normal, Color.green);
        }

        normal *= -1;
        currentNormal = normal;
        rb.AddForce(currentNormal * gravityMultplier, ForceMode.Force);

        Debug.DrawRay(transform.position, currentNormal, Color.red);
    }

    public Vector3 GetCurrentNormal()
    {
        return currentNormal;
    }
}
