using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class ActionApplyForce : WorldAction, IExecuteArgument
{
    public float forceMagnitude = 1000f;

    public float yStrength = 2f;

    private Rigidbody rb;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    public override void Execute() {}

    /// <summary>
    /// Apply force to the object
    /// </summary>
    /// <param name="vec">Interactor transform position</param>
    public void Execute(Vector3 vec)
    {
        Vector3 player = vec;
        Vector3 forceDir = (transform.position - player).normalized * forceMagnitude;

        forceDir.y *= yStrength;

        rb.AddForce(forceDir, ForceMode.Impulse);

        Debug.DrawRay(transform.position, forceDir, Color.cyan, 1f);
    }
}
