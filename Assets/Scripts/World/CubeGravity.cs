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

        Debug.DrawRay(transform.position, rayDir, Color.blue);

        RaycastHit hit;
        if (Physics.Raycast(transform.position, rayDir, out hit, Mathf.Infinity, layerMask))
        {
            currentNormal = hit.normal;
            Debug.DrawRay(hit.point, currentNormal, Color.green);
        }

        currentNormal *= -1;
        rb.AddForce(currentNormal * gravityMultplier, ForceMode.Force);

        Debug.DrawRay(transform.position, currentNormal, Color.red);
    }
}
