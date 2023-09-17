using UnityEngine;

/// <summary>
/// This allows a game object to act as an interactor for Interactable objects.
/// Attach this script to an empty game object.
/// </summary>
[RequireComponent(typeof(Collider))]
public class Interactor : MonoBehaviour
{
    private IInteractable interactWith;

    private void Start()
    {
        interactWith = null;
    }

    public void Update()
    {
        if (interactWith == null)
        {
            return;
        }

        // TODO: Other input methods
        if (Input.GetButtonDown("Interact"))
        {
            bool result = interactWith.OnInteract(this);
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        var interactable = other.GetComponent<IInteractable>();
        if (interactable == null)
        {
            return;
        }

        interactWith = interactable;
    }

    private void OnTriggerExit(Collider other)
    {
        var interactable = other.GetComponent<IInteractable>();
        if (interactable == null)
        {
            return;
        }

        interactWith = null;
    }
}
