using System.Net.NetworkInformation;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
[ExecuteAlways]
public class CubeGravity : MonoBehaviour
{
    [Header("Main Cube transform")]
    public Transform cubeTransform;

    public LayerMask layerMask;

    private Rigidbody rb;
    
    private void Start()
    {
        rb = GetComponent<Rigidbody>();

        if (cubeTransform == null)
        {
            Debug.Log("CubeGravity: cubeTransform is null, using parent transform");
            cubeTransform = transform.parent;
        }
    }

    private void Update()
    {
        ApplyCubeGravity();
    }

    private void ApplyCubeGravity()
    {
        Vector3 rayDir = cubeTransform.position - transform.position;
        Vector3 currentNormal = transform.up;

        RaycastHit hit;
        if (Physics.Raycast(transform.position, rayDir, out hit, Mathf.Infinity, layerMask))
        {
            currentNormal = hit.normal + hit.point;
            Debug.DrawLine(hit.normal + hit.point, hit.point, Color.green);
        }

        rb.AddForce(currentNormal * -9.81f, ForceMode.Acceleration);

        Debug.DrawRay(transform.position, transform.position + currentNormal * -9.81f, Color.red);
    }
}
