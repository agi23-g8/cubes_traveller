using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class ActionTogglePhysics : WorldAction
{
    public enum ToggleBetween
    {
        WorldAndCube,
        WorldAndFreezed,
        CubeAndFreezed
    }

    public ToggleBetween toggleBetween = ToggleBetween.WorldAndCube;

    public Transform CubeTransform;

    [Header("Current gravity (this is the initial state)")]

    [SerializeField]
    private bool worldGravity = false;

    [SerializeField]
    private bool cubeGravity = false;

    [SerializeField]
    private bool freezed = false;

    private Rigidbody rb;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    private void Update()
    {
        if (worldGravity)
        {
            // use world gravity
            rb.isKinematic = false;
        }

        else if (cubeGravity)
        {
            // use cube gravity
            rb.isKinematic = false;
            ApplyCubeGravity();
        }

        else if (freezed)
        {
            // freeze
            rb.isKinematic = true;
        }
    }

    public override void Execute()
    {
        Toggle();
    }

    private void ApplyCubeGravity()
    {
        Vector3 cubeRelativePosition = CubeTransform.InverseTransformPoint(transform.position);
        Vector3 currentPosition = CubeTransform.TransformPoint(cubeRelativePosition);

        RaycastHit hit;
        Vector3 rayDir = CubeTransform.position - currentPosition;
        Vector3 currentNormal = transform.up;
        if (Physics.Raycast(currentPosition, rayDir, out hit))
        {
            currentNormal = hit.normal;
        }

        Debug.DrawRay(currentPosition, rayDir, Color.red);

        rb.AddForce(currentNormal * -9.81f, ForceMode.Acceleration);
    }

    private void Toggle()
    {
        switch (toggleBetween)
        {
            case ToggleBetween.WorldAndCube:
                worldGravity = !worldGravity;
                cubeGravity = !cubeGravity;
                break;
            case ToggleBetween.WorldAndFreezed:
                worldGravity = !worldGravity;
                freezed = !freezed;
                break;
            case ToggleBetween.CubeAndFreezed:
                cubeGravity = !cubeGravity;
                freezed = !freezed;
                break;
        }
    }
}
