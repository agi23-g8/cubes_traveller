using UnityEngine;

[RequireComponent(typeof(Collider))]
public class Button : MonoBehaviour, IInteractable
{
    [SerializeField]
    private string interactionText;
    public string InteractionText => interactionText;

    [SerializeField]
    private GameObject tooltip;
    public GameObject UITooltip => tooltip;

    private void Start()
    {
        ToggleTooltip(false);
    }

    public bool OnInteract(Interactor interactor)
    {
        Debug.Log(interactionText);
        return true;
    }

    private void OnTriggerEnter(Collider other)
    {
        ToggleTooltip(true);
    }

    private void OnTriggerExit(Collider other)
    {
        ToggleTooltip(false);
    }

    private void ToggleTooltip(bool show)
    {
        UITooltip.SetActive(show);
    }
}
