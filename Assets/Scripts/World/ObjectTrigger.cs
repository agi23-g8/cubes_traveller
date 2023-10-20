using UnityEngine;

public class ObjectTrigger : MonoBehaviour
{
    public GameObject objectOfInterest;

    public WorldAction actionOnTrigger;

    public WorldAction ballRespawn;

    private void Start()
    {
        if (actionOnTrigger == null)
        {
            Debug.LogWarning("No world action set for trigger on " + gameObject.name);
        }
    }

    public void OnTriggerEnter(Collider other)
    {
        if (other.gameObject == objectOfInterest)
        {
            if (actionOnTrigger == null)
            {
                return;
            }

            actionOnTrigger.Execute();
            Invoke("Respawn", 3.0f);
        }
    }

    private void Respawn()
    {
        ballRespawn.Execute();
    }
}
