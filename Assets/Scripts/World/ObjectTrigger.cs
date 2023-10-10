using UnityEngine;

public class ObjectTrigger : MonoBehaviour
{
    public GameObject objectOfInterest;

    public WorldAction actionOnTrigger;

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
            Debug.Log("YOU WON!");

            if (actionOnTrigger == null)
            {
                return;
            }

            actionOnTrigger.Execute();
        }
    }
}
