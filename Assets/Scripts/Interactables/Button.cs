using UnityEngine;

[RequireComponent(typeof(Collider))]
public class Button : MonoBehaviour, IInteractable
{
    [SerializeField]
    private string interactionText;
    public string InteractionText => interactionText;

    [SerializeField]
    private string displayText;
    public string DisplayText => displayText;

    public bool OnInteract(PlayerInteractor interactor)
    {
        Debug.Log(interactionText);
        return true;
    }
}
