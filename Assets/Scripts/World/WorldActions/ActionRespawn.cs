using UnityEngine;

public class ActionRespawn : WorldAction
{
    public Transform spawnPoint;
    private Rigidbody rb;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    public override void Execute()
    {
        transform.position = spawnPoint.position;

        if (rb != null)
        {
            rb.velocity = Vector3.zero;
        }

        Debug.Log("Respawned");
    }
}
